[🏠 Home](README.md) | [Filesystem](filesystem.md) | [Permissions](file-permissions.md) | [Processes](processes.md) | [Networking](networking.md) | [Users & Groups](users-groups.md) | [Storage](storage.md) | [Packages](package-management.md) | [Shell Scripting](shell-scripting.md) | [Security](security.md)

# 🧭 Navigation Commands

Commands for moving around the Linux filesystem, locating files, and understanding where you are and what things are.

## Table of Contents
1. [pwd](#pwd) 2. [cd](#cd) 3. [ls](#ls) 4. [tree](#tree) 5. [find](#find) 6. [locate](#locate) 7. [updatedb](#updatedb) 8. [which](#which) 9. [whereis](#whereis) 10. [type](#type) 11. [file](#file) 12. [stat](#stat) 13. [readlink](#readlink) 14. [realpath](#realpath) 15. [basename](#basename) 16. [dirname](#dirname) 17. [pushd](#pushd) 18. [popd](#popd) 19. [dirs](#dirs) 20. [history](#history) 21. [alias](#alias) 22. [clear](#clear) 23. [man](#man) 24. [whatis](#whatis) 25. [apropos](#apropos) 26. [info](#info)

---

# pwd
## Purpose
Print the full absolute path of the current working directory.
## Syntax
```
pwd [OPTIONS]
```
## Common Options
| Option | Description |
|---|---|
| `-L` | Print the logical path (default; follows symlinks as-is) |
| `-P` | Print the physical path (resolves all symlinks) |

## Example
```bash
pwd
```
## Expected Output
```
/home/kapilesh/projects/linux-cheatsheet
```
## Explanation
`pwd` (print working directory) queries the shell's current directory and prints it. It's one of the first commands every Linux user learns because nearly every relative-path command depends on knowing where you currently are.
## Tips
- Use `pwd -P` when working with symlinked directories to see the *real* path.
- Combine with command substitution: `cd $(pwd)` is redundant but shows how `pwd` output can be reused.
## Common Mistakes
- Assuming your shell prompt always shows the full path — many default prompts truncate it (`~/proj` instead of `/home/user/proj`).
- Forgetting that `pwd` shows the *shell's* idea of the directory, which can differ slightly from the OS path if you `cd`'d through a symlink.
## Related Commands
[cd](#cd), [ls](#ls), [realpath](#realpath)

---

# cd
## Purpose
Change the current working directory of the shell.
## Syntax
```
cd [DIRECTORY]
```
## Common Options / Special Arguments
| Argument | Description |
|---|---|
| `cd` (no args) | Go to your home directory |
| `cd -` | Go to the previous directory |
| `cd ..` | Go up one directory level |
| `cd ~user` | Go to another user's home directory |
| `cd /` | Go to the filesystem root |

## Example
```bash
cd /var/log
cd -
```
## Expected Output
```
(no output on success — the prompt path changes)
```
## Explanation
`cd` is a **shell builtin**, not a standalone binary — this is why it can change the shell's own working directory (an external program cannot change its parent shell's directory).
## Tips
- `cd -` is extremely useful for toggling between two directories quickly.
- Set up `CDPATH` in your `.bashrc` to jump to frequently used directories from anywhere.
## Common Mistakes
- Trying to `cd` into a file instead of a directory (`Not a directory` error).
- Forgetting that `cd` without `sudo` won't work in directories you lack execute (`x`) permission on.
## Related Commands
[pwd](#pwd), [pushd](#pushd), [popd](#popd)

---

# ls
## Purpose
List directory contents.
## Syntax
```
ls [OPTIONS] [PATH]
```
## Common Options
| Option | Description |
|---|---|
| `-a` | Show all files, including hidden (dotfiles) |
| `-l` | Long listing format (permissions, owner, size, date) |
| `-h` | Human-readable file sizes (used with `-l`) |
| `-R` | List subdirectories recursively |
| `-t` | Sort by modification time, newest first |
| `-S` | Sort by file size, largest first |
| `-i` | Show inode numbers |

## Example
```bash
ls -lah
```
## Expected Output
```
drwxr-xr-x  4 kapilesh kapilesh 4.0K Jul  6 10:15 .
drwxr-xr-x 20 kapilesh kapilesh 4.0K Jul  5 09:02 ..
-rw-r--r--  1 kapilesh kapilesh  220 Jul  6 10:10 .bashrc
-rw-r--r--  1 kapilesh kapilesh 8.1K Jul  6 10:12 notes.txt
```
## Explanation
Displays files in the given directory (current directory by default). The long format (`-l`) reveals permission bits, link count, owner, group, size, and last-modified timestamp — this is the same data structure exposed by `stat`.
## Tips
- Alias `ll='ls -lah'` is one of the most common shell customizations.
- Use `ls -d */` to list only directories.
## Common Mistakes
- Forgetting `-a` and assuming a directory is empty when it only contains dotfiles (like `.git`).
- Confusing `-S` (sort by size) with `-s` (show allocated blocks) — they look similar but do different things.
## Related Commands
[tree](#tree), [find](#find), [stat](#stat)

---

# tree
## Purpose
Display directory contents as a recursive, indented tree diagram.
## Syntax
```
tree [OPTIONS] [PATH]
```
## Common Options
| Option | Description |
|---|---|
| `-a` | Include hidden files |
| `-d` | List directories only |
| `-L n` | Limit recursion to `n` levels deep |
| `-I pattern` | Ignore files matching a pattern |

## Example
```bash
tree -L 2 -I 'node_modules'
```
## Expected Output
```
.
├── README.md
├── src
│   ├── index.js
│   └── utils.js
└── package.json
```
## Explanation
`tree` is not installed by default on all distros (`sudo apt install tree` / `sudo dnf install tree`). It's purely a visualization tool built on the same directory-walking logic as `find`.
## Tips
- Use `tree -L 2` on large repos to avoid an overwhelming wall of output.
- `tree -d` is great for quickly understanding a project's folder architecture.
## Common Mistakes
- Running plain `tree` in a huge directory (like `/` or `node_modules`) without `-L`, producing thousands of lines of output.
## Related Commands
[ls](#ls), [find](#find)

---

# find
## Purpose
Search for files and directories based on name, type, size, time, permissions, and more, then optionally act on the results.
## Syntax
```
find [PATH] [EXPRESSION]
```
## Common Options
| Option | Description |
|---|---|
| `-name "pattern"` | Match by filename (case-sensitive) |
| `-iname "pattern"` | Match by filename (case-insensitive) |
| `-type f/d/l` | Match file / directory / symlink |
| `-mtime -7` | Modified in the last 7 days |
| `-size +100M` | Larger than 100MB |
| `-exec CMD {} \;` | Run a command on each result |
| `-delete` | Delete matched files |

## Example
```bash
find /var/log -name "*.log" -mtime +30 -size +50M
```
## Expected Output
```
/var/log/old-app/debug.log
/var/log/nginx/access.log.3
```
## Explanation
`find` walks the directory tree in real time (unlike `locate`, which uses a prebuilt index) and evaluates every file against the expression you give it. This makes it slower but always up-to-date and far more powerful for conditional logic.
## Tips
- Always test destructive `-exec rm` or `-delete` first with a harmless action like `-print` to confirm the match set.
- Use `find . -type f -exec chmod 644 {} \;` to bulk-fix permissions.
## Common Mistakes
- Forgetting to quote glob patterns (`find -name *.txt` lets the shell expand `*.txt` before `find` sees it — always use `find -name "*.txt"`).
- Running `find / -delete` style commands without a narrow enough scope — this is a classic way to cause catastrophic data loss.
## Related Commands
[locate](#locate), [grep](shell-scripting.md#grep), [xargs](shell-scripting.md#xargs)

---

# locate
## Purpose
Quickly search for files by name using a prebuilt filesystem index (much faster than `find`).
## Syntax
```
locate [OPTIONS] PATTERN
```
## Common Options
| Option | Description |
|---|---|
| `-i` | Case-insensitive search |
| `-c` | Print only a count of matches |
| `-l N` | Limit output to N results |

## Example
```bash
locate -i "resume.pdf"
```
## Expected Output
```
/home/kapilesh/Documents/resume.pdf
```
## Explanation
`locate` searches a database (typically `/var/lib/mlocate/mlocate.db`) built by `updatedb`, rather than scanning the live filesystem. This makes it dramatically faster than `find`, but results can be stale if the index hasn't refreshed since a file was created or deleted.
## Tips
- Run `sudo updatedb` manually right after creating files you need to `locate` immediately.
- Not installed by default on all distros — install via `mlocate` or `plocate` package.
## Common Mistakes
- Assuming `locate` shows a file you *just* created — it won't appear until the database is refreshed.
## Related Commands
[updatedb](#updatedb), [find](#find)

---

# updatedb
## Purpose
Rebuild the file index database used by `locate`.
## Syntax
```
sudo updatedb
```
## Common Options
| Option | Description |
|---|---|
| `-U path` | Only update the index for a specific path |
| `--prunepaths "paths"` | Exclude specific paths from indexing |

## Example
```bash
sudo updatedb
```
## Expected Output
```
(no output on success)
```
## Explanation
This command is usually run automatically via a daily cron job (`/etc/cron.daily/mlocate`), but can be run manually when you need `locate` results to reflect very recent filesystem changes.
## Tips
- Requires root privileges since it scans the entire filesystem by default.
- On systems with many files, this can take noticeable time and I/O.
## Common Mistakes
- Running it constantly in scripts — it's I/O-intensive and meant to be run periodically, not on every file operation.
## Related Commands
[locate](#locate)

---

# which
## Purpose
Show the full path of the executable that would run for a given command name.
## Syntax
```
which [COMMAND]
```
## Example
```bash
which python3
```
## Expected Output
```
/usr/bin/python3
```
## Explanation
`which` searches your `$PATH` directories in order and reports the first matching executable — exactly the one your shell would run if you typed that command.
## Tips
- Use `which -a COMMAND` to list *every* matching executable in your `$PATH`, useful for diagnosing version conflicts (e.g., multiple Python installs).
## Common Mistakes
- Assuming `which` checks shell builtins or aliases — it does **not**; use `type` for that instead.
## Related Commands
[whereis](#whereis), [type](#type)

---

# whereis
## Purpose
Locate the binary, source code, and man page files for a command.
## Syntax
```
whereis [COMMAND]
```
## Example
```bash
whereis ls
```
## Expected Output
```
ls: /usr/bin/ls /usr/share/man/man1/ls.1.gz
```
## Explanation
Unlike `which`, `whereis` searches a predefined set of standard system directories (not your `$PATH`), and also reports man page and source locations if available.
## Tips
- Useful when you need to find a command's man page file location directly, not just the binary.
## Common Mistakes
- Confusing it with `which` — `whereis` gives more categories of output but is less precise about "what would actually execute."
## Related Commands
[which](#which), [man](#man)

---

# type
## Purpose
Show how the shell would interpret a given command name (builtin, alias, function, or executable file).
## Syntax
```
type [COMMAND]
```
## Common Options
| Option | Description |
|---|---|
| `-a` | Show all matching interpretations |
| `-t` | Print only the type (alias/keyword/function/builtin/file) |

## Example
```bash
type cd
type ls
```
## Expected Output
```
cd is a shell builtin
ls is aliased to `ls --color=auto'
```
## Explanation
`type` is a Bash builtin that inspects the shell's own command resolution order (aliases → functions → builtins → `$PATH` executables), making it the most accurate tool for "what will run when I type this."
## Tips
- Use `type -a` when debugging why a command behaves unexpectedly (e.g., an alias overriding the real binary).
## Common Mistakes
- Using `which` instead of `type` when troubleshooting aliases — `which` will not detect them.
## Related Commands
[which](#which), [alias](#alias)

---

# file
## Purpose
Determine the type of a file by examining its content (not just its extension).
## Syntax
```
file [FILENAME]
```
## Common Options
| Option | Description |
|---|---|
| `-i` | Output MIME type instead of a description |
| `-z` | Look inside compressed files |

## Example
```bash
file document.pdf
```
## Expected Output
```
document.pdf: PDF document, version 1.7
```
## Explanation
`file` reads "magic numbers" (byte signatures) at the start of a file to identify its real type, which is why it can correctly identify a file even if someone renamed `image.jpg` to `image.txt`.
## Tips
- Use `file -i` when scripting, since MIME types are easier to parse programmatically than free-text descriptions.
## Common Mistakes
- Trusting file extensions for security decisions — always verify actual file type with `file` when processing untrusted uploads.
## Related Commands
[stat](#stat), [ls](#ls)

---

# stat
## Purpose
Display detailed metadata about a file or filesystem: size, permissions, timestamps, inode, and more.
## Syntax
```
stat [FILENAME]
```
## Common Options
| Option | Description |
|---|---|
| `-f` | Show filesystem status instead of file status |
| `-c FORMAT` | Custom output format |

## Example
```bash
stat notes.txt
```
## Expected Output
```
  File: notes.txt
  Size: 8192      	Blocks: 16         IO Block: 4096   regular file
Device: 803h/2051d	Inode: 1449234     Links: 1
Access: (0644/-rw-r--r--)  Uid: ( 1000/kapilesh)   Gid: ( 1000/kapilesh)
Modify: 2026-07-06 10:12:44.000000000 +0530
```
## Explanation
`stat` exposes the raw inode metadata the kernel keeps for every file, including three separate timestamps: **access time** (atime), **modify time** (mtime), and **change time** (ctime — metadata changes like permissions).
## Tips
- Use `stat -c "%a %n"` in scripts to extract just the octal permission and filename cleanly.
## Common Mistakes
- Confusing "modify time" (content changed) with "change time" (metadata like permissions changed) — they are genuinely different fields.
## Related Commands
[file](#file), [ls](#ls)

---

# readlink
## Purpose
Print the target that a symbolic link points to.
## Syntax
```
readlink [OPTIONS] [SYMLINK]
```
## Common Options
| Option | Description |
|---|---|
| `-f` | Resolve the full canonical path, following all links |

## Example
```bash
readlink -f /usr/bin/python3
```
## Expected Output
```
/usr/bin/python3.12
```
## Explanation
Symbolic links store a path string, not the actual file data. `readlink` reveals what that stored path is, which is invaluable for debugging broken links or chained symlinks (e.g., version-managed binaries).
## Tips
- `readlink -f` is commonly used inside shell scripts to resolve a script's own real directory: `SCRIPT_DIR=$(dirname "$(readlink -f "$0")")`.
## Common Mistakes
- Using `readlink` without `-f` and getting only the immediate target, not the fully resolved chain if multiple symlinks are nested.
## Related Commands
[realpath](#realpath), [ln](filesystem.md#ln)

---

# realpath
## Purpose
Print the absolute, canonical path of a file, resolving all symlinks and relative components (`.`/`..`).
## Syntax
```
realpath [FILENAME]
```
## Example
```bash
realpath ../scripts/deploy.sh
```
## Expected Output
```
/home/kapilesh/projects/scripts/deploy.sh
```
## Explanation
`realpath` is very similar to `readlink -f` but is purpose-built and slightly more portable across scripting contexts. It's frequently used to normalize paths before comparison in scripts.
## Tips
- Prefer `realpath` over manual string concatenation when scripts need to compare or log absolute paths reliably.
## Common Mistakes
- Assuming the file must exist — by default `realpath` requires the path to exist; use `realpath -m` to allow non-existent paths (useful for constructing future paths).
## Related Commands
[readlink](#readlink), [pwd](#pwd)

---

# basename
## Purpose
Strip the directory path and (optionally) a suffix from a filename, leaving just the file's base name.
## Syntax
```
basename PATH [SUFFIX]
```
## Example
```bash
basename /home/kapilesh/notes.txt
basename /home/kapilesh/notes.txt .txt
```
## Expected Output
```
notes.txt
notes
```
## Explanation
Commonly used in shell scripts to extract just the filename from a full path, e.g., for logging or generating output filenames based on an input file.
## Tips
- Combine with `dirname` when a script needs both the folder and the filename separately.
## Common Mistakes
- Forgetting the suffix argument is a literal string match, not a wildcard — `basename file.tar.gz .gz` only strips `.gz`, leaving `file.tar`.
## Related Commands
[dirname](#dirname), [realpath](#realpath)

---

# dirname
## Purpose
Strip the filename from a path, leaving just the directory portion.
## Syntax
```
dirname PATH
```
## Example
```bash
dirname /home/kapilesh/notes.txt
```
## Expected Output
```
/home/kapilesh
```
## Explanation
The logical counterpart to `basename`. Frequently used together in scripts: `dirname "$0"` gets a running script's own directory.
## Tips
- `dirname` on a bare filename (no slashes) returns `.` (current directory), which is often a source of confusion for beginners.
## Common Mistakes
- Expecting an absolute path back — `dirname` only manipulates the string you give it; combine with `realpath` if you need an absolute, resolved path.
## Related Commands
[basename](#basename), [realpath](#realpath)

---

# pushd
## Purpose
Change directory while saving the previous directory onto a navigable stack.
## Syntax
```
pushd [DIRECTORY]
```
## Example
```bash
pushd /var/log
```
## Expected Output
```
/var/log ~
```
## Explanation
`pushd` is a Bash builtin that extends `cd` with a directory stack, letting you hop between several locations without manually remembering each path.
## Tips
- Combine with `popd` and `dirs` for efficient multi-location workflows in long terminal sessions.
## Common Mistakes
- Overusing the stack without checking it (`dirs -v`), leading to confusion about which directory you'll land on after `popd`.
## Related Commands
[popd](#popd), [dirs](#dirs), [cd](#cd)

---

# popd
## Purpose
Return to the directory at the top of the `pushd` stack, removing it from the stack.
## Syntax
```
popd
```
## Example
```bash
pushd /tmp
# do work in /tmp
popd
```
## Expected Output
```
~
```
## Explanation
Works as the reverse operation of `pushd`, letting you "pop back" to where you were before jumping elsewhere.
## Tips
- `dirs -v` before calling `popd` shows exactly which directory you'll return to.
## Common Mistakes
- Calling `popd` with an empty stack (no prior `pushd`), which produces an error.
## Related Commands
[pushd](#pushd), [dirs](#dirs)

---

# dirs
## Purpose
Display the current directory stack maintained by `pushd`/`popd`.
## Syntax
```
dirs [OPTIONS]
```
## Common Options
| Option | Description |
|---|---|
| `-v` | Show the stack with numbered index positions |
| `-c` | Clear the stack |

## Example
```bash
dirs -v
```
## Expected Output
```
 0  ~/projects/linux-cheatsheet
 1  /var/log
 2  /tmp
```
## Explanation
Useful for visualizing exactly where `popd` will take you, especially after several chained `pushd` calls.
## Tips
- Use the numbered index with `cd +N` to jump directly to any stack entry.
## Common Mistakes
- Forgetting the stack persists only for the current shell session, not across terminal restarts.
## Related Commands
[pushd](#pushd), [popd](#popd)

---

# history
## Purpose
Display previously executed shell commands.
## Syntax
```
history [N]
```
## Common Options
| Option | Description |
|---|---|
| `history N` | Show only the last N commands |
| `history -c` | Clear the history list |
| `!N` | Re-run history entry number N |
| `!!` | Re-run the previous command |

## Example
```bash
history 10
```
## Expected Output
```
  991  cd /var/log
  992  ls -lah
  993  sudo journalctl -xe
```
## Explanation
Bash keeps a record of commands in memory during a session and persists them to `~/.bash_history` on exit (or continuously, depending on `HISTCONTROL`/`PROMPT_COMMAND` settings).
## Tips
- Use `Ctrl+R` for reverse-search through history interactively — far faster than scrolling `history` output.
- Set `HISTTIMEFORMAT="%F %T "` in `.bashrc` to add timestamps to history entries.
## Common Mistakes
- Assuming history is instantly saved — by default it's only written to disk at shell exit unless `history -a` or `PROMPT_COMMAND` is configured.
## Related Commands
[alias](#alias)

---

# alias
## Purpose
Create a shortcut name for a longer command or command with fixed options.
## Syntax
```
alias name='command'
```
## Example
```bash
alias ll='ls -lah'
alias gs='git status'
```
## Expected Output
```
(no output — the alias is now active for the session)
```
## Explanation
Aliases are simple text-substitution shortcuts recognized only by interactive shells (they do not work reliably in non-interactive scripts). Persist them by adding to `~/.bashrc` or `~/.zshrc`.
## Tips
- Run `alias` with no arguments to list all currently defined aliases.
- Use `unalias name` to remove one.
## Common Mistakes
- Defining aliases only in the current session and being confused why they "disappear" after opening a new terminal — they must be added to a shell startup file to persist.
## Related Commands
[type](#type), [history](#history)

---

# clear
## Purpose
Clear the terminal screen.
## Syntax
```
clear
```
## Example
```bash
clear
```
## Explanation
Simply sends a terminal control sequence to reset the visible screen; it does **not** delete your scrollback history or command history — just the visible display.
## Tips
- Keyboard shortcut `Ctrl+L` does the same thing without typing the command.
## Common Mistakes
- Assuming `clear` erases command history (`history`) — it does not; they are unrelated.
## Related Commands
[history](#history)

---

# man
## Purpose
Display the manual page (official reference documentation) for a command.
## Syntax
```
man [SECTION] COMMAND
```
## Common Options
| Option | Description |
|---|---|
| `man 5 passwd` | View section 5 (file formats) instead of default section 1 (commands) |
| `-k KEYWORD` | Search all man page descriptions for a keyword (same as `apropos`) |

## Example
```bash
man ls
```
## Expected Output
```
LS(1)                    User Commands                   LS(1)
NAME
       ls - list directory contents
SYNOPSIS
       ls [OPTION]... [FILE]...
...
```
## Explanation
Man pages are organized into numbered sections (1 = user commands, 5 = file formats, 8 = admin commands, etc.). This is why `man passwd` and `man 5 passwd` show completely different, equally valid documents.
## Tips
- Press `/` inside `man` to search the page, and `q` to quit.
- This wiki is a supplement to `man` pages, not a replacement — always confirm against `man` for your specific distro/version.
## Common Mistakes
- Not knowing man pages have sections, and being confused when a command and a config file share a name (e.g., `crontab` the command vs. `crontab` the file format).
## Related Commands
[whatis](#whatis), [apropos](#apropos), [info](#info)

---

# whatis
## Purpose
Show a one-line description of a command from its man page.
## Syntax
```
whatis COMMAND
```
## Example
```bash
whatis grep
```
## Expected Output
```
grep (1)             - print lines that match patterns
```
## Explanation
A quick-reference tool that pulls just the "NAME" section summary from the man database, useful when you just need a reminder of what a command does.
## Tips
- Faster than opening the full `man` page when you just need a one-line reminder.
## Common Mistakes
- Getting a "nothing appropriate" error because the `man-db` database (`mandb`) hasn't been built yet on a fresh system — run `sudo mandb` to fix.
## Related Commands
[man](#man), [apropos](#apropos)

---

# apropos
## Purpose
Search man page descriptions for a keyword, useful when you don't know a command's exact name.
## Syntax
```
apropos KEYWORD
```
## Example
```bash
apropos "list directory"
```
## Expected Output
```
ls (1)               - list directory contents
```
## Explanation
Searches the same man-db database as `whatis`, but matches against keywords anywhere in the description rather than requiring an exact command name.
## Tips
- Great for discovering commands you didn't know existed based on what you want to accomplish.
## Common Mistakes
- Expecting full-text search of entire man pages — `apropos` only searches short descriptions, not full page content.
## Related Commands
[man](#man), [whatis](#whatis)

---

# info
## Purpose
Display more detailed, hyperlinked documentation for GNU utilities (an alternative/supplement to `man`).
## Syntax
```
info COMMAND
```
## Example
```bash
info coreutils
```
## Explanation
GNU's `info` system provides a hypertext-style documentation format, often more detailed than `man` pages for core GNU utilities, though less commonly used day-to-day.
## Tips
- Navigate with arrow keys and `Enter` to follow links; press `q` to quit.
## Common Mistakes
- Assuming every command has an `info` page — many third-party tools only ship a `man` page.
## Related Commands
[man](#man)

---

⬅️ Back to [README.md](README.md) | Next: [filesystem.md](filesystem.md) ➡️
