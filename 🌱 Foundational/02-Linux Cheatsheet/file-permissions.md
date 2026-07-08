[🏠 Home](README.md) | [Navigation](navigation.md) | [Filesystem](filesystem.md) | [Processes](processes.md) | [Networking](networking.md) | [Users & Groups](users-groups.md) | [Storage](storage.md) | [Packages](package-management.md) | [Shell Scripting](shell-scripting.md) | [Security](security.md)

# 🔐 File Permissions & Ownership

Linux enforces access control through a permission model attached to every file and directory. This page covers reading, changing, and understanding that model — including advanced ACLs and extended attributes.

## Understanding the Permission Model (read this first)

Every file has three permission classes and three permission types:

| Class | Meaning |
|---|---|
| **Owner (u)** | The user who owns the file |
| **Group (g)** | Users belonging to the file's group |
| **Others (o)** | Everyone else |

| Type | Symbol | Octal Value | Meaning on a file | Meaning on a directory |
|---|---|---|---|---|
| Read | `r` | 4 | View file contents | List directory contents |
| Write | `w` | 2 | Modify file contents | Create/delete/rename entries inside |
| Execute | `x` | 1 | Run as a program/script | Enter the directory (`cd` into it) |

Reading `ls -l` output like `-rwxr-xr--`:
```
-   rwx      r-x      r--
type  owner    group   others
```
Octal notation sums the values per class: `rwxr-xr--` = owner `7` (4+2+1), group `5` (4+0+1), others `4` (4+0+0) → **754**.

