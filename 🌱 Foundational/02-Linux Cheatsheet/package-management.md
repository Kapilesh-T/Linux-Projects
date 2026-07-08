[🏠 Home](README.md) | [Navigation](navigation.md) | [Filesystem](filesystem.md) | [Permissions](file-permissions.md) | [Processes](processes.md) | [Networking](networking.md) | [Users & Groups](users-groups.md) | [Storage](storage.md) | [Shell Scripting](shell-scripting.md) | [Security](security.md)

# 📦 Package Management

Commands for installing, updating, and removing software across the major Linux distribution families.

## A Note on Distro Families
Package managers are distro-specific. This page is organized by family so you can jump straight to the tool relevant to your system:

| Family | Distros | Package Manager | Package Format |
|---|---|---|---|
| Debian-based | Ubuntu, Debian, Linux Mint, Kali | `apt` / `apt-get` / `dpkg` | `.deb` |
| Red Hat-based | Fedora, RHEL, CentOS, Rocky, AlmaLinux | `dnf` (modern) / `yum` (legacy) / `rpm` | `.rpm` |
| Arch-based | Arch Linux, Manjaro, EndeavourOS | `pacman` | `.pkg.tar.zst` |
| Universal | Any modern distro | `snap`, `flatpak` | `.snap`, `.flatpak` |

