#!/usr/bin/env bash
# lib/history.sh
#
# Machine-readable transaction records and the --undo mechanism.
#
# Honesty about scope (documented in README too): this is a *single-run*
# undo, not a general version-control system. It replays the most recent
# run's transactions in reverse and refuses (rather than overwrites) on
# any conflict. It does not chain across multiple runs.
# shellcheck shell=bash

if [[ -n "${_ORGANIZER_HISTORY_LOADED:-}" ]]; then
    return 0
fi
_ORGANIZER_HISTORY_LOADED=1

ORGANIZER_HISTORY_DIR=""
ORGANIZER_HISTORY_FILE=""

# init_history LOG_DIR
#
# Sets up LOG_DIR/.history/<run_id>.tsv as this run's transaction file,
# and updates LOG_DIR/.history/LATEST to point at it (used by --undo to
# find "the most recent run" without needing to sort filenames).
init_history() {
    local log_dir="$1"
    local ts
    ts="$(date '+%Y%m%d_%H%M%S')"

    ORGANIZER_HISTORY_DIR="${log_dir}/.history"
    mkdir -p -- "$ORGANIZER_HISTORY_DIR" 2>/dev/null || {
        echo "warning: could not create history directory; --undo will not be available for this run" >&2
        return 1
    }

    ORGANIZER_HISTORY_FILE="${ORGANIZER_HISTORY_DIR}/run_${ts}.tsv"
    : >"$ORGANIZER_HISTORY_FILE" 2>/dev/null || {
        ORGANIZER_HISTORY_FILE=""
        return 1
    }

    printf '%s\n' "$ORGANIZER_HISTORY_FILE" >"${ORGANIZER_HISTORY_DIR}/LATEST"
}

# record_transaction SRC DEST
#
# Appends one successful move to this run's transaction file. Only ever
# called for moves that actually succeeded (never for dry-run or failed
# moves) — the history file is a record of real, undoable state changes.
record_transaction() {
    local src="$1" dest="$2"
    local ts esrc edest
    [[ -z "$ORGANIZER_HISTORY_FILE" ]] && return 0
    # Escaped so a filename containing a literal TAB or NEWLINE can
    # never split one logical transaction across multiple physical
    # lines or extra TSV fields — see escape_for_record in
    # lib/fsops.sh. This is the critical path: an unescaped record
    # here would cause undo_last_run() to misparse src/dest and
    # either fail to restore the file or, in principle, pair the
    # wrong src with the wrong dest.
    #
    # Uses the _var / builtin-strftime variants (no subshell forks) —
    # this runs once per moved file, so fork count matters at scale.
    escape_for_record_var esrc "$src"
    escape_for_record_var edest "$dest"
    printf -v ts '%(%Y-%m-%d %H:%M:%S)T' -1
    printf '%s\t%s\t%s\n' "$esrc" "$edest" "$ts" >>"$ORGANIZER_HISTORY_FILE"
}

# undo_last_run LOG_DIR
#
# Reads LOG_DIR/.history/LATEST, then replays that run's transactions in
# reverse (last move undone first), moving each file from its recorded
# destination back to its recorded source.
#
# Conflict handling: if the original source path is now occupied by
# something else, that entry is reported as a CONFLICT and skipped —
# never overwritten. Returns 0 if all entries were restored cleanly,
# non-zero if any conflicts or errors occurred (so callers can set a
# meaningful exit code).
undo_last_run() {
    local log_dir="$1"
    local history_dir="${log_dir}/.history"
    local latest_pointer="${history_dir}/LATEST"
    local run_file
    local -i restored=0 conflicts=0 missing=0

    if [[ ! -f "$latest_pointer" ]]; then
        echo "error: no previous run found to undo (no ${latest_pointer})" >&2
        return 1
    fi

    run_file="$(<"$latest_pointer")"
    if [[ ! -f "$run_file" ]]; then
        echo "error: recorded run file '$run_file' no longer exists" >&2
        return 1
    fi

    echo "Undoing run: $run_file"

    # Read into an array first so we can iterate in reverse order
    # (undo last-moved-file first), rather than depending on `tac`
    # (not POSIX/portable, and not present on every minimal system).
    local -a lines=()
    while IFS=$'\t' read -r src dest _ts; do
        lines+=("${src}"$'\t'"${dest}")
    done <"$run_file"

    local i
    for ((i = ${#lines[@]} - 1; i >= 0; i--)); do
        IFS=$'\t' read -r src dest <<<"${lines[$i]}"
        # Reverse escape_for_record's encoding (see lib/fsops.sh and
        # record_transaction above) to recover the real filesystem
        # paths before using them in the -e/mv tests below.
        src="$(unescape_from_record "$src")"
        dest="$(unescape_from_record "$dest")"

        if [[ ! -e "$dest" ]]; then
            echo "  MISSING  : $dest (already moved or deleted, skipping)"
            missing=$((missing + 1))
            continue
        fi

        if [[ -e "$src" ]]; then
            echo "  CONFLICT : $src already exists, not restoring $dest"
            conflicts=$((conflicts + 1))
            continue
        fi

        mkdir -p -- "$(dirname -- "$src")" 2>/dev/null
        if mv -n -- "$dest" "$src" 2>/dev/null; then
            echo "  RESTORED : $dest -> $src"
            restored=$((restored + 1))
        else
            echo "  FAILED   : could not restore $dest -> $src"
            conflicts=$((conflicts + 1))
        fi
    done

    echo
    echo "Undo complete: ${restored} restored, ${conflicts} conflicts/failures, ${missing} missing."

    ((conflicts == 0))
}
