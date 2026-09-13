[🏠 Home](README.md) | [Navigation](navigation.md) | [Filesystem](filesystem.md) | [Permissions](file-permissions.md) | [Processes](processes.md) | [Users & Groups](users-groups.md) | [Storage](storage.md) | [Packages](package-management.md) | [Shell Scripting](shell-scripting.md) | [Security](security.md)

# Networking Commands

Inspecting network configuration, diagnosing connectivity, transferring
files remotely, and talking to services over the network.

**Contents:** [ip](#ip) · [ifconfig](#ifconfig) · [ping](#ping) · [traceroute](#traceroute) · [mtr](#mtr) · [ss](#ss) · [netstat](#netstat) · [curl](#curl) · [wget](#wget) · [ssh](#ssh) · [scp](#scp) · [sftp](#sftp) · [dig](#dig) · [nslookup](#nslookup) · [host](#host) · [nmap](#nmap) · [nc](#nc) · [hostname](#hostname) · [route](#route) · [iwconfig](#iwconfig) · [nmcli](#nmcli) · [whois](#whois) · [arp](#arp) · [tcpdump](#tcpdump)

---

### ip
The modern tool for interfaces, addresses, and routing (replaces `ifconfig` + `route`).

```bash
ip addr show          # or just: ip a — interfaces and IPs
ip link show          # interface status (up/down)
ip route show         # routing table
sudo ip addr add 10.0.0.5/24 dev eth0    # assign an IP
sudo ip link set eth0 up                 # bring an interface up
ip -c a               # -c: color output
```

Changes made with `ip` are **runtime-only** — they don't survive a reboot unless written into your distro's network config (or `nmcli`).

### ifconfig
The legacy interface tool from `net-tools`. Deprecated in favour of `ip` and not installed by default on minimal modern systems — but still common in older docs and tutorials, so worth recognizing.

### ping
Test reachability and latency with ICMP echo requests.

```bash
ping -c 4 google.com    # always use -c in scripts (else it runs forever)
```

Notes:
- 0% loss with high latency = congestion; high loss = problem.
- "ping fails" is **not** proof the network is down — many hosts/firewalls block ICMP while serving normal traffic fine.

### traceroute
Show the hop-by-hop path packets take to a destination.

```bash
traceroute google.com
```

Works by sending packets with increasing TTL so each router reports back. Hops showing `* * *` are often just routers that silently drop probe packets — not necessarily broken.

### mtr
`ping` + `traceroute` combined, updating live — makes intermittent packet loss on a specific hop much easier to spot.

```bash
mtr -r -c 10 google.com    # -r: report mode (script-friendly)
```

### ss
Show sockets: open connections and listening ports — the modern, fast replacement for `netstat`.

```bash
sudo ss -tulnp    # t=TCP u=UDP l=listening n=numeric p=process
```

`-tulnp` is the combination to memorize for "what is listening on what port". `sudo` is needed to see the process for sockets owned by other users.

### netstat
The older `net-tools` port/socket tool. Still everywhere in documentation, same `-tulnp` idea, but slower than `ss` and not guaranteed pre-installed on modern minimal distros. Prefer `ss`.
### curl
Transfer data to/from a URL — the standard tool for testing APIs and HTTP.

```bash
curl -I https://example.com                # headers only (HEAD)
curl -L https://example.com                # -L: follow redirects
curl -s -X POST https://api.example.com/login \
     -H "Content-Type: application/json" \
     -d '{"user":"me","pass":"***"}'        # JSON POST
curl -o out.bin https://example.com/file    # save to a file
```

- `-v` shows the full request/response for debugging; `-s` silences the progress meter.
- Forgetting `-L` on a redirecting URL returns an empty/redirect page instead of the final content.

### wget
Download files with strong support for resuming and mirroring.

```bash
wget -c https://example.com/large.iso    # -c: resume interrupted download
wget -r -O out https://example.com/      # -r: recursive mirror
wget --limit-rate=500k https://example.com/file.iso
```

`curl` is better for APIs; `wget` is the go-to for straightforward downloads — use `-c` on large files over flaky connections.

### ssh
Securely log in to a remote machine over an encrypted connection.

```bash
ssh -i ~/.ssh/id_ed25519 kapilesh@192.168.1.50
ssh -p 2222 user@host          # non-default port
ssh -L 8080:localhost:80 user@host   # local port forward (tunnel)
```

- SSH uses encryption where `telnet` sent everything in plaintext; key-based auth beats passwords (see `ssh-keygen` in security.md).
- Define host aliases in `~/.ssh/config` (`Host myserver`, `HostName`, `User`, `Port`) so you don't retype long command lines.
- SSH **refuses** a private key whose file permissions are too open — `chmod 600 keyfile` fixes it.
- Once keys work, disable password auth server-side to shrink the brute-force surface.

### scp
Copy files over SSH.

```bash
scp -r ./project kapilesh@192.168.1.50:/home/kapilesh/backup/
```

Note the port flag is uppercase `-P` for `scp` (lowercase `-p` means "preserve attributes") — the opposite of `ssh`. For repeated/large transfers prefer `rsync -avz -e ssh` (delta transfers).

### sftp
Interactive FTP-style session over SSH.

```bash
sftp kapilesh@192.168.1.50
sftp> ls / get report.pdf / put file.txt / cd / lcd
```

`ls`/`cd`/`get`/`put` act on the **remote** side; `lls`/`lcd` act locally. GUI file managers accept `sftp://` URLs.

### dig
Detailed DNS queries — the professional DNS troubleshooting tool.

```bash
dig +short google.com          # just the answer
dig google.com MX              # specific record type
dig @8.8.8.8 example.com       # query a specific DNS server
```

`+short` gives clean parseable output for scripts. Querying a known public DNS (`dig @8.8.8.8`) isolates local resolver/cache problems.

### nslookup
Older, simpler DNS lookup — the cross-platform "lowest common denominator" tool (also on Windows). Prefer `dig` for deeper work.
### host
Quick forward and reverse DNS lookups.

```bash
host google.com            # google.com has address 142.250.196.14
host 142.250.196.14        # reverse: IP -> hostname
```

Minimal one-line output — fine for sanity checks; use `dig` when you need TTLs or full record sets.

### nmap
The industry-standard network scanner: discovers hosts, open ports, services, and OS fingerprints.

```bash
nmap -sV -p 1-1000 192.168.1.50    # version detection on specific ports
nmap -sn 192.168.1.0/24            # ping scan: which hosts are up?
nmap -A 192.168.1.50               # aggressive: OS + versions + scripts
```

**Only scan networks you own or have written permission to test** — port scanning without authorization can be illegal (and breaks cloud providers' acceptable-use policies). Keep ranges narrow; aggressive scans are noisy and can trip IDS/IPS alerts.

### nc (netcat)
Read and write raw data across TCP/UDP — the "Swiss Army knife" of networking.

```bash
nc -zv 192.168.1.50 22     # -z: just check if the port is open
nc -l -p 9000              # listen mode (server)
echo hi | nc 192.168.1.50 9000    # send raw data
```

An unauthenticated listening `nc` is an open door — never leave one on a production box.

### hostname
Show (or temporarily set) the system hostname.

```bash
hostname        # webserver01
hostname -I     # all assigned IPs
sudo hostnamectl set-hostname NAME    # permanent (systemd)
```

Plain `hostname NEW_NAME` only lasts until reboot; make it permanent with `hostnamectl` (or `/etc/hostname`) on systemd distros.

### route
The legacy routing-table tool (deprecated; use `ip route`).

```bash
route -n    # -n: numeric output, skips slow DNS lookups
```

### iwconfig
Wireless counterpart to `ifconfig` (legacy `wireless-tools`). Shows SSID, signal strength, and mode for the *current* connection — it doesn't scan for networks (use `nmcli device wifi list` for that). Superseded by `iw`/`nmcli`.

### nmcli
Command-line control for NetworkManager — the persistent, user-friendly way to manage connections.

```bash
nmcli device status
nmcli device wifi list
nmcli device wifi connect "HomeNetwork" password "s3cr3t"
nmcli connection show
nmcli connection up NAME
```

Unlike `ip`'s runtime-only changes, `nmcli` connections are saved profiles that survive reboots. On servers that don't run NetworkManager (systemd-networkd, netplan), check which system is in use first.

### whois
Query domain registration records (registrar, dates, sometimes owner).

```bash
whois example.com
```

Useful for OSINT and checking domain expiry. Registrant data is often redacted these days (GDPR/privacy proxies). Package: `whois`.

### arp
Show and manage the ARP cache (IP → MAC address mappings on the local network).

```bash
arp -n    # numeric output: IP and MAC pairs
```

Deprecated in favour of `ip neigh` on modern iproute2 installs.

### tcpdump
Capture and analyze packets on the wire.

```bash
sudo tcpdump -i eth0                     # everything on an interface
sudo tcpdump -i eth0 port 80             # one port
sudo tcpdump -i eth0 -w capture.pcap     # save for later analysis
sudo tcpdump -i eth0 host 192.168.1.50   # one host
```

The classic diagnostics/security tool (and the CLI behind Wireshark). Needs root, and on busy links filter first or you'll drown in output.

---

⬅️ Back to [Processes](processes.md) | Next: [Users & Groups](users-groups.md) ➡️