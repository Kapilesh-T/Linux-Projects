[🏠 Home](README.md) | [Navigation](navigation.md) | [Filesystem](filesystem.md) | [Permissions](file-permissions.md) | [Networking](networking.md) | [Users & Groups](users-groups.md) | [Storage](storage.md) | [Packages](package-management.md) | [Shell Scripting](shell-scripting.md) | [Security](security.md)

# Process & Service Management

Viewing, monitoring, controlling, and scheduling processes, jobs, and
system services.

**Contents:** [ps](#ps) · [top](#top) · [htop](#htop) · [kill](#kill) · [killall](#killall) · [pkill](#pkill) · [pgrep](#pgrep) · [nice](#nice) · [renice](#renice) · [jobs](#jobs) · [bg](#bg) · [fg](#fg) · [nohup](#nohup) · [disown](#disown) · [systemctl](#systemctl) · [journalctl](#journalctl) · [service](#service) · [uptime](#uptime) · [free](#free) · [vmstat](#vmstat) · [lsof](#lsof) · [crontab](#crontab) · [at](#at) · [watch](#watch) · [pstree](#pstree) · [strace](#strace)

---

### ps
Take a snapshot of running processes.

```bash
ps aux                    # all processes, BSD-style, detailed columns
ps -ef                    # all processes, UNIX-style full format
ps aux --sort=-%mem | head   # top memory consumers
ps -ef --forest           # show parent/child tree
```

Key columns: **PID**, **%CPU**/**%MEM** (usage at that instant), **STAT** (process state: `S` sleeping, `R` running, `Z` zombie, `T` stopped), **TIME** (total CPU time consumed). `ps` is a one-time snapshot — use `top` for live monitoring.

### top
Live, continuously updating view of processes and system resources.

```bash
top
```

Interactive keys: `P` sort by CPU · `M` sort by memory · `k` kill a process (prompts for PID) · `q` quit. The **load average** (three numbers: 1/5/15-minute averages) is the number of processes waiting for CPU time — compare it to your core count: load 4.0 is fine on 8 cores, a bottleneck on 2.

### htop
Interactive, color-coded `top` alternative with mouse support.

```bash
htop
```

Keys: `F6` change sort column · `F5` tree view · `F4` filter by name · `F9` kill · `Space` tag processes. Not installed by default on most distros (`sudo apt install htop`).
### kill
Send a signal to a process — most commonly to terminate it.

```bash
kill 4521         # SIGTERM (15), the default — a polite request
kill -9 4521      # SIGKILL — forced, no cleanup, cannot be ignored
kill -HUP 4521    # SIGHUP — reload config (daemons)
kill -STOP 4521   # pause
kill -CONT 4521   # resume
```

Always try plain `kill` (SIGTERM) first and only escalate to `-9` if the process ignores it — `-9` skips cleanup handlers and can corrupt files, locks, or database state.

### killall
Kill every process with a given **name**.

```bash
killall firefox
killall -9 chrome
```

Kills all matching instances at once. Double-check the name with `ps aux | grep NAME` first — broad matches can hit processes you didn't mean.

### pkill / pgrep
Find and kill processes by name or attribute pattern. `pgrep` prints matching PIDs; `pkill` sends them a signal.

```bash
pgrep -la nginx            # -l: show names too, -a: full command line
pkill -u kapilesh -f "python manage.py runserver"
pgrep -x nginx >/dev/null && echo "nginx is running"
```

`pgrep` is the reliable, script-friendly alternative to `ps aux | grep ...`, which famously matches its own `grep` process. Run the `pgrep` first to preview, then `pkill`.

### nice / renice
Set a process's CPU scheduling priority.

```bash
nice -n 10 ./long_backup.sh     # start with low priority
renice 10 -p 4521               # change an already-running process
```

Niceness runs **-20 (highest priority) to 19 (lowest)**. A normal user may only *increase* niceness (make things less urgent); lowering it (negative values) needs root.

### jobs / bg / fg
Job control for one shell session. `jobs` lists background and stopped jobs (numbered `[1]`, `[2]` — different from PIDs); `%1` refers to job 1.

```bash
sleep 300 &        # start in the background
jobs -l            # list with PIDs
Ctrl+Z             # stop the foreground job (SIGTSTP)
bg %1              # resume it in the background
fg %1              # bring it back to the foreground
```

A `Ctrl+Z`'d process is *paused*, not backgrounded, until you run `bg`.

### nohup
Run a command so it survives the terminal closing (immune to `SIGHUP`).

```bash
nohup python3 long_task.py &   # output goes to nohup.out
```

Closing a terminal sends `SIGHUP` to its children; `nohup` makes the process ignore it — essential for long jobs over SSH. Don't forget the trailing `&`: `nohup` alone doesn't background anything. For real daemons prefer `systemd` services or `tmux`/`screen`.

### disown
Detach an already-running background job so it survives terminal closure.

```bash
long_task.sh &
disown %1          # remove job 1 from the shell's job table
disown -a          # disown all background jobs
```

Unlike `nohup` (applied at launch), `disown` works retroactively on running jobs.
### systemctl
Control the `systemd` init system — the service manager on most modern distros (Ubuntu, Debian, Fedora, RHEL, Arch).

```bash
sudo systemctl restart nginx
sudo systemctl enable --now nginx      # start now AND at boot
sudo systemctl reload nginx            # re-read config, no downtime
systemctl status nginx
systemctl list-units --type=service
```

- `enable` alone only sets up autostart — it doesn't start the service; `enable --now` does both.
- `restart` is a full process restart (brief downtime); `reload` re-reads config without downtime, but only works for services written to support it.

### journalctl
Query logs collected by systemd's journal.

```bash
journalctl -u nginx -f                  # -u: one service, -f: follow live
journalctl --since "10 minutes ago" -p err
journalctl -b                           # this boot only
journalctl -xe                          # most recent errors with context
```

`journalctl -xe` is the first command to run after a service fails to start. Journals can be volatile (cleared on reboot) unless `Storage=persistent` is set in `/etc/systemd/journald.conf`.

### service
The legacy service wrapper. On systemd distros it forwards to `systemctl` for compatibility with old scripts and muscle memory.

```bash
sudo service nginx restart
```

Prefer `systemctl` directly on modern systems.

### uptime
How long the system has been running, plus the load average.

```bash
uptime      #  10:24:01 up 3 days,  2:16,  1 user,  load average: 0.15, 0.20, 0.18
uptime -p   #  up 3 days, 2 hours, 16 minutes
```

### free
RAM and swap usage.

```bash
free -h     #  Mem: 7.8Gi total, 2.1Gi used, ... 5.3Gi available
```

Watch the **available** column, not `free` — Linux deliberately uses spare RAM for disk cache (`buff/cache`) and reclaims it automatically. A tiny "free" number is normal.

### vmstat
CPU, memory, and I/O statistics for spotting bottlenecks.

```bash
vmstat 2 5     # sample every 2 seconds, 5 times
```

Key columns: **r** processes waiting for CPU, **b** blocked on I/O, **wa** CPU time waiting on I/O (high = disk bottleneck), **si/so** swap in/out (sustained non-zero = memory pressure). Ignore the first line — it's averages since boot; the real-time data is in the lines after.

### lsof
List open files — and therefore which process holds a port or file.

```bash
sudo lsof -i :8080    # who is using port 8080?
lsof -u kapilesh      # files open by a user
lsof -p 4521          # files open by a PID
```

On Linux, sockets and devices are files, so `lsof` doubles as a port tool. Without `sudo` you won't see other users' (or root's) entries.

### crontab
Schedule recurring commands.

```bash
crontab -e     # edit your jobs
crontab -l     # list them
```

One line per job: `minute hour day-of-month month day-of-week command`:

```
0 2 * * * /home/kapilesh/scripts/backup.sh
```

Tips:
- Always use *absolute* paths in cron jobs — cron runs with a minimal environment (no interactive `$PATH`). Scripts that work by hand but fail under cron are almost always missing environment/PATH entries.
- `systemd` timers are the modern alternative.

### at
Schedule a **one-time** command for a specific time.

```bash
at 22:00
at> /home/kapilesh/scripts/check.sh
at> <Ctrl+D>
```

`atq` lists pending jobs; `atrm N` cancels one. Package: `at` (not always installed by default).

### watch
Re-run a command on a fixed interval, refreshing the screen.

```bash
watch -n 1 -d "df -h"    # -d: highlight what changed between refreshes
```

Quote complex commands so `watch` receives the whole pipeline, not just the first word.

### pstree
Show running processes as a tree, with parents and children.

```bash
pstree -p    # with PIDs
```

### strace
Trace the system calls a program makes — the debugging tool for "why does this fail".

```bash
strace -p 4521                # attach to a running process
strace -e open,read ./app     # trace only specific syscalls
strace -o trace.txt ./app     # write to a file
```

Requires `strace` package; attaching to other users' processes needs root.

---

⬅️ Back to [Permissions](file-permissions.md) | Next: [Networking](networking.md) ➡️