#!/usr/bin/env bash
# tests/test_organizer.sh
#
# Lightweight, dependency-free test suite (no bats, no external test
# framework — consistent with the "no unnecessary dependencies" rule).
# Every test runs inside a mktemp -d sandbox and cleans up after itself
# via a trap; the user's real files are never touched.

set -Eeuo pipefail

SCRIPT_DIR="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"
readonly SCRIPT_DIR
readonly ORGANIZER="${SCRIPT_DIR}/organizer.sh"

declare -i TESTS_RUN=0
declare -i TESTS_PASSED=0
declare -a FAILURES=()

pass() {
    TESTS_PASSED+=1
    echo "  PASS: $1"
}

fail() {
    FAILURES+=("$1")
    echo "  FAIL: $1"
}

run_test() {
    local name="$1"
    TESTS_RUN+=1
    echo "TEST: $name"
}

assert_exists() {
    if [[ -e "$1" ]]; then
        pass "$2"
    else
        fail "$2 (missing: $1)"
    fi
}

assert_not_exists() {
    if [[ ! -e "$1" ]]; then
        pass "$2"
    else
        fail "$2 (should not exist: $1)"
    fi
}

assert_eq() {
    if [[ "$1" == "$2" ]]; then
        pass "$3"
    else
        fail "$3 (expected '$2', got '$1')"
    fi
}

# new_sandbox
# Creates a fresh temp dir and returns its path on stdout.
new_sandbox() {
    mktemp -d "${TMPDIR:-/tmp}/organizer_test.XXXXXX"
}

# --- Test 1: Basic image/video/document categorization ------------------
test_basic_categorization() {
    run_test "basic categorization by extension"
    local dir
    dir="$(new_sandbox)"
    touch "$dir/photo.jpg" "$dir/movie.mp4" "$dir/report.pdf" "$dir/archive.zip"

    "$ORGANIZER" "$dir" >/dev/null

    assert_exists "$dir/Images/photo.jpg" "jpg moved to Images/"
    assert_exists "$dir/Videos/movie.mp4" "mp4 moved to Videos/"
    assert_exists "$dir/Documents/report.pdf" "pdf moved to Documents/"
    assert_exists "$dir/Archives/archive.zip" "zip moved to Archives/"

    rm -rf -- "$dir"
}

# --- Test 2: Unknown extension -> Others --------------------------------
test_unknown_extension() {
    run_test "unknown extension goes to Others/"
    local dir
    dir="$(new_sandbox)"
    touch "$dir/mystery.xyz123"

    "$ORGANIZER" "$dir" >/dev/null

    assert_exists "$dir/Others/mystery.xyz123" "unknown ext routed to Others/"

    rm -rf -- "$dir"
}

# --- Test 3: Duplicate filename handling --------------------------------
test_duplicate_filenames() {
    run_test "duplicate filenames get unique suffixes"
    local dir
    dir="$(new_sandbox)"
    mkdir -p "$dir/Images"
    : >"$dir/Images/photo.jpg" # pre-existing file in destination
    : >"$dir/photo.jpg"        # a second, different photo.jpg to move

    "$ORGANIZER" "$dir" >/dev/null

    assert_exists "$dir/Images/photo.jpg" "original photo.jpg untouched"
    assert_exists "$dir/Images/photo_1.jpg" "second photo.jpg renamed to photo_1.jpg"

    rm -rf -- "$dir"
}

# --- Test 4: Spaces and special characters in filenames ------------------
test_special_filenames() {
    run_test "filenames with spaces and special characters"
    local dir
    dir="$(new_sandbox)"
    touch "$dir/my photo (final) [v2].jpg"
    touch "$dir/report & summary.pdf"
    touch "$dir/it's a file!.txt"

    "$ORGANIZER" "$dir" >/dev/null

    assert_exists "$dir/Images/my photo (final) [v2].jpg" "spaces/parens/brackets handled"
    assert_exists "$dir/Documents/report & summary.pdf" "ampersand handled"
    assert_exists "$dir/Documents/it's a file!.txt" "apostrophe/bang handled"

    rm -rf -- "$dir"
}

