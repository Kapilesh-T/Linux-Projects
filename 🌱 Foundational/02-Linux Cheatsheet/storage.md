[🏠 Home](README.md) | [Navigation](navigation.md) | [Filesystem](filesystem.md) | [Permissions](file-permissions.md) | [Processes](processes.md) | [Networking](networking.md) | [Users & Groups](users-groups.md) | [Packages](package-management.md) | [Shell Scripting](shell-scripting.md) | [Security](security.md)

# 💾 Storage, Disks & Filesystems

Commands for inspecting disk usage, managing partitions, formatting filesystems, and mounting storage devices.

## Table of Contents
1. [df](#df) 2. [du](#du) 3. [mount](#mount) 4. [umount](#umount) 5. [lsblk](#lsblk) 6. [blkid](#blkid) 7. [fdisk](#fdisk) 8. [parted](#parted) 9. [mkfs](#mkfs) 10. [fsck](#fsck) 11. [dd](#dd) 12. [mkswap](#mkswap) 13. [swapon](#swapon) 14. [swapoff](#swapoff) 15. [tune2fs](#tune2fs) 16. [ncdu](#ncdu) 17. [smartctl](#smartctl) 18. [/etc/fstab (concept)](#etcfstab-concept)

---

# df
## Purpose
Report disk space usage for mounted filesystems.
## Syntax
```
df [OPTIONS]
```
## Common Options
| Option | Description |
|---|---|
| `-h` | Human-readable sizes (GB/MB) |
| `-T` | Show filesystem type |
| `-i` | Show inode usage instead of block usage |

## Example
```bash
df -hT
```
## Expected Output
```
Filesystem     Type  Size  Used Avail Use% Mounted on
/dev/sda1      ext4   98G   42G   51G  46% /
tmpfs          tmpfs 3.9G     0  3.9G   0% /dev/shm
```
## Explanation
`df` reports at the **filesystem** level (whole partitions/mounts), giving a quick overview of overall disk space, unlike `du` which reports at the individual file/directory level.
## Tips
- Always check `df -i` when you get "No space left on device" errors despite `df -h` showing free space — you may have exhausted available **inodes** (metadata entries), a separate limit from raw byte capacity, common with directories containing millions of tiny files.
## Common Mistakes
- Only ever checking `df -h` and never `df -i`, missing inode-exhaustion issues entirely.
## Related Commands
[du](#du), [lsblk](#lsblk)

---

# du
## Purpose
Report disk usage of individual files and directories (disk usage), useful for finding what's consuming space.
## Syntax
```
du [OPTIONS] [PATH]
```
## Common Options
| Option | Description |
|---|---|
| `-h` | Human-readable sizes |
| `-s` | Summarize — show only the total for each argument, not every subdirectory |
| `-a` | Include files, not just directories |
| `--max-depth=N` | Limit recursion depth |

## Example
```bash
du -sh /var/log/*
```
## Expected Output
```
1.2G	/var/log/nginx
850M	/var/log/journal
12M	/var/log/apt
```
## Explanation
Unlike `df` (whole-filesystem view), `du` walks the directory tree and sums actual file sizes — the classic pattern `du -sh /path/* | sort -rh | head` is the standard way to find what's eating disk space.
## Tips
- `du -sh /path/* | sort -rh | head` (summarize, human-readable, sort by size descending, top results) is one of the most useful one-liners in system administration.
## Common Mistakes
- Running plain `du` (no `-s`) on a large directory tree and being flooded with a line for *every* subdirectory instead of just the totals you wanted.
- `du` totals can differ slightly from `df` totals due to deleted-but-still-open files (held open by a running process) that `df` still counts but `du` cannot see, since they no longer have a filesystem path.
## Related Commands
[df](#df), [ncdu](#ncdu)

---

# mount
## Purpose
Attach a filesystem (from a disk, partition, network share, or image) to a directory in the filesystem tree.
## Syntax
```
mount [OPTIONS] DEVICE MOUNTPOINT
```
## Common Options
| Option | Description |
|---|---|
| `-t TYPE` | Specify filesystem type (ext4, ntfs, etc.) |
| `-o OPTIONS` | Mount options (e.g., `ro` for read-only, `noexec`) |

## Example
```bash
sudo mount /dev/sdb1 /mnt/usb
mount | grep sda1
```
## Expected Output
```
/dev/sda1 on / type ext4 (rw,relatime)
```
## Explanation
Linux uses a unified filesystem tree — unlike Windows' drive letters, external/additional storage is "mounted" onto an existing directory path (a **mount point**), becoming accessible as if it were part of the main tree.
## Tips
- Running plain `mount` with no arguments lists all currently mounted filesystems — useful for confirming a mount succeeded.
## Common Mistakes
- Mounting to a directory that already has files in it — those files become temporarily hidden (not deleted) until the filesystem is unmounted again, which can cause confusing "my files disappeared" reports.
## Related Commands
[umount](#umount), [/etc/fstab](#etcfstab-concept)

---

# umount
## Purpose
Detach ("unmount") a mounted filesystem.
## Syntax
```
umount [DEVICE_OR_MOUNTPOINT]
```
## Common Options
| Option | Description |
|---|---|
| `-l` | Lazy unmount — detach now, clean up once no longer busy |
| `-f` | Force unmount (useful for unresponsive network mounts) |

## Example
```bash
sudo umount /mnt/usb
```
## Expected Output
```
(no output on success)
```
## Explanation
Always unmount external/removable storage before physically disconnecting it — this ensures any buffered writes are flushed to disk, preventing data corruption.
## Tips
- If you get "target is busy," use `lsof +D /mount/point` or `fuser -m /mount/point` to find which process still has open files there before force-unmounting.
## Common Mistakes
- Physically removing a USB drive without unmounting first — write caching means recently "copied" files may not actually be fully written to the physical device yet.
- Using `-f` as a first resort instead of investigating what's actually holding the mount busy.
## Related Commands
[mount](#mount)

---

# lsblk
## Purpose
List all block devices (disks and their partitions) in a readable tree format.
## Syntax
```
lsblk [OPTIONS]
```
## Common Options
| Option | Description |
|---|---|
| `-f` | Show filesystem type and UUID |
| `-o COLUMNS` | Customize displayed columns |

## Example
```bash
lsblk -f
```
## Expected Output
```
NAME   FSTYPE   LABEL   UUID                                 MOUNTPOINT
sda
├─sda1 ext4             a1b2c3d4-e5f6-...                     /
└─sda2 swap             f6e5d4c3-b2a1-...                     [SWAP]
sdb
└─sdb1 vfat             1234-ABCD                             /mnt/usb
```
## Explanation
Usually the **first command to run** when working with disks/partitions — it gives an immediate visual map of every physical/virtual disk, its partitions, and what (if anything) is mounted where, without risk of accidentally modifying anything (unlike `fdisk`).
## Tips
- Always run `lsblk` before `fdisk`/`parted` operations to confirm you have the correct device name (e.g., `/dev/sdb` not `/dev/sda`) before making destructive changes.
## Common Mistakes
- Confusing disk device names (`/dev/sdb`) with partition names (`/dev/sdb1`) when passing arguments to other tools like `mkfs` or `mount`.
## Related Commands
[blkid](#blkid), [fdisk](#fdisk)

---

# blkid
## Purpose
Display block device attributes, particularly UUID and filesystem type — critical for writing reliable `/etc/fstab` entries.
## Syntax
```
blkid [DEVICE]
```
## Example
```bash
sudo blkid /dev/sda1
```
## Expected Output
```
/dev/sda1: UUID="a1b2c3d4-e5f6-4789-9abc-def012345678" TYPE="ext4"
```
## Explanation
UUIDs (Universally Unique Identifiers) are the recommended way to reference disks in `/etc/fstab`, since device names like `/dev/sda1` can shift between boots if disk enumeration order changes (e.g., after adding/removing a drive).
## Tips
- Always copy UUIDs from `blkid` output exactly (including quotes as needed) when writing `fstab` entries, to avoid boot failures from typos.
## Common Mistakes
- Hardcoding `/dev/sdX` device names in `/etc/fstab` instead of UUIDs — this can cause a system to fail to boot correctly if drive letters shift after a hardware change.
## Related Commands
[lsblk](#lsblk), [/etc/fstab](#etcfstab-concept)

---

# fdisk
## Purpose
View and modify disk partition tables (MBR-style, and basic GPT support).
## Syntax
```
sudo fdisk DEVICE
```
## Common Interactive Commands (inside fdisk)
| Key | Action |
|---|---|
| `p` | Print the current partition table |
| `n` | Create a new partition |
| `d` | Delete a partition |
| `w` | Write changes to disk and exit |
| `q` | Quit without saving changes |

## Example
```bash
sudo fdisk -l
sudo fdisk /dev/sdb
```
## Expected Output
```
Disk /dev/sdb: 32 GiB, 34359738368 bytes, 67108864 sectors
Device     Boot Start      End  Sectors  Size Id Type
/dev/sdb1        2048 67108863 67106816   32G 83 Linux
```
## Explanation
`fdisk` operates on the **partition table** (the "map" of where partitions start/end on a disk) — it does not create filesystems itself; that's a separate step done afterward with `mkfs`.
## Tips
- `fdisk -l` (list, no target device) is completely safe/read-only and a good way to survey all disks before deciding what to modify.
- Nothing is actually written to disk until you explicitly press `w` — you can safely explore with `p` and quit with `q` if unsure.
## Common Mistakes
- **This is one of the highest-risk commands in this entire wiki.** Running `fdisk` on the wrong device (e.g., your system disk `/dev/sda` instead of an external drive `/dev/sdb`) and pressing `w` can destroy your operating system's partition table. Always triple-check the device name with `lsblk` first.
## Related Commands
[parted](#parted), [lsblk](#lsblk), [mkfs](#mkfs)

---

# parted
## Purpose
A more modern, GPT-friendly alternative to `fdisk` for partition management, supporting disks larger than 2TB.
## Syntax
```
sudo parted DEVICE [COMMAND]
```
## Common Commands
| Command | Description |
|---|---|
| `print` | Show the current partition table |
| `mklabel gpt` | Initialize a new GPT partition table |
| `mkpart` | Create a new partition |
| `resizepart` | Resize an existing partition |

## Example
```bash
sudo parted /dev/sdb print
```
## Expected Output
```
Model: ATA VBOX HARDDISK
Disk /dev/sdb: 34.4GB
Partition Table: gpt
Number  Start   End     Size    File system  Name  Flags
```
## Explanation
Unlike `fdisk`'s older MBR-focused design, `parted` natively handles GPT (GUID Partition Table), required for disks larger than 2TB and for modern UEFI boot setups.
## Tips
- `parted`'s non-interactive mode (`parted /dev/sdb mkpart primary ext4 0% 100%`) is scriptable, unlike `fdisk`'s fully interactive-only design.
## Common Mistakes
- Some `parted` operations apply immediately (unlike `fdisk`'s "nothing happens until `w`" model) — there is less of a safety net for undoing a mistake mid-session.
## Related Commands
[fdisk](#fdisk)

---

# mkfs
## Purpose
Create ("make") a new filesystem on a partition or disk.
## Syntax
```
sudo mkfs.TYPE DEVICE
```
## Common Variants
| Command | Filesystem |
|---|---|
| `mkfs.ext4` | ext4 (most common Linux default) |
| `mkfs.xfs` | XFS (common on RHEL/CentOS, good for large files) |
| `mkfs.vfat` | FAT32 (cross-platform compatibility, e.g., USB drives) |
| `mkfs.ntfs` | NTFS (Windows compatibility) |

## Example
```bash
sudo mkfs.ext4 /dev/sdb1
```
## Expected Output
```
Creating filesystem with 8388352 4k blocks and 2097152 inodes
Allocating group tables: done
Writing inode tables: done
Writing superblocks and filesystem accounting information: done
```
## Explanation
This step **erases all existing data** on the target partition — it initializes the low-level data structures (inode tables, journal, superblock) that define how files will be organized on that partition going forward.
## Tips
- Always confirm the target device with `lsblk`/`blkid` beforehand — there is no "undo" or confirmation prompt on most `mkfs` variants.
## Common Mistakes
- Running `mkfs` on the wrong partition (a classic data-loss scenario alongside `fdisk` and `dd` mistakes) — always double, even triple-check the device path.
## Related Commands
[fdisk](#fdisk), [fsck](#fsck)

---

# fsck
## Purpose
Check and repair filesystem inconsistencies/corruption.
## Syntax
```
sudo fsck [OPTIONS] DEVICE
```
## Common Options
| Option | Description |
|---|---|
| `-y` | Automatically answer "yes" to all repair prompts |
| `-f` | Force a check even if the filesystem appears clean |

## Example
```bash
sudo fsck -y /dev/sdb1
```
## Expected Output
```
Pass 1: Checking inodes, blocks, and sizes
Pass 2: Checking directory structure
...
/dev/sdb1: 1234/2097152 files, 456789/8388352 blocks
```
## Explanation
Filesystem corruption can occur after unclean shutdowns (power loss, forced reboot mid-write). `fsck` verifies internal filesystem structures against expected consistency rules and repairs discrepancies where possible.
## Tips
- **Never run `fsck` on a currently mounted, actively-in-use filesystem** — unmount it first, or run from a live/rescue boot environment for the root filesystem.
## Common Mistakes
- Running `fsck -y` (auto-fix everything) on a filesystem with data corruption you haven't investigated — automatic repairs can sometimes delete unrecoverable fragments (placing them in `lost+found`) rather than truly restoring original content.
## Related Commands
[mkfs](#mkfs)

---

# dd
## Purpose
Low-level utility for copying and converting raw data block-by-block — commonly used for disk imaging, cloning, and creating bootable USB drives.
## Syntax
```
dd if=INPUT of=OUTPUT [OPTIONS]
```
## Common Options
| Option | Description |
|---|---|
| `if=` | Input file/device |
| `of=` | Output file/device |
| `bs=SIZE` | Block size (e.g., `bs=4M` for performance) |
| `status=progress` | Show live progress during the operation |

## Example
```bash
sudo dd if=ubuntu-24.04.iso of=/dev/sdb bs=4M status=progress
```
## Expected Output
```
1234567890 bytes (1.2 GB, 1.1 GiB) copied, 45 s, 27.4 MB/s
```
## Explanation
`dd` works at the raw byte/block level with **no filesystem awareness** — it will happily overwrite an entire disk's partition table and data with zero warning, which is exactly why it's the standard tool for writing bootable ISOs to USB drives (and equally why it's nicknamed "disk destroyer" among sysadmins).
## Tips
- Triple-check `of=` (output) before pressing Enter — there is no confirmation prompt and no undo.
- `status=progress` is essential for long operations; without it, `dd` runs silently with zero feedback until fully complete.
## Common Mistakes
- **Swapping `if=` and `of=`** — this single typo copies the *empty destination* onto your *source data*, permanently destroying it. Always read the command back before executing.
- Targeting a partition (`/dev/sdb1`) when you meant the whole disk (`/dev/sdb`), or vice versa, especially when writing bootable ISOs (which typically need the whole-disk device).
## Related Commands
[mkfs](#mkfs), [cp](filesystem.md#cp)

---

# mkswap
## Purpose
Set up a swap area on a partition or file (virtual memory, used when RAM is full).
## Syntax
```
sudo mkswap DEVICE_OR_FILE
```
## Example
```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
```
## Expected Output
```
Setting up swapspace version 1, size = 2 GiB (2147479552 bytes)
```
## Explanation
Swap space acts as an overflow for RAM — when physical memory is exhausted, the kernel moves inactive memory pages to swap (on disk), which is much slower than RAM but prevents out-of-memory process kills.
## Tips
- `chmod 600` on a swap file is important — a world-readable swap file could expose sensitive data that was temporarily paged out from RAM.
## Common Mistakes
- Forgetting that creating the swap area (`mkswap`) is separate from actually **activating** it (`swapon`) — both steps are required.
## Related Commands
[swapon](#swapon), [swapoff](#swapoff)

---

# swapon
## Purpose
Activate (enable) a configured swap area.
## Syntax
```
sudo swapon [DEVICE_OR_FILE]
```
## Common Options
| Option | Description |
|---|---|
| `-a` | Activate all swap areas listed in `/etc/fstab` |
| `-s` | Show a summary of active swap areas |

## Example
```bash
sudo swapon /swapfile
swapon -s
```
## Expected Output
```
Filename    Type       Size        Used    Priority
/swapfile   file       2097148     0       -2
```
## Explanation
Activated swap is immediately usable by the kernel; add an entry to `/etc/fstab` if you want it activated automatically on every boot rather than manually each time.
## Tips
- `free -h` will show the swap total increase once `swapon` succeeds — a quick way to confirm it worked.
## Common Mistakes
- Activating swap on a file without proper permissions (`chmod 600`) set beforehand, which some systems will reject for security reasons.
## Related Commands
[mkswap](#mkswap), [swapoff](#swapoff), [free](processes.md#free)

---

# swapoff
## Purpose
Deactivate a swap area.
## Syntax
```
sudo swapoff [DEVICE_OR_FILE]
```
## Example
```bash
sudo swapoff /swapfile
```
## Explanation
Before removing/resizing a swap file or partition, it must first be deactivated — any data currently swapped to it is moved back into RAM as part of this process (which requires enough free RAM to hold it).
## Tips
- If a system is under heavy memory pressure, `swapoff` can temporarily cause noticeable slowdown or even OOM (out-of-memory) issues as data is moved back to RAM — plan accordingly on production systems.
## Common Mistakes
- Trying to delete or resize an active swap file without running `swapoff` first, resulting in errors or an inconsistent state.
## Related Commands
[swapon](#swapon)

---

# tune2fs
## Purpose
View or adjust tunable parameters on ext2/ext3/ext4 filesystems.
## Syntax
```
sudo tune2fs [OPTIONS] DEVICE
```
## Common Options
| Option | Description |
|---|---|
| `-l` | List all filesystem parameters (read-only, safe) |
| `-L LABEL` | Set a filesystem label |
| `-c COUNT` | Set the maximum mount count before forcing an `fsck` |

## Example
```bash
sudo tune2fs -l /dev/sda1
```
## Expected Output
```
Filesystem volume name:  <none>
Filesystem UUID:         a1b2c3d4-e5f6-4789-9abc-def012345678
Filesystem state:        clean
Mount count:              12
```
## Explanation
Useful for both diagnostics (`-l`, completely safe/read-only) and advanced tuning (labels, reserved block percentage, forced check intervals) specific to the ext filesystem family.
## Tips
- `tune2fs -l` is a safe, informative first command when investigating a specific ext4 partition's configuration and health status.
## Common Mistakes
- Applying tuning changes (write operations) to a currently-mounted filesystem when the specific option requires it to be unmounted first — always check the man page for each specific flag's requirements.
## Related Commands
[fsck](#fsck), [blkid](#blkid)

---

# ncdu
## Purpose
An interactive, terminal-based disk usage analyzer — a visual, navigable alternative to repeatedly running `du`.
## Syntax
```
ncdu [PATH]
```
## Common Interactive Keys
| Key | Action |
|---|---|
| `↑`/`↓` | Navigate |
| `Enter` | Drill into a directory |
| `d` | Delete the selected file/directory (use carefully!) |
| `q` | Quit |

## Example
```bash
ncdu /var
```
## Explanation
Not installed by default (`sudo apt install ncdu`), but extremely popular among administrators for quickly and interactively hunting down what's consuming disk space, without repeatedly re-running `du` commands manually.
## Tips
- The built-in `d` delete function is convenient but genuinely destructive — always confirm you're looking at the right item before pressing it.
## Common Mistakes
- Forgetting `ncdu`'s delete function bypasses the trash entirely, just like `rm` — there's no undo.
## Related Commands
[du](#du), [df](#df)

---

# smartctl
## Purpose
Query a physical disk's S.M.A.R.T. (Self-Monitoring, Analysis, and Reporting Technology) health data to predict drive failure.
## Syntax
```
sudo smartctl [OPTIONS] DEVICE
```
## Common Options
| Option | Description |
|---|---|
| `-a` | Show all available SMART information |
| `-H` | Quick overall health check (PASSED/FAILED) |
| `-t short` / `-t long` | Run a short or long self-test |

## Example
```bash
sudo smartctl -H /dev/sda
```
## Expected Output
```
SMART overall-health self-assessment test result: PASSED
```
## Explanation
Part of the `smartmontools` package, this reads hardware-level diagnostic counters (reallocated sectors, temperature, power-on hours) that firmware tracks internally, providing early warning of impending physical disk failure — well before data loss occurs.
## Tips
- Periodically check `smartctl -a` on production servers' disks, especially reallocated sector count and temperature — rising trends often predict failure days-to-weeks in advance.
## Common Mistakes
- Assuming a drive is healthy just because the OS hasn't reported errors yet — SMART data often reveals early warning signs well before a filesystem-level failure occurs.
- SMART data may not be directly accessible on virtualized/cloud disks (e.g., some cloud VM block storage) since the underlying physical hardware is abstracted away.
## Related Commands
[fsck](#fsck)

---

# /etc/fstab (concept)
## Purpose
The system configuration file that defines which filesystems should be automatically mounted at boot, and with what options.
## Format
```
DEVICE_OR_UUID   MOUNT_POINT   FS_TYPE   OPTIONS   DUMP   PASS
```
## Example
```
UUID=a1b2c3d4-e5f6-4789-9abc-def012345678   /        ext4   defaults        0   1
UUID=f6e5d4c3-b2a1-4567-8def-012345678abc   none     swap   sw              0   0
/dev/sdb1                                    /mnt/usb  vfat   noauto,users    0   2
```
## Explanation
Each line's fields, left to right: the device (ideally by UUID, see [blkid](#blkid)); the mount point directory; the filesystem type; mount options (`defaults`, `ro`, `noauto`, etc.); the `dump` backup flag (usually `0`, rarely used today); and the `fsck` pass order (`0` = don't check, `1` = check first for root, `2` = check after).
## Tips
- After editing `/etc/fstab`, always test with `sudo mount -a` **before** rebooting — this applies the file's rules immediately and will surface syntax errors safely, rather than discovering them at the next boot.
## Common Mistakes
- **A broken `/etc/fstab` entry can prevent the system from booting entirely**, sometimes dropping to an emergency shell requiring manual repair. Always back up the file before editing (`sudo cp /etc/fstab /etc/fstab.bak`) and validate with `mount -a` before rebooting.
- Using `/dev/sdX` device names instead of UUIDs, which can silently reference the wrong disk after hardware changes.
## Related Commands
[mount](#mount), [blkid](#blkid)

---

⬅️ Back to [users-groups.md](users-groups.md) | Next: [package-management.md](package-management.md) ➡️
