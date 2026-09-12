# linux-file-organizer

A safe, dependency-free Bash CLI utility that organizes files in a
directory into category folders by file type — with dry-run preview,
recursive scanning, duplicate-safe renaming, logging, and undo.

Built as a Linux/Bash portfolio project with a deliberate focus on the
things that actually break naive file-organizing scripts: filenames with
spaces and unicode, accidental overwrites, symlink traversal, and
runaway self-recursion.

## Features

- **Type-based categorization** — Images, Videos, Audio, Documents,
  Spreadsheets, Presentations, Archives, Code, Disk Images, Packages,
  and Others, all easily extended via config.
- **Dry-run mode** (`--dry-run`) — see exactly what would happen, with
  zero filesystem changes.
- **Recursive mode** (`--recursive`) — scans subdirectories, and is
  structurally prevented from re-scanning its own output folders.
- **Never overwrites files** — automatic `name_1.ext`, `name_2.ext`
  duplicate resolution, plus a `mv -n` safety net against race
  conditions.
- **Safe with any filename** — spaces, parentheses, brackets, quotes,
  `&`, `!`, unicode. Iteration uses NUL-delimited `find -print0`, never
  a naive `for f in $(ls ...)`.
- **Hidden files protected by default** — dotfiles/dotdirs are never
  touched unless you explicitly pass `--include-hidden`.
- **Logging** — a human-readable, timestamped log of every action.
- **Undo** (`--undo`) — restores the most recent run from a separate
  machine-readable transaction record, never overwriting on conflict.
- **Configurable** — extension → category mapping, log location, and
  duplicate-resolution limits are all overridable via
  `config/organizer.conf` without editing the script.
- **Tested** — a 16-test suite covering categorization, duplicates,
  special filenames, dry-run, recursion, hidden files, permission
  errors, symlink safety, config errors, SIGINT interruption, and undo
  (including the historical empty-target-directory and
  embedded-tab/newline-filename regressions), run entirely inside
  `mktemp` sandboxes.
- **ShellCheck-clean** — `shellcheck -x` passes with zero warnings
  across every script.

## Demo

```
$ organizer ~/Downloads --dry-run
DRY RUN — no files will be modified

photo.jpg                      -> Images/
movie.mp4                      -> Videos/
report.pdf                     -> Documents/
project.zip                    -> Archives/

========== ORGANIZATION COMPLETE ==========

Files scanned:      4
Files moved:        4
Files skipped:      0
Errors:             0

Archives:           1
Documents:          1
Images:             1
Videos:             1

Dry run complete. No files were modified.
```

### Screenshots

_(placeholder — add a terminal screenshot or asciinema recording here)_

## Installation

**Requirements:** Bash 4.3+ (for associative arrays and namerefs — the
script checks this itself at startup and fails with a clear message on
anything older). No other dependencies; `shellcheck`/`shfmt` are only
needed for development, not for running the tool.

```bash
git clone https://github.com/Kapilesh-T/linux-file-organizer.git
cd linux-file-organizer
./install.sh
```

No root required — this symlinks `organizer.sh` into `~/.local/bin/organizer`.
See [docs/usage.md](docs/usage.md) for PATH setup details.

To remove it:

```bash
./uninstall.sh
```

## Usage

```bash
organizer.sh TARGET_DIR [OPTIONS]
organizer.sh --undo [TARGET_DIR]
organizer.sh --help
organizer.sh --version
```

```bash
organizer ~/Downloads
organizer ~/Downloads --dry-run
organizer ~/Downloads --recursive --verbose
organizer ~/Downloads --undo
```

Full walkthrough: [docs/usage.md](docs/usage.md)

## CLI Options

