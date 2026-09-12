#!/usr/bin/env bash
#
# organizer.sh — organize files in a directory into category folders
# by file type.
#
# Part of the linux-file-organizer project.
# License: MIT (see LICENSE)
#
# This file is the orchestrator: parse args -> load config -> source
# libs -> validate target -> discover files -> move/simulate -> print
# stats. All safety-critical logic lives in lib/*.sh, sourced below.

set -Eeuo pipefail
IFS=$'\n\t'

readonly ORGANIZER_VERSION="1.0.0"

# --- Interruption handling ------------------------------------------
# Without an explicit trap, a SIGINT/SIGTERM that happens to land on
# the `find` process feeding the main loop's process substitution (see
# the main loop below) can close that pipe and make the `while read`
# loop see a normal EOF — letting the script fall through to the
# statistics section and print "Completed successfully" / exit 0 for a
# run that was actually cut short. The underlying data is never wrong
# (every file that was moved is correctly logged; nothing is lost or
# duplicated — verified under load with `timeout -s INT`), but that
# status message and exit code would be misleading. These traps make
# interruption an explicit, reported outcome instead of an incidental
# one.
_interrupted() {
    local sig="$1"
    echo >&2
    echo "Interrupted (SIG${sig}) — run stopped early." >&2
    echo "Files already moved before the interruption remain moved and logged;" >&2
    echo "nothing else was touched. Re-run to continue organizing the rest." >&2
    case "$sig" in
        INT) exit 130 ;;
        TERM) exit 143 ;;
    esac
}
trap '_interrupted INT' INT
trap '_interrupted TERM' TERM

