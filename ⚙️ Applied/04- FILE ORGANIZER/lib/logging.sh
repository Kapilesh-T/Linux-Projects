#!/usr/bin/env bash
# lib/logging.sh
#
# Human-readable, append-only action logging. Deliberately separate from
# lib/history.sh, which writes a machine-readable transaction record for
# --undo. Keeping these separate means the human log's format can change
# freely for readability without ever risking the undo feature.
# shellcheck shell=bash

if [[ -n "${_ORGANIZER_LOGGING_LOADED:-}" ]]; then
    return 0
fi
_ORGANIZER_LOGGING_LOADED=1

ORGANIZER_LOG_FILE=""

# init_log LOG_DIR
#
# Creates LOG_DIR if needed and sets ORGANIZER_LOG_FILE to a fresh,
# timestamped log file for this run. No-op-safe to call in dry-run mode
# too, so dry-run output can optionally be logged for review.
init_log() {
    local log_dir="$1"
    local ts
    ts="$(date '+%Y%m%d_%H%M%S')"

    if [[ ! -d "$log_dir" ]]; then
        mkdir -p -- "$log_dir" 2>/dev/null || {
            echo "warning: could not create log directory '$log_dir'; logging to /tmp" >&2
            log_dir="/tmp"
        }
    fi

    ORGANIZER_LOG_FILE="${log_dir}/organizer_${ts}.log"
    : >"$ORGANIZER_LOG_FILE" 2>/dev/null || ORGANIZER_LOG_FILE=""
}

# log_action ACTION SRC DEST STATUS [DETAIL]
#
# Appends one line to ORGANIZER_LOG_FILE in the documented format:
#   TIMESTAMP | ACTION | SRC | DEST | STATUS [| DETAIL]
# Does not store file contents or any data beyond paths/status — no
# sensitive information beyond what's already visible in the filesystem
# itself is written to the log.
log_action() {
    local action="$1" src="$2" dest="$3" status="$4" detail="${5:-}"
    local ts

    [[ -z "$ORGANIZER_LOG_FILE" ]] && return 0

    # Bash builtin strftime (no `date` subprocess fork — see
    # escape_for_record_var below for why per-file fork count matters).
    printf -v ts '%(%Y-%m-%d %H:%M:%S)T' -1

    # Escaped so a filename containing a literal TAB or NEWLINE can
    # never split one logical log entry across multiple physical lines
    # (see escape_for_record in lib/fsops.sh for why this matters).
    # The pipe character is escaped too, separately: it's this log's
    # own field delimiter, so a filename containing literal " | " text
    # (a real, observed case — e.g. "a | touch hacked.txt") would
    # otherwise be indistinguishable from an extra field boundary when
    # a human or a script parses the line by splitting on " | ".
    escape_for_record_var src "$src"
    escape_for_record_var dest "$dest"
    escape_for_record_var detail "$detail"
    src="${src//|/\\|}"
    dest="${dest//|/\\|}"
    detail="${detail//|/\\|}"

    if [[ -n "$detail" ]]; then
        printf '%s | %-6s | %s | %s | %s | %s\n' \
            "$ts" "$action" "$src" "$dest" "$status" "$detail" \
            >>"$ORGANIZER_LOG_FILE"
    else
        printf '%s | %-6s | %s | %s | %s\n' \
            "$ts" "$action" "$src" "$dest" "$status" \
            >>"$ORGANIZER_LOG_FILE"
    fi
}
