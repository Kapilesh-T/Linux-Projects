[🏠 Home](README.md) | [Navigation](navigation.md) | [Permissions](file-permissions.md) | [Processes](processes.md) | [Networking](networking.md) | [Users & Groups](users-groups.md) | [Storage](storage.md) | [Packages](package-management.md) | [Shell Scripting](shell-scripting.md) | [Security](security.md)

# 📁 File & Directory Operations

Commands for creating, viewing, copying, moving, deleting, compressing, and comparing files and directories.

## Table of Contents
1. [mkdir](#mkdir) 2. [rmdir](#rmdir) 3. [touch](#touch) 4. [cp](#cp) 5. [mv](#mv) 6. [rm](#rm) 7. [cat](#cat) 8. [tac](#tac) 9. [less](#less) 10. [more](#more) 11. [head](#head) 12. [tail](#tail) 13. [wc](#wc) 14. [diff](#diff) 15. [cmp](#cmp) 16. [ln](#ln) 17. [tar](#tar) 18. [gzip](#gzip) 19. [gunzip](#gunzip) 20. [zip](#zip) 21. [unzip](#unzip) 22. [rsync](#rsync) 23. [shred](#shred) 24. [split](#split) 25. [truncate](#truncate) 26. [xxd](#xxd)

---

# mkdir
## Purpose
Create new directories.
## Syntax
```
mkdir [OPTIONS] DIRECTORY
```
## Common Options
| Option | Description |
|---|---|
| `-p` | Create parent directories as needed, no error if directory exists |
| `-v` | Verbose output, print each directory created |
| `-m MODE` | Set permissions at creation time |

## Example
```bash
mkdir -p project/src/components
```
## Expected Output
```
(no output on success)
```
## Explanation
Without `-p`, `mkdir` fails if any parent directory in the path doesn't already exist. `-p` creates the full chain in one command.
## Tips
- `mkdir -pv` combines silent bulk creation with a visible log of what was made.
## Common Mistakes
- Forgetting `-p` when creating nested paths, resulting in "No such file or directory" errors.
## Related Commands
[rmdir](#rmdir), [ls](navigation.md#ls)

---

# rmdir
## Purpose
Remove **empty** directories.
## Syntax
```
rmdir [OPTIONS] DIRECTORY
```
## Common Options
| Option | Description |
|---|---|
| `-p` | Remove a directory and its now-empty parents |

## Example
```bash
rmdir old_folder
```
## Explanation
`rmdir` is a safety-focused tool — it refuses to delete a directory that still contains files, unlike `rm -r`.
## Tips
- Use `rmdir` instead of `rm -r` when you specifically want to guard against accidentally deleting a non-empty directory.
## Common Mistakes
- Trying to use `rmdir` on a directory with contents and getting confused by the "Directory not empty" error — use `rm -r` intentionally instead.
## Related Commands
[mkdir](#mkdir), [rm](#rm)

---

# touch
## Purpose
Create a new empty file, or update the access/modification timestamp of an existing file.
## Syntax
```
touch [OPTIONS] FILENAME
```
## Common Options
| Option | Description |
|---|---|
| `-c` | Do not create the file if it doesn't exist |
| `-t TIMESTAMP` | Set a specific timestamp instead of "now" |
| `-a` / `-m` | Update only access time / only modification time |

## Example
```bash
touch app.log
```
## Expected Output
```
(no output — file created or timestamp updated)
```
## Explanation
Historically used to "touch" a file so build systems (like `make`) see it as newer and reprocess it, in addition to its common use of quickly creating placeholder files.
## Tips
- `touch {file1,file2,file3}.txt` creates multiple files in one command using brace expansion.
## Common Mistakes
- Assuming `touch` on an existing file changes its content — it only updates metadata (timestamps), never the file's contents.
## Related Commands
[stat](navigation.md#stat), [mkdir](#mkdir)

---

# cp
## Purpose
Copy files or directories.
## Syntax
```
cp [OPTIONS] SOURCE DESTINATION
```
## Common Options
| Option | Description |
|---|---|
| `-r` | Copy directories recursively |
| `-v` | Verbose — print each file copied |
| `-i` | Prompt before overwriting |
| `-p` | Preserve permissions, ownership, timestamps |
| `-u` | Copy only if source is newer than destination |

## Example
```bash
cp -rv src/ backup/
```
## Expected Output
```
'src/index.js' -> 'backup/index.js'
'src/utils.js' -> 'backup/utils.js'
```
## Explanation
By default, `cp` on a directory without `-r` fails ("omitting directory"). `-p` is important in system administration contexts where preserving ownership/permission metadata matters (e.g., backups).
## Tips
- Always test with `-i` (interactive) when copying into a directory that might already contain files with the same names.
## Common Mistakes
- Forgetting the trailing slash matters: `cp -r src dest` behaves differently than `cp -r src/ dest/` when `dest` already exists (whether `src` becomes a subfolder of `dest` or its contents merge in).
## Related Commands
[mv](#mv), [rsync](#rsync)

---

# mv
## Purpose
Move or rename files and directories.
## Syntax
```
mv [OPTIONS] SOURCE DESTINATION
```
## Common Options
| Option | Description |
|---|---|
| `-i` | Prompt before overwriting |
| `-n` | Never overwrite an existing file |
| `-v` | Verbose output |

## Example
```bash
mv draft.md final-report.md
```
## Expected Output
```
(no output on success)
```
## Explanation
On the same filesystem, `mv` is implemented as a fast metadata-only rename (no data copying). Across different filesystems/drives, it internally performs a copy followed by delete of the original.
## Tips
- Use `mv -n` in scripts to guard against accidentally clobbering existing files.
## Common Mistakes
- Moving a file into a directory that doesn't exist, which instead **renames** the source to that (non-existent-directory) name rather than erroring — a frequent source of confusion.
## Related Commands
[cp](#cp), [rm](#rm)

---

# rm
## Purpose
Remove (delete) files or directories.
## Syntax
```
rm [OPTIONS] FILE
```
## Common Options
| Option | Description |
|---|---|
| `-r` | Remove directories and their contents recursively |
| `-f` | Force removal, never prompt, ignore nonexistent files |
| `-i` | Prompt before every removal |
| `-v` | Verbose, print each removal |

## Example
```bash
rm -riv old_build/
```
## Expected Output
```
remove regular file 'old_build/output.bin'? y
removed 'old_build/output.bin'
```
## Explanation
`rm` does **not** move files to a trash/recycle bin by default — deleted files are gone immediately (though data may be forensically recoverable until overwritten, which is why `shred` exists for sensitive data).
## Tips
- Consider aliasing `rm` to `rm -i` while learning, to build a safety habit before you're fully comfortable.
- Use `trash-cli` (a separate package) if you want recycle-bin-like behavior.
## Common Mistakes
- **The single most dangerous Linux mistake:** running `rm -rf /` or `rm -rf *` from the wrong directory, or with a leading space typo like `rm -rf ~ /old` (note the space) which deletes your entire home directory. Always double-check the path before pressing Enter on any `rm -rf` command.
## Related Commands
[rmdir](#rmdir), [shred](#shred)

---

# cat
## Purpose
Concatenate and print file contents to standard output.
## Syntax
```
cat [OPTIONS] FILE
```
## Common Options
| Option | Description |
|---|---|
| `-n` | Number all output lines |
| `-A` | Show non-printing characters (tabs, line endings) |
| `-s` | Squeeze multiple blank lines into one |

## Example
```bash
cat -n /etc/hosts
```
## Expected Output
```
     1	127.0.0.1	localhost
     2	::1		localhost
```
## Explanation
`cat` reads a file's entire contents and streams it to stdout; it can also concatenate multiple files: `cat file1 file2 > combined`.
## Tips
- `cat > newfile.txt` (then `Ctrl+D`) is a fast way to create a small file directly from the terminal.
## Common Mistakes
- Using `cat largefile.log` on a huge file and flooding the terminal — use `less` for large files instead.
## Related Commands
[less](#less), [tac](#tac), [head](#head)

---

# tac
## Purpose
Print a file's lines in reverse order (last line first) — `cat` spelled backwards.
## Syntax
```
tac FILE
```
## Example
```bash
tac access.log
```
## Explanation
Useful for viewing log files where you want the newest entries (typically appended at the end) first, without scrolling to the bottom.
## Tips
- Combine with `head`: `tac app.log | head -20` shows the 20 most recent log lines instantly.
## Common Mistakes
- Assuming it reverses character order within each line — it only reverses the order of *lines*, not text within them.
## Related Commands
[cat](#cat), [tail](#tail)

---

# less
## Purpose
View file contents one screen at a time, with backward and forward scrolling and search.
## Syntax
```
less FILE
```
## Common Keybindings
| Key | Action |
|---|---|
| `Space` | Next page |
| `b` | Previous page |
| `/pattern` | Search forward |
| `n` / `N` | Next / previous search match |
| `q` | Quit |

## Example
```bash
less /var/log/syslog
```
## Explanation
`less` loads content incrementally, so it opens instantly even on multi-gigabyte files (unlike `cat`, which reads the whole file, or the older `more`, which can't scroll backward).
## Tips
- `less +F filename` behaves like `tail -f`, following new lines in real time, but you can press `Ctrl+C` to stop following and scroll freely.
## Common Mistakes
- Using `cat` on huge log files out of habit when `less` is both faster and safer for the terminal.
## Related Commands
[more](#more), [cat](#cat), [tail](#tail)

---

# more
## Purpose
View file contents one screen at a time (the older, simpler ancestor of `less`).
## Syntax
```
more FILE
```
## Example
```bash
more README.md
```
## Explanation
`more` only scrolls forward (with limited backward support in modern versions) and has fewer features than `less`. It's largely kept for backward compatibility and POSIX compliance.
## Tips
- Prefer `less` in almost all cases — the mnemonic "less is more" refers to `less` being the more capable successor.
## Common Mistakes
- Expecting the same search/navigation features as `less` — some are missing or behave differently in `more`.
## Related Commands
[less](#less), [cat](#cat)

---

# head
## Purpose
Display the first lines (or bytes) of a file.
## Syntax
```
head [OPTIONS] FILE
```
## Common Options
| Option | Description |
|---|---|
| `-n N` | Show first N lines (default 10) |
| `-c N` | Show first N bytes |

## Example
```bash
head -n 20 access.log
```
## Explanation
Extremely common in pipelines to preview large output without processing all of it, e.g., `ps aux | head`.
## Tips
- `head -c 100 file` is handy for peeking at binary file headers alongside `file` and `xxd`.
## Common Mistakes
- Confusing `-n` (lines) with `-c` (bytes) when precise byte-level output matters.
## Related Commands
[tail](#tail), [cat](#cat)

---

# tail
## Purpose
Display the last lines of a file, optionally following it in real time as it grows.
## Syntax
```
tail [OPTIONS] FILE
```
## Common Options
| Option | Description |
|---|---|
| `-n N` | Show last N lines (default 10) |
| `-f` | Follow the file, showing new lines as they're appended |
| `-F` | Like `-f` but also re-attaches if the file is rotated/recreated |

## Example
```bash
tail -f /var/log/nginx/access.log
```
## Expected Output
```
203.0.113.5 - - [06/Jul/2026:10:15:02 +0530] "GET /api/health HTTP/1.1" 200 15
```
## Explanation
`-f` is one of the most-used flags in system administration — it lets you watch a live log stream continuously (press `Ctrl+C` to stop).
## Tips
- Use `-F` instead of `-f` for logs managed by `logrotate`, since `-f` can keep watching a now-stale rotated file handle.
## Common Mistakes
- Forgetting to `Ctrl+C` out of a `tail -f` session, leaving an unattended terminal "stuck" watching logs.
## Related Commands
[head](#head), [less +F](#less)

---

# wc
## Purpose
Count lines, words, and bytes/characters in a file or input stream.
## Syntax
```
wc [OPTIONS] FILE
```
## Common Options
| Option | Description |
|---|---|
| `-l` | Count lines only |
| `-w` | Count words only |
| `-c` | Count bytes |
| `-m` | Count characters (handles multi-byte encodings) |

## Example
```bash
wc -l access.log
```
## Expected Output
```
15234 access.log
```
## Explanation
Extremely common in shell pipelines to quickly count results: `ls | wc -l` counts files in a directory; `grep "ERROR" app.log | wc -l` counts error occurrences.
## Tips
- `wc -l < file` (using input redirection instead of an argument) avoids printing the filename alongside the count — useful in scripts.
## Common Mistakes
- Using `-c` (bytes) when you meant `-m` (characters) on files with multi-byte UTF-8 content — the counts will differ.
## Related Commands
[grep](shell-scripting.md#grep), [cat](#cat)

---

# diff
## Purpose
Compare two files line-by-line and show the differences.
## Syntax
```
diff [OPTIONS] FILE1 FILE2
```
## Common Options
| Option | Description |
|---|---|
| `-u` | Unified diff format (most readable, used for patches) |
| `-r` | Compare directories recursively |
| `-q` | Only report whether files differ, not the details |
| `-i` | Ignore case differences |

## Example
```bash
diff -u config.old config.new
```
## Expected Output
```
--- config.old	2026-07-01 10:00:00
+++ config.new	2026-07-06 10:00:00
@@ -3,3 +3,3 @@
-port=8080
+port=9090
```
## Explanation
Unified diff format (`-u`) shows a few lines of context around each change, marking removed lines with `-` and added lines with `+`. This is the same format used for patch files (`.patch`/`.diff`) applied with `patch` or `git apply`.
## Tips
- Use `diff -rq dir1 dir2` to quickly find which files differ between two directory trees without seeing full contents.
## Common Mistakes
- Confusing `diff` argument order — the output convention shows FILE1 as removed (`-`) content and FILE2 as added (`+`) content.
## Related Commands
[cmp](#cmp)

---

# cmp
## Purpose
Compare two files byte-by-byte and report the first difference.
## Syntax
```
cmp [OPTIONS] FILE1 FILE2
```
## Common Options
| Option | Description |
|---|---|
| `-l` | List every differing byte position and value |
| `-s` | Silent mode; only return an exit code (useful in scripts) |

## Example
```bash
cmp file1.bin file2.bin
```
## Expected Output
```
file1.bin file2.bin differ: byte 42, line 3
```
## Explanation
Unlike `diff` (line-oriented, best for text), `cmp` works at the byte level, making it the correct tool for comparing binary files.
## Tips
- Use `cmp -s a b && echo "identical"` in scripts to check byte-for-byte equality without printing details.
## Common Mistakes
- Using `diff` on binary files and getting an unhelpful "binary files differ" message when `cmp -l` would show exact byte positions.
## Related Commands
[diff](#diff)

---

# ln
## Purpose
Create hard links or symbolic (soft) links between files.
## Syntax
```
ln [OPTIONS] TARGET LINK_NAME
```
## Common Options
| Option | Description |
|---|---|
| `-s` | Create a symbolic link (most commonly used) |
| `-f` | Force, overwrite existing link destination |

## Example
```bash
ln -s /opt/app/current/bin/app /usr/local/bin/app
```
## Expected Output
```
(no output on success)
```
## Explanation
A **symbolic link** is a separate file that stores a path pointing to the target — it can cross filesystems and point to directories, but breaks if the target is removed. A **hard link** (default, no `-s`) is a second directory entry pointing to the *same inode* — it can't cross filesystems or link directories, but survives even if the "original" name is deleted (since both names reference the same data).
## Tips
- Use `ls -li` to see inode numbers and confirm whether two names are hard-linked to the same inode.
## Common Mistakes
- Deleting a symlink's target and being surprised the symlink now points nowhere (a "broken" or "dangling" symlink) — this cannot happen with hard links.
## Related Commands
[readlink](navigation.md#readlink), [cp](#cp)

---

# tar
## Purpose
Bundle multiple files/directories into a single archive file (optionally compressed).
## Syntax
```
tar [OPTIONS] ARCHIVE_NAME FILES
```
## Common Options
| Option | Description |
|---|---|
| `-c` | Create a new archive |
| `-x` | Extract from an archive |
| `-v` | Verbose, list files as processed |
| `-f` | Specify archive filename (must come right before the filename) |
| `-z` | Compress/decompress with gzip (`.tar.gz`) |
| `-j` | Compress/decompress with bzip2 (`.tar.bz2`) |
| `-t` | List archive contents without extracting |

## Example
```bash
tar -czvf backup.tar.gz /home/kapilesh/projects
tar -xzvf backup.tar.gz
```
## Expected Output
```
home/kapilesh/projects/
home/kapilesh/projects/README.md
```
## Explanation
"tar" originally stood for **t**ape **ar**chive. It combines files into one stream; the `-z`/`-j` flags then pipe that stream through a compression algorithm. This is why `.tar.gz` is often called a "tarball."
## Tips
- Remember the mnemonic **"tar -czvf"** = **c**reate, **z** (gzip), **v**erbose, **f**ile — and the reverse **"tar -xzvf"** to extract.
## Common Mistakes
- Forgetting `-f` or putting the archive filename in the wrong position relative to `-f` (it must directly follow `-f`).
- Extracting an untrusted archive without first checking contents with `tar -tzvf` (archives can contain absolute paths or `../` traversal sequences in rare/malicious cases).
## Related Commands
[gzip](#gzip), [zip](#zip)

---

# gzip
## Purpose
Compress a file using the gzip (DEFLATE) algorithm.
## Syntax
```
gzip [OPTIONS] FILE
```
## Common Options
| Option | Description |
|---|---|
| `-k` | Keep the original file (default deletes it after compressing) |
| `-9` | Maximum compression (slower) |
| `-d` | Decompress (same as `gunzip`) |

## Example
```bash
gzip -k access.log
```
## Expected Output
```
(creates access.log.gz, keeps original with -k)
```
## Explanation
`gzip` compresses a **single file** in place — it has no concept of directories or multi-file archives (that's what `tar` is for, often combined with gzip as `.tar.gz`).
## Tips
- Always use `-k` if you want to keep the original uncompressed file around.
## Common Mistakes
- Trying to `gzip` a whole directory directly — it will error; you must `tar` it first, then compress.
## Related Commands
[gunzip](#gunzip), [tar](#tar)

---

# gunzip
## Purpose
Decompress a `.gz` file (equivalent to `gzip -d`).
## Syntax
```
gunzip [OPTIONS] FILE.gz
```
## Example
```bash
gunzip access.log.gz
```
## Explanation
Restores the original file from its compressed `.gz` form, removing the `.gz` extension.
## Tips
- Use `-k` to keep the compressed `.gz` copy alongside the extracted file.
## Common Mistakes
- Running `gunzip` on a `.tar.gz` file and expecting extracted files — this only removes the gzip layer, leaving you with a plain `.tar` file that still needs `tar -xf`.
## Related Commands
[gzip](#gzip), [tar](#tar)

---

# zip
## Purpose
Create a compressed `.zip` archive (cross-platform, widely compatible with Windows/macOS).
## Syntax
```
zip [OPTIONS] ARCHIVE.zip FILES
```
## Common Options
| Option | Description |
|---|---|
| `-r` | Recurse into directories |
| `-e` | Encrypt the archive with a password |

## Example
```bash
zip -r project.zip project/
```
## Expected Output
```
  adding: project/ (stored 0%)
  adding: project/README.md (deflated 42%)
```
## Explanation
Unlike `tar.gz`, a `.zip` file both bundles and compresses each file individually, making it more universally compatible with non-Linux operating systems.
## Tips
- Prefer `.tar.gz` for Linux-to-Linux transfers (better compression ratio, preserves permissions); prefer `.zip` when sharing with Windows/macOS users.
## Common Mistakes
- Forgetting `-r` when zipping a directory, resulting in an archive with no actual file contents.
## Related Commands
[unzip](#unzip), [tar](#tar)

---

# unzip
## Purpose
Extract files from a `.zip` archive.
## Syntax
```
unzip [OPTIONS] ARCHIVE.zip
```
## Common Options
| Option | Description |
|---|---|
| `-l` | List contents without extracting |
| `-d DIR` | Extract into a specific directory |
| `-o` | Overwrite existing files without prompting |

## Example
```bash
unzip -l project.zip
unzip project.zip -d ./extracted
```
## Explanation
Not installed by default on some minimal server distros — install via `sudo apt install unzip` or `sudo dnf install unzip` if missing.
## Tips
- Always run `-l` first on an unfamiliar archive to preview its contents before extracting.
## Common Mistakes
- Extracting directly into the current directory and unexpectedly overwriting existing files of the same name.
## Related Commands
[zip](#zip), [tar](#tar)

---

# rsync
## Purpose
Efficiently synchronize files and directories, locally or over a network, copying only the differences.
## Syntax
```
rsync [OPTIONS] SOURCE DESTINATION
```
## Common Options
| Option | Description |
|---|---|
| `-a` | Archive mode: preserves permissions, timestamps, symlinks, recurses into directories |
| `-v` | Verbose |
| `-z` | Compress data during transfer |
| `--delete` | Delete files in destination that no longer exist in source (mirror mode) |
| `-P` | Show progress and allow resuming partial transfers |

## Example
```bash
rsync -avzP ./project/ user@server:/var/www/project/
```
## Expected Output
```
sending incremental file list
index.html
       1,024 100%    2.31MB/s    0:00:00
```
## Explanation
`rsync` uses a delta-transfer algorithm — it only sends the parts of files that changed, making repeated syncs of large directories far faster than plain `cp`/`scp`. It's the standard tool behind most Linux backup solutions.
## Tips
- The trailing slash on the source matters: `rsync -av src/ dest/` copies the *contents* of `src` into `dest`; `rsync -av src dest/` copies `src` itself as a subfolder of `dest`.
- Always test `--delete` operations first with `--dry-run` to preview what would be removed.
## Common Mistakes
- Using `--delete` without `--dry-run` first and unexpectedly wiping files at the destination that weren't in the source.
## Related Commands
[cp](#cp), [scp](networking.md#scp)

---

# shred
## Purpose
Securely overwrite a file's data multiple times before deletion, to reduce recoverability.
## Syntax
```
shred [OPTIONS] FILE
```
## Common Options
| Option | Description |
|---|---|
| `-u` | Also delete (unlink) the file after shredding |
| `-n N` | Number of overwrite passes (default 3) |
| `-z` | Add a final overwrite with zeros to hide shredding occurred |

## Example
```bash
shred -uzn 5 secrets.txt
```
## Expected Output
```
(no output on success — the file is overwritten then removed)
```
## Explanation
Regular `rm` only removes the filesystem's *reference* to data; the underlying disk blocks often remain physically recoverable until overwritten. `shred` overwrites those blocks directly to make forensic recovery much harder.
## Tips
- Note: on modern SSDs with wear-leveling and on journaling/copy-on-write filesystems (like ext4 with certain configurations, or btrfs/zfs), `shred`'s guarantees are significantly weakened — the drive controller may write to different physical cells than expected. Full-disk encryption is generally a more reliable protection strategy.
## Common Mistakes
- Assuming `shred` guarantees unrecoverability on all storage types — it does not on SSDs or copy-on-write filesystems.
## Related Commands
[rm](#rm)

---

# split
## Purpose
Split a large file into smaller pieces.
## Syntax
```
split [OPTIONS] FILE PREFIX
```
## Common Options
| Option | Description |
|---|---|
| `-b SIZE` | Split by byte size (e.g., `-b 100M`) |
| `-l LINES` | Split by number of lines |
| `-d` | Use numeric suffixes instead of alphabetic |

## Example
```bash
split -b 50M largefile.iso chunk_
```
## Expected Output
```
(creates chunk_aa, chunk_ab, chunk_ac, ...)
```
## Explanation
Useful for splitting files too large to fit on transport media or upload limits; reassemble with `cat chunk_* > largefile.iso`.
## Tips
- Use `-d` for numeric suffixes (`chunk_00`, `chunk_01`) which sort more predictably than default alphabetic ones in some tools.
## Common Mistakes
- Forgetting the exact reassembly order matters — always `cat` the parts in the correct sorted sequence.
## Related Commands
[tar](#tar), [cat](#cat)

---

# truncate
## Purpose
Shrink or extend a file to a specified size.
## Syntax
```
truncate [OPTIONS] FILE
```
## Common Options
| Option | Description |
|---|---|
| `-s SIZE` | Set the exact size (e.g., `-s 0` to empty a file, `-s 1G` to create a 1GB sparse file) |

## Example
```bash
truncate -s 0 debug.log
```
## Expected Output
```
(no output — file is now 0 bytes, but still exists)
```
## Explanation
`truncate -s 0` is the standard safe way to empty a log file without deleting and recreating it (which would break any process still holding an open file handle to it).
## Tips
- `truncate -s 1G testfile` instantly creates a large sparse file for testing, without actually writing 1GB of real data to disk.
## Common Mistakes
- Using `rm` then recreating a log file instead of `truncate -s 0`, which can break running processes that hold the original file descriptor open (they keep writing to the now-unlinked old file).
## Related Commands
[rm](#rm)

---

# xxd
## Purpose
Display or create a hexadecimal dump of binary file contents.
## Syntax
```
xxd [OPTIONS] FILE
```
## Common Options
| Option | Description |
|---|---|
| `-l N` | Limit output to first N bytes |
| `-r` | Reverse: convert a hex dump back into binary |

## Example
```bash
xxd -l 32 /bin/ls
```
## Expected Output
```
00000000: 7f45 4c46 0201 0100 0000 0000 0000 0000  .ELF............
```
## Explanation
Shows raw byte values in hexadecimal alongside their ASCII representation — essential for inspecting binary file headers, debugging corrupted files, or basic malware/forensics analysis.
## Tips
- The bytes `7f 45 4c 46` at the start (seen above) spell "ELF" — the magic number identifying Linux executable files.
## Common Mistakes
- Using `cat` on binary files instead of `xxd`, which can print garbage to the terminal and even mess up terminal display settings.
## Related Commands
[file](navigation.md#file), [od](#xxd)

---

⬅️ Back to [navigation.md](navigation.md) | Next: [file-permissions.md](file-permissions.md) ➡️