# --- Test 5: Dry-run makes no changes ------------------------------------
test_dry_run() {
    run_test "dry-run does not modify the filesystem"
    local dir
    dir="$(new_sandbox)"
    touch "$dir/photo.jpg"

    "$ORGANIZER" "$dir" --dry-run >/dev/null

    assert_not_exists "$dir/Images" "no Images/ dir created during dry-run"
    assert_exists "$dir/photo.jpg" "photo.jpg remains in place during dry-run"

    rm -rf -- "$dir"
}

# --- Test 6: Invalid directory is rejected -------------------------------
test_invalid_directory() {
    run_test "invalid target directory is rejected"
    local rc=0
    "$ORGANIZER" "/nonexistent/path/hopefully_$$" >/dev/null 2>&1 || rc=$?
    assert_eq "$rc" "2" "invalid directory exits with code 2"
}

# --- Test 7: Recursive mode + no self-recursion --------------------------
test_recursive_mode() {
    run_test "recursive mode scans subdirs but not its own output"
    local dir
    dir="$(new_sandbox)"
    mkdir -p "$dir/sub"
    touch "$dir/sub/nested.png"
    touch "$dir/top.png"

    "$ORGANIZER" "$dir" --recursive >/dev/null
    # Run again to make sure category dirs aren't re-scanned/re-organized.
    "$ORGANIZER" "$dir" --recursive >/dev/null

    assert_exists "$dir/Images/nested.png" "nested file organized"
    assert_exists "$dir/Images/top.png" "top-level file organized"
    assert_not_exists "$dir/Images/Images" "no self-recursion into Images/Images"

    rm -rf -- "$dir"
}

# --- Test 8: Hidden files are skipped by default --------------------------
test_hidden_files_skipped() {
    run_test "hidden files are not touched by default"
    local dir
    dir="$(new_sandbox)"
    touch "$dir/.bashrc" "$dir/.hidden.jpg" "$dir/visible.jpg"

    "$ORGANIZER" "$dir" >/dev/null

    assert_exists "$dir/.bashrc" ".bashrc left in place"
    assert_exists "$dir/.hidden.jpg" ".hidden.jpg left in place (dotfile)"
    assert_exists "$dir/Images/visible.jpg" "visible.jpg still organized"

    rm -rf -- "$dir"
}

# --- Test 9: Non-fatal permission error doesn't abort the run -----------
test_permission_error_is_nonfatal() {
    run_test "a permission error on one file doesn't stop the whole run"
    if [[ "$(id -u)" -eq 0 ]]; then
        echo "  SKIP: running as root, permission test not meaningful"
        return
    fi
    local dir
    dir="$(new_sandbox)"
    touch "$dir/good.jpg" "$dir/blocked.jpg"
    mkdir -p "$dir/Images"
    chmod 000 "$dir/Images" # make destination unwritable

    local rc=0
    "$ORGANIZER" "$dir" >/dev/null 2>&1 || rc=$?

    chmod 755 "$dir/Images" # restore so cleanup can remove it
    assert_eq "$rc" "3" "run exits with code 3 (partial success) on a file error"

    rm -rf -- "$dir"
}

# --- Test 10: Undo restores a run -----------------------------------------
test_undo() {
    run_test "--undo restores files to their original location"
    local dir
    dir="$(new_sandbox)"
    touch "$dir/photo.jpg"

    "$ORGANIZER" "$dir" >/dev/null
    assert_exists "$dir/Images/photo.jpg" "file organized before undo"

    "$ORGANIZER" "$dir" --undo >/dev/null

    assert_exists "$dir/photo.jpg" "file restored to original location"
    assert_not_exists "$dir/Images/photo.jpg" "file no longer in Images/ after undo"

    rm -rf -- "$dir"
}

