[🏠 Home](README.md) | [Navigation](navigation.md) | [Filesystem](filesystem.md) | [Permissions](file-permissions.md) | [Processes](processes.md) | [Networking](networking.md) | [Storage](storage.md) | [Packages](package-management.md) | [Shell Scripting](shell-scripting.md) | [Security](security.md)

# User & Group Administration

Creating, modifying, and removing users and groups, managing passwords,
and controlling privilege escalation.

**Contents:** [useradd](#useradd) · [adduser](#adduser) · [usermod](#usermod) · [userdel](#userdel) · [passwd](#passwd) · [groupadd](#groupadd) · [groupmod](#groupmod) · [groupdel](#groupdel) · [groups](#groups) · [whoami](#whoami) · [who](#who) · [w](#w) · [su](#su) · [sudo](#sudo) · [visudo](#visudo) · [chsh](#chsh) · [chfn](#chfn) · [newgrp](#newgrp) · [last](#last)

---

### useradd
Create a user account (the low-level tool).

```bash
sudo useradd -m -s /bin/bash -G sudo,developers alex
sudo passwd alex
```

- `-m` creates the home directory; `-s` sets the login shell; `-G` adds supplementary groups.
- `useradd` doesn't set a password — a new account is locked until you run `passwd`.
- On Debian/Ubuntu the friendlier `adduser` wrapper is more common interactively; use `useradd` in scripts for predictable, non-interactive behaviour.

### adduser
Interactive, higher-level user-creation wrapper (Debian/Ubuntu family). Prompts for password and details, and creates the home directory and matching private group automatically.

```bash
sudo adduser alex
```

RHEL/Fedora generally don't ship the Debian-style `adduser` — use `useradd` there.

### usermod
Modify an existing account.

```bash
sudo usermod -aG docker kapilesh    # add to a group
sudo usermod -s /bin/zsh kapilesh   # change login shell
sudo usermod -L kapilesh / -U       # lock / unlock the account
```

**Always use `-a` (append) with `-G`.** `usermod -G docker user` without `-a` *replaces* the entire supplementary group list — the classic way people accidentally remove themselves from `sudo`. Group changes take effect at the next login (`newgrp` applies them now).

### userdel
Delete an account.

```bash
sudo userdel -r alex    # -r: also remove home directory and mail spool
```

Without `-r`, the home directory stays behind, owned by a now-nonexistent UID. Before deleting, check for files outside home (`sudo find / -user alex`), running processes, cron jobs, and `/etc/sudoers` references.

### passwd
Change a user's password, or lock/unlock an account.

```bash
passwd                   # change your own password
sudo passwd alex         # set someone else's
sudo passwd -l alex      # lock (disable password login)
sudo passwd -e alex      # expire: must change at next login
```

Note the command vs. files: `/etc/passwd` is the account database, `/etc/shadow` holds the hashes (restricted), and the `passwd` binary changes them.
### groupadd / groupmod / groupdel
Create, rename, and delete groups.

```bash
sudo groupadd developers
sudo groupmod -n devs developers    # rename
sudo groupdel devs
```

- Plan group structure before assigning permissions — overlapping groups become permission sprawl that's hard to audit.
- Renaming a group doesn't touch file ownership (stored by **GID number** on disk), so existing permissions survive. Changing the GID (`groupmod -g`) orphans files that referenced the old number until you `chgrp` them.
- `groupdel` refuses while the group is still anybody's **primary** group — check `grep devs /etc/group /etc/passwd` first.

### groups
List the groups a user belongs to.

```bash
groups kapilesh
```

The first listed is usually the **primary** group; the rest are supplementary. Cross-check with `id` for numeric GIDs.

### whoami
Print the current *effective* username — under `sudo` it prints `root`.

```bash
whoami
```

Good sanity check in scripts; don't confuse with `who` (current sessions).

### who / w
`who` lists current login sessions (terminal, login time, origin IP). `w` adds load average and each user's current foreground command.

```bash
who
w
```

Useful before disruptive maintenance on shared machines. `who` ≠ `last` (which shows *historical* logins).

### su
Switch to another user — usually to become root.

```bash
su - root      # the dash matters: full login shell, loads root's environment
```

Without `-`, `su` keeps your current environment (directory, variables) — a common source of "why is my environment different?" confusion. Modern distros prefer `sudo` because it logs every command and doesn't require sharing the root password.

### sudo
Run one command with elevated privileges, per `/etc/sudoers` rules.

```bash
sudo systemctl restart nginx
sudo -u postgres psql          # run as a specific user
sudo -i                        # interactive root shell
sudo -l                        # what am I allowed to run?
```

- Uses **your** password (unlike `su`, which wants root's) and every invocation is logged — typically `/var/log/auth.log`.
- Credentials are cached for a short window (default ~15 min).
- Don't run GUI apps or daily-driver commands under sudo "just in case" — it creates root-owned files and is a bad habit.

### visudo
The safe way to edit `/etc/sudoers`: it locks the file and **validates syntax before saving**, so a typo can't lock everyone out of sudo.

```bash
sudo visudo
sudo visudo -f /etc/sudoers.d/myfile    # drop-in files are preferred
```

Never hand-edit `/etc/sudoers` with a plain editor — a syntax error there can brick admin access on the box.

### chsh
Change a user's login shell. The shell must be listed in `/etc/shells` or `chsh` refuses.

```bash
chsh -s /bin/zsh
cat /etc/shells    # check what's allowed first
```

### chfn
Change the GECOS "finger" metadata — full name, room, phone. Mostly cosmetic these days, but some tools and mail systems still use the Full Name field.

```bash
chfn kapilesh
```

### newgrp
Start a new shell with a different **primary** group — the way to pick up group membership changes without logging out.

```bash
newgrp developers
```

### last
Show **historical** login records (from `/var/log/wtmp`) — who logged in, from where, and for how long.

```bash
last
last -F        # full timestamps
```

Useful for auditing; this is what "check who has been logging into this box" means. `last` shows the past — `who` shows right now.

---

⬅️ Back to [Networking](networking.md) | Next: [Storage](storage.md) ➡️