[🏠 Home](README.md) | [Filesystem](filesystem.md) | [Permissions](file-permissions.md) | [Processes](processes.md) | [Networking](networking.md) | [Users & Groups](users-groups.md) | [Storage](storage.md) | [Packages](package-management.md) | [Shell Scripting](shell-scripting.md) | [Security](security.md)

# Navigation Commands

Commands for moving around the filesystem, finding files, and
understanding where you are and what things are.

**Contents:** [pwd](#pwd) · [cd](#cd) · [ls](#ls) · [tree](#tree) · [find](#find) · [locate](#locate) · [updatedb](#updatedb) · [which](#which) · [whereis](#whereis) · [type](#type) · [file](#file) · [stat](#stat) · [readlink](#readlink) · [realpath](#realpath) · [basename](#basename) · [dirname](#dirname) · [pushd](#pushd) · [popd](#popd) · [dirs](#dirs) · [history](#history) · [alias](#alias) · [clear](#clear) · [man](#man) · [whatis](#whatis) · [apropos](#apropos) · [info](#info)

---

### pwd
Print the full path of the current working directory.

```bash
pwd        # /home/kapilesh/projects
```

Notes:
- `pwd -P` prints the physical path with symlinks resolved; `-L` (the default) prints the logical path you `cd`'d through.
- The shell prompt often truncates paths, so `pwd` is the reliable way to know where you are.

### cd
Change the current directory. `cd` is a shell **builtin**, not an external program — that's why it can change the shell's own directory (an external program can't change its parent's directory).

```bash
cd          # home directory
cd -        # previous directory
cd ..       # up one level
cd ~user    # another user's home
cd /        # filesystem root
```

- `cd` gives `Permission denied` on a directory you can't execute (`x`), even if you can list it.
- `CDPATH` in `.bashrc` makes `cd name` also search extra directories.

### ls
List directory contents.

```bash
ls -lah      # all files, long format, human-readable sizes
ls -t        # newest first
ls -S        # largest first
ls -i        # include inode numbers
ls -d */     # list only directories
```

Notes:
- Dotfiles need `-a`; without it a directory can look empty when it isn't.
- The long format (`-l`) shows permissions, link count, owner, group, size, and mtime — the same metadata `stat` exposes.

### tree
Draw the directory tree.

```bash
tree -L 2 -I node_modules    # 2 levels deep, ignore node_modules
tree -d                      # directories only
tree -a                      # include hidden files
```

Install with `sudo apt install tree` / `sudo dnf install tree`. Always use `-L` on large trees or you'll get thousands of lines.

### find
Walk the tree in real time and evaluate every file against an expression.

```bash
find /var/log -name "*.log" -mtime +30 -size +50M
find . -type f -exec chmod 644 {} \;
find . -name "*.tmp" -delete
```

Notes:
- Unlike `locate`, `find` always sees the current state, and it can match by name, type, size, time, and permissions.
- **Quote patterns** (`"*.log"`) or the shell expands them before `find` sees them.
- Test `-delete` / `-exec rm` with `-print` first. `find / -delete` is a classic data-loss command.
### locate
Name search against a prebuilt index — much faster than `find`.

```bash
locate -i resume.pdf    # case-insensitive
locate -c nginx         # print only the match count
```

The database is normally rebuilt daily by cron (`updatedb`), so files created after the last run won't appear.

### updatedb
Rebuild the index `locate` reads.

```bash
sudo updatedb
```

Run manually right after creating files you need to `locate` immediately. It scans the whole filesystem, so it's I/O-intensive — don't run it in scripts.

### which
Print the path of the executable the shell would run for a command name.

```bash
which python3      # /usr/bin/python3
```

`which -a python3` lists every match in `$PATH` (useful when diagnosing version conflicts). `which` does **not** see aliases or builtins — use `type` for those.

### whereis
Find the binary plus its source and man page locations.

```bash
whereis ls    # ls: /usr/bin/ls /usr/share/man/man1/ls.1.gz
```

Searches standard system directories, not your `$PATH`.

### type
Show how the shell resolves a name: alias, function, builtin, or file.

```bash
type cd        # cd is a shell builtin
type -a ls     # every possible interpretation
```

Use `type` instead of `which` when debugging why a command behaves unexpectedly — e.g. an alias overriding the real binary.

### file
Identify a file by its **contents** (magic bytes), not its extension.

```bash
file document.pdf    # PDF document, version 1.7
file -i image.jpg    # image/jpeg
```

`file -i` prints a MIME type, which is easier to parse in scripts. Don't trust extensions as a security control on untrusted uploads — `file` reveals the real type.

### stat
Show raw inode metadata: size, permissions, timestamps, link count.

```bash
stat notes.txt
stat -c "%a %n" notes.txt    # octal permissions + name only
```

`stat` exposes three timestamps — `atime` (last access), `mtime` (content changed), `ctime` (metadata like permissions changed). Don't confuse mtime with ctime.

### readlink
Print what a symbolic link points to.

```bash
readlink /usr/bin/python3         # python3.12
readlink -f /usr/bin/python3      # fully resolved chain
```

A symlink stores a path string, and `readlink` reveals it — invaluable for debugging broken or chained links. `readlink -f "$0"` at the top of a script resolves the script's real directory even when invoked through a symlink.

### realpath
Print the canonical absolute path, resolving symlinks and `.`/`..`.

```bash
realpath ../scripts/deploy.sh
realpath -m /tmp/future/file.txt    # -m: allow non-existent paths
```

`realpath -m` is handy when constructing a path for a file that doesn't exist yet.

### basename
Strip the directory (and optionally a suffix) from a path.

```bash
basename /home/kapilesh/notes.txt      # notes.txt
basename /home/kapilesh/notes.txt .txt # notes
```

The suffix is a literal string, not a wildcard: `basename file.tar.gz .gz` gives `file.tar`.

### dirname
Strip the filename, leaving the directory part.

```bash
dirname /home/kapilesh/notes.txt    # /home/kapilesh
```

`dirname "$0"` inside a script returns the script's own directory. On a bare name with no slash it prints `.` (current directory).

### pushd / popd / dirs
`pushd` moves to a directory while saving the current one on a stack; `popd` returns to the top of the stack and removes that entry; `dirs` prints the stack.

```bash
pushd /var/log
popd
dirs -v        # numbered stack; cd +1 jumps to entry 1
```

The stack lasts only for the shell session — after several `pushd`s, check `dirs -v` so you know where `popd` will land.

### history
Show previously executed commands (also `history N` for the last N).

```bash
history 10      # last 10 commands
!123            # re-run entry 123
!!              # re-run the previous command
history -c      # clear the in-memory history
```

- `Ctrl+R` reverse-searches interactively.
- By default history is written to `~/.bash_history` only on shell exit. Add `HISTTIMEFORMAT="%F %T "` to `.bashrc` to timestamp entries.

### alias
Create a shortcut name for a command.

```bash
alias ll='ls -lah'
alias gs='git status'
```

Aliases are interactive-shell features — add them to `~/.bashrc` to keep them across sessions; `unalias name` removes one; bare `alias` lists the current ones.

### clear
Clear the visible screen (`Ctrl+L` does the same). It does **not** erase command history or scrollback.

### man
Open the manual page for a command.

```bash
man ls
man 5 passwd      # section 5 = file formats
man -k keyword    # search descriptions (same as apropos)
```

Man pages are organized by section: 1 user commands, 5 file formats, 8 admin commands — so `man passwd` (the command) and `man 5 passwd` (the file format) are different documents. Inside a page, `/` searches and `q` quits. Treat `man` as the authoritative reference for your distro's version.

### whatis
One-line description of a command, from its man page.

```bash
whatis ls    # ls (1) - list directory contents
```

### apropos
Search man page names and descriptions for a keyword (equivalent to `man -k`).

```bash
apropos compress
```

### info
GNU's hypertext documentation reader — an alternative to `man` for GNU tools (`info coreutils` gives the full manual where the man page is often just a pointer).

---

⬅️ Back to [README](README.md) | Next: [Filesystem](filesystem.md) ➡️