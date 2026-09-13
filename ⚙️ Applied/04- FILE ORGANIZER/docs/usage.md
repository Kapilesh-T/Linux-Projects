# Usage Guide

## Installation

```bash
cd "⚙️ Applied/04- FILE ORGANIZER"
./install.sh
```

This symlinks `organizer.sh` into `~/.local/bin/organizer`. No root required.
If `~/.local/bin` isn't already on your `PATH`, `install.sh` will tell you
exactly what to add to `~/.bashrc` or `~/.profile`.

Without installing, you can always run it directly:

```bash
./organizer.sh ~/Downloads
```

## Basic Usage

```bash
organizer ~/Downloads
```

This scans the top level of `~/Downloads` (not subdirectories — see
[Recursive Mode](#recursive-mode)), moves each file into a category folder
next to it (`Images/`, `Videos/`, `Documents/`, ...), and prints a summary.

## Dry Run

Always safe to run first — simulates the entire operation without touching
any files:

```bash
organizer ~/Downloads --dry-run
```

Output:

```
DRY RUN — no files will be modified

photo.jpg                      -> Images/
movie.mp4                      -> Videos/
report.pdf                     -> Documents/
project.zip                    -> Archives/

========== ORGANIZATION COMPLETE ==========
...
Dry run complete. No files were modified.
```

## Recursive Mode

```bash
organizer ~/Downloads --recursive
```

Scans subdirectories too. The organizer automatically excludes its own
category output folders (`Images/`, `Videos/`, etc.) and `logs/` from the
scan — so running it twice in a row never re-organizes already-organized
files into nested category folders. **Any symlink is skipped entirely** —
not just "not followed": a symlink to a file, a symlink to a directory,
and a broken symlink are all left exactly as-is and never appear in the
output, so the scan can never step outside the target directory tree
through one.

## Verbose Mode

```bash
organizer ~/Downloads --verbose
```

Prints each file's action as it happens (in addition to the final summary),
useful for large directories where you want to watch progress.

## Hidden Files

By default, **dotfiles and dotdirectories are never touched** — at any
depth, even in `--recursive` mode. This protects things like `.bashrc`,
`.profile`, and `.config/` from ever being moved. If you deliberately want
hidden files organized too:

```bash
organizer ~/some-dir --include-hidden
```

## Configuration

Edit `config/organizer.conf` (plain Bash, sourced at startup) to:

- Add or override extension → category mappings
- Change the log directory name
- Change the duplicate-resolution attempt limit

Example:

```bash
EXT_TO_CATEGORY[heic]="Images"
EXT_TO_CATEGORY[epub]="Ebooks"
```

Use a different config file for a specific run with `--config PATH`. If
that path doesn't exist, or contains a Bash syntax error, the run fails
immediately with exit code `5` rather than silently falling back to
default behavior — organizing files under rules you didn't intend, with
no warning, would be worse than a hard stop.

**Security note:** `organizer.conf` (and any file passed via `--config`)
is plain Bash that gets *executed* (via `source`), not inert data parsed
for values. Treat it with the same caution you'd give any script — only
point `--config` at files you trust.

## Exit Codes

| Code | Meaning |
|---|---|
| 0 | Success |
| 1 | Invalid usage / arguments |
| 2 | Invalid target directory |
| 3 | One or more files failed to move (partial success) |
| 4 | `--undo` completed with unresolved conflicts |
| 5 | Invalid configuration (`--config` file missing, or has a Bash syntax error) |
| 130 | Interrupted by SIGINT (Ctrl+C) — files moved before the interruption are safe |
| 143 | Interrupted by SIGTERM — files moved before the interruption are safe |

## Logging

Every run creates `TARGET_DIR/logs/organizer_<timestamp>.log`:

```
2026-09-09 14:30:12 | MOVE   | /home/user/Downloads/photo.jpg | /home/user/Downloads/Images/photo.jpg | SUCCESS
```

No file contents or other sensitive data are ever logged — only paths,
actions, and status.

## Undo / Recovery

```bash
organizer ~/Downloads --undo
```

Restores files moved by the **most recent run** in that directory, using a
machine-readable transaction record kept separately from the human log
(`logs/.history/`). It:

- Restores files in reverse order of how they were moved
- **Never overwrites** an existing file — if the original location is now
  occupied, it reports a `CONFLICT` and leaves both files where they are
- Only undoes one run at a time — it is **not** a general-purpose,
  multi-level undo/version-control system, and doesn't chain across runs

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `error: target directory does not exist` | Typo in path, or directory was removed | Check the path with `ls` |
| `error: insufficient permissions` | No read/write access to the target dir | `chmod`/`chown`, or run as the owning user |
| A file didn't move, logged as `FAILURE` | Permission denied on that file, or a same-name collision limit hit | Check the log line's reason column |
| `--undo` reports `CONFLICT` | Something now occupies the file's original path | Resolve manually — undo will not overwrite |
| Nothing happens in `--recursive` on subfolders | They might already be excluded category folders | Expected — see Recursive Mode above |
| Run stopped with "Interrupted (SIGINT)" | Ctrl+C or another process sent SIGINT/SIGTERM | Expected and safe — files already moved stay moved and logged; re-run to continue with the rest |

## Examples

```bash
# Preview only
organizer ~/Downloads --dry-run

# Organize everything including subfolders, with progress output
organizer ~/Downloads --recursive --verbose

# Undo the last run
organizer ~/Downloads --undo

# Use a custom config for one run
organizer ~/Downloads --config ./my-organizer.conf
```