| Option | Description |
|---|---|
| `--dry-run` | Show what would happen; modify nothing. |
| `--recursive` | Also scan subdirectories (excludes own output + `logs/`). |
| `--verbose` | Print each file's action as it happens. |
| `--include-hidden` | Also process dotfiles/dotdirs (off by default). |
| `--config PATH` | Use an alternate config file for this run. |
| `--undo` | Restore files moved by the most recent run. |
| `--help` | Show usage help. |
| `--version` | Show version. |

## Supported File Types

| Category | Extensions |
|---|---|
| Images | jpg, jpeg, png, gif, webp, svg, bmp |
| Videos | mp4, mkv, avi, mov, webm, flv |
| Audio | mp3, wav, flac, aac, ogg, m4a |
| Documents | pdf, doc, docx, txt, odt, rtf |
| Spreadsheets | xls, xlsx, csv, ods |
| Presentations | ppt, pptx, odp |
| Archives | zip, tar, gz, bz2, xz, 7z, rar |
| Code | c, cpp, h, hpp, py, js, ts, java, go, rs, php, sh, html, css |
| Disk Images | iso, img |
| Packages | deb, rpm, AppImage |
| Others | anything unrecognized, or no extension |

Multi-extension files (e.g. `archive.tar.gz`) are categorized by their
*last* extension component (`.gz` → Archives) — a deliberate
simplification documented here rather than silent behavior.

## Configuration

