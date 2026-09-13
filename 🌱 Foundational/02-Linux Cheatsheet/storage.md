[🏠 Home](README.md) | [Navigation](navigation.md) | [Filesystem](filesystem.md) | [Permissions](file-permissions.md) | [Processes](processes.md) | [Networking](networking.md) | [Users & Groups](users-groups.md) | [Packages](package-management.md) | [Shell Scripting](shell-scripting.md) | [Security](security.md)

# Storage, Disks & Filesystems

Inspecting disk usage, managing partitions, formatting filesystems, and
mounting storage.

**Contents:** [df](#df) · [du](#du) · [mount](#mount) · [umount](#umount) · [lsblk](#lsblk) · [blkid](#blkid) · [fdisk](#fdisk) · [parted](#parted) · [mkfs](#mkfs) · [fsck](#fsck) · [dd](#dd) · [mkswap](#mkswap) · [swapon](#swapon) · [swapoff](#swapoff) · [tune2fs](#tune2fs) · [ncdu](#ncdu) · [smartctl](#smartctl) · [/etc/fstab](#etcfstab-concept)

---

### df
Disk space per **filesystem** (whole partitions/mounts).

```bash
df -hT    # human-readable, with filesystem type
df -i     # inode usage instead of bytes
```

`df` vs `du`: `df` shows whole-filesystem totals; `du` walks files and directories. When you get "No space left on device" but `df -h` shows free space, check `df -i` — you may have exhausted **inodes** (metadata entries), a separate limit that hits directories full of millions of tiny files.

### du
Disk usage per file/directory — the tool for finding what's eating space.

```bash
du -sh /var/log/*                  # total per directory
du -sh /path/* | sort -rh | head   # the classic "what's using all my disk" one-liner
```

- Always add `-s` (summary); bare `du` prints a line for *every* subdirectory.
- `du` and `df` can disagree because of deleted-but-still-open files: a process holding a deleted file keeps its blocks allocated (`df` counts them, `du` can't see them).

### mount / umount
Attach a filesystem to a directory (mount point), and detach it.

```bash
sudo mount /dev/sdb1 /mnt/usb
sudo mount -o ro /dev/sdb1 /mnt/usb      # read-only
mount | grep sdb1                        # list what's mounted
sudo umount /mnt/usb
```

- Linux has one unified tree — no drive letters; storage appears at a directory path.
- Files already in the mount-point directory are temporarily *hidden* (not deleted) while the mount is active.
- **Always `umount` before unplugging** — writes may still be cached. On "target is busy", find the holder with `lsof +D /mnt/usb` (or `fuser -m`) instead of reaching for `umount -f`.

### lsblk
List block devices as a tree — always the **first** command before touching disks, since it's read-only and shows exactly which device is which.

```bash
lsblk -f    # with filesystem type and UUID
```

Watch the difference between a *disk* (`/dev/sdb`) and a *partition* (`/dev/sdb1`) — passing the wrong one to `mkfs`/`mount` is a classic mistake.

### blkid
Show UUIDs and filesystem types of block devices.

```bash
sudo blkid /dev/sda1
```

UUIDs are the recommended way to reference disks in `/etc/fstab` because `/dev/sdX` names can shift between boots when drives are added or removed.

### fdisk
Interactive partition-table editor (MBR, basic GPT).

```bash
sudo fdisk -l          # read-only survey of all disks — safe
sudo fdisk /dev/sdb    # interactive edit of one disk
```

Inside fdisk: `p` print table · `n` new partition · `d` delete · `w` write & exit · `q` quit without writing. Nothing is written until `w`. **One of the highest-risk commands here**: editing the wrong device and pressing `w` destroys that disk's partition table. Triple-check with `lsblk` first.

### parted
GPT-friendly partitioning, required for disks > 2 TB and UEFI setups, and scriptable non-interactively.

```bash
sudo parted /dev/sdb print
sudo parted /dev/sdb mklabel gpt
sudo parted /dev/sdb mkpart primary ext4 0% 100%
```

Unlike `fdisk`, many `parted` commands apply **immediately** — less of a safety net, so be sure before you run them.
### mkfs
Create ("make") a filesystem — this **erases everything** on the target, with no undo.

```bash
sudo mkfs.ext4 /dev/sdb1     # standard Linux choice
sudo mkfs.xfs /dev/sdb1      # RHEL-family default, good for large files
sudo mkfs.vfat /dev/sdb1     # FAT32, for cross-platform USB sticks
sudo mkfs.ntfs /dev/sdb1     # Windows compatibility
```

Confirm the device with `lsblk`/`blkid` first — most variants have no confirmation prompt.

### fsck
Check and repair filesystem corruption (after unclean shutdowns, power loss).

```bash
sudo fsck -y /dev/sdb1    # -y: auto-yes repairs, -f: force full check
```

**Never run `fsck` on a mounted, in-use filesystem** — unmount it first, or check the root filesystem from a live/rescue environment. Auto-repair can move unrecoverable fragments into `lost+found` rather than fully restoring them, so don't run `-y` blindly on data you care about.

### dd
Raw block-level copy — disk imaging, cloning, writing bootable ISOs to USB. Nicknamed "disk destroyer" for a reason.

```bash
sudo dd if=ubuntu-24.04.iso of=/dev/sdb bs=4M status=progress
```

- `dd` has **no filesystem awareness and no confirmation** — the wrong `of=` overwrites that device completely.
- **Read the command back before pressing Enter.** Swapping `if=`/`of=` copies the empty destination *over* your source data, permanently. Also mind disk (`/dev/sdb`) vs partition (`/dev/sdb1`) — bootable ISOs usually want the whole disk.
- `status=progress` is essential; without it `dd` is silent until done. `bs=4M` makes it much faster.

### mkswap / swapon / swapoff
Set up and toggle swap (disk space used as overflow when RAM is full).

```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile       # swap can contain paged-out RAM secrets!
sudo mkswap /swapfile          # format as swap
sudo swapon /swapfile          # activate
swapon -s                      # show active swap areas
free -h                        # confirm the swap total went up
sudo swapoff /swapfile         # deactivate (moves swapped data back to RAM)
```

`mkswap` only *prepares* the area — `swapon` activates it, and an `/etc/fstab` entry makes it persist across reboots. `swapoff` requires enough free RAM to hold whatever was swapped; on a memory-pressured system it can trigger slowdowns or OOM kills.

### tune2fs
View or tune ext2/3/4 filesystem parameters.

```bash
sudo tune2fs -l /dev/sda1    # read-only dump of parameters — always safe
sudo tune2fs -L data /dev/sdb1    # set a filesystem label
```

`tune2fs -l` is a good first look at an ext4 partition's UUID, state, and mount counts. Tuning flags vary in whether they need the filesystem unmounted — check the man page per flag.

### ncdu
Interactive, navigable disk usage analyzer (package: `ncdu`).

```bash
ncdu /var
```

Keys: arrows navigate · `Enter` drill in · `d` delete (destructive — no trash, no undo!) · `q` quit. Far nicer than re-running `du` when hunting for space hogs.

### smartctl
Query a disk's S.M.A.R.T. health data to catch failing drives early (package: `smartmontools`).

```bash
sudo smartctl -H /dev/sda        # overall health verdict
sudo smartctl -a /dev/sda        # full attribute dump
sudo smartctl -t short /dev/sda  # run a short self-test
```

Watch `Reallocated_Sector_Ct` and `Current_Pending_Sector` — rising values are how drives announce they're dying.

### /etc/fstab (concept)
The file that defines which filesystems mount at boot:

```
UUID=a1b2c3d4-e5f6-...  /mnt/data  ext4  defaults  0  2
```

Fields: device (prefer **UUID** via `blkid`), mount point, filesystem type, mount options (`defaults`, `ro`, `noexec`, `nofail`...), `dump` flag (usually 0), and `fsck` pass order (root = 1, others = 2 or 0). Test changes safely with `sudo mount -a` before rebooting — a broken fstab line can stop the system from booting.

---

⬅️ Back to [Users & Groups](users-groups.md) | Next: [Packages](package-management.md) ➡️