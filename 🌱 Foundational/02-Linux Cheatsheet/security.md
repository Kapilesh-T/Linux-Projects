[🏠 Home](README.md) | [Navigation](navigation.md) | [Filesystem](filesystem.md) | [Permissions](file-permissions.md) | [Processes](processes.md) | [Networking](networking.md) | [Users & Groups](users-groups.md) | [Storage](storage.md) | [Packages](package-management.md) | [Shell Scripting](shell-scripting.md)

# 🛡️ Security & Hardening

Commands for securing SSH access, configuring firewalls, preventing brute-force attacks, and auditing system security. All content here is intended for **defensive, ethical, and legal use on systems you own or are authorized to administer.**

## Table of Contents
1. [ssh-keygen](#ssh-keygen) 2. [ssh-copy-id](#ssh-copy-id) 3. [ufw](#ufw) 4. [firewalld](#firewalld) 5. [iptables](#iptables) 6. [fail2ban](#fail2ban) 7. [gpg](#gpg) 8. [openssl](#openssl) 9. [sha256sum](#sha256sum) 10. [auditd / ausearch](#auditd--ausearch) 11. [chkrootkit / rkhunter](#chkrootkit--rkhunter) 12. [apparmor / aa-status](#apparmor--aa-status) 13. [getenforce / setenforce](#getenforce--setenforce)

---

# ssh-keygen
## Purpose
Generate a public/private cryptographic key pair for SSH authentication (far more secure than password-based login).
## Syntax
```
ssh-keygen [OPTIONS]
```
## Common Options
| Option | Description |
|---|---|
| `-t TYPE` | Key algorithm (`ed25519` recommended; `rsa` for legacy compatibility) |
| `-b BITS` | Key size in bits (relevant for RSA; e.g., `-b 4096`) |
| `-C "comment"` | Add a label comment (commonly an email/identifier) |
| `-f FILENAME` | Output file path for the key |

## Example
```bash
ssh-keygen -t ed25519 -C "kapilesh@laptop"
```
## Expected Output
```
Generating public/private ed25519 key pair.
Enter file in which to save the key (/home/kapilesh/.ssh/id_ed25519):
Enter passphrase (empty for no passphrase):
Your identification has been saved in /home/kapilesh/.ssh/id_ed25519
Your public key has been saved in /home/kapilesh/.ssh/id_ed25519.pub
```
## Explanation
Generates two files: a **private key** (never share this — it authenticates you) and a **public key** (`.pub` — safe to share, this is what gets placed on remote servers). `ed25519` is the modern recommended algorithm — smaller keys, faster, and cryptographically stronger than older RSA key sizes commonly still in use.
## Tips
- **Always set a passphrase** on your private key — this ensures that even if the key file is stolen, it can't be used without also knowing the passphrase.
- Use `ssh-agent` combined with `ssh-add` to unlock your key once per session instead of retyping the passphrase for every connection.
## Common Mistakes
- Never having set a passphrase, meaning a stolen laptop or leaked key file grants immediate, unrestricted access to every server that trusts it.
- Accidentally sharing the private key file (no `.pub` extension) instead of the public key when setting up server access.
## Related Commands
[ssh-copy-id](#ssh-copy-id), [ssh](networking.md#ssh)

---

# ssh-copy-id
## Purpose
Copy your public SSH key to a remote server's authorized keys list, enabling passwordless key-based login.
## Syntax
```
ssh-copy-id USER@HOST
```
## Example
```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub kapilesh@192.168.1.50
```
## Expected Output
```
Number of key(s) added: 1
Now try logging into the machine, with:   "ssh 'kapilesh@192.168.1.50'"
```
## Explanation
Automates what would otherwise be a manual process: appending your public key to the remote server's `~/.ssh/authorized_keys` file with correct permissions — a common source of manual errors this tool avoids.
## Tips
- After confirming key-based login works, disable password authentication server-side (`PasswordAuthentication no` in `/etc/ssh/sshd_config`) to substantially reduce brute-force attack surface.
## Common Mistakes
- Running this before confirming basic password-based SSH connectivity even works, making it hard to distinguish a network issue from a key-setup issue.
## Related Commands
[ssh-keygen](#ssh-keygen), [ssh](networking.md#ssh)

---

# ufw
## Purpose
"Uncomplicated Firewall" — a simplified, user-friendly frontend for managing firewall rules on Debian/Ubuntu systems (built on top of `iptables`/`nftables`).
## Syntax
```
sudo ufw [COMMAND]
```
## Common Commands
| Command | Description |
|---|---|
| `enable` / `disable` | Turn the firewall on/off |
| `status verbose` | Show current rules and firewall state |
| `allow PORT` | Allow traffic on a port (e.g., `ufw allow 22`) |
| `deny PORT` | Block traffic on a port |
| `allow from IP` | Allow traffic only from a specific IP |
| `delete RULE` | Remove a specific rule |

## Example
```bash
sudo ufw allow 22/tcp
sudo ufw allow from 192.168.1.0/24 to any port 5432
sudo ufw enable
```
## Expected Output
```
Rules updated
Firewall is active and enabled on system startup
```
## Explanation
`ufw` abstracts away the more complex, error-prone raw syntax of `iptables`, making common firewall tasks (allow/deny specific ports or IP ranges) far more approachable while still ultimately configuring the same underlying kernel packet-filtering rules.
## Tips
- **Critical safety step:** always explicitly allow your SSH port (`ufw allow 22` or your custom SSH port) *before* running `ufw enable` on a remote server — enabling the firewall with the default-deny policy before allowing SSH will lock you out immediately with no way back in except console/physical access.
## Common Mistakes
- Enabling `ufw` on a remote server without first allowing the SSH port, permanently severing the remote session (a very common, painful mistake for beginners).
## Related Commands
[iptables](#iptables), [firewalld](#firewalld)

---

# firewalld
## Purpose
The default dynamic firewall management tool on Fedora/RHEL/CentOS systems, using the concept of "zones" for different trust levels.
## Syntax
```
sudo firewall-cmd [OPTIONS]
```
## Common Options
| Option | Description |
|---|---|
| `--state` | Check if firewalld is running |
| `--list-all` | Show current zone's rules |
| `--add-port=PORT/PROTO` | Open a port (temporary, until reload/reboot) |
| `--permanent` | Make a rule change persistent across reloads |
| `--reload` | Apply permanent changes |

## Example
```bash
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload
```
## Expected Output
```
success
success
```
## Explanation
`firewalld`'s "zone" concept (e.g., `public`, `internal`, `trusted`) lets you apply different rule sets depending on network context — useful for laptops that move between trusted home networks and untrusted public Wi-Fi.
## Tips
- Always pair rule changes with `--permanent` (to persist) AND run `--reload` afterward — without `--permanent`, changes are lost on the next reload/reboot; without `--reload`, permanent changes don't take effect immediately.
## Common Mistakes
- Adding a rule without `--permanent`, testing successfully, then losing the rule entirely after the next system reboot or firewall reload.
## Related Commands
[ufw](#ufw), [iptables](#iptables)

---

# iptables
## Purpose
The traditional low-level Linux kernel firewall configuration tool, operating directly on packet-filtering rule chains.
## Syntax
```
sudo iptables [OPTIONS]
```
## Common Options
| Option | Description |
|---|---|
| `-L -v` | List current rules with packet/byte counters |
| `-A CHAIN` | Append a new rule to a chain (INPUT, OUTPUT, FORWARD) |
| `-P CHAIN POLICY` | Set the default policy for a chain (ACCEPT/DROP) |
| `-j TARGET` | Jump to a target action (ACCEPT, DROP, REJECT) |

## Example
```bash
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -L -v
```
## Expected Output
```
Chain INPUT (policy ACCEPT)
target     prot opt source       destination
ACCEPT     tcp  --  anywhere     anywhere    tcp dpt:ssh
```
## Explanation
`iptables` is the direct interface to the kernel's `netfilter` packet filtering framework. `ufw` and `firewalld` are both convenience layers built on top of this same underlying mechanism (or its modern successor, `nftables`).
## Tips
- Rules are evaluated top-to-bottom in order within a chain, and the **first matching rule wins** — rule order is critical, unlike some other firewall tools where all matching rules are considered.
- **`iptables` rules are NOT persistent by default** — they're lost on reboot unless explicitly saved (e.g., via `iptables-save` combined with a restore-on-boot mechanism, or the `iptables-persistent` package on Debian/Ubuntu).
## Common Mistakes
- Setting a default `DROP` policy on the INPUT chain via SSH without first ensuring an ACCEPT rule for SSH is already in place — this immediately disconnects and locks out the very session used to make the change.
- Forgetting rules aren't persistent, then being surprised the firewall "reset" after a routine server reboot.
## Related Commands
[ufw](#ufw), [firewalld](#firewalld)

---

# fail2ban
## Purpose
Monitor log files for repeated failed authentication attempts and automatically ban offending IP addresses via firewall rules.
## Syntax
```
sudo fail2ban-client [COMMAND]
```
## Common Commands
| Command | Description |
|---|---|
| `status` | Show active jails (monitored services) |
| `status JAIL` | Show details for a specific jail (e.g., `sshd`), including currently banned IPs |
| `set JAIL unbanip IP` | Manually unban an IP |
| `set JAIL banip IP` | Manually ban an IP |

## Example
```bash
sudo fail2ban-client status sshd
```
## Expected Output
```
Status for the jail: sshd
|- Currently failed: 3
|- Total failed:     47
`- Currently banned: 2
   `- IP list:   203.0.113.7 198.51.100.22
```
## Explanation
`fail2ban` watches log files (like `/var/log/auth.log`) for patterns matching failed login attempts, and after a configurable threshold of failures within a time window, automatically adds a temporary firewall rule blocking that IP — a critical, widely-used defense against SSH brute-force attacks.
## Tips
- Configure custom "jails" (in `/etc/fail2ban/jail.local`) for any service with a predictable log-based failure pattern, not just SSH — web application login forms, mail servers, etc.
## Common Mistakes
- Locking yourself out by triggering the ban threshold with your own repeated failed login attempts (e.g., testing SSH key setup) — always know the unban command (`fail2ban-client set sshd unbanip YOUR_IP`) or have console access as a backup.
## Related Commands
[ufw](#ufw), [journalctl](processes.md#journalctl)

---

# gpg
## Purpose
Encrypt, decrypt, sign, and verify files and messages using GnuPG (an implementation of the OpenPGP standard).
## Syntax
```
gpg [OPTIONS]
```
## Common Options
| Option | Description |
|---|---|
| `--gen-key` | Generate a new key pair |
| `-e -r RECIPIENT FILE` | Encrypt a file for a specific recipient's public key |
| `-d FILE` | Decrypt a file |
| `--sign FILE` | Cryptographically sign a file |
| `--verify FILE.sig` | Verify a file's signature |

## Example
```bash
gpg -e -r alex@example.com report.pdf
gpg -d report.pdf.gpg > report.pdf
```
## Expected Output
```
(creates report.pdf.gpg — an encrypted file only alex's private key can decrypt)
```
## Explanation
GPG uses **asymmetric encryption**: anyone can encrypt data using a recipient's *public* key, but only the holder of the corresponding *private* key can decrypt it — the same underlying cryptographic principle used by SSH keys, but applied to file/message encryption and digital signatures rather than authentication.
## Tips
- Package maintainers and software repositories commonly use GPG signatures to let users verify a downloaded package hasn't been tampered with — always verify signatures for security-sensitive downloads when checksums/signatures are provided.
## Common Mistakes
- Losing a private key with no backup, permanently losing access to everything encrypted for it (there is no "forgot password" recovery for lost GPG keys).
## Related Commands
[ssh-keygen](#ssh-keygen), [openssl](#openssl)

---

# openssl
## Purpose
A comprehensive cryptography toolkit: generate certificates/keys, encrypt/decrypt data, and inspect TLS/SSL connections.
## Syntax
```
openssl [COMMAND] [OPTIONS]
```
## Common Commands
| Command | Description |
|---|---|
| `req -new -x509 -days 365 -out cert.pem` | Generate a self-signed TLS certificate |
| `s_client -connect HOST:443` | Test/inspect a remote server's TLS connection and certificate |
| `dgst -sha256 FILE` | Compute a file's SHA-256 hash |
| `rand -hex 16` | Generate cryptographically random data (e.g., for secrets/tokens) |

## Example
```bash
openssl s_client -connect example.com:443 -servername example.com </dev/null
```
## Expected Output
```
Certificate chain
 0 s:CN=example.com
   i:C=US, O=Let's Encrypt, CN=R3
...
Verify return code: 0 (ok)
```
## Explanation
`openssl` is the workhorse behind much of Linux's cryptography and TLS infrastructure — used both for generating certificates/keys and for diagnosing HTTPS/TLS connection issues (expired certificates, wrong certificate chains, cipher mismatches).
## Tips
- `openssl s_client -connect HOST:443` is a standard first diagnostic step when a website's HTTPS certificate is suspected to be misconfigured or expired.
## Common Mistakes
- Generating a self-signed certificate and expecting browsers to trust it by default — self-signed certs will always show a browser warning unless manually trusted, since they lack a recognized certificate authority signature.
## Related Commands
[gpg](#gpg)

---

# sha256sum
## Purpose
Compute (or verify) the SHA-256 cryptographic hash of a file — used to confirm file integrity, especially for verifying downloads.
## Syntax
```
sha256sum [OPTIONS] FILE
```
## Common Options
| Option | Description |
|---|---|
| `-c FILE` | Verify hashes against a checksum file |

## Example
```bash
sha256sum ubuntu-24.04-desktop-amd64.iso
sha256sum -c SHA256SUMS
```
## Expected Output
```
a1b2c3d4e5f6...  ubuntu-24.04-desktop-amd64.iso
ubuntu-24.04-desktop-amd64.iso: OK
```
## Explanation
Even a single changed bit in a file produces a completely different hash output, making this the standard method to verify a downloaded file (an ISO, a software package) hasn't been corrupted in transit or tampered with, by comparing against a hash the publisher provides through a trusted channel.
## Tips
- Always fetch the expected checksum from the **official** publisher's site (ideally over HTTPS, or better, GPG-signed) — comparing a downloaded file against a checksum from the same untrusted source it came from provides no real security benefit.
## Common Mistakes
- Verifying a checksum but obtaining both the file and the checksum from the same potentially-compromised mirror, defeating the purpose of the verification entirely.
## Related Commands
[gpg](#gpg), [openssl](#openssl)

---

# auditd / ausearch
## Purpose
Kernel-level auditing subsystem (`auditd`) and its query tool (`ausearch`) for logging and reviewing security-relevant system events (file access, authentication, syscalls).
## Syntax
```
sudo ausearch [OPTIONS]
```
## Common Options
| Option | Description |
|---|---|
| `-m TYPE` | Filter by event type (e.g., `USER_LOGIN`) |
| `-ts today` | Filter events from today |
| `-f FILE` | Search for events related to a specific file |

## Example
```bash
sudo auditctl -w /etc/passwd -p wa -k passwd_changes
sudo ausearch -k passwd_changes
```
## Expected Output
```
type=PATH msg=audit(1720400000.123:456): item=0 name="/etc/passwd" ...
```
## Explanation
Unlike application-level logs, `auditd` operates at the kernel syscall level, providing a tamper-resistant, detailed audit trail of exactly who accessed or modified specific files/resources — commonly required for compliance frameworks (PCI-DSS, HIPAA, government security standards).
## Tips
- Use `auditctl -w PATH -p PERMISSIONS -k KEY_LABEL` to set up a watch rule on sensitive files, then filter results later with `ausearch -k KEY_LABEL`.
## Common Mistakes
- Not installed/enabled by default on all distros, and audit rules configured with `auditctl` directly are **not persistent** across reboots unless also added to `/etc/audit/rules.d/`.
## Related Commands
[journalctl](processes.md#journalctl)

---

# chkrootkit / rkhunter
## Purpose
Scan a system for signs of known rootkits, backdoors, and common local exploit indicators.
## Syntax
```
sudo chkrootkit
sudo rkhunter --check
```
## Example
```bash
sudo rkhunter --update
sudo rkhunter --check
```
## Expected Output
```
Checking for rootkits...
    Checking for prerequisites                              [ OK ]
    Checking for enabled compilers                          [ Warning ]
```
## Explanation
Both tools compare system binaries and behavior against databases of known rootkit signatures and common tampering indicators (like unexpected SUID binaries, hidden processes, or modified system commands).
## Tips
- These tools are **detective, not preventive** controls — they help identify a compromise that may have already occurred, and should be one layer among many (alongside firewalls, `fail2ban`, regular patching, and least-privilege practices), not a sole line of defense.
- False positives are common (especially "Warning" results for legitimate system configurations) — always investigate flagged results rather than assuming compromise automatically.
## Common Mistakes
- Treating a clean scan result as absolute proof of no compromise — sophisticated rootkits are specifically designed to evade signature-based detection tools like these.
## Related Commands
[auditd / ausearch](#auditd--ausearch)

---

# apparmor / aa-status
## Purpose
Query the status of AppArmor, a Linux Security Module that restricts individual programs' capabilities according to per-application security profiles.
## Syntax
```
sudo aa-status
```
## Example
```bash
sudo aa-status
```
## Expected Output
```
apparmor module is loaded.
28 profiles are loaded.
25 profiles are in enforce mode.
3 profiles are in complain mode.
```
## Explanation
AppArmor confines what individual applications can do (which files they can read/write, which network operations they can perform) even if that application is later compromised — a defense-in-depth "mandatory access control" layer beyond standard Unix permissions. It's the default MAC system on Ubuntu/Debian-family distros.
## Tips
- "Enforce mode" actively blocks disallowed actions; "complain mode" only logs violations without blocking — useful for testing a new profile before enabling full enforcement.
## Common Mistakes
- Diagnosing an application failure as a permissions or code bug without checking `dmesg`/`journalctl` for AppArmor denial messages — AppArmor restrictions can silently block otherwise-valid operations, producing confusing application-level errors.
## Related Commands
[getenforce / setenforce](#getenforce--setenforce)

---

# getenforce / setenforce
## Purpose
Check (`getenforce`) or temporarily change (`setenforce`) the current mode of SELinux, the mandatory access control system used primarily on Red Hat-family distros.
## Syntax
```
getenforce
sudo setenforce [Enforcing|Permissive]
```
## Example
```bash
getenforce
sudo setenforce 0
```
## Expected Output
```
Enforcing
```
## Explanation
SELinux is the Red Hat-family counterpart to AppArmor's confinement concept, but uses a more complex label-based (type enforcement) policy model. `Enforcing` actively blocks policy violations; `Permissive` only logs them (useful for debugging); `Disabled` turns SELinux off entirely (requires editing `/etc/selinux/config` and a reboot, not just `setenforce`).
## Tips
- `setenforce 0`/`1` only changes the mode **temporarily** until reboot — for a persistent change, edit `/etc/selinux/config` (`SELINUX=permissive`/`enforcing`/`disabled`).
- When an application mysteriously fails with "permission denied" despite correct Unix file permissions, check `sudo ausearch -m avc -ts recent` for SELinux denial messages before assuming a standard permissions bug.
## Common Mistakes
- Disabling SELinux entirely as a quick fix for a permission issue instead of properly diagnosing and creating an appropriate policy exception (`audit2allow`) — this is a significant, often unnecessary reduction in the system's security posture.
## Related Commands
[apparmor / aa-status](#apparmor--aa-status)

---

⬅️ Back to [shell-scripting.md](shell-scripting.md) | 🏠 Return to [README.md](README.md)
