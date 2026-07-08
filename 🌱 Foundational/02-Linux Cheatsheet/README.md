# 🐧 Linux Cheatsheet Wiki

A professional, beginner-friendly, technically accurate reference guide to essential Linux commands — organized by category, documented like real system administration documentation.

![Linux](https://img.shields.io/badge/OS-Linux-informational)
![Markdown](https://img.shields.io/badge/Docs-Markdown-blue)
![License](https://img.shields.io/badge/License-MIT-green)
![Status](https://img.shields.io/badge/Status-Active-brightgreen)

---

## 📖 Project Overview

**Linux Cheatsheet Wiki** is a structured, categorized reference to the most important Linux commands used in daily system administration, DevOps, cybersecurity, and software development work.

Unlike scattered blog posts or single-page cheatsheets, this project documents each command the way real internal engineering documentation does:

- What the command does and **why** it matters
- Full **syntax** and the options actually used in practice
- **Practical, copy-pasteable examples** with expected output
- **Beginner tips** to avoid confusion
- **Common mistakes** that trip up new Linux users
- **Related commands** so you can build a mental map of the ecosystem

This project is designed to be useful both as a **learning resource** for people new to Linux and as a **fast lookup reference** for experienced administrators, security professionals, and developers.

---

## ✨ Features

- ✅ 10 fully documented command categories
- ✅ 250+ individual command references
- ✅ Consistent, professional Markdown formatting
- ✅ Real terminal output examples
- ✅ Cross-linked navigation between topics
- ✅ Written for beginners, technically accurate for professionals
- ✅ Security and best-practice notes throughout
- ✅ 100% offline — clone it and read it anywhere, no internet required

---

## 📑 Table of Contents

| # | Page | Description |
|---|------|--------------|
| 1 | [navigation.md](navigation.md) | Moving around the filesystem: `cd`, `pwd`, `ls`, `tree`, and more |
| 2 | [filesystem.md](filesystem.md) | Creating, copying, moving, and inspecting files and directories |
| 3 | [file-permissions.md](file-permissions.md) | Ownership, permissions, `chmod`, `chown`, ACLs, `umask` |
| 4 | [processes.md](processes.md) | Process monitoring and control: `ps`, `top`, `kill`, `systemctl`, jobs |
| 5 | [networking.md](networking.md) | Network diagnostics and configuration: `ip`, `ping`, `ss`, `curl`, `ssh` |
| 6 | [users-groups.md](users-groups.md) | User and group administration: `useradd`, `passwd`, `sudo`, `groups` |
| 7 | [storage.md](storage.md) | Disks, partitions, mounting, and disk usage: `df`, `du`, `mount`, `fdisk` |
| 8 | [package-management.md](package-management.md) | Installing software: `apt`, `dnf`, `yum`, `pacman`, `snap` |
| 9 | [shell-scripting.md](shell-scripting.md) | Bash scripting essentials: variables, loops, conditionals, `grep`, `awk`, `sed` |
| 10 | [security.md](security.md) | Hardening and auditing: `ufw`, `iptables`, `fail2ban`, `ssh-keygen`, auditing tools |

Also see: [navigation.md](navigation.md) for the full cross-page navigation index.

---

## 🗂 Repository Structure

```
linux-cheatsheet/
│
├── README.md                 # This file — project overview
├── navigation.md             # Filesystem navigation commands
├── filesystem.md             # File & directory operations
├── file-permissions.md       # Permissions, ownership, ACLs
├── processes.md               # Process & service management
├── networking.md             # Network tools & diagnostics
├── users-groups.md           # User & group administration
├── storage.md                 # Disks, partitions, mounts
├── package-management.md     # Package managers (apt/dnf/pacman/snap)
├── shell-scripting.md         # Bash scripting reference
├── security.md                 # Security & hardening commands
│
└── images/                   # Diagrams and screenshots (placeholder)
    └── .gitkeep
```

---

## 🎯 Learning Objectives

By working through this documentation, you should be able to:

1. Confidently navigate and manipulate the Linux filesystem from the terminal.
2. Understand and correctly apply the Linux permission model (owner/group/other, `rwx`, octal notation, ACLs).
3. Monitor, manage, and troubleshoot running processes and system services (including `systemd`).
4. Diagnose and configure basic network connectivity and inspect open ports/connections.
5. Administer local users and groups, and understand privilege escalation via `sudo`.
6. Manage disks, partitions, and filesystems, and understand mounting and disk usage reporting.
7. Install, update, and remove software using the correct package manager for major distributions.
8. Write basic to intermediate Bash scripts using variables, loops, conditionals, and text-processing tools.
9. Apply foundational security hardening practices: firewalls, SSH key authentication, intrusion prevention, and auditing.
10. Build the habit of reading `man` pages and `--help` output as the authoritative source of truth (this wiki is a companion to those, not a replacement).

**Recommended learning path for beginners:**
`navigation.md` → `filesystem.md` → `file-permissions.md` → `processes.md` → `users-groups.md` → `package-management.md` → `storage.md` → `networking.md` → `shell-scripting.md` → `security.md`

---

## 🤝 How to Contribute

Contributions are welcome and encouraged — this project is meant to grow as a community reference.

1. **Fork** this repository.
2. Create a feature branch:
   ```bash
   git checkout -b add-command-xyz
   ```
3. Follow the existing documentation format for any new command entry:
   ```markdown
   # command-name
   ## Purpose
   ## Syntax
   ## Common Options
   ## Example
   ## Expected Output
   ## Explanation
   ## Tips
   ## Common Mistakes
   ## Related Commands
   ```
4. Test every command example on a real Linux system before submitting — **do not submit unverified output**.
5. Commit your changes with a clear message:
   ```bash
   git commit -m "Add: documentation for <command>"
   ```
6. Push your branch and open a **Pull Request** describing what was added or changed.

### Contribution Guidelines
- Keep formatting consistent with existing pages.
- Prefer real, tested example output over guessed output.
- Note distro-specific differences explicitly (e.g., Debian/Ubuntu vs RHEL/Fedora vs Arch) rather than assuming one distro.
- Security-related commands must include safe, ethical usage context.
- Avoid duplicate entries — check existing pages first.

---

## 📜 License

This project is licensed under the **MIT License**.

```
MIT License

Copyright (c) 2026 Linux Cheatsheet Wiki Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (this project), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
```

---

## 🧭 Quick Navigation

⬅️ Start here: [navigation.md](navigation.md) &nbsp; | &nbsp; Full index: see table of contents above

**Disclaimer:** Commands involving destructive operations (`rm -rf`, `dd`, `mkfs`, `fdisk`, etc.) are documented for educational purposes. Always test in a virtual machine or non-production environment first, and maintain backups before running any command you don't fully understand.
