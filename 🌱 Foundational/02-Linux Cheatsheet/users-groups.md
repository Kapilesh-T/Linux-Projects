[🏠 Home](README.md) | [Navigation](navigation.md) | [Filesystem](filesystem.md) | [Permissions](file-permissions.md) | [Processes](processes.md) | [Networking](networking.md) | [Storage](storage.md) | [Packages](package-management.md) | [Shell Scripting](shell-scripting.md) | [Security](security.md)

# 👤 User & Group Administration

Commands for creating, modifying, and removing users and groups, managing passwords, and controlling privilege escalation.

## Table of Contents
1. [useradd](#useradd) 2. [adduser](#adduser) 3. [usermod](#usermod) 4. [userdel](#userdel) 5. [passwd](#passwd) 6. [groupadd](#groupadd) 7. [groupmod](#groupmod) 8. [groupdel](#groupdel) 9. [groups](#groups) 10. [whoami](#whoami) 11. [who](#who) 12. [w](#w) 13. [su](#su) 14. [sudo](#sudo) 15. [visudo](#visudo) 16. [chsh](#chsh) 17. [chfn](#chfn) 18. [newgrp](#newgrp) 19. [last](#last) 20. [id](file-permissions.md#id)

---

# useradd
## Purpose
Create a new user account (low-level tool).
## Syntax
```
sudo useradd [OPTIONS] USERNAME
```
## Common Options
| Option | Description |
|---|---|
| `-m` | Create the user's home directory |
| `-s SHELL` | Set the login shell (e.g., `/bin/bash`) |
| `-G GROUP1,GROUP2` | Add to supplementary groups |
| `-c "Full Name"` | Set a comment/description (usually the full name) |

## Example
```bash
sudo useradd -m -s /bin/bash -G sudo,developers alex
sudo passwd alex
```
## Expected Output
```
(no output on success)
```
## Explanation
`useradd` is the low-level, distro-agnostic tool for creating users, but it does **not** set a password or always create a home directory by default depending on distro configuration — you must explicitly add `-m` and set a password separately with `passwd`.
## Tips
- Always follow up `useradd` with `passwd USERNAME` — a newly created account is locked (no valid password) until you set one.
## Common Mistakes
- Forgetting `-m` and ending up with a user account that has no home directory, breaking login and default shell behavior.
- On Debian/Ubuntu, forgetting that `adduser` (the friendlier wrapper) is generally recommended over raw `useradd` for interactive use.
## Related Commands
[adduser](#adduser), [passwd](#passwd), [usermod](#usermod)

---

# adduser
## Purpose
A friendlier, interactive, higher-level wrapper around `useradd` (primarily on Debian/Ubuntu-based distros).
## Syntax
```
sudo adduser USERNAME
```
## Example
```bash
sudo adduser alex
```
## Expected Output
```
Adding user `alex' ...
Adding new group `alex' (1001) ...
Enter new UNIX password:
Retype new UNIX password:
Full Name []: Alex Kumar
```
## Explanation
`adduser` interactively prompts for a password and user details, and automatically creates the home directory and a matching private group — behavior that must be manually specified with raw `useradd`.
## Tips
- Prefer `adduser` for interactive/manual user creation on Debian/Ubuntu systems; use `useradd` directly in scripts where non-interactive, precise control is needed.
## Common Mistakes
- Assuming `adduser` exists identically on all distros — RHEL/Fedora/CentOS generally only provide `useradd`, not the Debian-style `adduser` wrapper.
## Related Commands
[useradd](#useradd)

---

# usermod
## Purpose
Modify an existing user account's properties.
## Syntax
```
sudo usermod [OPTIONS] USERNAME
```
## Common Options
| Option | Description |
|---|---|
| `-aG GROUP` | **A**ppend to a supplementary group (always use with `-a`!) |
| `-s SHELL` | Change the login shell |
| `-l NEW_NAME` | Rename the login username |
| `-L` / `-U` | Lock / unlock the account |
| `-e DATE` | Set an account expiry date |

## Example
```bash
sudo usermod -aG docker kapilesh
```
## Expected Output
```
(no output on success)
```
## Explanation
`-aG` adds a group *without* removing existing group memberships. This distinction is critical because `-G` alone **replaces** the entire supplementary group list.
## Tips
- After adding yourself to a new group, log out and back in (or run `newgrp GROUP`) for the change to apply to your current session.
## Common Mistakes
- **The single most common `usermod` mistake:** running `usermod -G docker username` without the `-a` flag, which silently *removes* the user from all their other supplementary groups (like `sudo`), potentially locking them out of expected privileges.
## Related Commands
[groups](#groups), [id](file-permissions.md#id)

---

# userdel
## Purpose
Delete a user account.
## Syntax
```
sudo userdel [OPTIONS] USERNAME
```
## Common Options
| Option | Description |
|---|---|
| `-r` | Also remove the user's home directory and mail spool |

## Example
```bash
sudo userdel -r alex
```
## Expected Output
```
(no output on success)
```
## Explanation
Without `-r`, the user account is removed but their home directory and files remain on disk, potentially orphaned (owned by a now-nonexistent UID).
## Tips
- Before deleting, check `sudo find / -user USERNAME` to see all files owned by that account, in case some live outside their home directory.
## Common Mistakes
- Deleting a user who still owns running processes or cron jobs, or is referenced by `/etc/sudoers`, without cleaning those up first — this can leave orphaned references in the system.
## Related Commands
[useradd](#useradd)

---

# passwd
## Purpose
Change a user's password.
## Syntax
```
passwd [USERNAME]
```
## Common Options
| Option | Description |
|---|---|
| `-l` | Lock an account (prevent password login) |
| `-u` | Unlock a locked account |
| `-e` | Force password expiry, requiring a change at next login |
| `-S` | Show the account's password status |

## Example
```bash
passwd
sudo passwd -l alex
```
## Expected Output
```
Changing password for kapilesh.
Current password:
New password:
Retype new password:
passwd: password updated successfully
```
## Explanation
Regular users can only change their own password with plain `passwd`; changing another user's password requires `sudo passwd USERNAME`. Note the `passwd` **binary** relates to, but is distinct from, the `/etc/passwd` **file** (user account database) and `/etc/shadow` (encrypted password storage).
## Tips
- `sudo passwd -l USERNAME` is a fast way to temporarily disable an account without fully deleting it.
## Common Mistakes
- Confusing the `passwd` command with the `/etc/passwd` file — the file no longer even stores password hashes (those live in the more restricted `/etc/shadow`), a historical security improvement.
## Related Commands
[usermod](#usermod), [chsh](#chsh)

---

# groupadd
## Purpose
Create a new group.
## Syntax
```
sudo groupadd [OPTIONS] GROUPNAME
```
## Common Options
| Option | Description |
|---|---|
| `-g GID` | Specify a particular group ID number |

## Example
```bash
sudo groupadd developers
```
## Expected Output
```
(no output on success)
```
## Explanation
Groups provide a way to grant a set of permissions to multiple users at once (see [file-permissions.md](file-permissions.md)) without managing each user's access individually.
## Tips
- Plan group structure (e.g., `developers`, `readonly`, `admins`) before assigning permissions broadly across a shared server.
## Common Mistakes
- Creating overlapping/redundant groups without a clear naming convention, leading to permission sprawl that's hard to audit later.
## Related Commands
[groupmod](#groupmod), [usermod](#usermod)

---

# groupmod
## Purpose
Modify an existing group's properties (name or GID).
## Syntax
```
sudo groupmod [OPTIONS] GROUPNAME
```
## Common Options
| Option | Description |
|---|---|
| `-n NEW_NAME` | Rename the group |
| `-g NEW_GID` | Change the group ID number |

## Example
```bash
sudo groupmod -n devs developers
```
## Explanation
Renaming a group does not change file ownership references (which are stored by GID number internally), so existing file permissions remain intact after a rename.
## Tips
- Changing a GID (`-g`) on a group that already owns files will **not** automatically update those files' ownership — you may need to manually `chgrp` affected files.
## Common Mistakes
- Changing a GID expecting all existing file group-ownership to follow automatically — it does not; the numeric ownership on disk stays the same, effectively orphaning it from the renumbered group unless manually fixed.
## Related Commands
[groupadd](#groupadd), [chgrp](file-permissions.md#chgrp)

---

# groupdel
## Purpose
Delete a group.
## Syntax
```
sudo groupdel GROUPNAME
```
## Example
```bash
sudo groupdel developers
```
## Explanation
Fails if the group is still the **primary** group of any existing user account — you must reassign or remove those users first.
## Tips
- Check `grep GROUPNAME /etc/group` and `grep GROUPNAME /etc/passwd` before deletion to confirm no dependencies remain.
## Common Mistakes
- Attempting to delete a group that's still someone's primary group and being confused by the resulting error.
## Related Commands
[groupadd](#groupadd)

---

# groups
## Purpose
Show which groups a user belongs to.
## Syntax
```
groups [USERNAME]
```
## Example
```bash
groups kapilesh
```
## Expected Output
```
kapilesh : kapilesh sudo developers docker
```
## Explanation
The first group listed is typically the user's **primary** group; the rest are **supplementary** groups granting additional access.
## Tips
- Cross-check with `id` for a more detailed view including numeric GIDs.
## Common Mistakes
- Running `groups` right after being added to a new group and expecting to see it immediately — a fresh login (or `newgrp`) is required first.
## Related Commands
[id](file-permissions.md#id), [usermod](#usermod)

---

# whoami
## Purpose
Print the current effective username.
## Syntax
```
whoami
```
## Example
```bash
whoami
```
## Expected Output
```
kapilesh
```
## Explanation
Reflects the **effective** user, which changes under `sudo`/`su` — running `sudo whoami` prints `root`, since the effective identity for that command is elevated.
## Tips
- A quick sanity check inside scripts to confirm whether code is currently running with elevated privileges.
## Common Mistakes
- Confusing `whoami` (effective/current identity) with `who` (all logged-in sessions) — similarly named but functionally different commands.
## Related Commands
[who](#who), [id](file-permissions.md#id)

---

# who
## Purpose
Show who is currently logged into the system.
## Syntax
```
who
```
## Example
```bash
who
```
## Expected Output
```
kapilesh pts/0        2026-07-08 09:01 (192.168.1.10)
```
## Explanation
Lists each active login session, the terminal it's on, login time, and (for remote sessions) the originating IP address.
## Tips
- Useful on shared/multi-user servers to check who else is currently connected before performing disruptive maintenance.
## Common Mistakes
- Confusing `who` (currently logged-in users) with `last` (historical login records, including past sessions).
## Related Commands
[w](#w), [last](#last)

---

# w
## Purpose
Show who is logged in and what they're currently doing (an extended version of `who`).
## Syntax
```
w [USERNAME]
```
## Example
```bash
w
```
## Expected Output
```
 10:35:01 up 3 days,  2:27,  2 users,  load average: 0.10, 0.15, 0.12
USER     TTY      FROM             LOGIN@   IDLE   WHAT
kapilesh pts/0    192.168.1.10     09:01    0.00s  w
```
## Explanation
Combines `who`-style session info with `uptime`-style load average and a "WHAT" column showing each user's currently active process.
## Tips
- Useful for a quick, single-command system health + user-activity overview.
## Common Mistakes
- Assuming the "WHAT" column always reflects a long-running task — it shows the current foreground process, which can be as trivial as the `w` command itself.
## Related Commands
[who](#who), [uptime](processes.md#uptime)

---

# su
## Purpose
Switch to another user account (substitute user), typically used to become root.
## Syntax
```
su [-] [USERNAME]
```
## Common Options
| Option | Description |
|---|---|
| `-` (dash) | Start a full login shell (loads the target user's environment/profile) |

## Example
```bash
su - root
```
## Expected Output
```
Password:
root@server:~#
```
## Explanation
Without the `-`, `su` switches identity but keeps your *current* shell environment (working directory, some environment variables) — with `-`, it simulates a fresh login as that user, loading their full profile/environment as if they'd logged in directly.
## Tips
- On most modern distros, `sudo` is preferred over `su` for admin tasks because it provides per-command logging/auditing and doesn't require sharing the root password.
## Common Mistakes
- Forgetting the `-` and being confused why environment variables or the working directory don't match a "real" login as that user.
## Related Commands
[sudo](#sudo)

---

# sudo
## Purpose
Execute a single command with another user's privileges (typically root), based on rules defined in `/etc/sudoers`.
## Syntax
```
sudo [OPTIONS] COMMAND
```
## Common Options
| Option | Description |
|---|---|
| `-u USER` | Run as a specific user instead of root |
| `-l` | List the commands the current user is permitted to run with sudo |
| `-i` | Start an interactive root login shell |

## Example
```bash
sudo systemctl restart nginx
sudo -u postgres psql
```
## Expected Output
```
[sudo] password for kapilesh:
```
## Explanation
Unlike `su` (which requires the root password and switches your entire session), `sudo` uses **your own** password and grants temporary, per-command elevated privileges based on policy rules — providing far better auditability (every `sudo` command is logged, typically to `/var/log/auth.log` or via `journalctl`).
## Tips
- `sudo -l` is a great first command to check exactly what a user is authorized to do before assuming access.
- By default, `sudo` caches your credentials for a short window (commonly 15 minutes) so you're not re-prompted for every single command in quick succession.
## Common Mistakes
- Running GUI applications or scripts with `sudo` unnecessarily "just in case," which is both a security anti-pattern and can create root-owned files in a user's own directories, causing later permission conflicts.
## Related Commands
[su](#su), [visudo](#visudo)

---

# visudo
## Purpose
Safely edit the `/etc/sudoers` file, which controls sudo privilege rules.
## Syntax
```
sudo visudo
```
## Explanation
`visudo` locks the sudoers file during editing and — critically — **validates syntax before saving**, refusing to save a broken file that could lock every user (including root, via sudo) out of administrative access.
## Tips
- **Never** edit `/etc/sudoers` directly with a plain text editor (`nano /etc/sudoers`) — always use `visudo`, since a syntax error in a directly-edited file can be catastrophic and hard to recover from.
- Use `sudo visudo -f /etc/sudoers.d/myfile` to safely add custom rules in the recommended drop-in directory rather than editing the main file at all.
## Common Mistakes
- Bypassing `visudo` and hand-editing `/etc/sudoers`, introducing a syntax error that breaks `sudo` system-wide, often requiring a rescue boot or root console access to fix.
## Related Commands
[sudo](#sudo)

---

# chsh
## Purpose
Change a user's default login shell.
## Syntax
```
chsh -s /path/to/shell [USERNAME]
```
## Example
```bash
chsh -s /bin/zsh
```
## Expected Output
```
Password:
Shell changed.
```
## Explanation
The chosen shell must be listed in `/etc/shells` — `chsh` will refuse to set a shell path that isn't registered there, as a basic safety/validity check.
## Tips
- Check available valid shells first with `cat /etc/shells`.
## Common Mistakes
- Setting a shell path that isn't in `/etc/shells` (or doesn't exist), which can leave the account unable to log in properly until fixed.
## Related Commands
[passwd](#passwd)

---

# chfn
## Purpose
Change a user's "finger information" — full name and other account metadata (GECOS field).
## Syntax
```
chfn [USERNAME]
```
## Example
```bash
chfn kapilesh
```
## Expected Output
```
Changing the user information for kapilesh
Enter the new value, or press ENTER for the default
	Full Name: Kapilesh
	Room Number []:
```
## Explanation
This metadata is largely cosmetic on modern systems (historically used by the `finger` service, now rarely used), but some tools/mail systems still reference the full name field.
## Tips
- Rarely needed in day-to-day administration, but occasionally relevant for setting a proper display name for a service account.
## Common Mistakes
- Confusing this with actual account security settings — it's purely descriptive metadata, unrelated to permissions or passwords.
## Related Commands
[passwd](#passwd)

---

# newgrp
## Purpose
Start a new shell session with a different **primary** group active, without needing to log out and back in.
## Syntax
```
newgrp GROUPNAME
```
## Example
```bash
newgrp docker
```
## Explanation
The fastest way to make a recently-added group membership (via `usermod -aG`) take effect in your *current* terminal session, instead of requiring a full logout/login.
## Tips
- Remember `newgrp` starts a **new** shell — type `exit` to return to your previous shell/group context afterward.
## Common Mistakes
- Forgetting you're now in a nested shell after `newgrp` and being confused why `exit` doesn't close the terminal entirely (it just returns to the prior shell).
## Related Commands
[usermod](#usermod), [groups](#groups)

---

# last
## Purpose
Show a history of user logins, reading from the `/var/log/wtmp` login record.
## Syntax
```
last [USERNAME]
```
## Example
```bash
last -5
```
## Expected Output
```
kapilesh pts/0        192.168.1.10     Mon Jul  8 09:01   still logged in
kapilesh pts/0        192.168.1.10     Sun Jul  7 20:14 - 21:03  (00:49)
```
## Explanation
Useful for security auditing — reviewing who logged in, from where, and for how long, including detecting logins at unusual times or from unexpected IP addresses.
## Tips
- `last -F` shows full login/logout timestamps rather than abbreviated ones, useful for precise audit trails.
## Common Mistakes
- Treating `last` output as tamper-proof — the underlying `wtmp` log file can be altered by anyone with root access, so it should be one signal among several (alongside `journalctl`, auth logs) in a real security investigation.
## Related Commands
[who](#who), [w](#w)

---

⬅️ Back to [networking.md](networking.md) | Next: [storage.md](storage.md) ➡️
