[🏠 Home](README.md) | [Navigation](navigation.md) | [Filesystem](filesystem.md) | [Permissions](file-permissions.md) | [Processes](processes.md) | [Networking](networking.md) | [Users & Groups](users-groups.md) | [Storage](storage.md) | [Shell Scripting](shell-scripting.md) | [Security](security.md)

# Package Management

Installing, updating, and removing software. Package managers are
distro-specific, so this page is organized by family:

| Family | Distros | Manager | Format |
|---|---|---|---|
| Debian-based | Ubuntu, Debian, Mint, Kali | `apt` / `apt-get` / `dpkg` | `.deb` |
| Red Hat-based | Fedora, RHEL, CentOS, Rocky, Alma | `dnf` / `yum` / `rpm` | `.rpm` |
| Arch-based | Arch, Manjaro, EndeavourOS | `pacman` | `.pkg.tar.zst` |
| Universal | any distro | `snap`, `flatpak` | sandboxed apps |

**Contents:** [apt](#apt) · [apt-get](#apt-get) · [dpkg](#dpkg) · [dnf](#dnf) · [yum](#yum) · [rpm](#rpm) · [pacman](#pacman) · [snap](#snap) · [flatpak](#flatpak) · [pip](#pip) · [gem](#gem) · [npm](#npm)

---

### apt
The Debian/Ubuntu package manager.

```bash
sudo apt update && sudo apt upgrade -y   # refresh index, then upgrade
sudo apt install nginx
sudo apt remove nginx        # remove, keep config files
sudo apt purge nginx         # remove including config files
sudo apt autoremove          # drop orphaned dependencies
apt search keyword / apt show nginx / apt list --installed
```

- `update` refreshes the package *index*; `upgrade` actually installs new versions — running only `update` upgrades nothing.
- Run `apt update` before installing on a system you haven't touched in a while.
- `apt list --upgradable` previews what `upgrade` would change. Dependency-resolution-heavy updates (e.g. kernels) may need `apt full-upgrade`.

### apt-get
The older backend `apt` wraps. Output format is stable across versions, which is why **scripts, Dockerfiles, and CI** conventionally use `apt-get`, while humans use `apt`.

```bash
sudo apt-get install -y curl
sudo apt-get clean     # clear downloaded .deb cache
```

### dpkg
The low-level `.deb` installer `apt` is built on. It installs a single package file but does **not** resolve dependencies — that's what `apt` adds.

```bash
sudo dpkg -i app.deb
sudo apt install -f          # "fix broken": standard follow-up for missing deps
dpkg -l                      # all installed packages
dpkg -L nginx                # every file a package installed
dpkg -S /etc/nginx/nginx.conf    # which package owns this file?
```

### dnf
Fedora / RHEL 8+ / Rocky / Alma package manager (successor to `yum`).

```bash
sudo dnf install httpd
sudo dnf update
dnf search keyword / dnf info httpd / dnf list installed
dnf history && dnf history undo last
```

`dnf history` + `history undo` is a rollback mechanism apt doesn't have. On old RHEL/CentOS 7 boxes `dnf` isn't there — use `yum`.

### yum
The legacy Red Hat-family manager (pre-RHEL 8). On modern systems `yum` is just a symlink to `dnf`, but on genuinely old systems it's the slower, less capable original. Same subcommand style: `yum install httpd`.

### rpm
The low-level `.rpm` installer (parallel to `dpkg`); no automatic dependency resolution.

```bash
sudo rpm -i custom-app.rpm    # prefer: sudo dnf install ./custom-app.rpm
rpm -qa | grep nginx          # query all installed
rpm -qf /usr/sbin/nginx       # which package owns a file?
rpm -ql nginx                 # list a package's files
```

`rpm -qf FILE` is a quick way to trace a mystery file back to its package.

### pacman
Arch Linux's package manager — single-letter flags: `S` sync/install, `R` remove, `Q` query.

```bash
sudo pacman -Syu        # sync databases + full system upgrade
sudo pacman -S neovim   # install one package
sudo pacman -Rns pkg    # remove with deps + config
pacman -Ss keyword / pacman -Q
```

- **`pacman -Syu` regularly.** Arch is rolling-release, and partial upgrades (`pacman -Sy pkg` without the `u`) are officially unsupported — they create dependency version mismatches.

### snap
Sandboxed, self-contained apps that bundle their own dependencies; works across distros (Canonical's system).

```bash
sudo snap install code --classic    # --classic: disable confinement (dev tools need it)
sudo snap refresh                   # update all snaps
snap list / snap remove code
```

Snaps are larger on disk and slower to start than native packages — the trade-off for bundled dependencies and automatic updates.

### flatpak
A second cross-distro sandboxed app system (community-driven, app source: Flathub). Uses shared runtimes to reduce the disk overhead.

```bash
flatpak install flathub org.gimp.GIMP
flatpak list / flatpak update
```

Snap and flatpak are **separate ecosystems** — an app packaged for one won't install via the other.
### pip
Python's package manager (PyPI). Language managers run independently of the OS package manager.

```bash
pip install requests
pip install -r requirements.txt
pip freeze > requirements.txt    # snapshot installed packages
```

Use `pip` inside a **virtual environment** (`python3 -m venv`), not globally — modern Debian/Ubuntu even block global installs by default ("externally managed environment"), which is a deliberate guard against clobbering system-managed Python packages, not a bug. `sudo pip install` into the system Python is the classic way to break a distro.

### gem
Ruby's package manager (RubyGems.org).

```bash
gem install rails
gem list / gem update
```

Use a version manager (`rbenv`, `rvm`) to isolate gem sets per project, the Ruby equivalent of Python virtual environments. Avoid `sudo gem install` for the same dependency-conflict reasons as pip.

### npm
Node.js/JavaScript package manager.

```bash
npm install express    # local to the project (node_modules)
npm install            # install everything from package.json
npm install -g pkg     # global — for CLI tools, not project deps
npm audit              # check for known vulnerabilities
```

By default `npm install` is **local** (per project, tracked in `package.json` + `package-lock.json`) — the opposite default from system package managers. Commit `package-lock.json` so installs are reproducible across machines; use `-g` only for command-line tools.

---

⬅️ Back to [Storage](storage.md) | Next: [Shell Scripting](shell-scripting.md) ➡️