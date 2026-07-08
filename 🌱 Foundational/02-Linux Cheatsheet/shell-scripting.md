[🏠 Home](README.md) | [Navigation](navigation.md) | [Filesystem](filesystem.md) | [Permissions](file-permissions.md) | [Processes](processes.md) | [Networking](networking.md) | [Users & Groups](users-groups.md) | [Storage](storage.md) | [Packages](package-management.md) | [Security](security.md)

# 📜 Shell Scripting Essentials

Core Bash scripting concepts and the text-processing commands (`grep`, `sed`, `awk`, and friends) every script relies on.

## Table of Contents
1. [Shebang & Script Basics](#shebang--script-basics) 2. [Variables](#variables) 3. [Conditionals (if)](#conditionals-if) 4. [Loops (for/while)](#loops-forwhile) 5. [Functions](#functions) 6. [grep](#grep) 7. [sed](#sed) 8. [awk](#awk) 9. [cut](#cut) 10. [sort](#sort) 11. [uniq](#uniq) 12. [tr](#tr) 13. [xargs](#xargs) 14. [echo](#echo) 15. [printf](#printf) 16. [read](#read) 17. [test / [ ]](#test---) 18. [set](#set) 19. [export](#export) 20. [source](#source)

---

# Shebang & Script Basics
## Purpose
Establish the fundamental structure of an executable Bash script.
## Syntax
```bash
#!/bin/bash
# This is a comment
echo "Hello, World!"
```
## Example
```bash
cat > hello.sh << 'EOF'
#!/bin/bash
echo "Hello, $USER!"
EOF
chmod +x hello.sh
./hello.sh
```
## Expected Output
```
Hello, kapilesh!
```
## Explanation
The **shebang** (`#!/bin/bash`) on line 1 tells the kernel which interpreter to use when the file is executed directly. Without execute permission (`chmod +x`) and a correct shebang, `./script.sh` will fail even if the script logic is perfect.
## Tips
- Use `#!/usr/bin/env bash` instead of a hardcoded `#!/bin/bash` path for slightly better portability across systems where Bash may live in a different location.
- Always run scripts with `bash script.sh` while developing if you're unsure about execute permissions, to isolate permission issues from logic issues.
## Common Mistakes
- Forgetting `chmod +x` and getting a "Permission denied" error when trying to run `./script.sh`.
- Saving a script with Windows-style line endings (`\r\n`) which breaks the shebang line interpretation, causing a confusing "bad interpreter" error.
## Related Commands
[chmod](file-permissions.md#chmod)

---

# Variables
## Purpose
Store and reuse values within a script.
## Syntax
```bash
VAR_NAME="value"
echo "$VAR_NAME"
```
## Example
```bash
NAME="Kapilesh"
COUNT=5
echo "User: $NAME, Count: $COUNT"
echo "Today: $(date +%F)"
```
## Expected Output
```
User: Kapilesh, Count: 5
Today: 2026-07-08
```
## Explanation
Bash variables are **untyped strings** by default (even numbers are stored as text unless used in an arithmetic context). `$(...)` is **command substitution** — it runs a command and inserts its output as a string.
## Tips
- Always double-quote variable expansions (`"$VAR"` not `$VAR`) to prevent word-splitting and glob expansion issues, especially with filenames containing spaces.
- Use `${VAR}` (braces) when the variable name could be ambiguous next to other text, e.g., `"${NAME}_backup.txt"`.
## Common Mistakes
- **Leaving variables unquoted** is the single most common source of subtle Bash bugs — `rm $FILE` can break catastrophically if `$FILE` contains spaces or is empty (potentially expanding to unintended arguments).
- No spaces around `=` when assigning (`VAR = "value"` is a syntax error; it must be `VAR="value"`).
## Related Commands
[export](#export), [read](#read)

---

# Conditionals (if)
## Purpose
Execute code branches based on whether a condition is true or false.
## Syntax
```bash
if [ CONDITION ]; then
    # commands
elif [ OTHER_CONDITION ]; then
    # commands
else
    # commands
fi
```
## Example
```bash
#!/bin/bash
if [ -f "/etc/passwd" ]; then
    echo "File exists."
elif [ -d "/etc" ]; then
    echo "Directory exists but file doesn't."
else
    echo "Neither found."
fi
```
## Expected Output
```
File exists.
```
## Explanation
`[ ]` is actually a command (an alias for `test`), and the spaces around the brackets are syntactically required. Common test operators: `-f` (file exists), `-d` (directory exists), `-z` (string is empty), `-eq`/`-ne` (numeric equal/not-equal), `==`/`!=` (string equal/not-equal).
## Tips
- Prefer `[[ ]]` (double brackets, a Bash-specific extension) over `[ ]` for more forgiving syntax, especially with pattern matching and logical operators (`&&`, `||`) inside the test.
## Common Mistakes
- Forgetting the required spaces: `if [ -f "$FILE" ]` (correct) vs `if [-f "$FILE"]` (syntax error — no space after `[`).
- Using `=` for numeric comparison instead of `-eq`, or vice versa for strings — Bash's comparison operators differ for strings vs. numbers.
## Related Commands
[test / [ ]](#test---)

---

# Loops (for/while)
## Purpose
Repeat a block of commands over a list of items or while a condition remains true.
## Syntax
```bash
for VAR in LIST; do
    # commands
done

while [ CONDITION ]; do
    # commands
done
```
## Example
```bash
#!/bin/bash
for file in *.log; do
    echo "Processing: $file"
done

count=0
while [ $count -lt 5 ]; do
    echo "Count: $count"
    count=$((count + 1))
done
```
## Expected Output
```
Processing: access.log
Processing: error.log
Count: 0
Count: 1
Count: 2
Count: 3
Count: 4
```
## Explanation
`for` loops in Bash iterate over a **list of words** (from a glob pattern, a fixed list, or command output), not a numeric range like in many other languages — `for i in {1..10}` is the idiomatic way to get numeric range iteration.
## Tips
- Use `for i in {1..10}` for simple numeric ranges, or a C-style `for (( i=0; i<10; i++ ))` loop when you need more complex increment logic.
- `$((expression))` is Bash's arithmetic expansion syntax, used for integer math like `count=$((count + 1))`.
## Common Mistakes
- Looping over `ls` output directly (`for f in $(ls)`) instead of using globs (`for f in *`) — this breaks on filenames containing spaces or special characters; globbing is the safer idiom.
## Related Commands
[Conditionals (if)](#conditionals-if)

---

# Functions
## Purpose
Group reusable blocks of script logic under a name, callable with arguments.
## Syntax
```bash
function_name() {
    # commands
    # $1, $2, ... are positional arguments
}
```
## Example
```bash
#!/bin/bash
greet() {
    local name="$1"
    echo "Hello, $name!"
}

greet "Kapilesh"
```
## Expected Output
```
Hello, Kapilesh!
```
## Explanation
Bash functions receive arguments the same way scripts receive command-line arguments (`$1`, `$2`, `$@` for all, `$#` for count) — there's no separate parameter-declaration syntax like in most programming languages.
## Tips
- Always use `local` for variables inside functions unless you specifically intend them to be global — without `local`, function-scoped variables leak into the calling script's namespace.
## Common Mistakes
- Forgetting `local`, causing a variable name collision between a function's internal logic and the main script's variables — a classic source of hard-to-debug scripts.
- Defining a function *after* it's called in the script — Bash reads top-to-bottom, so functions must be defined before their first invocation.
## Related Commands
[Variables](#variables)

---

# grep
## Purpose
Search text for lines matching a pattern (the single most-used text-processing command in Linux).
## Syntax
```
grep [OPTIONS] PATTERN [FILE]
```
## Common Options
| Option | Description |
|---|---|
| `-i` | Case-insensitive search |
| `-r` / `-R` | Recursive search through directories |
| `-v` | Invert match — show lines that do NOT match |
| `-n` | Show line numbers |
| `-c` | Count matching lines instead of printing them |
| `-E` | Extended regex support (or use `egrep`) |
| `-w` | Match whole words only |

## Example
```bash
grep -rn "TODO" ./src
grep -i "error" app.log | wc -l
```
## Expected Output
```
./src/main.py:42:# TODO: refactor this function
./src/utils.py:8:# TODO: add input validation
```
## Explanation
`grep` (Global Regular Expression Print) is built on regular expressions, from simple literal text matches up to full pattern matching with `-E` (extended regex) or `-P` (Perl-compatible regex, if available).
## Tips
- `grep -rn "pattern" .` is one of the most common commands typed by developers/admins daily — searching an entire codebase for a term.
- Combine with pipelines constantly: `ps aux | grep nginx`, `history | grep ssh`.
## Common Mistakes
- Forgetting to quote patterns containing shell special characters (`$`, `*`, `[`), which the shell may try to expand before `grep` ever sees them.
- Using basic `grep` when a pattern needs extended regex features (like `+`, `|`, `{}`) without the `-E` flag, causing the pattern to be interpreted literally instead.
## Related Commands
[sed](#sed), [awk](#awk), [find](navigation.md#find)

---

# sed
## Purpose
Stream editor — perform find-and-replace and other text transformations on a stream or file, line by line.
## Syntax
```
sed [OPTIONS] 'SCRIPT' FILE
```
## Common Usage
| Pattern | Description |
|---|---|
| `s/old/new/` | Substitute the first occurrence per line |
| `s/old/new/g` | Substitute all occurrences per line (global) |
| `-i` | Edit the file in-place |
| `-n '2p'` | Print only line 2 |
| `/pattern/d` | Delete lines matching a pattern |

## Example
```bash
sed 's/http:/https:/g' urls.txt
sed -i 's/DEBUG=False/DEBUG=True/' settings.py
```
## Expected Output
```
https://example.com
https://api.example.com
```
## Explanation
`sed` processes input **line by line**, applying the given script to each line — the classic `s/pattern/replacement/flags` substitution syntax is the most common use case by far.
## Tips
- Always test destructive in-place edits (`-i`) on a copy first, or use `-i.bak` to automatically create a backup (`sed -i.bak 's/a/b/' file` creates `file.bak` before editing).
## Common Mistakes
- Using `-i` directly on important files without a backup — an incorrect regex can silently corrupt the file with no easy undo.
- Forgetting the trailing `g` flag and being confused why only the *first* match per line was replaced.
## Related Commands
[grep](#grep), [awk](#awk)

---

# awk
## Purpose
A full pattern-scanning and text-processing language, especially powerful for column/field-based data extraction and reporting.
## Syntax
```
awk 'PATTERN { ACTION }' FILE
```
## Common Usage
| Pattern | Description |
|---|---|
| `'{print $1}'` | Print the first whitespace-separated field of every line |
| `-F","` | Set a custom field separator (e.g., for CSV) |
| `'{sum += $2} END {print sum}'` | Accumulate and print a total |
| `'NR==2'` | Match only line number 2 |

## Example
```bash
ps aux | awk '{print $2, $11}'
awk -F',' '{print $1}' data.csv
```
## Expected Output
```
PID   COMMAND
1042  nginx: master process
```
## Explanation
`awk` automatically splits each input line into fields (`$1`, `$2`, ... `$NF` for the last field), making it far more convenient than `grep`/`sed` for extracting or computing over structured/tabular text like log files, `ps` output, or CSVs.
## Tips
- `awk '{print $NF}'` prints the *last* field of each line, regardless of how many fields exist — extremely useful for inconsistent-width data.
- Combine `BEGIN`/`END` blocks for setup and summary logic: `awk 'BEGIN{print "Start"} {total+=$1} END{print "Total:", total}'`.
## Common Mistakes
- Assuming `awk`'s default field separator (whitespace) applies to comma-separated files — always set `-F','` explicitly for CSVs.
## Related Commands
[grep](#grep), [sed](#sed), [cut](#cut)

---

# cut
## Purpose
Extract specific columns/fields from each line of text based on delimiter or fixed character position.
## Syntax
```
cut [OPTIONS] FILE
```
## Common Options
| Option | Description |
|---|---|
| `-d DELIM` | Set the field delimiter |
| `-f N` | Select field number N |
| `-c N` | Select character position N |

## Example
```bash
cut -d':' -f1 /etc/passwd
```
## Expected Output
```
root
daemon
kapilesh
```
## Explanation
A simpler, lighter-weight alternative to `awk` when you just need to extract one or two fixed columns without any computation or pattern logic.
## Tips
- For simple single-column extraction, `cut` is more readable in scripts than a full `awk` command; reach for `awk` once you need more than basic field selection.
## Common Mistakes
- Forgetting `-d` when the delimiter isn't the default tab character, resulting in `cut` treating the entire line as one field.
## Related Commands
[awk](#awk)

---

# sort
## Purpose
Sort lines of text alphabetically, numerically, or by a specific field.
## Syntax
```
sort [OPTIONS] FILE
```
## Common Options
| Option | Description |
|---|---|
| `-n` | Numeric sort (not lexicographic) |
| `-r` | Reverse order |
| `-k N` | Sort by field N |
| `-u` | Remove duplicate lines while sorting |
| `-h` | Human-readable numeric sort (handles "1K", "2M" suffixes) |

## Example
```bash
du -sh * | sort -rh | head -5
sort -n scores.txt
```
## Expected Output
```
1.2G	logs
850M	cache
120M	backups
```
## Explanation
Without `-n`, `sort` treats numbers as text (so "10" sorts before "2" lexicographically) — this is a very common beginner surprise. `-h` correctly understands human-readable size suffixes from tools like `du -h`.
## Tips
- `sort -rh` (reverse, human-readable) paired with `du -sh` is a go-to combo for finding the largest disk consumers at a glance.
## Common Mistakes
- Forgetting `-n` when sorting numeric data and getting a lexicographic (string) order instead — "10" appearing before "2" is the classic symptom.
## Related Commands
[uniq](#uniq)

---

# uniq
## Purpose
Remove or count duplicate adjacent lines in sorted text.
## Syntax
```
uniq [OPTIONS] FILE
```
## Common Options
| Option | Description |
|---|---|
| `-c` | Prefix each line with its occurrence count |
| `-d` | Show only lines that appear more than once |
| `-u` | Show only lines that appear exactly once |

## Example
```bash
sort access.log | awk '{print $1}' | uniq -c | sort -rn | head
```
## Expected Output
```
    142 203.0.113.5
     87 198.51.100.7
     12 192.0.2.14
```
## Explanation
`uniq` only removes duplicates that are **adjacent** — this is why it's almost always used right after `sort`, which groups identical lines together first. This exact pipeline (extract a field, sort, count uniques, sort by count) is one of the most common log-analysis patterns in Linux.
## Tips
- Memorize the pattern `sort | uniq -c | sort -rn` — "find and rank the most frequent values" — it applies to log analysis, security auditing, and general data exploration constantly.
## Common Mistakes
- Running `uniq` on unsorted input and being confused why duplicates still appear — it only catches consecutive duplicates, not duplicates scattered throughout the file.
## Related Commands
[sort](#sort)

---

# tr
## Purpose
Translate or delete individual characters from input (character-level, not line-level, transformation).
## Syntax
```
tr [OPTIONS] SET1 [SET2]
```
## Common Options
| Option | Description |
|---|---|
| `-d` | Delete characters in SET1 |
| `-s` | Squeeze repeated consecutive characters into one |

## Example
```bash
echo "Hello World" | tr 'a-z' 'A-Z'
echo "line1\nline2" | tr -d '\n'
```
## Expected Output
```
HELLO WORLD
```
## Explanation
`tr` operates purely on character sets/ranges — it has no concept of "words" or "patterns" like `sed`/`grep`, making it fast and simple for basic transformations like case conversion or stripping specific characters.
## Tips
- `tr -s ' '` (squeeze) is handy for collapsing multiple consecutive spaces into one, cleaning up inconsistently formatted text.
## Common Mistakes
- Trying to use `tr` for multi-character string replacement (like `sed`'s `s/old/new/`) — `tr` only maps individual characters, not substrings.
## Related Commands
[sed](#sed)

---

# xargs
## Purpose
Build and execute command lines from standard input — turns a list of items into arguments for another command.
## Syntax
```
COMMAND | xargs [OPTIONS] TARGET_COMMAND
```
## Common Options
| Option | Description |
|---|---|
| `-n N` | Pass N arguments per invocation of the target command |
| `-I {}` | Define a placeholder for substitution in the command |
| `-p` | Prompt for confirmation before each execution |
| `-0` | Read null-separated input (pairs with `find -print0`) |

## Example
```bash
find . -name "*.tmp" -print0 | xargs -0 rm -v
echo "file1.txt file2.txt" | xargs -n1 wc -l
```
## Expected Output
```
removed 'cache.tmp'
removed 'session.tmp'
```
## Explanation
Many commands (like `rm`, `grep`) accept arguments directly but not piped input — `xargs` bridges this gap, converting piped lines into command-line arguments for tools that expect them that way.
## Tips
- Combine `find -print0` with `xargs -0` when filenames might contain spaces or newlines — this null-delimiter pairing avoids the word-splitting issues that plain `find | xargs` can suffer from.
## Common Mistakes
- Piping `find` results directly to `xargs` (without `-print0`/`-0`) when filenames contain spaces, causing a single filename to be incorrectly split into multiple arguments.
## Related Commands
[find](navigation.md#find)

---

# echo
## Purpose
Print text or variable values to standard output.
## Syntax
```
echo [OPTIONS] TEXT
```
## Common Options
| Option | Description |
|---|---|
| `-n` | Suppress the trailing newline |
| `-e` | Enable interpretation of backslash escapes (`\n`, `\t`) |

## Example
```bash
echo "Deployment complete."
echo -e "Line1\nLine2"
```
## Expected Output
```
Deployment complete.
Line1
Line2
```
## Explanation
`echo` is a shell builtin (fast, no separate process spawned) used constantly for debugging output, script status messages, and constructing strings.
## Tips
- Use `printf` instead of `echo` when output formatting needs to be precise and portable across shells — `echo`'s exact behavior around flags/escapes varies slightly between shells.
## Common Mistakes
- Assuming `-e` escape interpretation is always on by default — behavior differs across shells/systems, causing inconsistent script output.
## Related Commands
[printf](#printf)

---

# printf
## Purpose
Print formatted output with precise control over formatting, similar to C's `printf`.
## Syntax
```
printf "FORMAT" ARGUMENTS
```
## Common Format Specifiers
| Specifier | Description |
|---|---|
| `%s` | String |
| `%d` | Integer |
| `%.2f` | Floating point, 2 decimal places |
| `\n` | Newline (always interpreted, unlike plain `echo`) |

## Example
```bash
printf "Name: %s, Score: %.1f%%\n" "Kapilesh" 87.456
```
## Expected Output
```
Name: Kapilesh, Score: 87.5%
```
## Explanation
Unlike `echo`, `printf` behavior is consistent and predictable across shells/systems, and it requires an explicit `\n` for line breaks (no implicit trailing newline), giving finer control.
## Tips
- Prefer `printf` over `echo` in scripts intended to be portable or where exact output formatting matters (e.g., generating reports, tables, or padded columns).
## Common Mistakes
- Forgetting the format string's `%` needs escaping as `%%` to print a literal percent sign, since `%` is otherwise a format specifier prefix.
## Related Commands
[echo](#echo)

---

# read
## Purpose
Read a line of input from standard input (keyboard or a pipe) into a variable.
## Syntax
```
read [OPTIONS] VAR_NAME
```
## Common Options
| Option | Description |
|---|---|
| `-p PROMPT` | Display a prompt before reading |
| `-s` | Silent mode — don't echo input (useful for passwords) |
| `-a ARRAY` | Read into an array, splitting on whitespace |

## Example
```bash
read -p "Enter your name: " name
echo "Hello, $name!"

read -sp "Password: " pw
echo
```
## Expected Output
```
Enter your name: Kapilesh
Hello, Kapilesh!
```
## Explanation
`read` is the standard way to make interactive Bash scripts, and is also frequently used inside `while read line; do ...; done < file` loops to process a file line by line.
## Tips
- `while IFS= read -r line; do ... done < file` is the most robust idiom for reading a file line-by-line, correctly preserving leading/trailing whitespace and backslashes.
## Common Mistakes
- Using `for line in $(cat file)` instead of `while read`, which incorrectly splits on all whitespace (not just newlines) and mangles lines with spaces.
## Related Commands
[Variables](#variables)

---

# test / [ ]
## Purpose
Evaluate a conditional expression, returning a true/false exit status — the mechanism underlying every `if` statement.
## Syntax
```
test EXPRESSION
[ EXPRESSION ]
```
## Common Test Operators
| Operator | Description |
|---|---|
| `-f FILE` | True if FILE exists and is a regular file |
| `-d FILE` | True if FILE exists and is a directory |
| `-z STRING` | True if STRING is empty |
| `-n STRING` | True if STRING is not empty |
| `STR1 == STR2` | String equality |
| `NUM1 -eq NUM2` | Numeric equality |

## Example
```bash
if [ -z "$1" ]; then
    echo "No argument provided."
    exit 1
fi
```
## Expected Output
```
No argument provided.
```
## Explanation
`test` and `[ ]` are exactly equivalent — `[` is literally a command (or shell builtin) that requires a matching `]` as its final argument, which is why the spacing around brackets is mandatory syntax, not just style.
## Tips
- `[[ ]]` (Bash-specific double brackets) is generally safer/more forgiving than single `[ ]`, particularly for pattern matching and avoiding word-splitting pitfalls with unquoted variables.
## Common Mistakes
- Missing spaces around brackets or the expression (`[$VAR == "x"]` instead of `[ "$VAR" == "x" ]`), causing a syntax error.
## Related Commands
[Conditionals (if)](#conditionals-if)

---

# set
## Purpose
Configure shell options that change script execution behavior — most notably for safer, more predictable error handling.
## Syntax
```
set [OPTIONS]
```
## Common Options
| Option | Description |
|---|---|
| `-e` | Exit immediately if any command fails (non-zero exit code) |
| `-u` | Treat unset variables as an error instead of silently expanding to empty |
| `-x` | Print each command before executing it (debugging trace) |
| `-o pipefail` | Make a pipeline fail if ANY command in it fails, not just the last one |

## Example
```bash
#!/bin/bash
set -euo pipefail

echo "Starting deployment..."
cd /nonexistent-directory
echo "This line will never run because 'cd' failed."
```
## Expected Output
```
Starting deployment...
script.sh: line 4: cd: /nonexistent-directory: No such file or directory
```
## Explanation
By default, Bash scripts continue executing even after a command fails, silently masking errors. `set -euo pipefail` is a widely recommended "strict mode" pattern that makes scripts fail fast and loud instead of continuing in a broken state.
## Tips
- Start production/automation scripts with `set -euo pipefail` as a defensive default — it catches an entire category of silent failure bugs.
## Common Mistakes
- Not using `-o pipefail` and being confused why a script "succeeded" (exit code 0) even though an earlier command in a pipeline actually failed — without it, only the *last* command's exit code determines pipeline success.
## Related Commands
[Conditionals (if)](#conditionals-if)

---

# export
## Purpose
Mark a variable as an **environment variable**, making it visible to child processes spawned from the current shell.
## Syntax
```
export VAR_NAME=value
```
## Example
```bash
export API_KEY="abc123"
python3 my_script.py   # can access API_KEY via os.environ
```
## Explanation
Regular shell variables exist only within the current shell — `export` promotes a variable into the environment block that gets copied to every child process (scripts, programs) launched from that shell.
## Tips
- Use `printenv` or `env` to view all currently exported environment variables in a session.
- Environment variable changes are **not** persistent across sessions unless added to a shell startup file (`~/.bashrc`, `~/.profile`).
## Common Mistakes
- Setting a variable without `export` and being confused why a called script/program can't see it — plain assignment (`VAR=value`) stays local to the current shell only.
## Related Commands
[Variables](#variables)

---

# source
## Purpose
Execute a script's commands within the **current** shell session, rather than spawning a new subshell (as running `./script.sh` would).
## Syntax
```
source FILENAME
. FILENAME
```
## Example
```bash
source ~/.bashrc
source venv/bin/activate
```
## Explanation
Because `source` runs in the current shell, any variables, functions, or directory changes (`cd`) the script performs *persist* after it finishes — this is precisely why Python virtual environment activation requires `source` (it needs to modify your current shell's `$PATH` and environment).
## Tips
- The dot (`.`) is a POSIX-standard shorthand for `source` and works identically in most shells.
## Common Mistakes
- Running a script with `./script.sh` when it's meant to modify your current shell's environment (like activating a virtualenv) — this launches a subshell whose environment changes are discarded once it exits, silently failing to have the intended effect.
## Related Commands
[export](#export)

---

⬅️ Back to [package-management.md](package-management.md) | Next: [security.md](security.md) ➡️
