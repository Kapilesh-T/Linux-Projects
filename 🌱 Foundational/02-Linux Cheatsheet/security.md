[🏠 Home](README.md) | [Navigation](navigation.md) | [Filesystem](filesystem.md) | [Permissions](file-permissions.md) | [Processes](processes.md) | [Networking](networking.md) | [Users & Groups](users-groups.md) | [Storage](storage.md) | [Packages](package-management.md) | [Shell Scripting](shell-scripting.md)

# Security & Hardening

Securing SSH, firewalls, brute-force prevention, encryption, file
integrity, and auditing. Everything here is for defensive, ethical use
on systems you own or are authorized to administer.

**Contents:** [ssh-keygen](#ssh-keygen) · [ssh-copy-id](#ssh-copy-id) · [ufw](#ufw) · [firewalld](#firewalld) · [iptables](#iptables) · [fail2ban](#fail2ban) · [gpg](#gpg) · [openssl](#openssl) · [sha256sum](#sha256sum) · [auditd / ausearch](#auditd--ausearch) · [chkrootkit / rkhunter](#chkrootkit--rkhunter) · [apparmor](#apparmor) · [getenforce / setenforce](#getenforce--setenforce)

---

### ssh-keygen
Generate a public/private key pair for SSH authentication — far better than password login.

```bash
ssh-keygen -t ed25519 -C "kapilesh@laptop"    # ed25519: modern default
ssh-keygen -t rsa -b 4096                      # RSA for legacy systems
```

This creates two files: the **private key** (never share it — it authenticates you) and the **public key** (`.pub` — safe to distribute, this is what goes on servers). Always set a **passphrase**: a stolen key file without one is instant access to every server that trusts it. Use `ssh-agent` + `ssh-add` to unlock once per session instead of retyping. `-b` only matters for RSA; ed25519 keys have a fixed size.

### ssh-copy-id
Append your public key to a server's `~/.ssh/authorized_keys` with correct permissions — the manual way is error-prone.

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub kapilesh@192.168.1.50
```

Confirm basic password SSH works first (so you can tell a network problem from a key problem). Once key login is confirmed, disable password auth server-side: `PasswordAuthentication no` in `/etc/ssh/sshd_config`.

### ufw
"Uncomplicated Firewall" — the friendly Debian/Ubuntu frontend over iptables/nftables.

```bash
sudo ufw allow 22/tcp                        # BEFORE enabling, on remote servers!
sudo ufw allow from 192.168.1.0/24 to any port 5432
sudo ufw deny 23
sudo ufw delete allow 23
sudo ufw enable
sudo ufw status verbose
```

**The classic lockout**: enabling ufw on a remote server without first allowing SSH cuts your own session — with no way back in except console access. Allow the SSH port *before* `enable`.

### firewalld
The Fedora/RHEL-family firewall manager, organized by **zones** (public, internal, trusted...) for different trust levels.

```bash
sudo firewall-cmd --state
sudo firewall-cmd --list-all
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload
```

Rules without `--permanent` vanish on the next reload/reboot; permanent rules don't take effect until `--reload` — you usually need both.

### iptables
The traditional low-level firewall tool — direct access to the kernel's netfilter. `ufw` and `firewalld` are convenience layers over this (or its successor, nftables).

```bash
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT   # append a rule
sudo iptables -P INPUT DROP                          # set default policy
sudo iptables -L -v                                  # list rules with counters
```

- Rules are evaluated **top to bottom, first match wins** — order matters.
- Rules are **not persistent** across reboots unless saved (`iptables-persistent` on Debian/Ubuntu, or `iptables-save` wired into boot).
- Setting a `DROP` default policy over SSH without an ACCEPT rule for SSH first locks you out instantly.
### fail2ban
Watch logs for repeated failed logins and automatically firewall-ban the offenders — the standard SSH brute-force defense.

```bash
sudo fail2ban-client status sshd     # bans, failures, current banned IPs
sudo fail2ban-client set sshd unbanip 203.0.113.7   # manual unban
```

Works by matching failure patterns in log files (`/var/log/auth.log`) and adding a temporary firewall rule past a threshold. Configure extra jails in `/etc/fail2ban/jail.local` for anything with a predictable failure log — web login forms, mail, etc. Know the unban command before you lock *yourself* out testing keys.

### gpg
Encrypt, decrypt, sign, and verify files (GnuPG / OpenPGP).

```bash
gpg --gen-key
gpg -e -r alex@example.com report.pdf    # encrypt for a recipient's public key
gpg -d report.pdf.gpg > report.pdf       # decrypt with your private key
gpg --sign file.tar.gz
gpg --verify file.tar.gz.sig
```

**Asymmetric encryption**: anyone can encrypt to a recipient's *public* key; only the *private* key holder can decrypt — the same principle as SSH keys, applied to files and signatures. Distro repos sign packages with GPG; verify signatures on security-sensitive downloads. There is no "forgot password": lose the private key with no backup and everything encrypted to it is gone.

### openssl
The cryptography workhorse: keys, certificates, TLS inspection, hashing, randomness.

```bash
openssl req -new -x509 -days 365 -out cert.pem -keyout key.pem   # self-signed cert
openssl s_client -connect example.com:443 -servername example.com </dev/null
openssl dgst -sha256 file.iso
openssl rand -hex 16        # crypto-random bytes for tokens/secrets
```

`s_client` is the first diagnostic for HTTPS certificate problems (expired, wrong chain, cipher mismatch). Self-signed certs always show browser warnings — they lack a recognized CA signature.

### sha256sum
Compute/verify a file's SHA-256 hash — the standard download-integrity check.

```bash
sha256sum ubuntu-24.04-desktop-amd64.iso
sha256sum -c SHA256SUMS        # verify against a checksum file
```

One changed bit produces a completely different hash, so a mismatch means corruption or tampering. Get the expected hash from the **publisher's official site** (ideally GPG-signed) — comparing against a checksum from the same untrusted mirror verifies nothing.

### auditd / ausearch
Kernel-level auditing: tamper-resistant logs of exactly who touched what (package: `auditd`; usually not enabled by default).

```bash
sudo auditctl -w /etc/passwd -p wa -k passwd_changes   # watch rule (w=write a=attr)
sudo ausearch -k passwd_changes                        # query by key
sudo ausearch -m USER_LOGIN -ts today                  # by event type/time
```

Unlike application logs, auditd hooks syscalls — the trail required by compliance frameworks (PCI-DSS, HIPAA). Rules set with `auditctl` are **not persistent** unless also written to `/etc/audit/rules.d/`.

### chkrootkit / rkhunter
Scan for known rootkits, backdoors, and tampering indicators (unexpected SUID binaries, hidden processes).

```bash
sudo rkhunter --update
sudo rkhunter --check
sudo chkrootkit
```

These are **detective, not preventive** — one layer among many (firewall, fail2ban, patching, least privilege). False positives are common; investigate flags rather than panicking. A clean scan isn't proof of no compromise — sophisticated rootkits evade signature-based detection by design.
### apparmor
Query AppArmor — a Linux Security Module that restricts each program to a per-application profile (what files it may read/write, what it may execute).

```bash
sudo aa-status
```

Shows loaded profiles and whether they're in `enforce` (blocking) or `complain` (log-only) mode. Default on Ubuntu; profiles live in `/etc/apparmor.d/`.

### getenforce / setenforce
Query and switch SELinux mode — the RHEL/Fedora/CentOS equivalent of AppArmor.

```bash
getenforce                 # Enforcing | Permissive | Disabled
sudo setenforce 0          # switch to Permissive (logging, no blocking)
sudo setenforce 1          # back to Enforcing
sestatus                   # full status: mode, policy, exceptions
```

Permissive mode logs violations without enforcing — useful for diagnosing which rule is breaking an app. **Don't disable SELinux entirely** to "fix" a permission problem: diagnose it and write a proper policy exception (`audit2allow`) — disabling removes a major part of the system's security posture.

---

⬅️ Back to [Shell Scripting](shell-scripting.md) | [🏠 Home](README.md) ➡️