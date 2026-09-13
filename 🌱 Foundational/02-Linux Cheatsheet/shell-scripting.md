[🏠 Home](README.md) | [Navigation](navigation.md) | [Filesystem](filesystem.md) | [Permissions](file-permissions.md) | [Processes](processes.md) | [Networking](networking.md) | [Users & Groups](users-groups.md) | [Storage](storage.md) | [Packages](package-management.md) | [Security](security.md)

# Shell Scripting Essentials

Bash scripting basics plus the text-processing commands (`grep`, `sed`,
`awk` and friends) scripts rely on.

**Contents:** [Shebang & script basics](#shebang--script-basics) · [Variables](#variables) · [Conditionals](#conditionals-if) · [Loops](#loops-forwhile) · [Functions](#functions) · [grep](#grep) · [sed](#sed) · [awk](#awk) · [cut](#cut) · [sort](#sort) · [uniq](#uniq) · [tr](#tr) · [xargs](#xargs) · [echo](#echo) · [printf](#printf) · [read](#read) · [test / [ ]](#test--) · [set](#set) · [export](#export) · [source](#source)

---

### Shebang & script basics
The `#!/bin/bash` first line tells the kernel which interpreter to use when a script runs directly. Without `chmod +x` and a correct shebang, `./script.sh` fails even if the logic is perfect.

```bash
#!/usr/bin/env bash    # preferred over a hardcoded /bin/bash path
echo "Hello, $USER!"
```

Save scripts with **LF line endings** — CRLF breaks the shebang (`bad interpreter` error). While developing, `bash script.sh` isolates permission problems from logic problems.

### Variables
Bash variables are untyped strings; `$()` runs a command and substitutes its output.

```bash
NAME="Kapilesh"
COUNT=5
echo "User: $NAME, Count: $COUNT"
echo "Today: $(date +%F)"
```

- **Quote your expansions** ("$VAR", not $VAR) — unquoted `rm $FILE` breaks on spaces and can become dangerous when empty.
- Use braces when the name is ambiguous: `"${NAME}_backup.txt"`.
- No spaces around `=` (`VAR = "x"` is a syntax error).
- Arithmetic uses `$(( ))`: `count=$((count + 1))`.

### Conditionals (if)
`[ ]` is the `test` command — the spaces around brackets are required syntax, not style.

```bash
if [ -f "/etc/passwd" ]; then
    echo "File exists."
elif [ -d "/etc" ]; then
    echo "Directory exists but file doesn't."
else
    echo "Neither found."
fi
```

Operators: `-f` file exists · `-d` dir exists · `-z` string empty · `-n` not empty · `==`/`!=` string compare · `-eq`/`-ne` numeric compare. Prefer `[[ ]]` (Bash-only) — more forgiving with quoting and supports `&&`, `||`, and pattern matching. String vs numeric operators differ: `=` is for strings, `-eq` for numbers.

### Loops (for/while)
`for` iterates over a list of **words** (glob, literal list, command output); `while` repeats while a condition holds.

```bash
for file in *.log; do            # glob — safe with spaces in names
    echo "Processing: $file"
done

for i in {1..10}; do echo "$i"; done
for (( i=0; i<10; i++ )); do echo "$i"; done

count=0
while [ $count -lt 5 ]; do
    echo "Count: $count"
    count=$((count + 1))
done
```

Never loop over `ls` output (`for f in $(ls)`) — it breaks on spaces and special characters; globs (`for f in *`) are the safe idiom.

### Functions
Arguments arrive as `$1`, `$2`... (`$@` all, `$#` count) — same as script arguments.

```bash
greet() {
    local name="$1"
    echo "Hello, $name!"
}
greet "Kapilesh"
```

Always use `local` for function variables — without it they leak into the script's namespace and can clobber global state. Functions must be defined before their first call (Bash reads top to bottom).
### grep
Search text for matching lines — the most-used text tool in Linux.

```bash
grep -rn "TODO" ./src         # recursive, with line numbers
grep -i "error" app.log | wc -l
grep -v "^#" config.txt       # lines NOT matching (skip comments)
grep -c ERROR app.log         # count matches
grep -E "foo|bar" file.txt    # extended regex (| + {})
grep -w root /etc/passwd      # whole-word matches only
```

Quote patterns containing `$`, `*`, `[` so the shell doesn't expand them first. Basic `grep` treats `+|{}` literally — use `-E` for extended regex.

### sed
Stream editor — find-and-replace and other line-by-line transformations.

```bash
sed 's/http:/https:/g' urls.txt          # global replace (no g = first per line)
sed -i.bak 's/DEBUG=False/DEBUG=True/' settings.py   # in-place with backup
sed -n '2p' file.txt                     # print only line 2
sed '/pattern/d' file.txt                # delete matching lines
```

Test `-i` edits on a copy, or use `-i.bak` to keep a backup automatically — a bad regex with `-i` corrupts the file with no undo.

### awk
A small pattern-scanning language for column-based text. Fields split on whitespace automatically: `$1`, `$2`, ..., `$NF` is the last field.

```bash
ps aux | awk '{print $2, $11}'          # PID + command
awk -F',' '{print $1}' data.csv         # -F: custom delimiter (CSV!)
awk '{sum += $2} END {print sum}' nums.txt
awk 'NR==2' file.txt                    # just line 2
```

`awk`'s default separator is whitespace — always set `-F','` for CSV. `BEGIN`/`END` blocks give you setup and summary logic without extra processes.

### cut
Extract fixed columns by delimiter or character position — the light option when `awk` is overkill.

```bash
cut -d':' -f1 /etc/passwd     # usernames
cut -c1-10 file.txt           # first 10 chars of each line
```

If you forget `-d`, the default delimiter is tab and a comma-separated line becomes a single field.

### sort / uniq
Sort lines, then collapse/count duplicates. `uniq` only removes *adjacent* duplicates, which is why it always follows `sort`.

```bash
sort -n scores.txt            # -n: numeric (else "10" < "2" lexicographically!)
sort -rh sizes.txt            # -h: human sizes (1K, 2M)
sort -u names.txt             # -u: drop duplicates while sorting

sort access.log | awk '{print $1}' | uniq -c | sort -rn | head
```

The `sort | uniq -c | sort -rn` pattern ("rank the most frequent values") is worth memorizing — it's the core of most log-analysis one-liners.

### tr
Character-level translation — individual characters, not substrings or patterns.

```bash
echo "Hello World" | tr 'a-z' 'A-Z'
echo "a  b" | tr -s ' '       # -s: squeeze repeated chars
echo "line1\nline2" | tr -d '\n'
```

Multi-character replacement needs `sed`; `tr` maps single characters only. Watch out for ranges: in `tr`, `()-_` would be a range from `)` to `_` — put a literal hyphen last in the set.
### xargs
Turn piped lines into command-line arguments — the bridge for commands like `rm` that don't read stdin.

```bash
find . -name "*.tmp" -print0 | xargs -0 rm -v    # safe with weird filenames
echo "file1.txt file2.txt" | xargs -n1 wc -l     # -n1: one arg per invocation
cat urls.txt | xargs -I {} curl -s -o {}.html {}
```

`find -print0 | xargs -0` (NUL-delimited) is the safe pairing when filenames can contain spaces or newlines — plain `find | xargs` splits a filename with a space into two arguments.

### echo
Print text. Shell builtin, so it's fast.

```bash
echo "Deployment complete."
echo -e "Line1\nLine2"     # -e: interpret \n, \t escapes
echo -n "no newline"
```

`echo`'s escape handling varies between shells — for portable, precise output use `printf`.

### printf
Formatted output, C-style. Behavior is consistent across shells; `\n` is never implicit.

```bash
printf "Name: %s, Score: %.1f%%\n" "Kapilesh" 87.456
# Name: Kapilesh, Score: 87.5%
```

`%s` string · `%d` integer · `%.2f` float with 2 decimals. A literal `%` must be written as `%%`.

### read
Read input into a variable — from the keyboard or a pipe.

```bash
read -p "Enter your name: " name
read -sp "Password: " pw; echo    # -s: silent (no echo of typed chars)
```

The robust idiom for reading a file line by line:

```bash
while IFS= read -r line; do
    echo "$line"
done < file.txt
```

`for line in $(cat file)` splits on *all* whitespace and mangles lines with spaces — use `while read`.

### test / [ ]
The conditional evaluator behind every `if`. `[` is literally a command taking `]` as its last argument — that's why the spaces are mandatory.

```bash
[ -f file.txt ] && echo exists
[ -z "$1" ] && { echo "No argument provided."; exit 1; }
```

Prefer `[[ ]]` in Bash scripts (safer with unquoted variables, supports regex matching with `=~`).

### set
Configure shell behaviour — most importantly the "safe mode" flags.

```bash
#!/bin/bash
set -euo pipefail
```

- `-e` exit immediately when any command fails
- `-u` error on unset variables (instead of silently expanding to empty)
- `-o pipefail` a pipeline fails if *any* command in it fails, not just the last
- `-x` print each command before running it (debug trace)

`set -euo pipefail` at the top of a script stops it from continuing past a failed `cd` or using an unset variable — the standard Bash "strict mode".

### export
Mark a variable as inherited by child processes. Plain variables stay local to the shell.

```bash
export EDITOR=vim
export PATH="$HOME/.local/bin:$PATH"
```

### source
Execute a file's commands **in the current shell** (rather than a child process) — how config files and libraries apply their variables/functions to your shell.

```bash
source ~/.bashrc
source ./lib/helpers.sh
. ./config.env    # `.` is the POSIX synonym
```

Also the standard way to load environment files (`source venv/bin/activate` in Python).

---

⬅️ Back to [Packages](package-management.md) | Next: [Security](security.md) ➡️