# --- Test 11: Undo refuses to overwrite on conflict -----------------------
test_undo_conflict() {
    run_test "--undo reports a conflict instead of overwriting"
    local dir
    dir="$(new_sandbox)"
    touch "$dir/photo.jpg"
    "$ORGANIZER" "$dir" >/dev/null

    # Recreate a *new* file at the original source path before undoing.
    echo "unrelated new content" >"$dir/photo.jpg"

    local output rc=0
    output="$("$ORGANIZER" "$dir" --undo 2>&1)" || rc=$?

    assert_exists "$dir/Images/photo.jpg" "original organized file untouched by undo conflict"
    if [[ "$output" == *CONFLICT* ]]; then
        pass "conflict reported instead of silently overwriting"
    else
        fail "expected a CONFLICT message in undo output"
    fi

    rm -rf -- "$dir"
}

# --- Test 12: an explicitly empty TARGET_DIR ("") must be rejected,
# never silently default to the current directory --------------------
#
# "" is a distinct, invalid input: it must not be treated the same as
# "no argument given" (which defaults to the current directory).
# See organizer.sh's argument parser (TARGET_DIR_SET).
test_empty_target_dir_rejected() {
    run_test "empty-string TARGET_DIR is rejected, not defaulted to cwd"
    local dir marker rc=0
    dir="$(new_sandbox)"

    # Run with CWD set to the sandbox and a canary file present. If the
    # bug were present, `organizer.sh ""` would organize $dir itself.
    marker="$dir/canary.jpg"
    touch "$marker"

    (cd "$dir" && "$ORGANIZER" "") >/dev/null 2>&1 && rc=0 || rc=$?

    assert_eq "$rc" "1" "empty TARGET_DIR exits with usage error (code 1)"
    assert_exists "$marker" "canary file untouched (cwd was NOT silently organized)"
    assert_not_exists "$dir/Images" "no Images/ dir created from the empty-arg call"

    rm -rf -- "$dir"
}

# --- Test 13: filenames containing a literal TAB or NEWLINE must not
# corrupt the history file or break --undo ---------------------------
#
# A transaction record is one physical line in logs/.history/*.tsv.
# If a path were written unescaped, a file named with a tab or newline
# would split that record across multiple lines and undo_last_run()
# would misparse it. Verify that the escaping in escape_for_record /
# unescape_from_record (lib/fsops.sh) round-trips correctly.
test_tab_newline_filenames_roundtrip_through_undo() {
    run_test "filenames with embedded TAB/NEWLINE survive organize + undo"
    local dir tab_file nl_file
    dir="$(new_sandbox)"

    tab_file="$(printf 'tab\tfile.txt')"
    nl_file="$(printf 'newline\nfile.txt')"
    : >"${dir}/${tab_file}"
    : >"${dir}/${nl_file}"

    "$ORGANIZER" "$dir" >/dev/null
    assert_exists "${dir}/Documents/${tab_file}" "tab-named file organized correctly"
    assert_exists "${dir}/Documents/${nl_file}" "newline-named file organized correctly"

    local history_file line_count
    history_file="$(find "$dir/logs/.history" -maxdepth 1 -name 'run_*.tsv')"
    line_count="$(wc -l <"$history_file")"
    assert_eq "$line_count" "2" "history file has exactly 2 lines (one per transaction, not corrupted)"

    "$ORGANIZER" "$dir" --undo >/dev/null
    assert_exists "${dir}/${tab_file}" "tab-named file correctly restored by undo"
    assert_exists "${dir}/${nl_file}" "newline-named file correctly restored by undo"

    rm -rf -- "$dir"
}

