#!/usr/bin/env bash
# lib/fsops.sh
#
# Safe filesystem operations: discovering files to organize and moving
# them without ever overwriting an existing file. This is the
# safety-critical part of the project — every rule here exists because
# of a specific, real Bash file-handling failure mode.
# shellcheck shell=bash
#
# File-wide: SAFE_MOVE_SRC / SAFE_MOVE_DEST / SAFE_MOVE_REASON below
# are set here and read by organizer.sh after calling safe_move() —
# ShellCheck can't see that cross-file usage when analyzing this file
# in isolation, so SC2034 ("appears unused") is a false positive for
# all three at every assignment site in this file.
# shellcheck disable=SC2034

if [[ -n "${_ORGANIZER_FSOPS_LOADED:-}" ]]; then
    return 0
fi
_ORGANIZER_FSOPS_LOADED=1

# discover_files TARGET_DIR RECURSIVE(0|1) INCLUDE_HIDDEN(0|1)
#
# Prints NUL-separated paths of files to process, one per invocation of
# the caller's read loop. Deliberately NUL-delimited (not newline) so
# filenames containing spaces, tabs, or even embedded newlines are
# handled correctly — newline-delimited output is the classic Bash
# file-listing bug (`for f in $(find ...)`) and is not used anywhere in
# this project.
#
# Excludes:
#   - hidden files/dirs (dotfiles), unless INCLUDE_HIDDEN=1
#   - this tool's own category output directories (Images/, Videos/,
#     ... see categorize.sh:all_category_names) and the logs/ directory,
#     so a --recursive run can never re-organize its own output and
#     loop forever.
discover_files() {
    local target_dir="$1" recursive="$2" include_hidden="$3"
    local -a prune_args=()
    local cat

    # Build a -path .../CategoryName -prune -o ... clause for every
    # known category, so find never descends into them.
    while IFS= read -r cat; do
        prune_args+=(-path "${target_dir}/${cat}" -prune -o)
    done < <(all_category_names)
    prune_args+=(-path "${target_dir}/logs" -prune -o)

    local -a hidden_args=()
    if [[ "$include_hidden" -ne 1 ]]; then
        # Exclude any path component starting with '.' at any depth.
        hidden_args=(-not -path '*/.*')
    fi

    local -a depth_args=()
    if [[ "$recursive" -ne 1 ]]; then
        depth_args=(-maxdepth 1)
    fi

    # -L intentionally omitted: symlinked directories are NOT followed.
    # Following symlinks during a recursive organize could walk outside
    # the target directory tree entirely, which is an unacceptable risk
    # for a tool that moves files. This is documented in the README.
    find "$target_dir" "${depth_args[@]}" "${prune_args[@]}" \
        -type f "${hidden_args[@]}" -print0
}

# unique_destination DEST_DIR FILENAME
#
# Prints a path inside DEST_DIR that does not currently exist, based on
# FILENAME. If DEST_DIR/FILENAME is free, prints it unchanged. Otherwise
# tries FILENAME with _1, _2, ... inserted before the extension until a
# free name is found (photo.jpg -> photo_1.jpg -> photo_2.jpg ...).
#
# The loop is bounded (MAX_DUPLICATE_ATTEMPTS) so a pathological
# directory full of pre-existing "name_N.ext" files cannot spin forever.
unique_destination() {
    local dest_dir="$1" filename="$2"
    local stem ext candidate attempt=0
    local -i max_attempts="${MAX_DUPLICATE_ATTEMPTS:-9999}"

    if [[ "$filename" == *.* && "$filename" != .* ]]; then
        stem="${filename%.*}"
        ext=".${filename##*.}"
    else
        stem="$filename"
        ext=""
    fi

    candidate="$dest_dir/$filename"
    while [[ -e "$candidate" ]]; do
        attempt=$((attempt + 1))
        if ((attempt > max_attempts)); then
            return 1
        fi
        candidate="$dest_dir/${stem}_${attempt}${ext}"
    done

    printf '%s\n' "$candidate"
}

