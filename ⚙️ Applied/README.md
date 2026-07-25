# Linux System Information Reporter

A simple Bash script that collects and displays useful information about a
Linux system — operating system details, CPU, memory, disk usage, network
configuration, logged-in users, internet connectivity, and the top
CPU-consuming processes.

This project was built as a first-year Computer Science Linux/Bash
assignment, and later hardened for portfolio use: input validation, graceful
handling of missing commands, and consistent error messages.

## Example output

```
==========================================
      SYSTEM INFORMATION REPORT
      Generated on: 2026-07-22 08:03:15
==========================================

----------------------------------------
OPERATING SYSTEM
----------------------------------------
Hostname     : my-machine
Distribution : Ubuntu 24.04.4 LTS
Kernel       : 6.8.0-generic
Architecture : x86_64
Uptime       : up 2 hours, 14 minutes

----------------------------------------
CPU INFORMATION
----------------------------------------
Model        : Intel(R) Core(TM) i5-1135G7
CPU cores    : 4
Load average : 0.15 (1 min), 0.09 (5 min), 0.05 (15 min)

... (memory, disk, network, users, connectivity, and top processes follow)
```

## Requirements

The script uses a couple of Bash-only features (like `<<<` here-strings), so
run it with `bash` or `./sysreport.sh` — not `sh sysreport.sh`, since some
minimal `/bin/sh` implementations (like `dash`) don't support them.

It only uses standard Linux command-line tools that ship with (or are
trivially available on) most distributions:

`bash`, `grep`, `cut`, `sed`, `awk`, `head`, `date`

For a fuller report, it will also use these tools **if they are installed**,
but works fine without them by falling back to reading files directly from
`/proc`:

`hostname`, `uname`, `uptime`, `nproc`, `free`, `df`, `ip` / `ifconfig`,
`who` / `w`, `ping`, `ps`

If any of the above are missing, the corresponding section of the report
simply says so (e.g. `Could not find 'df', skipping disk info.`) instead of
the script crashing.

Tested on Ubuntu, Debian, Fedora, Arch Linux, Rocky Linux, and CentOS.

## Usage

```bash
# Make it executable (only needed once, after downloading)
chmod +x sysreport.sh

# Print the report to the screen
./sysreport.sh

# Save the report to a file instead
./sysreport.sh -o report.txt

# Verbose mode: show progress messages while the report is generated
./sysreport.sh -v

# Show help
./sysreport.sh -h
```

Note: like standard shell redirection, `-o` will silently overwrite the
target file if it already exists.

Pressing `Ctrl+C` at any point exits cleanly with a short message instead of
leaving a half-finished report or a raw interrupt trace.

## How it's organized

The script is split into small, single-purpose functions, one per report
section (`show_os_info`, `show_cpu_info`, `show_memory_info`, and so on).
`generate_report` calls them in order to build the full report. This keeps
each piece easy to read, test, and explain on its own.

A few small helper functions are shared across sections:

- `command_exists` — checks if a command-line tool is installed before
  using it.
- `print_unavailable` — prints a consistent message when a tool is missing.
- `print_section_title` — prints the `---- TITLE ----` banner used above
  every section.
- `log_info` — prints progress messages, only shown in verbose (`-v`) mode.

## Known limitations

- The disk usage fallback (used only when `df` is unavailable) reports on
  the root filesystem (`/`) only, not every mounted disk.
- The internet connectivity check relies on `ping` reaching `8.8.8.8`; this
  will report "no connection" on networks that block ICMP even if other
  traffic (like HTTPS) would work fine.
- Load average and process listing reflect a live Linux system and will not
  be meaningful on other Unix-like systems (macOS, BSD) since some of the
  underlying `/proc` files and `ps` output columns differ there.

## License

MIT — see [LICENSE](LICENSE).