# --- Test 14: an explicit --config path that does not exist must fail
# loudly, never silently fall back to defaults ------------------------
test_missing_explicit_config_errors() {
    run_test "--config with a nonexistent path fails with exit 5"
    local dir rc=0
    dir="$(new_sandbox)"
    touch "$dir/photo.jpg"

    "$ORGANIZER" "$dir" --config "/nonexistent/config_$$.conf" >/dev/null 2>&1 && rc=0 || rc=$?

    assert_eq "$rc" "5" "missing --config path exits with code 5"
    assert_exists "$dir/photo.jpg" "file left untouched, not organized under wrong/default rules"

    rm -rf -- "$dir"
}

# --- Test 15: symlinks are never followed or moved -----------------
test_symlinks_never_touched() {
    run_test "symlinks (file, dir, broken) are left untouched"
    local dir outside rc=0
    dir="$(new_sandbox)"
    outside="$(new_sandbox)"
    touch "$outside/secret.txt"

    ln -s "$outside/secret.txt" "$dir/link_to_file.jpg"
    ln -s "$outside" "$dir/link_to_dir"
    ln -s "/nonexistent/target" "$dir/broken_link.jpg"
    touch "$dir/real.jpg"

    "$ORGANIZER" "$dir" --recursive >/dev/null || rc=$?

    assert_exists "$dir/Images/real.jpg" "the one real file was organized"
    assert_exists "$dir/link_to_file.jpg" "symlink-to-file left in place, untouched"
    assert_exists "$dir/link_to_dir" "symlink-to-dir left in place, untouched"
    # -e follows symlinks and is false for a broken link's (nonexistent)
    # target, so a broken symlink needs -L (does the link itself still
    # exist) rather than assert_exists's -e check.
    if [[ -L "$dir/broken_link.jpg" ]]; then
        pass "broken symlink left in place, untouched"
    else
        fail "broken symlink left in place, untouched (missing: $dir/broken_link.jpg)"
    fi
    assert_exists "$outside/secret.txt" "target of symlink outside sandbox was never touched"

    rm -rf -- "$dir" "$outside"
}

# --- Test 16: SIGINT during a run is reported accurately, not
# silently swallowed into a false "Completed successfully" ----------
#
# A SIGINT landing while files are being moved can close the `find`
# process substitution's pipe, making the main loop see a normal EOF
# and print a success summary for a run that was actually cut short —
# even though the file data is always safe (nothing lost, nothing
# duplicated). organizer.sh traps INT/TERM so interruption is reported
# explicitly with exit code 130/143 instead.
#
# Uses a large file count so the run reliably outlasts the signal;
# skips gracefully if `timeout` isn't available.
test_sigint_reported_accurately() {
    run_test "SIGINT mid-run is reported as interrupted, not as success"
    local dir outfile pid rc moved remaining waited attempt i

    for attempt in 1 2 3; do
        dir="$(new_sandbox)"
        for i in $(seq 1 5000); do
            : >"${dir}/file_${i}.jpg"
        done

        # Deterministic instead of racing a fixed wall-clock timeout: a
        # fixed `timeout -s INT 1` is flaky when the run happens to
        # finish faster than the 1-second window on a lightly-loaded
        # system. Polling for genuine partial progress (some files
        # already moved, most not) before sending the signal makes this
        # reliable regardless of system speed. The retry loop below
        # absorbs the residual case where the run finishes before the
        # signal lands — that is an environment timing fluke, not a
        # product defect.
        #
        # `set -m` (job control) matters here: without it, a
        # non-interactive script backgrounding a command with `&` has
        # SIGINT/SIGQUIT force-ignored for that child by bash/POSIX
        # itself (a shell-level rule, not something organizer.sh's own
        # `trap` can override) — a plain `kill -INT` on such a child
        # would silently do nothing and the run would simply complete
        # normally. `set -m` gives the background job its own process
        # group and normal signal behavior, like an interactive shell
        # would.
        local old_monitor_state
        old_monitor_state="$(set +o | grep monitor)"
        set -m
        outfile="$(mktemp)"
        "$ORGANIZER" "$dir" --verbose >"$outfile" 2>&1 &
        pid=$!

        waited=0
        while true; do
            moved="$(find "${dir}/Images" -type f 2>/dev/null | wc -l)" || true
            if ((moved >= 20)); then
                break
            fi
            if ! kill -0 "$pid" 2>/dev/null; then
                break # process already finished — stop polling either way
            fi
            sleep 0.01
            waited=$((waited + 1))
            if ((waited > 3000)); then
                break # ~30s safety cap against a hang
            fi
        done

        kill -INT "$pid" 2>/dev/null || true
        rc=0
        wait "$pid" || rc=$?
        eval "$old_monitor_state"

        moved="$(find "${dir}/Images" -type f 2>/dev/null | wc -l)" || true

        if ((moved < 5000)); then
            break # genuinely interrupted mid-way — proceed to assertions
        fi

        # Race: the run completed before the signal took effect. Clean
        # up and retry rather than failing the whole test on an
        # environment timing fluke.
        rm -f "$outfile"
        rm -rf -- "$dir"
        if ((attempt == 3)); then
            fail "run completed fully before it could be interrupted, on all 3 attempts — cannot validate interruption handling"
            return
        fi
    done

    local output
    output="$(cat "$outfile" 2>/dev/null)"
    rm -f "$outfile"

    remaining="$(find "$dir" -maxdepth 1 -type f | wc -l)" || true

    pass "run was genuinely interrupted mid-way ($moved of 5000 moved before signal)"
    assert_eq "$rc" "130" "interrupted run exits with 130 (SIGINT), not 0"
    if [[ "$output" == *"Interrupted"* ]]; then
        pass "output reports the run was interrupted"
    else
        fail "expected an 'Interrupted' message in output, got: $output"
    fi
    if [[ "$output" == *"Completed successfully"* ]]; then
        fail "output falsely claims 'Completed successfully' after interruption"
    else
        pass "no false 'Completed successfully' message after interruption"
    fi

    assert_eq "$((moved + remaining))" "5000" "no files lost or duplicated across the interruption"

    rm -rf -- "$dir"
}