# escape_for_record TEXT
#
# Encodes TEXT so it always occupies exactly one line in a persisted
# log/history record, regardless of embedded TAB or NEWLINE characters
# in a filename (both are legal in Unix filenames). Without this, a
# filename containing a real tab or newline would split a single
# logical log/history entry across multiple physical lines, corrupting
# the field structure that both the human log and --undo's TSV parser
# depend on — a real "log injection" risk, not just a cosmetic one.
#
# Backslash is escaped FIRST so the scheme is unambiguous to reverse:
# after this step, every backslash in the output is guaranteed to be
# part of one of exactly three two-character tokens (\\, \t, \n), never
# a stray single backslash — see unescape_from_record.
escape_for_record() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//$'\t'/\\t}"
    s="${s//$'\n'/\\n}"
    printf '%s' "$s"
}

# escape_for_record_var VARNAME TEXT
#
# Same encoding as escape_for_record, but writes the result directly
# into the variable named VARNAME via `printf -v` instead of returning
# it on stdout. Performance matters here: logging and history run once
# per file, and `x="$(escape_for_record "$y")"` forks a subshell every
# call. On a directory with thousands of files those forks are the
# dominant cost (measured: ~7ms/file, mostly process-creation
# overhead) — this variant does the same work with zero forks.
escape_for_record_var() {
    local -n _out="$1"
    local s="$2"
    s="${s//\\/\\\\}"
    s="${s//$'\t'/\\t}"
    s="${s//$'\n'/\\n}"
    _out="$s"
}

# unescape_from_record TEXT
#
# Reverses escape_for_record. `printf '%b'` decodes exactly the \\, \t,
# \n sequences we ever produce (and nothing else, since escape_for_record
# never emits any other backslash sequence), so this round-trips exactly.
unescape_from_record() {
    printf '%b' "$1"
}

# safe_move SRC DEST_DIR DRY_RUN(0|1)
#
# The ONLY function in this project permitted to move a file. Centralizing
# the operation here means every safety property (no-overwrite, quoting,
# logging hook) is enforced in exactly one place.
#
# Communicates its result via the SAFE_MOVE_SRC / SAFE_MOVE_DEST /
# SAFE_MOVE_REASON globals rather than a delimited string on stdout.
# An earlier version encoded the result as "STATUS<TAB>SRC<TAB>DEST" on
# stdout for the caller to re-parse; a filename containing a literal
# tab or newline could collide with that delimiter and cause the
# caller to mis-parse its own success/failure result. Globals avoid
# the problem entirely — no delimiter, no parsing, no collision.
#
# Returns 0 on success (or a successful dry-run simulation), non-zero
# on failure. Callers (organizer.sh) are responsible for logging the
# result and continuing to the next file — a single failed file must
# never abort the whole run.
# SAFE_MOVE_SRC / SAFE_MOVE_DEST / SAFE_MOVE_REASON are the current
# result of the most recent safe_move() call (see file header).
SAFE_MOVE_SRC=""
SAFE_MOVE_DEST=""
SAFE_MOVE_REASON=""

safe_move() {
    local src="$1" dest_dir="$2" dry_run="$3"
    local filename dest

    SAFE_MOVE_SRC="$src"
    SAFE_MOVE_DEST=""
    SAFE_MOVE_REASON=""

    filename="${src##*/}"

    if [[ ! -e "$dest_dir" ]]; then
        if [[ "$dry_run" -eq 1 ]]; then
            : # Simulate directory creation; nothing to do in dry-run.
        elif ! mkdir -p -- "$dest_dir" 2>/dev/null; then
            SAFE_MOVE_REASON="could not create destination dir $dest_dir"
            return 1
        fi
    fi

    if ! dest="$(unique_destination "$dest_dir" "$filename")"; then
        SAFE_MOVE_REASON="too many name collisions in $dest_dir"
        return 1
    fi
    SAFE_MOVE_DEST="$dest"

    if [[ "$dry_run" -eq 1 ]]; then
        return 0
    fi

    # -n (--no-clobber) is a second layer of defense against a
    # TOCTOU race between unique_destination()'s check and this mv:
    # if something else creates the destination in that tiny window,
    # mv -n refuses instead of overwriting, and we treat that as a
    # normal, loggable failure rather than a crash.
    if mv -n -- "$src" "$dest" 2>/dev/null; then
        return 0
    else
        SAFE_MOVE_REASON="mv failed (permissions or race condition)"
        return 1
    fi
}