## Table of Contents
1. [chmod](#chmod) 2. [chown](#chown) 3. [chgrp](#chgrp) 4. [umask](#umask) 5. [getfacl](#getfacl) 6. [setfacl](#setfacl) 7. [chattr](#chattr) 8. [lsattr](#lsattr) 9. [id](#id) 10. [find (permission search)](#find-permission-search) 11. [Special Permissions: SUID, SGID, Sticky Bit](#special-permissions-suid-sgid-sticky-bit)

---

# chmod
## Purpose
Change the read/write/execute permissions of a file or directory.
## Syntax
```
chmod [OPTIONS] MODE FILE
```
## Common Options
| Option | Description |
|---|---|
| `-R` | Apply recursively to a directory and its contents |
| `--reference=FILE` | Copy permissions from another file |

## Example
```bash
chmod 755 deploy.sh
chmod u+x deploy.sh
chmod -R go-w /var/www/html
```
## Expected Output
```
(no output on success)
```
## Explanation
`chmod` accepts either **octal notation** (e.g., `755`) or **symbolic notation** (`u`/`g`/`o`/`a` combined with `+`/`-`/`=` and `r`/`w`/`x`). Symbolic mode is often clearer for *incremental* changes (`u+x` adds execute for owner without touching other bits); octal is clearer for setting the *entire* permission set explicitly.
## Tips
- `chmod +x script.sh` is the single most common command new Linux users need — it makes a script executable.
- Use `chmod -R` cautiously; recursively applying `x` to files (not just directories) can incorrectly make plain data files "executable."
## Common Mistakes
- Running `chmod 777` to "just make it work" — this grants full read/write/execute to everyone, a serious security anti-pattern, especially on web-facing directories.
- Using `-R` with a numeric mode on a mixed tree of files and directories, applying execute permission to files that shouldn't have it (use `chmod -R u+X` — capital X — which only adds execute to directories or files that already have some execute bit).
## Related Commands
[chown](#chown), [umask](#umask), [ls](navigation.md#ls)

---

# chown
## Purpose
Change the owner (and optionally group) of a file or directory.
## Syntax
```
chown [OPTIONS] OWNER[:GROUP] FILE
```
## Common Options
| Option | Description |
|---|---|
| `-R` | Apply recursively |
| `--from=CURRENT_OWNER` | Only change if the current owner matches |

## Example
```bash
sudo chown www-data:www-data /var/www/html -R
sudo chown kapilesh notes.txt
```
## Expected Output
```
(no output on success)
```
## Explanation
Only the **root user** (or a user with `sudo`) can change a file's owner to a *different* user — this prevents users from "gifting" files to escape disk quotas or shift blame for file content.
## Tips
- Use `owner:group` syntax to set both in a single command, saving a call to `chgrp`.
## Common Mistakes
- Forgetting `sudo` when changing ownership to another user (regular users can only change the *group* of files they own, and only to a group they belong to).
- Recursively `chown`-ing a directory containing files owned by services (e.g., accidentally chowning `/var/lib/mysql`), which can break running services expecting specific ownership.
## Related Commands
[chgrp](#chgrp), [chmod](#chmod)

---

# chgrp
## Purpose
Change the group ownership of a file or directory.
## Syntax
```
chgrp [OPTIONS] GROUP FILE
```
## Common Options
| Option | Description |
|---|---|
| `-R` | Apply recursively |

## Example
```bash
chgrp developers project/ -R
```
## Explanation
A regular (non-root) user can change a file's group only to a group they themselves belong to — you cannot assign a file to an arbitrary group you're not a member of.
## Tips
- Combine with `chmod g+w` when setting up shared team directories so all group members can collaborate.
## Common Mistakes
- Assuming any user can set any group — attempting to set a group you don't belong to fails with "Operation not permitted."
## Related Commands
[chown](#chown), [groups](users-groups.md#groups)

---

# umask
## Purpose
Display or set the default permission mask applied to newly created files and directories.
## Syntax
```
umask [MASK]
```
## Example
```bash
umask
umask 022
```
## Expected Output
```
0022
```
## Explanation
`umask` works by **subtraction**, not addition: it removes permission bits from the maximum default (666 for files, 777 for directories). A umask of `022` means new files get `666 - 022 = 644` (`rw-r--r--`) and new directories get `777 - 022 = 755` (`rwxr-xr-x`).
## Tips
- Set a custom `umask` in `~/.bashrc` (e.g., `umask 027`) if you want new files to be private-by-default from other users on shared systems.
## Common Mistakes
- Confusing `umask` values with `chmod` values — they represent what gets **removed**, which is the inverse logic of `chmod`'s "what gets set."
## Related Commands
[chmod](#chmod)

---

# getfacl
## Purpose
Display detailed Access Control List (ACL) permissions for a file, beyond the basic owner/group/other model.
## Syntax
```
getfacl FILE
```
## Example
```bash
getfacl shared_report.docx
```
## Expected Output
```
# file: shared_report.docx
# owner: kapilesh
# group: kapilesh
user::rw-
user:alex:rw-
group::r--
mask::rw-
other::r--
```
## Explanation
Standard Unix permissions only support one owner and one group. **ACLs** (Access Control Lists) extend this to allow fine-grained permissions for *multiple specific users or groups* on the same file — for example, granting a specific colleague write access without changing the file's group ownership.
## Tips
- Look for a `+` at the end of the permission string in `ls -l` output (e.g., `-rw-rwx---+`) — that plus sign indicates ACLs are present on the file.
## Common Mistakes
- Forgetting ACLs exist and being confused why a user can access a file that basic `ls -l` permissions suggest they shouldn't be able to.
## Related Commands
[setfacl](#setfacl), [chmod](#chmod)

---

# setfacl
## Purpose
Set fine-grained Access Control List permissions for specific users or groups on a file.
## Syntax
```
setfacl [OPTIONS] FILE
```
## Common Options
| Option | Description |
|---|---|
| `-m` | Modify (add/edit) an ACL entry |
| `-x` | Remove a specific ACL entry |
| `-b` | Remove all ACL entries |
| `-R` | Apply recursively |
| `-d` | Set a default ACL (inherited by new files created in a directory) |

## Example
```bash
setfacl -m u:alex:rw- shared_report.docx
setfacl -d -m g:developers:rwx /srv/team-project
```
## Expected Output
```
(no output on success)
```
## Explanation
The second example sets a **default ACL** on a directory, meaning any new file created inside it automatically inherits `rwx` for the `developers` group — extremely useful for shared team folders.
## Tips
- Requires the filesystem to be mounted with ACL support (`acl` mount option) — most modern ext4/xfs setups enable this by default.
## Common Mistakes
- Setting an ACL on a file but forgetting the `mask` entry, which caps the *effective* maximum permission for all named users/groups regardless of their individual ACL entries.
## Related Commands
[getfacl](#getfacl), [chmod](#chmod)

---

# chattr
## Purpose
Set special filesystem-level attributes on a file (beyond standard permissions), such as making it immutable even to root.
## Syntax
```
chattr [+-=ATTRIBUTE] FILE
```
## Common Attributes
| Attribute | Description |
|---|---|
| `+i` | Immutable — file cannot be modified, deleted, or renamed, even by root, until the attribute is removed |
| `+a` | Append-only — file can only be added to, not overwritten or deleted (useful for log files) |

## Example
```bash
sudo chattr +i /etc/resolv.conf
```
## Expected Output
```
(no output on success)
```
## Explanation
`chattr` operates at a level *below* normal Unix permissions — an immutable file can't be changed even by root without first clearing the attribute (`chattr -i`), providing an extra layer of protection against accidental or malicious modification.
## Tips
- Commonly used to lock down critical config files like `/etc/resolv.conf` from being overwritten by network managers.
## Common Mistakes
- Setting `+i` on a file and then being confused why even `sudo rm` fails — always check `lsattr` when a "permission denied"-style error happens despite having root.
- Not all filesystems support all attributes (mainly ext2/3/4, xfs, btrfs have varying support).
## Related Commands
[lsattr](#lsattr)

---

# lsattr
## Purpose
List the special filesystem attributes set on a file (as set by `chattr`).
## Syntax
```
lsattr [FILE]
```
## Example
```bash
lsattr /etc/resolv.conf
```
## Expected Output
```
----i---------e------- /etc/resolv.conf
```
## Explanation
The letters shown correspond directly to `chattr`'s attribute flags — here `i` confirms the file is immutable.
## Tips
- Check `lsattr` whenever a file mysteriously refuses to be edited/deleted despite correct ownership and permissions.
## Common Mistakes
- Overlooking `chattr`/`lsattr` entirely and spending time debugging permission issues that are actually attribute issues.
## Related Commands
[chattr](#chattr)

---

# id
## Purpose
Display the user ID (UID), group ID (GID), and all group memberships for a user.
## Syntax
```
id [USERNAME]
```
## Example
```bash
id kapilesh
```
## Expected Output
```
uid=1000(kapilesh) gid=1000(kapilesh) groups=1000(kapilesh),27(sudo),999(docker)
```
## Explanation
Shows exactly which groups determine a user's access — critical for debugging "permission denied" issues (e.g., a user not in the `docker` group can't run Docker commands without `sudo`).
## Tips
- Run `id` with no arguments to check your *own* current identity, including any group membership changes that may require a fresh login to take effect.
## Common Mistakes
- Adding a user to a group with `usermod -aG` and expecting it to apply immediately in an already-open shell session — group membership changes require a new login (or `newgrp`) to take effect.
## Related Commands
[groups](users-groups.md#groups), [whoami](users-groups.md#whoami)

---

# find (permission search)
## Purpose
Locate files matching specific permission criteria — a critical security auditing technique.
## Syntax
```
find PATH -perm MODE
```
## Common Options
| Option | Description |
|---|---|
| `-perm -4000` | Find files with the SUID bit set |
| `-perm -2000` | Find files with the SGID bit set |
| `-perm -o+w` | Find world-writable files |
| `-perm /u+s` | Find files with SUID set (alternate syntax, matches ANY of specified bits) |

## Example
```bash
find / -perm -4000 -type f 2>/dev/null
find / -perm -o+w -type f 2>/dev/null
```
## Expected Output
```
/usr/bin/sudo
/usr/bin/passwd
```
## Explanation
This is a standard security auditing pattern: SUID binaries run with the file owner's privileges (often root) regardless of who executes them, and world-writable files can be tampered with by any user — both are common privilege escalation vectors that penetration testers and system auditors check for regularly.
## Tips
- Redirect stderr to `/dev/null` when scanning the whole filesystem (`/`) to suppress a flood of "Permission denied" messages from directories you can't read.
## Common Mistakes
- Confusing `-perm 4000` (exact match only) with `-perm -4000` (the SUID bit is set, regardless of other bits) — the leading dash matters enormously.
## Related Commands
[chmod](#chmod), [find](navigation.md#find)

---

# Special Permissions: SUID, SGID, Sticky Bit
## Purpose
Three special permission bits that modify standard behavior for specific security and collaboration use cases.
## Syntax
```
chmod u+s FILE     # Set SUID
chmod g+s DIRECTORY # Set SGID
chmod +t DIRECTORY  # Set Sticky Bit
```
## Explanation
| Bit | Octal Prefix | On a File | On a Directory |
|---|---|---|---|
| **SUID** (Set User ID) | 4000 | Program runs with the *file owner's* privileges, not the executing user's (e.g., `/usr/bin/passwd` runs as root so any user can update their own password entry in `/etc/shadow`) | No effect |
| **SGID** (Set Group ID) | 2000 | Program runs with the file's *group* privileges | New files/subdirectories created inside inherit the directory's group automatically — very useful for shared team folders |
| **Sticky Bit** | 1000 | No effect | Users can only delete/rename files they own, even if the directory is group/world-writable (e.g., `/tmp` uses this) |

## Example
```bash
chmod 4755 /usr/bin/custom-tool   # SUID + rwxr-xr-x
chmod 2775 /srv/team-shared       # SGID + rwxrwxr-x
chmod 1777 /tmp                   # Sticky bit + rwxrwxrwx
```
## Expected Output
```
-rwsr-xr-x 1 root root ... /usr/bin/custom-tool
drwxrwsr-x 2 root devteam ... /srv/team-shared
drwxrwxrwt 10 root root ... /tmp
```
Note the lowercase `s`, `s`, and `t` replacing the normal `x` position — this indicates the special bit AND the execute bit are both set (uppercase `S`/`T` would indicate the special bit is set but execute is NOT).
## Tips
- SUID root binaries are a top area of focus in privilege-escalation research and CTF challenges — auditing them regularly is a real-world security best practice (see `find -perm -4000` above).
## Common Mistakes
- Setting SUID on scripts (shell scripts) expecting the same effect as on compiled binaries — most modern Linux kernels **ignore** the SUID bit on interpreted scripts for security reasons.
- Confusing SGID on a directory (permission inheritance) with SUID on an executable (privilege elevation) — they solve different problems.
## Related Commands
[chmod](#chmod), [find (permission search)](#find-permission-search)

---

⬅️ Back to [filesystem.md](filesystem.md) | Next: [processes.md](processes.md) ➡️
