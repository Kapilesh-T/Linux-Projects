# Linux Projects

A learning portfolio of Linux, Bash and security-related utilities and reference notes. Each project has its own README with setup and usage instructions.

## Project index

| Level | Project | What it demonstrates |
| --- | --- | --- |
| Foundational | [01 — Password Generator](%F0%9F%8C%B1%20Foundational/01-Password%20Generator/README.md) | Configurable random password generation, strength indication, clipboard integration and optional file output. |
| Foundational | [02 — Linux Cheatsheet](%F0%9F%8C%B1%20Foundational/02-Linux%20Cheatsheet/README.md) | Reference notes on navigation, filesystems, permissions, processes, networking, users and groups, storage, packages, shell scripting and security. |
| Applied | [03 — System Reporter](%E2%9A%99%EF%B8%8F%20Applied/03-%20SYSTEM%20REPORTER/README.md) | Reporting on OS, CPU, memory, disk, network, users, connectivity and top processes. |
| Applied | [04 — File Organizer](%E2%9A%99%EF%B8%8F%20Applied/04-%20FILE%20ORGANIZER/README.md) | File categorization, dry-run, recursive processing, logging, undo, modular Bash code and a regression test suite. |

## Getting started

Clone the repository:

```bash
git clone https://github.com/Kapilesh-T/Linux-Projects.git
cd Linux-Projects
```

Open the README for the project you want to explore. Follow its requirements and usage instructions before running any scripts.

### Requirements

- Linux with Bash 4.3 or newer (required by the File Organizer).
- Standard Linux command-line utilities; some optional features require additional tools. Refer to individual project documentation.

## Safety and testing

- These are educational projects, not production security tools.
- Test file-moving operations in a disposable directory with sample files first. Use the File Organizer's dry-run option and keep backups of important data.
- The Password Generator's optional file output stores passwords in plaintext. Avoid saving real credentials through that feature or committing generated passwords.
- Review scripts before execution; use ordinary user privileges unless a specific operation requires otherwise.
- A regression test suite is included for the File Organizer. No test-pass or compatibility claims are made here without execution evidence.
- See [SECURITY.md](SECURITY.md) for vulnerability reporting and project scope.

## Planned learning projects

User and group management, authorized network scanning, log analysis, SSH auditing, file integrity monitoring, disk usage analysis, process and service monitoring, backup and restore, firewall management and server hardening.

These are planned learning topics, not completed implementations.

## Author and license

Kapilesh T — [GitHub](https://github.com/Kapilesh-T) · [LinkedIn](https://www.linkedin.com/in/kapilesh-t/)

MIT — see [LICENSE](LICENSE).
