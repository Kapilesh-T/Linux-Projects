[🏠 Home](README.md) | [Navigation](navigation.md) | [Filesystem](filesystem.md) | [Permissions](file-permissions.md) | [Processes](processes.md) | [Users & Groups](users-groups.md) | [Storage](storage.md) | [Packages](package-management.md) | [Shell Scripting](shell-scripting.md) | [Security](security.md)

# 🌐 Networking Commands

Commands for inspecting network configuration, diagnosing connectivity issues, transferring files remotely, and interacting with services over the network.

## Table of Contents
1. [ip](#ip) 2. [ifconfig](#ifconfig) 3. [ping](#ping) 4. [traceroute](#traceroute) 5. [mtr](#mtr) 6. [ss](#ss) 7. [netstat](#netstat) 8. [curl](#curl) 9. [wget](#wget) 10. [ssh](#ssh) 11. [scp](#scp) 12. [sftp](#sftp) 13. [dig](#dig) 14. [nslookup](#nslookup) 15. [host](#host) 16. [nmap](#nmap) 17. [nc](#nc) 18. [hostname](#hostname) 19. [route](#route) 20. [iwconfig](#iwconfig) 21. [nmcli](#nmcli) 22. [whois](#whois) 23. [arp](#arp) 24. [tcpdump](#tcpdump)

---

# ip
## Purpose
View and configure network interfaces, IP addresses, routing tables, and more — the modern replacement for `ifconfig`/`route`.
## Syntax
```
ip [OBJECT] [COMMAND]
```
## Common Usage
| Command | Description |
|---|---|
| `ip addr show` (or `ip a`) | Show all interfaces and their IP addresses |
| `ip link show` | Show interface status (up/down) |
| `ip route show` | Show the routing table |
| `sudo ip addr add IP/CIDR dev IFACE` | Manually assign an IP to an interface |
| `sudo ip link set IFACE up/down` | Bring an interface up or down |

## Example
```bash
ip a
ip route
```
## Expected Output
```
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500
    inet 192.168.1.42/24 brd 192.168.1.255 scope global eth0
default via 192.168.1.1 dev eth0
```
## Explanation
`ip` is part of the modern `iproute2` package and is the current standard tool on virtually all Linux distros, offering more capability and consistency than the deprecated `net-tools` suite (`ifconfig`, `route`, `netstat`).
## Tips
- `ip -c a` adds color output for easier scanning of interface states.
- Changes made with `ip` are **not persistent** across reboots by default — use your distro's network configuration files or `nmcli` for permanent changes.
## Common Mistakes
- Expecting `ip addr add` to survive a reboot — it's a runtime-only change unless written into persistent network config.
## Related Commands
[ifconfig](#ifconfig), [route](#route), [nmcli](#nmcli)

---

# ifconfig
## Purpose
Legacy tool to display and configure network interface parameters.
## Syntax
```
ifconfig [INTERFACE] [OPTIONS]
```
## Example
```bash
ifconfig eth0
```
## Expected Output
```
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.1.42  netmask 255.255.255.0  broadcast 192.168.1.255
```
## Explanation
`ifconfig` comes from the older `net-tools` package, which is **deprecated** on most modern distros in favor of `iproute2` (`ip`), though it's still commonly taught and available for backward compatibility.
## Tips
- If learning fresh in 2026, prioritize learning `ip` — `ifconfig` may not be installed by default on minimal modern installs.
## Common Mistakes
- Relying on `ifconfig` in scripts intended for long-term/modern portability — it may not exist on a fresh minimal server install without manually installing `net-tools`.
## Related Commands
[ip](#ip)

---

# ping
## Purpose
Test network connectivity to a host by sending ICMP echo request packets and measuring the response.
## Syntax
```
ping [OPTIONS] HOST
```
## Common Options
| Option | Description |
|---|---|
| `-c N` | Send only N packets, then stop |
| `-i SECONDS` | Interval between packets |
| `-t TTL` | Set the time-to-live for outgoing packets |

## Example
```bash
ping -c 4 google.com
```
## Expected Output
```
64 bytes from bom07s02-in-f14.1e100.net (142.250.196.14): icmp_seq=1 ttl=115 time=12.4 ms
--- google.com ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3005ms
```
## Explanation
`ping` is the first tool to reach for when diagnosing "is the network even up" — it verifies basic Layer 3 connectivity and round-trip latency before investigating higher-level issues (DNS, application, firewall).
## Tips
- Always use `-c N` in scripts — without it, `ping` runs indefinitely until manually stopped.
- 0% packet loss with high/unstable latency suggests congestion, not an outright outage.
## Common Mistakes
- Assuming "ping fails = network down" — many servers and firewalls deliberately block ICMP for security reasons while still serving normal traffic (e.g., HTTP) fine.
## Related Commands
[traceroute](#traceroute), [mtr](#mtr)

---

# traceroute
## Purpose
Show the path (sequence of routers/hops) packets take to reach a destination host.
## Syntax
```
traceroute HOST
```
## Example
```bash
traceroute google.com
```
## Expected Output
```
 1  192.168.1.1 (192.168.1.1)  1.2 ms  1.1 ms  1.0 ms
 2  10.10.0.1 (10.10.0.1)  8.4 ms  8.1 ms  8.5 ms
 3  * * *
 4  142.250.196.14 (142.250.196.14)  12.4 ms  12.1 ms  12.6 ms
```
## Explanation
Works by sending packets with progressively increasing TTL (time-to-live) values, causing each intermediate router to respond with a "TTL exceeded" message — this reveals the full path hop by hop, helping identify exactly where latency or packet loss is occurring.
## Tips
- Asterisks (`* * *`) at a hop don't necessarily mean a problem — many routers are configured not to respond to traceroute probes but still forward traffic normally.
## Common Mistakes
- Concluding a hop showing `* * *` is broken — it's often just a router that silently drops the probe packets by policy, while normal traffic passes through fine.
## Related Commands
[mtr](#mtr), [ping](#ping)

---

# mtr
## Purpose
Combine `ping` and `traceroute` into a single continuously updating live diagnostic tool.
## Syntax
```
mtr HOST
```
## Common Options
| Option | Description |
|---|---|
| `-r` | Generate a report and exit (non-interactive, script-friendly) |
| `-c N` | Number of pings per hop in report mode |

## Example
```bash
mtr -r -c 10 google.com
```
## Expected Output
```
HOST: myhost                    Loss%   Snt   Last   Avg  Best  Wrst StDev
  1. 192.168.1.1                 0.0%    10    1.2   1.1   1.0   1.5   0.1
  2. 10.10.0.1                   0.0%    10    8.4   8.2   8.0   8.9   0.3
```
## Explanation
Unlike a single `traceroute` snapshot, `mtr` continuously re-probes every hop, making intermittent packet loss at a specific hop much easier to spot over time.
## Tips
- `mtr -r` (report mode) is ideal for including diagnostic output in support tickets or logs, since normal interactive `mtr` requires a live terminal.
## Common Mistakes
- Not installed by default on many distros — install via `sudo apt install mtr` / `sudo dnf install mtr`.
## Related Commands
[traceroute](#traceroute), [ping](#ping)

---

# ss
## Purpose
Display socket statistics — active network connections, listening ports, and related information.
## Syntax
```
ss [OPTIONS]
```
## Common Options
| Option | Description |
|---|---|
| `-t` | TCP sockets |
| `-u` | UDP sockets |
| `-l` | Listening sockets only |
| `-n` | Show numeric addresses/ports (skip DNS resolution, much faster) |
| `-p` | Show the process using each socket (requires sudo for full info) |

## Example
```bash
sudo ss -tulnp
```
## Expected Output
```
Netid State    Local Address:Port   Peer Address:Port   Process
tcp   LISTEN   0.0.0.0:22           0.0.0.0:*            users:(("sshd",pid=980))
tcp   LISTEN   127.0.0.1:5432       0.0.0.0:*            users:(("postgres",pid=1200))
```
## Explanation
`ss` is the modern replacement for `netstat`, built on newer kernel interfaces (`netlink`) that are significantly faster, especially on systems with many open connections.
## Tips
- `-tulnp` (TCP+UDP, listening, numeric, with process) is the single most useful flag combination — memorize it for quickly seeing "what's listening on what port."
## Common Mistakes
- Forgetting `sudo` when trying to see the process name for sockets owned by other users — without it, the `Process` column is often blank.
## Related Commands
[netstat](#netstat), [lsof](processes.md#lsof)

---

# netstat
## Purpose
Display network connections, routing tables, interface statistics (legacy tool, largely superseded by `ss`/`ip`).
## Syntax
```
netstat [OPTIONS]
```
## Common Options
| Option | Description |
|---|---|
| `-tulnp` | TCP+UDP listening sockets, numeric, with process (same idea as `ss`) |
| `-r` | Show routing table |

## Example
```bash
sudo netstat -tulnp
```
## Explanation
Part of the deprecated `net-tools` package. Functionally similar to `ss` but slower on systems with large numbers of connections, and not guaranteed to be pre-installed on modern minimal distros.
## Tips
- If writing new scripts or learning fresh, prefer `ss` — but recognize `netstat` syntax since it remains extremely common in existing documentation, tutorials, and older systems.
## Common Mistakes
- Assuming `netstat` is always available out-of-the-box — many modern minimal server images (e.g., recent Ubuntu Server, Debian minimal) don't include `net-tools` by default.
## Related Commands
[ss](#ss)

---

# curl
## Purpose
Transfer data to or from a URL — commonly used to test APIs, download files, and debug HTTP requests/responses.
## Syntax
```
curl [OPTIONS] URL
```
## Common Options
| Option | Description |
|---|---|
| `-I` | Fetch headers only (HEAD request) |
| `-X METHOD` | Specify HTTP method (GET, POST, PUT, DELETE...) |
| `-d "data"` | Send data in the request body (POST) |
| `-H "Header: value"` | Add a custom request header |
| `-o FILE` | Save output to a file |
| `-L` | Follow redirects |
| `-s` | Silent mode, suppress progress meter |
| `-v` | Verbose, show full request/response details |

## Example
```bash
curl -s -X POST https://api.example.com/login \
  -H "Content-Type: application/json" \
  -d '{"user":"kapilesh","pass":"***"}'
```
## Expected Output
```
{"token":"eyJhbGciOi...","expires":3600}
```
## Explanation
`curl` is the standard tool for scripting HTTP interactions and debugging APIs directly from the command line, supporting a huge range of protocols beyond HTTP (FTP, SFTP, SMTP, and more).
## Tips
- `curl -v` is invaluable for debugging exactly what headers/data are being sent and received when an API integration misbehaves.
- `curl -I` (headers only) is a fast way to check if a URL is reachable and what status code it returns, without downloading the full body.
## Common Mistakes
- Forgetting `-L` when a URL redirects (e.g., HTTP → HTTPS), resulting in an unexpected empty or redirect-page response instead of the final content.
## Related Commands
[wget](#wget)

---

# wget
## Purpose
Download files from the web, with strong support for recursive downloads and resuming interrupted transfers.
## Syntax
```
wget [OPTIONS] URL
```
## Common Options
| Option | Description |
|---|---|
| `-c` | Continue/resume a partially downloaded file |
| `-r` | Recursive download (e.g., mirror a whole site/directory) |
| `-O FILE` | Save with a specific output filename |
| `-q` | Quiet mode |
| `--limit-rate=RATE` | Throttle download speed |

## Example
```bash
wget -c https://example.com/large-file.iso
```
## Expected Output
```
Saving to: 'large-file.iso'
large-file.iso   45%[========>       ]  2.1G  5.2MB/s
```
## Explanation
While `curl` is generally preferred for API interaction/scripting flexibility, `wget` remains the go-to for straightforward, robust file downloads — especially large files needing resume support or recursive site mirroring.
## Tips
- Use `wget -c` by default for large downloads over unreliable connections to avoid restarting from zero on failure.
## Common Mistakes
- Using `wget` for API calls requiring custom methods/headers where `curl` is generally more ergonomic and flexible.
## Related Commands
[curl](#curl)

---

# ssh
## Purpose
Securely log in to and execute commands on a remote machine over an encrypted connection.
## Syntax
```
ssh [OPTIONS] USER@HOST
```
## Common Options
| Option | Description |
|---|---|
| `-p PORT` | Connect on a non-default port |
| `-i KEYFILE` | Use a specific private key for authentication |
| `-L LOCAL:REMOTE` | Local port forwarding (tunnel) |
| `-v` | Verbose, useful for debugging connection issues |

## Example
```bash
ssh -i ~/.ssh/id_ed25519 kapilesh@192.168.1.50
```
## Expected Output
```
Welcome to Ubuntu 24.04 LTS
Last login: Mon Jul  6 09:58:12 2026 from 192.168.1.10
kapilesh@server:~$
```
## Explanation
SSH (Secure Shell) encrypts all traffic between client and server, replacing insecure legacy protocols like `telnet`. Authentication is most securely done via public-key cryptography rather than passwords (see `ssh-keygen` in [security.md](security.md#ssh-keygen)).
## Tips
- Configure `~/.ssh/config` with host aliases (`Host myserver` / `HostName` / `User` / `Port`) to avoid retyping long connection strings.
- Disable password authentication server-side once key-based auth is confirmed working, to significantly reduce brute-force attack surface.
## Common Mistakes
- Storing private keys with overly permissive file permissions — SSH will refuse to use a private key file that's readable by group/others (fix with `chmod 600 keyfile`).
## Related Commands
[scp](#scp), [sftp](#sftp), [ssh-keygen](security.md#ssh-keygen)

---

# scp
## Purpose
Securely copy files between local and remote hosts over SSH.
## Syntax
```
scp [OPTIONS] SOURCE DESTINATION
```
## Common Options
| Option | Description |
|---|---|
| `-r` | Copy directories recursively |
| `-P PORT` | Specify a non-default SSH port (uppercase, unlike `ssh -p`) |
| `-i KEYFILE` | Use a specific private key |

## Example
```bash
scp -r ./project kapilesh@192.168.1.50:/home/kapilesh/backup/
```
## Expected Output
```
index.html                        100%  1234     1.2MB/s   00:00
```
## Explanation
`scp` rides on top of the SSH protocol, inheriting the same encryption and authentication. For large or frequently repeated transfers, `rsync` (which can also run over SSH) is generally preferred for its delta-transfer efficiency.
## Tips
- For anything beyond a single quick file copy, prefer `rsync -avz -e ssh` — same security, far better performance on repeated/partial transfers.
## Common Mistakes
- Using a lowercase `-p` (which means "preserve file attributes" in `scp`) when you meant to specify a port — the port flag is uppercase `-P`, opposite of `ssh`'s lowercase `-p`.
## Related Commands
[rsync](filesystem.md#rsync), [sftp](#sftp)

---

# sftp
## Purpose
Interactively transfer files over SSH using an FTP-like command interface.
## Syntax
```
sftp USER@HOST
```
## Common Interactive Commands
| Command | Description |
|---|---|
| `ls` / `lls` | List remote / local directory |
| `get FILE` | Download a file |
| `put FILE` | Upload a file |
| `cd` / `lcd` | Change remote / local directory |

## Example
```bash
sftp kapilesh@192.168.1.50
sftp> get report.pdf
```
## Explanation
Provides an interactive session for browsing and transferring files, useful when you need to explore a remote filesystem rather than transferring a single known file path (which `scp` handles more directly).
## Tips
- Many GUI file managers (Nautilus, Dolphin, FileZilla) support `sftp://` URLs directly, giving a graphical alternative to the command-line session.
## Common Mistakes
- Confusing local vs. remote context inside the session — commands like `cd` affect the remote side, while `lcd` affects your local machine.
## Related Commands
[scp](#scp), [ssh](#ssh)

---

# dig
## Purpose
Query DNS servers for detailed information about a domain (the modern, detailed DNS lookup tool).
## Syntax
```
dig [OPTIONS] DOMAIN [RECORD_TYPE]
```
## Common Options
| Option | Description |
|---|---|
| `+short` | Only show the essential answer, not the full response |
| `MX` / `TXT` / `NS` / `A` | Query a specific DNS record type |
| `@SERVER` | Query a specific DNS server instead of the system default |

## Example
```bash
dig +short google.com
dig google.com MX
```
## Expected Output
```
142.250.196.14
```
## Explanation
`dig` provides the most complete and script-friendly view of DNS resolution, including the full response, authority, and additional sections — the standard tool for professional DNS troubleshooting.
## Tips
- Use `dig +short` in scripts for clean, parseable output instead of the default verbose format.
- `dig @8.8.8.8 domain.com` lets you test resolution against a specific DNS server (here, Google's public DNS) to isolate local DNS cache/config issues.
## Common Mistakes
- Not installed by default on some minimal distros — install via the `dnsutils` (Debian/Ubuntu) or `bind-utils` (RHEL/Fedora) package.
## Related Commands
[nslookup](#nslookup), [host](#host)

---

# nslookup
## Purpose
Query DNS servers to resolve a domain name to an IP address (or vice versa) — an older, simpler alternative to `dig`.
## Syntax
```
nslookup DOMAIN
```
## Example
```bash
nslookup google.com
```
## Expected Output
```
Server:		127.0.0.53
Address:	127.0.0.53#53

Non-authoritative answer:
Name:	google.com
Address: 142.250.196.14
```
## Explanation
Functionally overlaps heavily with `dig`, but with a simpler, less detailed output format. Widely known because it's cross-platform (also available on Windows), making it a common "lowest common denominator" DNS tool taught in networking basics.
## Tips
- For deeper DNS troubleshooting (specific record types, authoritative server chains), prefer `dig`.
## Common Mistakes
- Officially considered semi-deprecated by its own maintainers in favor of `dig`/`host`, though it remains widely available and used out of habit.
## Related Commands
[dig](#dig), [host](#host)

---

# host
## Purpose
A simple DNS lookup utility for quick forward and reverse DNS queries.
## Syntax
```
host DOMAIN_OR_IP
```
## Example
```bash
host google.com
host 142.250.196.14
```
## Expected Output
```
google.com has address 142.250.196.14
142.250.196.14.in-addr.arpa domain name pointer bom07s02-in-f14.1e100.net.
```
## Explanation
Simpler and more concise than `dig` for quick lookups, and handles reverse DNS lookups (IP → hostname) with the same simple syntax as forward lookups.
## Tips
- Good for quick sanity checks in scripts where you just need a one-line confirmation of DNS resolution.
## Common Mistakes
- Expecting the same level of detail (TTLs, full record sets) as `dig` — `host` intentionally keeps output minimal.
## Related Commands
[dig](#dig), [nslookup](#nslookup)

---

# nmap
## Purpose
Scan networks and hosts to discover open ports, running services, and (with scripts) potential vulnerabilities.
## Syntax
```
nmap [OPTIONS] TARGET
```
## Common Options
| Option | Description |
|---|---|
| `-p PORT(S)` | Scan specific port(s) |
| `-sV` | Detect service versions on open ports |
| `-A` | Aggressive scan: OS detection, version detection, script scanning |
| `-sn` | Ping scan only — discover live hosts without port scanning |

## Example
```bash
nmap -sV -p 1-1000 192.168.1.50
```
## Expected Output
```
PORT     STATE SERVICE VERSION
22/tcp   open  ssh     OpenSSH 9.6
80/tcp   open  http    nginx 1.24.0
```
## Explanation
`nmap` is the industry-standard network scanning tool used in security auditing, penetration testing, and network inventory. It works by sending crafted packets and analyzing responses to infer open ports, service versions, and sometimes OS fingerprints.
## Tips
- Always scope scans narrowly (`-p` specific ports) on production networks — full aggressive scans generate heavy traffic and can trigger IDS/IPS alerts.
## Common Mistakes
- **Legal/ethical note:** scanning networks or hosts you do not own or have explicit written authorization to test can violate computer misuse laws in many jurisdictions (including India's IT Act, 2000) and most cloud providers' Acceptable Use Policies. Only scan infrastructure you own or have documented permission to test.
## Related Commands
[nc](#nc), [ss](#ss)

---

# nc
## Purpose
"Netcat" — a versatile networking utility for reading/writing raw data across TCP/UDP connections; useful for testing ports, simple file transfers, and basic chat/debug servers.
## Syntax
```
nc [OPTIONS] HOST PORT
```
## Common Options
| Option | Description |
|---|---|
| `-l` | Listen mode (act as a server) |
| `-v` | Verbose |
| `-z` | Zero-I/O mode — just scan for open ports, don't send data |
| `-u` | Use UDP instead of TCP |

## Example
```bash
nc -zv 192.168.1.50 22
```
## Expected Output
```
Connection to 192.168.1.50 22 port [tcp/ssh] succeeded!
```
## Explanation
Often called the "Swiss Army knife" of networking tools — beyond port testing, it can pipe raw data between machines, making it useful for quick file transfers or manually crafting protocol requests to debug a service.
## Tips
- `nc -zv HOST PORT` is a fast, lightweight alternative to a full `nmap` scan when you just need to check one specific port.
## Common Mistakes
- Leaving an `nc -l` listener open unintentionally on a production system — it accepts unauthenticated connections by design, which is a security risk if exposed.
## Related Commands
[nmap](#nmap), [ss](#ss)

---

# hostname
## Purpose
Display or set the system's hostname.
## Syntax
```
hostname [NEW_HOSTNAME]
```
## Common Options
| Option | Description |
|---|---|
| `-I` | Show all assigned IP addresses |
| `-f` | Show the fully qualified domain name (FQDN) |

## Example
```bash
hostname
hostname -I
```
## Expected Output
```
webserver01
192.168.1.42
```
## Explanation
The hostname is used in logging, shell prompts, and network identification. Setting it with the plain `hostname` command is **temporary** (until reboot); permanent changes require editing `/etc/hostname` or using `hostnamectl` on `systemd` systems.
## Tips
- Use `sudo hostnamectl set-hostname NAME` for a permanent hostname change on modern `systemd` distros.
## Common Mistakes
- Using plain `hostname NEW_NAME` and expecting it to persist across a reboot — it won't without also updating `/etc/hostname`.
## Related Commands
[ip](#ip)

---

# route
## Purpose
Display or manipulate the IP routing table (legacy tool, largely replaced by `ip route`).
## Syntax
```
route [OPTIONS]
```
## Example
```bash
route -n
```
## Expected Output
```
Destination     Gateway         Genmask         Flags Metric Iface
0.0.0.0         192.168.1.1     0.0.0.0         UG    100    eth0
```
## Explanation
Part of the deprecated `net-tools` suite. `ip route show` is the modern equivalent and generally preferred going forward.
## Tips
- `-n` avoids slow DNS reverse-lookups on displayed addresses, showing numeric output much faster.
## Common Mistakes
- Assuming `route` is pre-installed on modern minimal distros — it often isn't without `net-tools`.
## Related Commands
[ip](#ip)

---

# iwconfig
## Purpose
View and configure wireless (Wi-Fi) network interface parameters (legacy tool).
## Syntax
```
iwconfig [INTERFACE]
```
## Example
```bash
iwconfig wlan0
```
## Expected Output
```
wlan0     IEEE 802.11  ESSID:"HomeNetwork"
          Mode:Managed  Frequency:5.18 GHz  Access Point: AA:BB:CC:DD:EE:FF
          Link Quality=58/70  Signal level=-52 dBm
```
## Explanation
The wireless-specific counterpart to `ifconfig`, showing signal strength, SSID, and connection mode — also part of the older `wireless-tools` package, largely superseded by `iw` and `nmcli` on modern systems.
## Tips
- For modern Wi-Fi management (scanning, connecting, forgetting networks), `nmcli` is generally far more practical.
## Common Mistakes
- Expecting to see Wi-Fi networks to *connect to* — `iwconfig` only shows the *current* connection's config, not a scan of nearby networks (use `nmcli device wifi list` for that).
## Related Commands
[nmcli](#nmcli), [ip](#ip)

---

# nmcli
## Purpose
Command-line interface for NetworkManager — the modern way to configure network connections (Wi-Fi, Ethernet, VPN) on most desktop and many server Linux distros.
## Syntax
```
nmcli [OBJECT] [COMMAND]
```
## Common Usage
| Command | Description |
|---|---|
| `nmcli device status` | Show status of all network devices |
| `nmcli device wifi list` | Scan and list available Wi-Fi networks |
| `nmcli device wifi connect SSID password PASS` | Connect to a Wi-Fi network |
| `nmcli connection show` | List saved network connection profiles |

## Example
```bash
nmcli device wifi connect "HomeNetwork" password "s3cr3t"
```
## Expected Output
```
Device 'wlan0' successfully activated with 'a1b2c3d4-...'
```
## Explanation
Unlike `ip`/`ifconfig` changes (which are typically temporary), `nmcli`-managed connections are saved as persistent connection profiles by NetworkManager, surviving reboots automatically.
## Tips
- `nmcli connection show` followed by `nmcli connection up NAME` is useful for quickly switching between saved network profiles.
## Common Mistakes
- Using `nmcli` on servers where NetworkManager isn't the active network service (some server distros use `systemd-networkd` or `netplan` instead) — check which network management system is actually in use first.
## Related Commands
[ip](#ip), [iwconfig](#iwconfig)

---

# whois
## Purpose
Query domain registration information (registrar, owner, creation/expiry dates) for a domain name.
## Syntax
```
whois DOMAIN
```
## Example
```bash
whois example.com
```
## Expected Output
```
Domain Name: EXAMPLE.COM
Registrar: RESERVED-Internet Assigned Numbers Authority
Creation Date: 1995-08-14T04:00:00Z
```
## Explanation
Useful for OSINT (open-source intelligence) research, verifying domain ownership before business dealings, or checking domain expiry dates — though many registrars now redact personal registrant data for privacy (GDPR/ICANN privacy proxy services).
## Tips
- Not installed by default on all distros — install via `sudo apt install whois`.
## Common Mistakes
- Expecting full registrant personal details for most modern domains — privacy protection services now redact this by default for the vast majority of registrations.
## Related Commands
[dig](#dig)

---

# arp
## Purpose
Display or modify the system's ARP (Address Resolution Protocol) cache, which maps local network IP addresses to MAC addresses.
## Syntax
```
arp [OPTIONS]
```
## Example
```bash
arp -a
```
## Expected Output
```
? (192.168.1.1) at aa:bb:cc:dd:ee:ff [ether] on eth0
```
## Explanation
ARP resolves IP addresses to hardware (MAC) addresses on a local network segment — the cache avoids re-resolving the same address on every packet. This legacy tool is being replaced by `ip neigh` in modern `iproute2` workflows.
## Tips
- Use `ip neigh show` for the modern equivalent with more consistent output formatting.
## Common Mistakes
- Confusing ARP cache entries (local network Layer 2 mapping) with DNS entries (Layer 7 name resolution) — they solve entirely different problems.
## Related Commands
[ip](#ip)

---

# tcpdump
## Purpose
Capture and analyze network packets traveling through an interface — a powerful low-level network debugging and security tool.
## Syntax
```
tcpdump [OPTIONS]
```
## Common Options
| Option | Description |
|---|---|
| `-i INTERFACE` | Capture on a specific interface (`any` for all) |
| `-n` | Don't resolve hostnames (faster, avoids DNS noise) |
| `-w FILE` | Write raw capture to a file for later analysis (e.g., in Wireshark) |
| `port PORT` | Filter to a specific port |
| `host IP` | Filter to a specific host |

## Example
```bash
sudo tcpdump -i eth0 -n port 443
```
## Expected Output
```
10:30:01.123456 IP 192.168.1.42.51234 > 142.250.196.14.443: Flags [S], seq 123456789
```
## Explanation
`tcpdump` operates at the packet level, showing raw protocol details (TCP flags, sequence numbers, payload where unencrypted) — essential for diagnosing connectivity issues that higher-level tools like `curl`/`ping` can't explain, and a foundational tool in network security analysis.
## Tips
- Save captures with `-w capture.pcap` and analyze them later in Wireshark for a graphical, deeply filterable view of the same data.
## Common Mistakes
- Running `tcpdump` without a filter on a busy interface, producing an overwhelming, hard-to-read firehose of unrelated traffic — always scope with `port`/`host`/`net` filters.
- Requires root/`sudo` privileges (or the `CAP_NET_RAW` capability) since raw packet capture is a privileged operation.
## Related Commands
[nc](#nc), [ss](#ss)

---

⬅️ Back to [processes.md](processes.md) | Next: [users-groups.md](users-groups.md) ➡️
