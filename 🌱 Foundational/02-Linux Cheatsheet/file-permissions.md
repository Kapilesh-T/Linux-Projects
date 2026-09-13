[🏠 Home](README.md) | [Navigation](navigation.md) | [Filesystem](filesystem.md) | [Processes](processes.md) | [Networking](networking.md) | [Users & Groups](users-groups.md) | [Storage](storage.md) | [Packages](package-management.md) | [Shell Scripting](shell-scripting.md) | [Security](security.md)

# File Permissions & Ownership

How Linux controls access to files: the owner/group/other model,
changing permissions, ACLs, special bits, and filesystem attributes.

**Contents:** [The permission model](#the-permission-model) · [chmod](#chmod) · [chown](#chown) · [chgrp](#chgrp) · [umask](#umask) · [getfacl](#getfacl) · [setfacl](#setfacl) · [chattr](#chattr) · [lsattr](#lsattr) · [id](#id) · [find by permissions](#find-by-permissions) · [SUID / SGID / sticky bit](#suid--sgid--sticky-bit)

---

## The permission model (read this first)

Every file has three permission **classes** and three permission **types**:

| Class | Meaning |
|---|---|
| Owner (`u`) | the user who owns the file |
| Group (`g`) | users belonging to the file's group |
| Others (`o`) | everyone else |

| Type | Symbol | Octal | On a file | On a directory |
|---|---|---|---|---|
| Read | `r` | 4 | view contents | list entries |
| Write | `w` | 2 | modify contents | create/delete/rename entries inside |
| Execute | `x` | 1 | run as a program | enter the directory (`cd` into it) |

Reading `ls -l` output `-rwxr-xr--`:

```
-    rwx      r-x      r--
type owner   group   others
```

Octal sums the bits per class: `rwxr-xr--` = owner `4+2+1=7`, group `4+0+1=5`, others `4+0+0=4` → **754**.

### chmod
Change permissions, in octal or symbolic form.

```bash
chmod 755 deploy.sh          # set the whole mode explicitly
chmod u+x deploy.sh          # add execute for owner only
chmod -R go-w /var/www/html  # -R: recursive
chmod -R u+X /srv            # capital X: add x only to dirs / already-x files
chmod --reference=file.txt other.txt   # copy one file's mode
```

- Symbolic (`u+x`) is best for incremental changes; octal (`755`) for setting the full mode.
- `chmod +x script.sh` is the standard "make this runnable" command.
- Avoid `chmod 777` to "just make it work" — world-writable files are a security anti-pattern, especially on web dirs.
- With `-R`, prefer `u+X` (capital X), which adds execute only to directories and files that already have some execute bit — plain `-R 755` marks every data file executable too.
### chown
Change the owner (and optionally group) of a file. Needs root — a normal user can't reassign ownership to someone else.

```bash
sudo chown www-data:www-data /var/www/html -R
sudo chown kapilesh notes.txt
```

Use `owner:group` to set both at once. Be careful with `-R` over directories that services own (e.g. `/var/lib/mysql`) — changing ownership can break a running service.

### chgrp
Change the group of a file. A normal user may only set a group they themselves belong to.

```bash
chgrp developers project/ -R
```

Pair with `chmod g+w` when setting up shared team directories.

### umask
Show or set the default permission mask applied to **newly created** files and directories.

```bash
umask      # 0022
umask 027  # stricter: private-by-default files
```

The mask is *subtracted* from the maximum: files default to 666, directories to 777. A `022` mask gives files `666-022=644` and dirs `777-022=755`. Put `umask 027` in `~/.bashrc` on shared systems so new files aren't world-readable.

### getfacl
Show Access Control Lists (ACLs) — fine-grained permissions for *multiple* specific users/groups beyond the single owner/group model.

```bash
getfacl shared_report.docx
```

A `+` at the end of the `ls -l` permission string means the file has ACL entries. If somebody can access a file against what `ls -l` seems to say, check for ACLs.

### setfacl
Set those fine-grained entries.

```bash
setfacl -m u:alex:rw- shared_report.docx          # give alex rw
setfacl -d -m g:developers:rwx /srv/team-project  # default ACL for new files
setfacl -x u:alex file.sh       # remove one entry
setfacl -b file.sh              # remove all entries
```

The `-d` default ACL means every file created inside the directory inherits the entry — the standard way to wire up shared team folders. Needs ACL support on the filesystem (on by default for modern ext4/xfs). Note the `mask` entry caps the effective permissions of all named users, so check `getfacl` when an ACL user still can't do what the entry suggests.

### chattr
Set filesystem-level attributes that override normal permissions — even root can't change or delete the file while these are set.

```bash
sudo chattr +i /etc/resolv.conf   # immutable: no modify/delete/rename
sudo chattr +a /var/log/app.log   # append-only: logs can only grow
sudo chattr -i /etc/resolv.conf   # remove the attribute
```

If a file refuses deletion despite correct permissions, check `lsattr` for an `i` flag. Not all filesystems support all attributes.

### lsattr
List the attributes set by `chattr`.

```bash
lsattr /etc/resolv.conf    # ----i---------e------- /etc/resolv.conf
```

### id
Show a user's UID, GID, and all group memberships.

```bash
id kapilesh
```

This is the first thing to check on "permission denied": a user not in the `docker` group can't run docker without sudo. Group changes from `usermod -aG` only take effect after a new login (`newgrp` applies them to the current shell).

### find by permissions
Locate files by permission bits — a standard security-auditing technique.

```bash
find / -perm -4000 -type f 2>/dev/null     # SUID binaries
find / -perm -2000 -type f 2>/dev/null     # SGID binaries
find / -perm -o+w -type f 2>/dev/null      # world-writable files
```

The leading `-` matters: `-perm 4000` matches modes where *exactly* 4000 is set, while `-perm -4000` matches any mode that *has* the SUID bit. Redirect stderr to `/dev/null` when scanning `/` to skip the flood of "Permission denied".

### SUID / SGID / sticky bit
Three special bits that change default behaviour:

| Bit | Octal prefix | On a file | On a directory |
|---|---|---|---|
| **SUID** | 4000 | runs with the file *owner's* privileges (e.g. `/usr/bin/passwd` runs as root so any user can update their own password in `/etc/shadow`) | no effect |
| **SGID** | 2000 | runs with the file's *group* privileges | new files created inside inherit the directory's group |
| **Sticky** | 1000 | no effect | only the file's owner can delete/rename entries, even in a world-writable dir (that's how `/tmp` works) |

```bash
chmod 4755 /usr/bin/custom-tool
chmod 2775 /srv/team-shared
chmod 1777 /tmp
```

`ls -l` shows them as `s`/`s`/`t` in the execute position (uppercase `S`/`T` = special bit set but execute not). Notes:

- Linux kernels **ignore** SUID on interpreted scripts (shell/perl) for security — it only works on compiled binaries.
- Enumerate SUID files with `find / -perm -4000` when auditing a machine: each one is a potential privilege-escalation vector.

---

⬅️ Back to [Filesystem](filesystem.md) | Next: [Processes](processes.md) ➡️