# Reject category symlinks rather than moving files outside the target.
test_symlink_destination_rejected() {
    run_test "category symlink cannot redirect moves outside target"
    local dir outside rc
    dir="$(new_sandbox)"
    outside="$(new_sandbox)"
    touch "$dir/photo.jpg"
    ln -s "$outside" "$dir/Images"
    rc=0
    "$ORGANIZER" "$dir" >/dev/null 2>&1 || rc=$?
    assert_eq "$rc" "3" "unsafe destination is reported as an error"
    assert_exists "$dir/photo.jpg" "source remains in target"
    assert_not_exists "$outside/photo.jpg" "no file moved outside target"
    rm -rf -- "$dir" "$outside"
}

# --- Run all tests --------------------------------------------------
main() {
    if [[ ! -x "$ORGANIZER" ]]; then
        chmod +x "$ORGANIZER"
    fi

    test_basic_categorization
    test_unknown_extension
    test_duplicate_filenames
    test_special_filenames
    test_dry_run
    test_invalid_directory
    test_recursive_mode
    test_hidden_files_skipped
    test_permission_error_is_nonfatal
    test_undo
    test_undo_conflict
    test_empty_target_dir_rejected
    test_tab_newline_filenames_roundtrip_through_undo
    test_missing_explicit_config_errors
    test_symlinks_never_touched
    test_symlink_destination_rejected
    test_sigint_reported_accurately

    echo
    echo "========== TEST SUMMARY =========="
    echo "Tests run:    $TESTS_RUN"
    echo "Assertions passed: $TESTS_PASSED"
    echo "Assertions failed: ${#FAILURES[@]}"

    if [[ "${#FAILURES[@]}" -gt 0 ]]; then
        echo
        echo "Failed assertions:"
        printf '  - %s\n' "${FAILURES[@]}"
        exit 1
    fi

    echo
    echo "All tests passed."
}

main "$@"