## Table of Contents
1. [apt](#apt) 2. [apt-get](#apt-get) 3. [dpkg](#dpkg) 4. [dnf](#dnf) 5. [yum](#yum) 6. [rpm](#rpm) 7. [pacman](#pacman) 8. [snap](#snap) 9. [flatpak](#flatpak) 10. [pip](#pip) 11. [gem](#gem) 12. [npm](#npm)

---

# apt
## Purpose
The modern, user-friendly package manager for Debian/Ubuntu-based systems.
## Syntax
```
sudo apt [COMMAND]
```
## Common Commands
| Command | Description |
|---|---|
| `update` | Refresh the local package index (does NOT install/upgrade anything itself) |
| `upgrade` | Install available upgrades for all installed packages |
| `install PACKAGE` | Install a package |
| `remove PACKAGE` | Remove a package, keeping its config files |
| `purge PACKAGE` | Remove a package AND its config files |
| `autoremove` | Remove packages that were installed as dependencies and are no longer needed |
| `search KEYWORD` | Search for a package by name/description |
| `show PACKAGE` | Show detailed info about a package |
| `list --installed` | List all currently installed packages |

## Example
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install nginx
```
## Expected Output
```
Reading package lists... Done
Building dependency tree... Done
The following NEW packages will be installed:
  nginx nginx-common nginx-core
```
## Explanation
`apt` was introduced as a friendlier, more visually informative frontend over the older `apt-get`/`apt-cache` tools, consolidating their most common functionality into one consistent command with better default output (progress bars, colorized info).
## Tips
- **Always run `apt update` before `apt install`** on a system you haven't touched recently — otherwise you may install an outdated version or fail to find a newly-released package.
- Use `apt list --upgradable` to preview what `upgrade` would change before committing.
## Common Mistakes
- Confusing `update` (refresh package index/metadata) with `upgrade` (actually install newer package versions) — running only `update` and expecting software to be upgraded is one of the most common beginner mistakes.
- Running `apt upgrade` when a `apt dist-upgrade` (or `full-upgrade`) is needed for changes involving dependency resolution across major version boundaries (e.g., kernel updates).
## Related Commands
[apt-get](#apt-get), [dpkg](#dpkg)

---

# apt-get
## Purpose
The older, more script-stable command-line package manager for Debian/Ubuntu systems, still the backend `apt` builds on.
## Syntax
```
sudo apt-get [COMMAND]
```
## Common Commands
| Command | Description |
|---|---|
| `update` | Refresh package index |
| `install PACKAGE` | Install a package |
| `remove PACKAGE` | Remove a package |
| `clean` | Clear the local package cache of downloaded `.deb` files |

## Example
```bash
sudo apt-get install curl -y
```
## Explanation
`apt-get` has a more stable, predictable output format across versions, which is why it's still often preferred in **scripts and automation** (Dockerfiles, provisioning scripts), while `apt` is preferred for **interactive, human use** due to its nicer output.
## Tips
- In Dockerfiles and CI/CD scripts, `apt-get` is still the more conventional choice for this exact reason — its output format is considered a stable interface, whereas `apt`'s is explicitly documented as subject to change.
## Common Mistakes
- Mixing `apt` and `apt-get` inconsistently in documentation/scripts without realizing they're largely interchangeable for basic operations but differ in scripting stability guarantees.
## Related Commands
[apt](#apt), [dpkg](#dpkg)

---

# dpkg
## Purpose
The low-level package installer that `apt`/`apt-get` are built on top of — directly installs/removes/queries individual `.deb` files.
## Syntax
```
sudo dpkg [OPTIONS] FILE_OR_PACKAGE
```
## Common Options
| Option | Description |
|---|---|
| `-i FILE.deb` | Install a local `.deb` package file |
| `-r PACKAGE` | Remove a package |
| `-l` | List all installed packages |
| `-L PACKAGE` | List all files installed by a package |
| `-S FILE` | Find which package owns a given file |

## Example
```bash
sudo dpkg -i downloaded-app.deb
sudo apt install -f
```
## Expected Output
```
Selecting previously unselected package downloaded-app.
Unpacking downloaded-app (1.2.0) ...
```
## Explanation
`dpkg` handles a single package file in isolation and does **not** automatically resolve or download missing dependencies — that's precisely what `apt`/`apt-get` add on top. This is why `sudo apt install -f` ("fix" broken dependencies) is the standard follow-up after a `dpkg -i` that reports missing dependencies.
## Tips
- Use `dpkg -L PACKAGE` when you need to know exactly which files a specific installed package placed on your system (useful for auditing or troubleshooting).
## Common Mistakes
- Installing a `.deb` with `dpkg -i` and getting dependency errors, then not knowing that `sudo apt install -f` (or `apt --fix-broken install`) is the standard fix.
## Related Commands
[apt](#apt), [apt-get](#apt-get)

---

# dnf
## Purpose
The modern package manager for Fedora and current RHEL/CentOS/Rocky/AlmaLinux releases (successor to `yum`).
## Syntax
```
sudo dnf [COMMAND]
```
## Common Commands
| Command | Description |
|---|---|
| `install PACKAGE` | Install a package |
| `update` (or `upgrade`) | Update all installed packages |
| `remove PACKAGE` | Remove a package |
| `search KEYWORD` | Search for packages |
| `info PACKAGE` | Show detailed package info |
| `list installed` | List installed packages |
| `history` | Show a log of past dnf transactions (and allows `dnf history undo`) |

## Example
```bash
sudo dnf install httpd
sudo dnf update
```
## Expected Output
```
Dependencies resolved.
===========================================
 Package   Arch    Version    Repository  Size
===========================================
Installing:
 httpd     x86_64  2.4.62-1   fedora      1.5 M
```
## Explanation
`dnf` improved on `yum` with faster dependency resolution (using a proper SAT solver), better metadata handling, and a transaction history you can actually roll back — a notable advantage over `apt`, which has no equivalent built-in undo mechanism.
## Tips
- `dnf history` followed by `dnf history undo LAST` is a genuinely useful safety net not present in Debian-based package managers.
## Common Mistakes
- On older RHEL 7/CentOS 7 systems, `dnf` may not be available/default — check whether the system uses `yum` instead before assuming `dnf` syntax works.
## Related Commands
[yum](#yum), [rpm](#rpm)

---

# yum
## Purpose
The legacy package manager for older Red Hat-family systems (RHEL/CentOS 7 and earlier), largely superseded by `dnf`.
## Syntax
```
sudo yum [COMMAND]
```
## Common Commands
| Command | Description |
|---|---|
| `install PACKAGE` | Install a package |
| `update` | Update installed packages |
| `remove PACKAGE` | Remove a package |
| `search KEYWORD` | Search packages |

## Example
```bash
sudo yum install httpd
```
## Explanation
On most current Fedora/RHEL 8+/Rocky/AlmaLinux systems, `yum` is now simply an alias/symlink to `dnf` for backward command compatibility — but the underlying resolution engine and behavior are `dnf`'s.
## Tips
- If working on an older RHEL/CentOS 7 system, expect genuinely different (slower, less capable) behavior than modern `dnf`.
## Common Mistakes
- Assuming `yum` and `dnf` are always functionally identical — on true legacy systems (pre-RHEL 8), meaningful differences exist in dependency resolution speed and reliability.
## Related Commands
[dnf](#dnf), [rpm](#rpm)

---

# rpm
## Purpose
The low-level package installer for `.rpm` files that `dnf`/`yum` are built on top of (parallel to `dpkg` in the Debian world).
## Syntax
```
sudo rpm [OPTIONS] PACKAGE
```
## Common Options
| Option | Description |
|---|---|
| `-i FILE.rpm` | Install a package |
| `-e PACKAGE` | Remove (erase) a package |
| `-qa` | Query all installed packages |
| `-qf FILE` | Find which package owns a given file |
| `-ql PACKAGE` | List files installed by a package |

## Example
```bash
sudo rpm -i custom-app.rpm
rpm -qa | grep nginx
```
## Explanation
Like `dpkg`, `rpm` does not automatically resolve dependencies from remote repositories — that convenience layer is what `dnf`/`yum` add.
## Tips
- `rpm -qf /path/to/file` is a fast way to identify which installed package a given file belongs to, useful in troubleshooting and forensics.
## Common Mistakes
- Installing directly with `rpm -i` and hitting unresolved dependency errors, rather than using `dnf install ./file.rpm`, which properly pulls in dependencies from configured repos.
## Related Commands
[dnf](#dnf), [yum](#yum)

---

# pacman
## Purpose
The package manager for Arch Linux and Arch-based distros (Manjaro, EndeavourOS), known for its simplicity and rolling-release model.
## Syntax
```
sudo pacman [OPTIONS] [PACKAGE]
```
## Common Options
| Option | Description |
|---|---|
| `-S PACKAGE` | Install (Sync) a package from repositories |
| `-Syu` | Sync package databases and upgrade the entire system |
| `-R PACKAGE` | Remove a package |
| `-Rs PACKAGE` | Remove a package and its now-unneeded dependencies |
| `-Ss KEYWORD` | Search for a package |
| `-Q` | Query locally installed packages |

## Example
```bash
sudo pacman -Syu
sudo pacman -S neovim
```
## Expected Output
```
:: Synchronizing package databases...
:: Starting full system upgrade...
resolving dependencies...
```
## Explanation
`pacman`'s flag system is a distinctive single-letter operation model (`-S` sync/install, `-R` remove, `-Q` query) combined with modifier flags, differing structurally from the subcommand style of `apt`/`dnf`.
## Tips
- On Arch's rolling-release model, run `pacman -Syu` regularly (not just occasionally) — infrequent updates on a rolling-release distro increase the risk of complex, harder-to-resolve dependency conflicts.
## Common Mistakes
- Running `pacman -Sy PACKAGE` (sync database, install one package) without the `u` (full upgrade) — this is explicitly discouraged by Arch documentation ("partial upgrades are unsupported") since it can create dependency version mismatches across the system.
## Related Commands
[apt](#apt), [dnf](#dnf)

---

# snap
## Purpose
Install and manage "snap" packages — sandboxed, self-contained applications that bundle their own dependencies, working consistently across many different distros.
## Syntax
```
sudo snap [COMMAND] PACKAGE
```
## Common Commands
| Command | Description |
|---|---|
| `install PACKAGE` | Install a snap |
| `remove PACKAGE` | Remove a snap |
| `list` | List installed snaps |
| `refresh` | Update all installed snaps |
| `info PACKAGE` | Show details about a snap |

## Example
```bash
sudo snap install code --classic
```
## Expected Output
```
code 1.90.0 from Visual Studio Code (vscode✓) installed
```
## Explanation
Snaps are sandboxed (confined) by default for security, bundling their own runtime dependencies — this makes them larger on disk and sometimes slower to start, but avoids the classic "dependency hell" of conflicting library versions across applications.
## Tips
- The `--classic` flag disables sandboxing confinement, required for some development tools (like VS Code) that need broader filesystem access.
## Common Mistakes
- Being surprised by slower first-launch times for snap applications compared to natively-installed `.deb`/`.rpm` equivalents — this is a known trade-off of the sandboxing/mounting mechanism snaps use.
## Related Commands
[flatpak](#flatpak), [apt](#apt)

---

# flatpak
## Purpose
Another cross-distro, sandboxed application packaging and distribution system, similar in goals to `snap` but developed by a different community/vendor (not tied to Canonical/Ubuntu).
## Syntax
```
flatpak [COMMAND]
```
## Common Commands
| Command | Description |
|---|---|
| `install REMOTE PACKAGE` | Install an application |
| `list` | List installed flatpaks |
| `update` | Update installed applications |
| `uninstall PACKAGE` | Remove an application |

## Example
```bash
flatpak install flathub org.gimp.GIMP
```
## Explanation
Flatpak relies on shared "runtimes" (common dependency bundles multiple apps can share) to reduce some of the disk-space overhead that fully self-contained sandboxed formats like early snap versions had.
## Tips
- Flathub (flathub.org) is the primary community app repository for flatpak, analogous to Ubuntu's Snap Store for snaps.
## Common Mistakes
- Assuming `snap` and `flatpak` are interchangeable/compatible — they are separate, competing ecosystems with different sandboxing and distribution models; an app packaged for one won't run via the other's tooling.
## Related Commands
[snap](#snap)

---

# pip
## Purpose
Install and manage Python packages from the Python Package Index (PyPI).
## Syntax
```
pip install [OPTIONS] PACKAGE
```
## Common Options
| Option | Description |
|---|---|
| `install PACKAGE` | Install a package |
| `uninstall PACKAGE` | Remove a package |
| `list` | List installed packages |
| `freeze` | Output installed packages in `requirements.txt` format |
| `install -r requirements.txt` | Install all packages listed in a requirements file |

## Example
```bash
pip install requests
pip freeze > requirements.txt
```
## Expected Output
```
Collecting requests
  Downloading requests-2.32.0-py3-none-any.whl (64 kB)
Successfully installed requests-2.32.0
```
## Explanation
`pip` is language-specific (Python), operating independently of your distro's system package manager — this is precisely why it's strongly recommended to use it inside a **virtual environment** (`python3 -m venv`) rather than installing globally, to avoid version conflicts between projects.
## Tips
- Modern Debian/Ubuntu systems enforce "externally managed environment" protection, blocking global `pip install` outside a virtual environment by default — this is a deliberate safety measure, not a bug, to prevent conflicts with system-managed Python packages.
## Common Mistakes
- Installing packages globally with `sudo pip install` instead of using a project-specific virtual environment, leading to version conflicts between unrelated projects on the same machine.
## Related Commands
[apt](#apt) (for system-level Python itself), [npm](#npm) (equivalent for Node.js)

---

# gem
## Purpose
Install and manage Ruby packages ("gems") from RubyGems.org.
## Syntax
```
gem [COMMAND] PACKAGE
```
## Common Commands
| Command | Description |
|---|---|
| `install PACKAGE` | Install a gem |
| `uninstall PACKAGE` | Remove a gem |
| `list` | List installed gems |
| `update` | Update installed gems |

## Example
```bash
gem install rails
```
## Explanation
Analogous to `pip` for Python or `npm` for Node.js — a language-specific package manager operating independently of the OS-level package manager.
## Tips
- Consider using a Ruby version manager (like `rbenv` or `rvm`) alongside `gem` to isolate gem sets per project, similar to Python virtual environments.
## Common Mistakes
- Installing gems with elevated privileges (`sudo gem install`) system-wide instead of per-project/per-user, which is generally discouraged for the same dependency-conflict reasons as with `pip`.
## Related Commands
[pip](#pip), [npm](#npm)

---

# npm
## Purpose
Install and manage JavaScript/Node.js packages from the npm registry.
## Syntax
```
npm [COMMAND] [PACKAGE]
```
## Common Commands
| Command | Description |
|---|---|
| `install PACKAGE` | Install a package into the current project |
| `install -g PACKAGE` | Install a package globally |
| `install` (no args) | Install all dependencies listed in `package.json` |
| `uninstall PACKAGE` | Remove a package |
| `list` | List installed packages |
| `update` | Update packages to their latest allowed versions |

## Example
```bash
npm install express
npm install
```
## Expected Output
```
added 57 packages, and audited 58 packages in 3s
```
## Explanation
By default, `npm install` installs packages **locally** into a project's `node_modules` folder (tracked via `package.json`/`package-lock.json`), rather than system-wide — the opposite default behavior from most system package managers.
## Tips
- Run `npm audit` periodically to check installed packages for known security vulnerabilities.
- Commit `package-lock.json` to version control to ensure reproducible installs across different machines/environments.
## Common Mistakes
- Using `npm install -g` for project dependencies instead of local installs, which breaks the reproducibility that `package.json`/`package-lock.json` are designed to guarantee across different developers' machines.
## Related Commands
[pip](#pip), [gem](#gem)

---

⬅️ Back to [storage.md](storage.md) | Next: [shell-scripting.md](shell-scripting.md) ➡️
