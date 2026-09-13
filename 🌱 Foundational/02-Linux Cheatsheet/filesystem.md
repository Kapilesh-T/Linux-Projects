[🏠 Home](README.md) | [Navigation](navigation.md) | [Permissions](file-permissions.md) | [Processes](processes.md) | [Networking](networking.md) | [Users & Groups](users-groups.md) | [Storage](storage.md) | [Packages](package-management.md) | [Shell Scripting](shell-scripting.md) | [Security](security.md)

# File & Directory Operations

Creating, copying, moving, deleting, comparing, compressing, and
archiving files.

**Contents:** [mkdir](#mkdir) · [rmdir](#rmdir) · [touch](#touch) · [cp](#cp) · [mv](#mv) · [rm](#rm) · [cat](#cat) · [tac](#tac) · [less](#less) · [more](#more) · [head](#head) · [tail](#tail) · [wc](#wc) · [diff](#diff) · [cmp](#cmp) · [ln](#ln) · [tar](#tar) · [gzip](#gzip) · [gunzip](#gunzip) · [zip](#zip) · [unzip](#unzip) · [rsync](#rsync) · [shred](#shred) · [split](#split) · [truncate](#truncate) · [xxd](#xxd)

---

### mkdir
Create directories.

```bash
mkdir -p project/src/components    # -p: create missing parents too
mkdir -m 700 private               # -m: set permissions at creation
```

`-p` never errors when the directory already exists — it's also the idiomatic way to make deep nested paths in one command. `-v` prints each directory it creates.

### rmdir
Remove **empty** directories.

```bash
rmdir old_folder          # fails with "Directory not empty" if it has contents
rmdir -p a/b/c            # also remove now-empty parents
```

Use `rmdir` when you specifically want the safety of refusing non-empty directories; `rm -r` is the deliberate "delete everything inside too" variant.

### touch
Create an empty file, or update the timestamps of an existing one.

```bash
touch app.log                    # create if missing
touch -t 202601011200 notes.txt  # set a specific timestamp
touch -c config.bak              # -c: do NOT create if missing
```

`touch` never changes a file's *contents*. It's also how you "nudge" a file so build tools like `make` see it as newer. Brace expansion makes multi-file creation easy: `touch {a,b,c}.txt`.

### cp
Copy files or directories.

```bash
cp -rv src/ backup/          # -r recurse, -v verbose
cp -p file.txt copy.txt      # -p preserve perms, ownership, timestamps
cp -u src dest               # -u only if source is newer
```

- Without `-r`, `cp` on a directory fails ("omitting directory").
- The trailing slash matters when the destination exists: `cp -r src dest` puts `src` *inside* `dest`; `cp -r src/ dest/` merges the contents. Test with `-i` (prompt before overwrite) until you're sure.

### mv
Move or rename files and directories.

```bash
mv draft.md final-report.md    # rename
mv -n file dest/               # -n: never overwrite an existing file
```

- On the same filesystem, `mv` is a fast metadata-only rename. Across filesystems it's a copy + delete.
- Gotcha: `mv file /path/that/does/not/exist` **renames** the file to that name instead of erroring.

### rm
Remove files or directories. There is **no trash bin** — files are gone immediately.

```bash
rm -riv old_build/      # -r recurse, -i prompt, -v verbose
```

- `rm -f` never prompts and ignores nonexistent files — handy in scripts, dangerous interactively.
- The classic data-loss commands: `rm -rf /` and `rm -rf ~ /old` (note the stray space). Double-check the path before pressing Enter; alias `rm` to `rm -i` while learning.
- For sensitive data, `rm` only unlinks the name — disk blocks can still be recovered. That's what `shred` is for.

### cat
Print file contents, or concatenate files.

```bash
cat -n /etc/hosts          # -n: number lines
cat -A config.txt          # -A: show tabs and line endings
cat file1 file2 > merged   # concatenate into a new file
cat > newfile.txt          # type, then Ctrl+D to finish
```

`cat largefile.log` floods the terminal — use `less` for big files. `-s` squeezes repeated blank lines.

### tac
Print a file's lines in reverse order (`cat` backwards).

```bash
tac access.log | head -20    # 20 most recent lines of a growing log
```

Reverses the order of *lines*, not the characters within them.
### less
Page through files with forward/backward scrolling and search. Loads incrementally, so it opens multi-gigabyte files instantly.

```bash
less /var/log/syslog
```

Keys: `Space` next page · `b` previous page · `/pattern` search, `n`/`N` next/prev match · `q` quit. `less +F file` follows appended lines like `tail -f` (press `Ctrl+C` to stop following and scroll freely).

### more
The older, simpler pager `less` replaced. Forward-only scrolling, weaker search — kept for backward compatibility. Prefer `less`.

### head
Print the first lines or bytes of a file.

```bash
head -n 20 access.log     # first 20 lines (default 10)
head -c 100 file.bin      # first 100 bytes
```

`head` in a pipeline is the standard way to preview large output: `ps aux | head`.

### tail
Print the last lines of a file, or follow it as it grows.

```bash
tail -n 50 app.log        # last 50 lines (default 10)
tail -f /var/log/nginx/access.log    # live follow; Ctrl+C to stop
tail -F app.log           # -F: re-attach after log rotation
```

Use `-F` (capital) for logs managed by `logrotate` — `-f` keeps watching the stale rotated file handle.

### wc
Count lines, words, or bytes.

```bash
wc -l access.log          # 15234 access.log
ls | wc -l                # count of files in a directory
grep -c ERROR app.log     # count of matches (no wc needed)
```

`wc -l < file` (redirection instead of an argument) omits the filename from the output — tidier in scripts. `-c` counts bytes, `-m` counts characters; they differ on multi-byte UTF-8.

### diff
Compare files line by line.

```bash
diff -u config.old config.new    # unified format (used for patches)
diff -rq dir1 dir2               # -r recurse, -q just "differ or not"
diff -i a.txt b.txt              # ignore case
```

Unified output marks removed lines `-` and added lines `+` with a few lines of context — the same format `patch` and `git apply` expect. Arguments are order-sensitive: FILE1 is the `-` side.

### cmp
Compare files byte by byte — the right tool for binaries.

```bash
cmp file1.bin file2.bin        # "differ: byte 42, line 3"
cmp -s a b && echo identical   # -s: silent, exit code only
```

`diff` on binary files just says "binary files differ"; `cmp -l` lists every differing byte position.

### ln
Create hard or symbolic links.

```bash
ln -s /opt/app/bin/app /usr/local/bin/app    # symbolic link
ln target.txt hardlink.txt                    # hard link (default)
```

- A **symbolic link** is a small file storing a path — it can cross filesystems and point at directories, but breaks ("dangling") if the target is removed.
- A **hard link** is a second directory entry for the *same inode* — it can't cross filesystems or link directories, but survives the "original" name being deleted. `ls -li` shows inode numbers to confirm a hard link.
### tar
Bundle files and directories into one archive file, optionally compressed.

```bash
tar -czvf backup.tar.gz /home/kapilesh/projects   # c=create, z=gzip, v=verbose, f=file
tar -xzvf backup.tar.gz                           # x=extract
tar -tzvf backup.tar.gz                           # t=list contents
```

- "tar" is short for **t**ape **ar**chive. `-z` pipes the stream through gzip (use `-j` for bzip2), which is why the result is a `.tar.gz`.
- `-f` must be followed directly by the archive filename.
- Check an untrusted archive's contents (`tar -tzvf`) before extracting — archives can contain absolute paths or `../` traversal sequences.

### gzip
Compress a **single file** in place using gzip.

```bash
gzip -k access.log        # access.log.gz, original kept (-k)
gzip -9 backup.tar        # max compression, slower
gunzip access.log.gz      # or: gzip -d
```

`gzip` has no concept of directories or multiple files — combine with `tar` first for those. Default deletes the original file; `-k` keeps it.

### gunzip
Decompress a `.gz` file (same as `gzip -d`).

```bash
gunzip access.log.gz          # restores access.log
gunzip -k access.log.gz       # keep the .gz too
```

`gunzip` on a `.tar.gz` only removes the gzip layer — you still need `tar -xf` to get the files out.

### zip
Create a compressed `.zip` archive — the cross-platform format for sharing with Windows/macOS.

```bash
zip -r project.zip project/    # -r: recurse into directories
zip -e secrets.zip file.txt    # -e: encrypt with a password
```

Unlike `.tar.gz`, zip bundles *and* compresses each file individually. For Linux-to-Linux transfers `.tar.gz` is usually better (better compression, preserves permissions).

### unzip
Extract a `.zip` archive.

```bash
unzip project.zip          # extract into the current directory
unzip -l project.zip       # -l: list contents without extracting
unzip project.zip -d out/  # -d: extract into a specific directory
```

Always run `unzip -l` first on an unfamiliar archive so you know what will be written before it overwrites anything.

### rsync
Synchronize files locally or over a network, transferring only what changed.

```bash
rsync -avzP ./project/ user@server:/var/www/project/
rsync -av --delete src/ dest/     # mirror: delete extras at dest
```

- `-a` archive (permissions, timestamps, symlinks, recursion), `-v` verbose, `-z` compress, `-P` progress + resume.
- Trailing slash matters: `rsync -av src/ dest/` copies the *contents* of `src`; `rsync -av src dest/` copies `src` itself into `dest`.
- Delta-transfer sends only changed file parts, which is why repeated syncs are fast — the engine behind most rsync-based backup setups.
- Always preview `--delete` with `--dry-run` first; done wrong it wipes destination files that aren't in the source.

### shred
Overwrite a file's data before deletion to make forensic recovery much harder.

```bash
shred -uzn 5 secrets.txt    # -u delete after, -n 5 passes, -z zero-pass
```

`rm` only removes the filesystem reference; the data often stays on disk. Caveat: on SSDs (wear leveling) and copy-on-write filesystems (btrfs/zfs), `shred` can't guarantee the physical cells were rewritten — full-disk encryption is the more reliable protection.

### split
Split a large file into pieces.

```bash
split -b 50M largefile.iso chunk_      # byte-size pieces
split -l 1000 big.txt part_            # by line count
split -d -b 50M largefile.iso chunk_   # -d: numeric suffixes (chunk_00)
```

Rename the pieces to reassemble later, or use `cat chunk_* > original` to recombine.

### truncate
Set a file's size without touching its contents.

```bash
truncate -s 100M sparse.img    # grow to 100 MB (sparse — no disk used yet)
truncate -s 0 app.log          # empty an existing file in place
```

Growing creates a sparse file whose blocks are allocated on first write — useful for making loopback images and testing. `-s -5K` shrinks by 5 KB.

### xxd
Hex dump a file — the standard way to inspect raw bytes.

```bash
xxd file.bin              # full hex + ASCII side-by-side dump
xxd -l 64 file.bin        # first 64 bytes only
xxd -r hex.txt > out.bin  # reverse: hex back to binary
```

Pair with `file -i` and `head -c ... | xxd` when checking magic numbers of unknown file types.

---

⬅️ Back to [Navigation](navigation.md) | Next: [Permissions](file-permissions.md) ➡️