# Resolve the real directory this script lives in, even if invoked via
# a symlink (e.g. after install.sh links it into ~/.local/bin), so
# `lib/` and `config/` are found regardless of the caller's CWD.
SCRIPT_SOURCE="${BASH_SOURCE[0]}"
while [[ -L "$SCRIPT_SOURCE" ]]; do
    SCRIPT_DIR="$(cd -P "$(dirname -- "$SCRIPT_SOURCE")" >/dev/null 2>&1 && pwd)"
    SCRIPT_SOURCE="$(readlink -- "$SCRIPT_SOURCE")"
    [[ "$SCRIPT_SOURCE" != /* ]] && SCRIPT_SOURCE="$SCRIPT_DIR/$SCRIPT_SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname -- "$SCRIPT_SOURCE")" >/dev/null 2>&1 && pwd)"
readonly SCRIPT_DIR

# --- Bash version guard -----------------------------------------------
# Requires Bash 4.3+: associative arrays (Bash 4.0+) for the category
# map, and namerefs (`local -n`, Bash 4.3+) used in
# escape_for_record_var for fork-free logging on large directories.
# Stock macOS still ships Bash 3.2; this project targets Linux but
# fails loudly rather than mysteriously on an old Bash.
if ((BASH_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 3))); then
    echo "error: organizer.sh requires Bash 4.3 or newer (found ${BASH_VERSION})" >&2
    exit 1
fi

# --- Source libraries ---------------------------------------------------
# shellcheck source=lib/categorize.sh
source "${SCRIPT_DIR}/lib/categorize.sh"
# shellcheck source=lib/fsops.sh
source "${SCRIPT_DIR}/lib/fsops.sh"
# shellcheck source=lib/logging.sh
source "${SCRIPT_DIR}/lib/logging.sh"
# shellcheck source=lib/history.sh
source "${SCRIPT_DIR}/lib/history.sh"

# --- Defaults (overridable by config/organizer.conf) --------------------
LOG_DIR_NAME="logs"
MAX_DUPLICATE_ATTEMPTS=9999

# --- Runtime state --------------------------------------------------
TARGET_DIR=""
TARGET_DIR_SET=""
DRY_RUN=0
RECURSIVE=0
VERBOSE=0
INCLUDE_HIDDEN=0
DO_UNDO=0
CONFIG_FILE=""

declare -i STAT_SCANNED=0
declare -i STAT_MOVED=0
declare -i STAT_SKIPPED=0
declare -i STAT_ERRORS=0
declare -A STAT_BY_CATEGORY=()

# ------------------------------------------------------------------
usage() {
    cat <<'EOF'
organizer.sh — organize files into category folders by type

USAGE:
    organizer.sh TARGET_DIR [OPTIONS]
    organizer.sh --undo [TARGET_DIR]
    organizer.sh --help
    organizer.sh --version

OPTIONS:
    --dry-run          Show what would happen; do not move any files.
    --recursive        Also scan subdirectories (excluding this tool's
                        own category output folders and logs/).
    --verbose          Print every file's action as it happens.
    --include-hidden   Also process dotfiles/dotdirs (excluded by
                        default for safety — see README "Hidden Files").
    --config PATH      Use PATH instead of config/organizer.conf.
    --undo             Restore files moved by the most recent run in
                        TARGET_DIR/logs (or the directory given after
                        --undo). Never overwrites existing files.
    --help             Show this help and exit.
    --version          Show version and exit.

EXAMPLES:
    organizer.sh ~/Downloads
    organizer.sh ~/Downloads --dry-run
    organizer.sh ~/Downloads --recursive --verbose
    organizer.sh ~/Downloads --undo

EXIT CODES:
    0    success
    1    invalid usage / arguments
    2    invalid target directory
    3    one or more files failed to move (partial success)
    4    undo completed with unresolved conflicts
    5    invalid configuration (--config file missing or has a syntax error)
    130  interrupted by SIGINT (Ctrl+C) — files moved so far are safe
    143  interrupted by SIGTERM — files moved so far are safe
EOF
}

version() {
    printf 'organizer.sh version %s\n' "$ORGANIZER_VERSION"
}

die_usage() {
    echo "error: $1" >&2
    echo >&2
    usage >&2
    exit 1
}

# load_config CONFIG_PATH EXPLICIT(0|1)
#
# Sources the config file if it exists. Config is plain Bash (variable
# assignments and EXT_TO_CATEGORY[...]=... overrides), consistent with
# the "no unnecessary dependencies" rule (no YAML/JSON parser needed).
# Config can only override *data* (paths, mappings) — it is sourced
# after `set -Eeuo pipefail` is already active and cannot disable
# safety flags, since it's just appending to variables/arrays already
# defined above.
#
# SECURITY NOTE: a config file is TRUSTED, EXECUTED Bash, not inert
# data — treat --config PATH with the same caution you would give to
# running a script. This tool never fetches or is pointed at a config
# path from untrusted input on its own; that responsibility belongs to
# whatever invokes it.
#
# EXPLICIT distinguishes two cases that must fail differently:
#   - default config (config/organizer.conf) missing -> silently skip;
#     the config file is optional and defaults apply.
#   - a config path the user passed via --config missing -> hard error
#     (exit 5). Silently falling back to default behavior when the user
#     explicitly asked for a specific config file would risk organizing
#     files under rules they did not intend, with no indication anything
#     was different.
#
# A config file with a Bash syntax error is rejected (exit 5) via a
# `bash -n` pre-check *before* sourcing, rather than being partially
# sourced and then aborting the whole script via `set -e` with an
# unrelated, misleading exit code.
load_config() {
    local config_path="$1" explicit="$2"
    local syntax_err_file

    if [[ ! -f "$config_path" ]]; then
        if [[ "$explicit" -eq 1 ]]; then
            echo "error: --config file not found: $config_path" >&2
            exit 5
        fi
        return 0
    fi

    syntax_err_file="$(mktemp)" || {
        echo "error: could not create a temp file to validate config syntax" >&2
        exit 5
    }

    if ! bash -n "$config_path" 2>"$syntax_err_file"; then
        echo "error: config file has a Bash syntax error: $config_path" >&2
        cat "$syntax_err_file" >&2
        rm -f "$syntax_err_file"
        exit 5
    fi
    rm -f "$syntax_err_file"

    # shellcheck source=/dev/null
    source "$config_path"
}

# --- Argument parsing -------------------------------------------------
if [[ $# -eq 0 ]]; then
    die_usage "TARGET_DIR is required (or use --undo / --help)"
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        --recursive) RECURSIVE=1 ;;
        --verbose) VERBOSE=1 ;;
        --include-hidden) INCLUDE_HIDDEN=1 ;;
        --undo) DO_UNDO=1 ;;
        --config)
            [[ $# -ge 2 ]] || die_usage "--config requires a path argument"
            CONFIG_FILE="$2"
            shift
            ;;
        --help | -h)
            usage
            exit 0
            ;;
        --version | -v)
            version
            exit 0
            ;;
        --)
            shift
            break
            ;;
        -*)
            die_usage "unknown option: $1"
            ;;
        *)
            if [[ -n "$TARGET_DIR_SET" ]]; then
                die_usage "unexpected extra argument: $1"
            fi
            # An explicitly empty string ("") is a distinct, invalid
            # input — it must NOT be confused with "no positional
            # argument given", which later defaults to the current
            # directory. Rejecting it here closes a bug where
            # `organizer.sh ""` silently organized the caller's
            # current working directory instead of failing loudly.
            if [[ -z "$1" ]]; then
                die_usage "TARGET_DIR must not be an empty string"
            fi
            TARGET_DIR="$1"
            TARGET_DIR_SET=1
            ;;
    esac
    shift
done

# --- Target directory validation ---------------------------------------
# Deliberate design choice: a file-MOVING tool never silently defaults
# to "the current directory" for the actual organize operation — that
# is exactly the class of bug where an unexpected/empty argument could
# cause files to be moved somewhere the caller didn't intend. An
# explicit TARGET_DIR is required for every mode except --undo, where
# defaulting to the current directory is low-risk (it only looks up a
# history file to restore from; it does not scan and move arbitrary
# files).
if [[ -z "${TARGET_DIR_SET:-}" ]]; then
    if [[ "$DO_UNDO" -eq 1 ]]; then
        TARGET_DIR="$(pwd)"
    else
        die_usage "TARGET_DIR is required (pass a directory, or use --undo)"
    fi
fi

if [[ ! -e "$TARGET_DIR" ]]; then
    echo "error: target directory does not exist: $TARGET_DIR" >&2
    exit 2
fi
if [[ ! -d "$TARGET_DIR" ]]; then
    echo "error: target path is not a directory: $TARGET_DIR" >&2
    exit 2
fi
if [[ ! -r "$TARGET_DIR" || ! -w "$TARGET_DIR" ]]; then
    echo "error: insufficient permissions on target directory: $TARGET_DIR" >&2
    exit 2
fi

# Resolve to an absolute path so log/history entries and prune paths are
# unambiguous regardless of the caller's CWD.
TARGET_DIR="$(cd -P -- "$TARGET_DIR" >/dev/null 2>&1 && pwd)"
LOG_DIR="${TARGET_DIR}/${LOG_DIR_NAME}"

# --- Load config (after defaults, before use) ---------------------------
if [[ -n "$CONFIG_FILE" ]]; then
    load_config "$CONFIG_FILE" 1
else
    load_config "${SCRIPT_DIR}/config/organizer.conf" 0
fi

# --- Undo path -----------------------------------------------------
if [[ "$DO_UNDO" -eq 1 ]]; then
    if undo_last_run "$LOG_DIR"; then
        exit 0
    else
        exit 4
    fi
fi

# --- Main organize run --------------------------------------------------
init_log "$LOG_DIR"
init_history "$LOG_DIR" || true # history is best-effort; run still proceeds

if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "DRY RUN — no files will be modified"
    echo
fi

while IFS= read -r -d '' file; do
    STAT_SCANNED+=1

    category="$(category_for_file "$file")"
    dest_dir="${TARGET_DIR}/${category}"

    # A file that already lives directly inside its own target category
    # directory (e.g. re-running the tool, or a file manually placed
    # there) needs no move. Skip it rather than performing a no-op
    # move through safe_move/mv.
    if [[ "$(dirname -- "$file")" == "$dest_dir" ]]; then
        STAT_SKIPPED+=1
        log_action "MOVE" "$file" "$dest_dir" "SKIPPED" "already in place"
        [[ "$VERBOSE" -eq 1 ]] && printf '  %-30s already in %s/\n' "${file##*/}" "$category"
        continue
    fi

    if safe_move "$file" "$dest_dir" "$DRY_RUN"; then
        STAT_MOVED+=1
        STAT_BY_CATEGORY["$category"]=$((${STAT_BY_CATEGORY["$category"]:-0} + 1))

        if [[ "$DRY_RUN" -eq 1 ]]; then
            printf '%-30s -> %s/\n' "${file##*/}" "$category"
        else
            log_action "MOVE" "$SAFE_MOVE_SRC" "$SAFE_MOVE_DEST" "SUCCESS"
            record_transaction "$SAFE_MOVE_SRC" "$SAFE_MOVE_DEST"
            [[ "$VERBOSE" -eq 1 ]] && printf '  %-30s -> %s/\n' "${file##*/}" "$category"
        fi
    else
        STAT_ERRORS+=1
        log_action "MOVE" "$SAFE_MOVE_SRC" "$dest_dir" "FAILURE" "$SAFE_MOVE_REASON"
        [[ "$VERBOSE" -eq 1 ]] && echo "  FAILED  : ${file##*/} -> ${SAFE_MOVE_REASON}"
    fi
done < <(discover_files "$TARGET_DIR" "$RECURSIVE" "$INCLUDE_HIDDEN")

# --- Statistics summary --------------------------------------------------
echo
echo "========== ORGANIZATION COMPLETE =========="
echo
printf 'Files scanned:  %5d\n' "$STAT_SCANNED"
printf 'Files moved:    %5d\n' "$STAT_MOVED"
printf 'Files skipped:  %5d\n' "$STAT_SKIPPED"
printf 'Errors:         %5d\n' "$STAT_ERRORS"
echo

if [[ "${#STAT_BY_CATEGORY[@]}" -gt 0 ]]; then
    for category in "${!STAT_BY_CATEGORY[@]}"; do
        printf '%-15s %5d\n' "${category}:" "${STAT_BY_CATEGORY[$category]}"
    done | sort
    echo
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "Dry run complete. No files were modified."
elif [[ "$STAT_ERRORS" -eq 0 ]]; then
    echo "Completed successfully."
else
    echo "Completed with ${STAT_ERRORS} error(s). See log: ${ORGANIZER_LOG_FILE:-N/A}"
fi

[[ "$STAT_ERRORS" -eq 0 ]] || exit 3
exit 0
