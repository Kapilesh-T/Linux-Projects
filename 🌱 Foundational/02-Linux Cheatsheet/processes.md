[🏠 Home](README.md) | [Navigation](navigation.md) | [Filesystem](filesystem.md) | [Permissions](file-permissions.md) | [Networking](networking.md) | [Users & Groups](users-groups.md) | [Storage](storage.md) | [Packages](package-management.md) | [Shell Scripting](shell-scripting.md) | [Security](security.md)

# ⚙️ Process & Service Management

Commands for viewing, monitoring, controlling, and scheduling processes, jobs, and system services.

## Table of Contents
1. [ps](#ps) 2. [top](#top) 3. [htop](#htop) 4. [kill](#kill) 5. [killall](#killall) 6. [pkill](#pkill) 7. [pgrep](#pgrep) 8. [nice](#nice) 9. [renice](#renice) 10. [jobs](#jobs) 11. [bg](#bg) 12. [fg](#fg) 13. [nohup](#nohup) 14. [disown](#disown) 15. [systemctl](#systemctl) 16. [journalctl](#journalctl) 17. [service](#service) 18. [uptime](#uptime) 19. [free](#free) 20. [vmstat](#vmstat) 21. [lsof](#lsof) 22. [crontab](#crontab) 23. [at](#at) 24. [watch](#watch) 25. [pstree](#pstree) 26. [strace](#strace)

---

# ps
## Purpose
Report a snapshot of currently running processes.
## Syntax
```
ps [OPTIONS]
```
## Common Options
| Option | Description |
|---|---|
| `aux` | Show all processes for all users, BSD-style, with detailed columns |
| `-ef` | Show all processes, full-format, UNIX-style |
| `--forest` | Display as a process tree showing parent/child relationships |

## Example
```bash
ps aux | grep nginx
```
## Expected Output
```
USER   PID  %CPU %MEM    VSZ   RSS TTY   STAT START   TIME COMMAND
root   1042  0.0  0.3  55000  4200 ?     Ss   09:01   0:00 nginx: master process
www-d  1043  0.0  0.2  55200  3100 ?     S    09:01   0:00 nginx: worker process
```
## Explanation
`ps` takes a one-time snapshot (unlike `top`, which updates live). Key columns: **PID** (process ID), **%CPU**/**%MEM** (resource usage), **STAT** (process state — `S`=sleeping, `R`=running, `Z`=zombie, `T`=stopped), **TIME** (total CPU time consumed).
## Tips
- `ps aux --sort=-%mem | head` quickly finds the top memory-consuming processes.
- `ps -ef --forest` is excellent for understanding which process spawned which.
## Common Mistakes
- Confusing `%CPU`/`%MEM` (a snapshot at that instant) with sustained/average usage — for real trends, use `top` or monitoring tools over time.
## Related Commands
[top](#top), [pgrep](#pgrep), [kill](#kill)

---

# top
## Purpose
Display a real-time, continuously updating view of running processes and system resource usage.
## Syntax
```
top
```
## Common Interactive Keys
| Key | Action |
|---|---|
| `P` | Sort by CPU usage |
| `M` | Sort by memory usage |
| `k` | Kill a process (prompts for PID) |
| `q` | Quit |

## Example
```bash
top
```
## Expected Output
```
top - 10:22:01 up 3 days,  2:14,  1 user,  load average: 0.42, 0.38, 0.35
Tasks: 178 total,   1 running, 177 sleeping
%Cpu(s):  3.2 us,  1.1 sy,  0.0 ni, 95.4 id
MiB Mem :   7942.0 total,   2103.4 free
```
## Explanation
The **load average** (three numbers: 1, 5, and 15-minute averages) represents the average number of processes waiting for CPU time — a value equal to your CPU core count generally means the system is fully utilized but not overloaded.
## Tips
- Press `1` inside `top` to toggle a per-core CPU usage breakdown instead of the aggregate.
## Common Mistakes
- Misreading load average without knowing the core count — a load of 4.0 is fine on an 8-core machine but a serious bottleneck on a 2-core machine.
## Related Commands
[htop](#htop), [ps](#ps), [vmstat](#vmstat)

---

# htop
## Purpose
An enhanced, interactive, color-coded alternative to `top` with easier navigation and visualization.
## Syntax
```
htop
```
## Common Interactive Keys
| Key | Action |
|---|---|
| `F6` | Change sort column |
| `F9` | Kill selected process |
| `Space` | Tag/select a process |
| `F5` | Toggle tree view |

## Example
```bash
htop
```
## Explanation
`htop` is not installed by default on most distros (`sudo apt install htop`) but is widely preferred for its mouse support, colored per-core meters, and easier process searching/killing compared to `top`.
## Tips
- Use `F4` to filter/search processes by name interactively.
## Common Mistakes
- Assuming `htop` is always available on minimal/server installations — it must be installed separately.
## Related Commands
[top](#top), [ps](#ps)

---

# kill
## Purpose
Send a signal to a process, most commonly to terminate it.
## Syntax
```
kill [-SIGNAL] PID
```
## Common Signals
| Signal | Number | Description |
|---|---|---|
| `SIGTERM` | 15 (default) | Politely ask the process to terminate, allowing cleanup |
| `SIGKILL` | 9 | Force-kill immediately, no cleanup, cannot be caught or ignored |
| `SIGHUP` | 1 | Hang up — often used to tell a daemon to reload its config |
| `SIGSTOP` | 19 | Pause the process |
| `SIGCONT` | 18 | Resume a paused process |

## Example
```bash
kill 4521
kill -9 4521
kill -HUP 4521
```
## Expected Output
```
(no output on success)
```
## Explanation
`kill` doesn't necessarily "kill" — it sends a signal, and the default (`SIGTERM`) is a *request* the process can intercept to shut down gracefully (closing files, saving state). `SIGKILL` bypasses this entirely at the kernel level.
## Tips
- Always try plain `kill PID` (SIGTERM) first, and only escalate to `kill -9` if the process doesn't respond after a few seconds — this avoids data corruption from abrupt termination.
## Common Mistakes
- Reaching for `kill -9` by default — this skips cleanup handlers and can leave temp files, locks, or database states corrupted.
## Related Commands
[killall](#killall), [pkill](#pkill)

---

# killall
## Purpose
Kill all processes matching a given process **name** (rather than a PID).
## Syntax
```
killall [-SIGNAL] PROCESS_NAME
```
## Example
```bash
killall firefox
killall -9 chrome
```
## Explanation
Useful when multiple instances of the same program are running and you want to terminate all of them without hunting down individual PIDs.
## Tips
- Use `killall -i` for interactive confirmation before each kill, reducing the risk of an unintended match.
## Common Mistakes
- Using a name that partially matches unrelated processes on some systems/tools (depends on exact-match behavior) — always double check with `ps aux | grep NAME` first.
## Related Commands
[kill](#kill), [pkill](#pkill)

---

# pkill
## Purpose
Kill processes matching a name or other attribute pattern (more flexible matching than `killall`).
## Syntax
```
pkill [OPTIONS] PATTERN
```
## Common Options
| Option | Description |
|---|---|
| `-u USER` | Only match processes owned by a specific user |
| `-f` | Match against the full command line, not just process name |

## Example
```bash
pkill -u kapilesh -f "python manage.py runserver"
```
## Explanation
`pkill` and its companion `pgrep` use the same underlying pattern-matching engine, making them a matched pair for "find" (`pgrep`) and "act" (`pkill`) workflows.
## Tips
- Run the equivalent `pgrep` command first to preview exactly which processes would be affected before running `pkill`.
## Common Mistakes
- Using a pattern too broad (like `pkill python`) that matches unrelated Python processes you didn't intend to kill.
## Related Commands
[pgrep](#pgrep), [kill](#kill)

---

# pgrep
## Purpose
Search for processes matching a name or attribute and print their PIDs.
## Syntax
```
pgrep [OPTIONS] PATTERN
```
## Common Options
| Option | Description |
|---|---|
| `-l` | Also print the process name alongside the PID |
| `-u USER` | Filter by owning user |
| `-a` | Show the full command line |

## Example
```bash
pgrep -la nginx
```
## Expected Output
```
1042 nginx: master process
1043 nginx: worker process
```
## Explanation
A read-only, script-friendly companion to `ps | grep`, but far more reliable since it avoids `ps`'s output-parsing pitfalls (e.g., `grep`'s own process matching itself).
## Tips
- Use `pgrep` output directly in scripts: `if pgrep -x nginx > /dev/null; then echo "running"; fi`.
## Common Mistakes
- Using `ps aux | grep processname` and forgetting the `grep` command itself shows up as a match — `pgrep` avoids this entirely.
## Related Commands
[pkill](#pkill), [ps](#ps)

---

# nice
## Purpose
Start a new process with a specified CPU scheduling priority.
## Syntax
```
nice -n PRIORITY COMMAND
```
## Explanation
Priority ("niceness") ranges from **-20** (highest priority, least "nice" to other processes) to **19** (lowest priority, most "nice"). Regular users can only *increase* niceness (lower priority); only root can decrease it (raise priority).
## Example
```bash
nice -n 10 ./long_running_backup.sh
```
## Tips
- Use a high niceness value (e.g., `nice -n 15`) for long batch jobs (backups, video encoding) that shouldn't compete with interactive processes for CPU time.
## Common Mistakes
- Attempting `nice -n -10` as a regular user and getting a permission error — negative values require root.
## Related Commands
[renice](#renice), [top](#top)

---

# renice
## Purpose
Change the scheduling priority ("niceness") of an already-running process.
## Syntax
```
renice PRIORITY -p PID
```
## Example
```bash
renice 10 -p 4521
```
## Expected Output
```
4521 (process ID) old priority 0, new priority 10
```
## Explanation
Unlike `nice` (set priority at launch), `renice` adjusts a process that's already running — useful when you realize mid-execution that a job is hogging resources.
## Tips
- You can renice by process group (`-g`) or by user (`-u`) to adjust multiple processes at once.
## Common Mistakes
- Forgetting only root can *decrease* niceness (raise priority) of a process, including your own.
## Related Commands
[nice](#nice), [top](#top)

---

# jobs
## Purpose
List background and stopped jobs running in the current shell session.
## Syntax
```
jobs [OPTIONS]
```
## Common Options
| Option | Description |
|---|---|
| `-l` | Include PIDs in the output |

## Example
```bash
sleep 300 &
jobs -l
```
## Expected Output
```
[1]+  12045 Running                 sleep 300 &
```
## Explanation
Job control lets you manage multiple tasks within one terminal session — jobs are numbered `[1]`, `[2]`, etc., distinct from system-wide PIDs.
## Tips
- Reference a job by number in other commands: `kill %1`, `fg %2`.
## Common Mistakes
- Confusing job numbers (`%1`) with process IDs (`12045`) — they are different identifiers used in different contexts.
## Related Commands
[bg](#bg), [fg](#fg), [disown](#disown)

---

# bg
## Purpose
Resume a stopped job and continue running it in the background.
## Syntax
```
bg [%JOB_NUMBER]
```
## Example
```bash
# Press Ctrl+Z to stop a foreground job, then:
bg %1
```
## Explanation
Commonly used after accidentally suspending a foreground process with `Ctrl+Z` (which sends `SIGTSTP`) — `bg` resumes it without bringing it back to the foreground, freeing your terminal.
## Tips
- Combine with `disown` if you want the job to keep running even after you close the terminal.
## Common Mistakes
- Forgetting a `Ctrl+Z`'d process is only *paused*, not backgrounded, until you explicitly run `bg`.
## Related Commands
[fg](#fg), [jobs](#jobs)

---

# fg
## Purpose
Bring a background or stopped job back to the foreground.
## Syntax
```
fg [%JOB_NUMBER]
```
## Example
```bash
fg %1
```
## Explanation
Restores full terminal control (including keyboard input like `Ctrl+C`) to the selected job.
## Tips
- With only one background job, plain `fg` (no argument) brings it forward automatically.
## Common Mistakes
- Trying to `fg` a job number that has already finished, resulting in a "no such job" error.
## Related Commands
[bg](#bg), [jobs](#jobs)

---

# nohup
## Purpose
Run a command so it keeps running even after the terminal session that launched it closes (immune to `SIGHUP`).
## Syntax
```
nohup COMMAND &
```
## Example
```bash
nohup python3 long_task.py &
```
## Expected Output
```
nohup: ignoring input and appending output to 'nohup.out'
```
## Explanation
By default, closing a terminal sends `SIGHUP` (hangup) to all its child processes, terminating them. `nohup` makes the process ignore that signal, so it survives logout/disconnection — essential for long-running jobs over SSH.
## Tips
- For more robust long-running/production processes, prefer a proper process manager (`systemd` service, `tmux`/`screen` session, or `supervisord`) over `nohup`, which is best for quick one-off tasks.
## Common Mistakes
- Forgetting the trailing `&` to also background the process — `nohup` alone doesn't background it, it just changes signal handling.
## Related Commands
[disown](#disown), [systemctl](#systemctl)

---

# disown
## Purpose
Remove a job from the shell's active job table so it survives terminal closure, without needing to have started it with `nohup`.
## Syntax
```
disown [%JOB_NUMBER]
```
## Example
```bash
long_task.sh &
disown %1
```
## Explanation
Unlike `nohup` (which must be applied at launch time), `disown` can detach an already-running background job from the current shell retroactively.
## Tips
- Use `disown -a` to disown all current background jobs at once.
## Common Mistakes
- Assuming `disown` also protects against `SIGHUP` in every shell configuration — behavior can vary depending on `huponexit` shell settings; `nohup` is the more universally reliable option when launching a new process.
## Related Commands
[nohup](#nohup), [jobs](#jobs)

---

# systemctl
## Purpose
Control the `systemd` init system: start, stop, enable, disable, and inspect services (units).
## Syntax
```
systemctl [COMMAND] [SERVICE]
```
## Common Commands
| Command | Description |
|---|---|
| `start` | Start a service now |
| `stop` | Stop a running service |
| `restart` | Stop then start a service |
| `reload` | Reload config without restarting the process |
| `enable` | Start the service automatically at boot |
| `disable` | Remove a service from automatic boot startup |
| `status` | Show current state and recent log lines |
| `list-units --type=service` | List all currently loaded services |

## Example
```bash
sudo systemctl restart nginx
sudo systemctl enable nginx
systemctl status nginx
```
## Expected Output
```
● nginx.service - A high performance web server
     Loaded: loaded (/lib/systemd/system/nginx.service; enabled)
     Active: active (running) since Mon 2026-07-06 09:01:14 IST
```
## Explanation
`systemd` is the init system (PID 1) used by most modern distros (Ubuntu, Debian, Fedora, RHEL, Arch). `systemctl` is its primary control interface, replacing older `service`/`init.d` scripts on these systems.
## Tips
- `enable` only sets up autostart at boot — it does **not** start the service immediately; use `enable --now` to do both in one command.
- Always check `status` after any change to confirm success before assuming a config took effect.
## Common Mistakes
- Running `systemctl start` and forgetting `enable`, so the service doesn't survive the next reboot (or vice versa).
- Confusing `restart` (brief downtime, full process restart) with `reload` (no downtime, only re-reads config — but only supported by services designed for it).
## Related Commands
[journalctl](#journalctl), [service](#service)

---

# journalctl
## Purpose
Query and display logs collected by `systemd`'s journal logging system.
## Syntax
```
journalctl [OPTIONS]
```
## Common Options
| Option | Description |
|---|---|
| `-u SERVICE` | Show logs for a specific service/unit |
| `-f` | Follow logs live (like `tail -f`) |
| `-b` | Show logs only from the current boot |
| `-p err` | Filter by priority level (e.g., errors only) |
| `--since "1 hour ago"` | Time-based filtering |

## Example
```bash
journalctl -u nginx -f
journalctl --since "10 minutes ago" -p err
```
## Expected Output
```
Jul 06 10:15:02 server nginx[1042]: worker process started
```
## Explanation
`journalctl` reads from a structured binary log format (unlike traditional flat-text logs in `/var/log`), enabling powerful filtering by time, service, priority, and boot session in one unified tool.
## Tips
- `journalctl -xe` shows the most recent logs with extra explanatory context — often the first command to run right after a service fails to start.
## Common Mistakes
- Forgetting logs may be volatile (in-memory only, cleared on reboot) unless persistent journal storage is configured (`Storage=persistent` in `/etc/systemd/journald.conf`).
## Related Commands
[systemctl](#systemctl)

---

# service
## Purpose
Start, stop, or check the status of a service (a legacy interface, largely superseded by `systemctl` on `systemd` distros but still commonly available).
## Syntax
```
service SERVICE_NAME COMMAND
```
## Example
```bash
sudo service nginx restart
```
## Explanation
On modern `systemd`-based distros, `service` is typically a compatibility wrapper that forwards to `systemctl` under the hood, provided for muscle-memory/script compatibility with older SysVinit-based systems.
## Tips
- Prefer `systemctl` directly on modern systems, since it exposes far more functionality (enabling at boot, viewing detailed status, dependency management).
## Common Mistakes
- Using `service` on systems that still genuinely use SysVinit/Upstart (rare today, but present on some embedded or legacy systems) and expecting `systemctl`-style behavior that doesn't exist there.
## Related Commands
[systemctl](#systemctl)

---

# uptime
## Purpose
Show how long the system has been running, along with the current load average.
## Syntax
```
uptime
```
## Example
```bash
uptime
```
## Expected Output
```
 10:24:01 up 3 days,  2:16,  1 user,  load average: 0.15, 0.20, 0.18
```
## Explanation
A quick single-line health check combining boot duration and the same load average metric shown in `top`.
## Tips
- Use `uptime -p` for a human-readable "pretty" format: `up 3 days, 2 hours, 16 minutes`.
## Common Mistakes
- Reading load average in isolation without considering core count (see the `top` entry above for the correct interpretation).
## Related Commands
[top](#top), [w](#uptime)

---

# free
## Purpose
Display current memory (RAM) and swap usage.
## Syntax
```
free [OPTIONS]
```
## Common Options
| Option | Description |
|---|---|
| `-h` | Human-readable units (MB/GB) |
| `-s N` | Repeat the report every N seconds |

## Example
```bash
free -h
```
## Expected Output
```
               total        used        free      shared  buff/cache   available
Mem:            7.8Gi       2.1Gi       1.2Gi       210Mi       4.5Gi       5.3Gi
Swap:           2.0Gi          0B       2.0Gi
```
## Explanation
The **`available`** column (not `free`) is the most accurate indicator of usable memory — Linux aggressively uses "free" RAM for disk caching (`buff/cache`), which is automatically reclaimed when applications need it.
## Tips
- Don't panic seeing low "free" memory — check "available" instead; Linux's caching behavior is by design and improves performance.
## Common Mistakes
- Interpreting a small `free` value as "the system is almost out of memory" without checking `available`, which accounts for reclaimable cache.
## Related Commands
[top](#top), [vmstat](#vmstat)

---

# vmstat
## Purpose
Report virtual memory, process, CPU, and I/O statistics, useful for diagnosing performance bottlenecks.
## Syntax
```
vmstat [INTERVAL] [COUNT]
```
## Example
```bash
vmstat 2 5
```
## Expected Output
```
procs -----------memory---------- ---swap-- -----io---- -system-- ------cpu-----
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
 1  0      0 1245000  85000 4600000    0    0     2    15  120  200  3  1 95  1  0
```
## Explanation
Key columns: **r** (processes waiting for CPU), **b** (processes blocked on I/O), **wa** (percentage of CPU time waiting on I/O — high values suggest disk bottlenecks), **si/so** (swap in/out — any sustained non-zero value suggests memory pressure).
## Tips
- `vmstat 2 5` samples every 2 seconds, 5 times — much more informative than a single static snapshot for spotting trends.
## Common Mistakes
- Reading only the first line of `vmstat` output, which shows *averages since boot*, not current values — always look at subsequent lines for real-time data.
## Related Commands
[free](#free), [top](#top)

---

# lsof
## Purpose
List open files, including regular files, directories, network sockets, and devices — and which process has each one open.
## Syntax
```
lsof [OPTIONS]
```
## Common Options
| Option | Description |
|---|---|
| `-i :PORT` | Show which process is using a specific network port |
| `-u USER` | Filter by user |
| `-p PID` | Show files opened by a specific process |

## Example
```bash
sudo lsof -i :8080
```
## Expected Output
```
COMMAND   PID    USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
node    12045 kapilesh   22u  IPv6 123456      0t0  TCP *:8080 (LISTEN)
```
## Explanation
In Linux, "everything is a file" — including network sockets and devices — which is why `lsof` (list open files) doubles as a powerful network/port diagnostic tool, commonly used to answer "what process is using port 8080?"
## Tips
- `lsof -i :PORT` is the fastest way to identify and then `kill` a process blocking a port you need.
## Common Mistakes
- Running `lsof` without `sudo` and missing results for processes owned by other users or root.
## Related Commands
[ss](networking.md#ss), [netstat](networking.md#netstat)

---

# crontab
## Purpose
Schedule commands or scripts to run automatically at specified times/intervals.
## Syntax
```
crontab [OPTIONS]
```
## Common Options
| Option | Description |
|---|---|
| `-e` | Edit the current user's crontab |
| `-l` | List the current user's scheduled cron jobs |
| `-r` | Remove the current user's entire crontab |

## Example
```bash
crontab -e
```
Adding a line like:
```
0 2 * * * /home/kapilesh/scripts/backup.sh
```
## Explanation
The cron time format is five fields: `minute hour day-of-month month day-of-week`. The example above runs at 2:00 AM every day. `*` means "every" value for that field.
## Tips
- Use [crontab.guru](https://crontab.guru) style mental models: `* * * * *` = minute, hour, day, month, weekday — always in that order.
- Always use absolute paths inside cron scripts, since cron runs with a minimal environment (no interactive shell `$PATH`).
## Common Mistakes
- Writing a script that works fine manually but fails under cron — almost always caused by relying on environment variables or relative paths that don't exist in cron's minimal execution environment.
## Related Commands
[at](#at), [systemctl](#systemctl) (systemd timers are a modern alternative)

---

# at
## Purpose
Schedule a one-time command to run at a specific future time (unlike `crontab`, which is for recurring schedules).
## Syntax
```
at TIME
```
## Example
```bash
at 22:00
at> /home/kapilesh/scripts/shutdown_check.sh
at> Ctrl+D
```
## Expected Output
```
job 3 at Mon Jul  6 22:00:00 2026
```
## Explanation
Useful for one-off delayed tasks ("remind me" or "run this once tonight") without the overhead of setting up and later removing a cron entry.
## Tips
- Use `atq` to list pending `at` jobs, and `atrm JOBNUMBER` to cancel one.
## Common Mistakes
- Not installed by default on all minimal distros — install via the `at` package if the command is missing.
## Related Commands
[crontab](#crontab)

---

# watch
## Purpose
Repeatedly run a command at a fixed interval and display its output, refreshing the screen each time.
## Syntax
```
watch [OPTIONS] COMMAND
```
## Common Options
| Option | Description |
|---|---|
| `-n SECONDS` | Set the refresh interval (default 2 seconds) |
| `-d` | Highlight the differences between successive updates |

## Example
```bash
watch -n 1 -d "df -h"
```
## Explanation
Effectively turns any static command into a live-updating dashboard — commonly used to monitor disk space, process counts, or log line counts in real time without manually re-running the command.
## Tips
- The `-d` diff-highlighting flag makes it easy to spot exactly what changed between refreshes.
## Common Mistakes
- Forgetting to quote complex commands with pipes, which can cause `watch` to interpret only part of the command.
## Related Commands
[top](#top)

---

# pstree
## Purpose
Display running processes as a visual tree, showing parent-child relationships.
## Syntax
```
pstree [OPTIONS] [PID or USER]
```
## Common Options
| Option | Description |
|---|---|
| `-p` | Show PIDs alongside process names |
| `-u` | Show the user that owns each process |

## Example
```bash
pstree -p kapilesh
```
## Expected Output
```
bash(1200)───python3(4521)───┬─{python3}(4522)
                              └─{python3}(4523)
```
## Explanation
Much easier to read than `ps --forest` for quickly understanding which process spawned which, especially useful when debugging orphaned or runaway child processes.
## Tips
- Combine with `-p` when you need to `kill` a specific child process without affecting its siblings.
## Common Mistakes
- Assuming every process shown is a "real" process — entries in curly braces `{}` represent threads of the parent process, not separate processes.
## Related Commands
[ps](#ps), [top](#top)

---

# strace
## Purpose
Trace system calls and signals made by a running program — a powerful low-level debugging tool.
## Syntax
```
strace [OPTIONS] COMMAND
```
## Common Options
| Option | Description |
|---|---|
| `-f` | Trace child processes too (follow forks) |
| `-e trace=CATEGORY` | Only trace specific syscall categories, e.g., `-e trace=network` |
| `-p PID` | Attach to an already-running process |
| `-c` | Summarize syscall counts and time instead of a full trace |

## Example
```bash
strace -f -e trace=open,read ./myprogram
```
## Expected Output
```
open("/etc/config.conf", O_RDONLY) = 3
read(3, "port=8080\n", 4096) = 10
```
## Explanation
`strace` intercepts every system call a program makes to the kernel (file opens, network calls, memory allocation, etc.), making it invaluable for diagnosing "why is this program failing" when no useful application-level error is given — e.g., discovering a program is looking for a config file in the wrong path.
## Tips
- `strace -c ./program` gives a quick summary of which syscalls dominate execution time — a fast first step in performance debugging.
## Common Mistakes
- Running `strace` on performance-critical production processes without understanding it adds significant overhead, potentially slowing the traced process substantially.
## Related Commands
[lsof](#lsof), [ps](#ps)

---

⬅️ Back to [file-permissions.md](file-permissions.md) | Next: [networking.md](networking.md) ➡️