`config/organizer.conf` is plain, sourced Bash — no external parser
dependency. Override or extend the category mapping, change the log
directory name, or adjust the duplicate-resolution attempt cap. See
[docs/usage.md](docs/usage.md#configuration) for examples.

**Security note:** a config file is executed Bash, not inert data —
`--config PATH` should only ever point at a file you trust. An explicitly
passed `--config` that's missing or has a syntax error fails the run
immediately (exit `5`) rather than silently falling back to defaults.

## Logging

Every run writes `TARGET_DIR/logs/organizer_<timestamp>.log`:

```
2026-09-09 14:30:12 | MOVE   | /home/user/Downloads/photo.jpg | /home/user/Downloads/Images/photo.jpg | SUCCESS
```

Only paths, actions, and status are logged — never file contents.

## Undo / Recovery

`--undo` replays the most recent run's transactions in reverse, using a
separate machine-readable record in `logs/.history/`. It never overwrites
an existing file — a blocked restore is reported as a `CONFLICT`, not
silently skipped or forced. This is intentionally a **single-run** undo,
not a general version-control system — see
[docs/usage.md](docs/usage.md#undo--recovery) for exact semantics and
limitations.

## Testing

```bash
./tests/test_organizer.sh
```

Runs 16 tests (44 assertions as root — 45 as a non-root user, since the
permission-error test only runs a real check when not root) entirely
inside `mktemp -d` sandboxes — your real files are never touched, and
sandboxes are cleaned up automatically. Covers categorization, unknown
extensions, duplicate filenames, special/unicode filenames, dry-run
correctness, invalid directories, recursive mode + anti-self-recursion,
hidden-file protection, non-fatal permission errors, symlink safety
(file, directory, and broken symlinks are never touched), missing/invalid
`--config` handling, SIGINT interruption (reported accurately, no data
loss), and undo (including conflict handling, and filenames containing
embedded tab/newline characters).

## Security / Safety Considerations

This project is part of a cybersecurity portfolio, so secure Bash
practice is treated as a first-class concern, not an afterthought:

- **Input validation** — the target directory is checked for existence,
  directory-ness, and read/write permission before anything else runs.
- **Quoting discipline** — every variable expansion touching a filename
  is double-quoted; no bare `$var` is used where a filename could
  contain spaces, globs, or other shell metacharacters.
- **Safe iteration** — files are discovered and iterated using
  NUL-delimited `find ... -print0` / `read -r -d ''`, the only fully
  safe way to handle arbitrary filenames in Bash (handles spaces,
  newlines, unicode — everything except NUL, which can't appear in a
  Unix filename).
- **No command injection surface** — filenames are never passed through
  `eval`, and are never interpolated into a command string; they're
  always passed as discrete, quoted arguments.
- **No overwrite, ever** — a pre-move existence check plus `mv -n`
  (`--no-clobber`) as a second layer of defense against a
  check-then-act (TOCTOU) race.
- **Symlink caution** — `find` runs without `-L`, so it never follows
  symlinked directories, and `-type f` never matches a symlink itself
  (file or directory). In practice this means **any symlink inside the
  target directory — to a file, to a directory, or broken — is left
  untouched and never reported**, and a `--recursive` scan can never
  wander outside the target directory tree through one. Verified with
  a symlink to a file outside the target dir, a symlink to a directory
  outside the target dir, and a broken symlink — none were moved,
  modified, or caused anything outside the target directory to be
  touched.
- **Least privilege** — the tool never requires root, and `install.sh`
  installs into the user's own `~/.local/bin`, not a system directory.
- **Safe logging** — logs record paths and status only, never file
  contents, avoiding accidental disclosure of sensitive data in a log
  file that may be less carefully protected than the files themselves.
- **Bounded loops** — duplicate-filename resolution is capped
  (`MAX_DUPLICATE_ATTEMPTS`) rather than able to loop indefinitely.
- **Log/history injection resistance** — filenames containing a literal
  TAB, NEWLINE, or the human log's own `|` delimiter are escaped before
  being written, so one logical record always occupies exactly one line
  in both the human log and the machine-readable undo history.
  Without this, such a filename could split a record across lines and
  cause `--undo` to misparse it (found and fixed during audit).
- **Safe interruption** — `organizer.sh` traps `SIGINT`/`SIGTERM`
  explicitly: an interrupted run is reported as interrupted (exit `130`
  or `143`), never silently reported as a successful completion. Files
  already moved before the interruption stay correctly moved and
  logged; nothing else is touched, and nothing is lost or duplicated.

This project does **not** claim to be exhaustively audited or
"military-grade" — see [Future Improvements](#future-improvements) for
known limitations.

## Project Structure

```
linux-file-organizer/
├── organizer.sh          # Orchestrator: parses args, wires everything together
├── install.sh             # User-level (no root) installer
├── uninstall.sh           # Removes only what install.sh created
├── lib/
│   ├── categorize.sh       # Extension -> category mapping + lookup
│   ├── fsops.sh             # Safe file discovery + the only move function
│   ├── logging.sh           # Human-readable action log
│   └── history.sh           # Machine-readable transaction log + undo
├── config/
│   └── organizer.conf       # User-overridable settings
├── tests/
│   └── test_organizer.sh    # 16-test suite, sandboxed with mktemp
├── docs/
│   └── usage.md              # Full usage guide
├── logs/                    # Created per-run; contents gitignored
├── LICENSE
└── .gitignore
```

The `lib/` split (beyond a single monolithic script) exists so each
concern is independently testable and independently ShellCheck-clean —
see the commit history / design notes for the full reasoning.

## Troubleshooting

See [docs/usage.md](docs/usage.md#troubleshooting) for a full table of
common issues and fixes.

## Future Improvements

- Multi-level undo (chain across several runs, not just the latest)
- Parallel processing for very large directories
- An opt-in JSON/machine-readable output mode for scripting
- Optional MIME-type detection (via `file`) as a fallback for files
  with no or a misleading extension
- Packaging (`.deb`) for easier distribution

## Contributing

Issues and pull requests are welcome. Please run `shellcheck -x` and
`./tests/test_organizer.sh` before submitting — both must pass cleanly.

## License

[MIT](LICENSE)

---

### Suggested GitHub metadata

**Description:** A safe, tested, ShellCheck-clean Bash CLI that organizes files by type — with dry-run, recursive mode, and undo.

**Topics:** `linux` `bash` `shell-script` `linux-utility` `file-organizer` `automation` `cybersecurity` `cli`
