# Linux Commands & Notes

My personal reference for Linux commands I use while practising system
administration, shell scripting, and security. Each page covers one
topic: what the command does, the options I actually use, a short
example, and notes on the parts that tend to trip people up.

## Pages

| Page | Covers |
|---|---|
| [navigation.md](navigation.md) | `cd`, `pwd`, `ls`, `find`, `which`, inspecting files |
| [filesystem.md](filesystem.md) | creating, copying, moving, deleting; archives and compression |
| [file-permissions.md](file-permissions.md) | `chmod`, `chown`, `umask`, setuid/sticky bits, ACLs |
| [processes.md](processes.md) | `ps`, `top`, `kill`, jobs, `systemctl`, `crontab` |
| [networking.md](networking.md) | `ip`, `ping`, `ss`, `curl`, `wget`, `ssh`, DNS |
| [users-groups.md](users-groups.md) | `useradd`, `passwd`, `sudo`, `su`, groups |
| [storage.md](storage.md) | `df`, `du`, `mount`, partitions, LVM, swap |
| [package-management.md](package-management.md) | `apt`, `dnf`, `pacman`, `snap` |
| [shell-scripting.md](shell-scripting.md) | bash basics, `grep`, `sed`, `awk`, redirection |
| [security.md](security.md) | SSH keys, `ufw`, `fail2ban`, `gpg`, file hashes, auditing |

## How to use this

* `navigation.md` → `filesystem.md` → `file-permissions.md` is a good
  starting path; the other pages build on those.
* `man <command>` and `<command> --help` are the authoritative
  references. These notes are a quick-start companion, not a replacement.

## License

MIT — see [LICENSE](../../LICENSE).

---

Destructive commands (`rm -rf`, `dd`, `mkfs`, `fdisk`) are documented for
reference. Test them in a virtual machine or scratch directory first —
never on a machine where you cannot afford to lose the data.