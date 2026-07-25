#!/usr/bin/env bash
#
# ==========================================================================
# System Information Reporter
# --------------------------------------------------------------------------
# A simple Bash script that collects and displays basic information about
# a Linux system: OS details, CPU, memory, disk usage, network, logged in
# users, internet connectivity, and the top CPU-consuming processes.
#
# The script is written to be safe on many different Linux distributions
# (Ubuntu, Debian, Fedora, Arch, Rocky, CentOS, ...): if a command or file
# is missing, the script prints "Unavailable"/"Unknown" for that value
# instead of crashing.
#
# Usage:
#   ./sysreport.sh              Show the report on the screen
#   ./sysreport.sh -o file.txt  Save the report to a file instead
#   ./sysreport.sh -v           Verbose mode (prints extra status messages)
#   ./sysreport.sh -h           Show help message
#
# Author: (your name here)
# ==========================================================================

# Stop the script if an undefined variable is used. This helps catch typos
# in variable names while we are still developing/testing the script.
set -u

# --------------------------------------------------------------------------
# Global settings (changed by command line options)
# --------------------------------------------------------------------------
OUTPUT_FILE=""      # if set, the report is written here instead of the screen
VERBOSE=false       # if true, print extra "doing this now" messages

# --------------------------------------------------------------------------
# Handle Ctrl+C (and similar interrupts) gracefully
# --------------------------------------------------------------------------
# Without this, pressing Ctrl+C while the script is running can leave the
# terminal in an odd state or just print a raw "Interrupted" message. This
# prints a clean message and exits with the conventional 130 exit code
# (128 + signal number 2, which is SIGINT).
# shellcheck disable=SC2329 # this function IS used, just indirectly via "trap" below
handle_interrupt() {
    echo
    echo "Interrupted by user. Exiting."
    exit 130
}
trap handle_interrupt INT TERM

# --------------------------------------------------------------------------
# Small helper functions
# --------------------------------------------------------------------------

# Print a message only when verbose mode is on. Used to show progress
# while the script is collecting information.
log_info() {
    if [ "$VERBOSE" = true ]; then
        echo "[info] $1" >&2
    fi
}

# Check whether a command is installed on this system.
# Returns 0 (true) if found, 1 (false) if not.
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Print a consistent "command not found" message for a report section.
# The caller passes the command name already wrapped in quotes, so this
# works the same whether it's one command or a couple of alternatives.
# Usage: print_unavailable "'df'" "disk usage information"
#        print_unavailable "'ip' or 'ifconfig'" "interface list"
print_unavailable() {
    local missing_command="$1"
    local section_description="$2"
    echo "Could not find $missing_command, skipping $section_description."
}

# Print a section title in a consistent style, e.g.:
# ---------------------
# CPU INFORMATION
# ---------------------
print_section_title() {
    local title="$1"
    echo "----------------------------------------"
    echo "$title"
    echo "----------------------------------------"
}

show_help() {
    echo "System Information Reporter"
    echo
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  -o FILE   Save the report to FILE instead of printing it"
    echo "  -v        Verbose mode, prints progress messages"
    echo "  -h        Show this help message"
}

# --------------------------------------------------------------------------
# Functions that collect and print each section of the report
# --------------------------------------------------------------------------

show_os_info() {
    log_info "Collecting operating system information"
    print_section_title "OPERATING SYSTEM"

    # --- Distribution name ---
    # We read the PRETTY_NAME line from /etc/os-release ourselves instead of
    # "source"-ing the file. Sourcing it would run it as a shell script,
    # which could overwrite our own variables if the file ever contained
    # something unexpected. Reading just the one line we need is safer.
    # /etc/os-release is the standard way distributions identify themselves
    # on Ubuntu, Debian, Fedora, Arch, Rocky, and CentOS alike.
    local distro_name=""
    if [ -r /etc/os-release ]; then
        distro_name=$(grep -m 1 '^PRETTY_NAME=' /etc/os-release | cut -d '=' -f2- | tr -d '"')
    fi
    [ -z "$distro_name" ] && distro_name="Unknown"

    # --- Hostname ---
    local host_name=""
    if command_exists hostname; then
        host_name=$(hostname 2>/dev/null)
    elif [ -r /proc/sys/kernel/hostname ]; then
        read -r host_name < /proc/sys/kernel/hostname
    fi
    [ -z "$host_name" ] && host_name="Unavailable"

    # --- Kernel version and architecture ---
    # "uname -rm" prints both the release and machine type in a single
    # command instead of calling uname twice.
    local kernel_version="" arch=""
    if command_exists uname; then
        read -r kernel_version arch <<< "$(uname -rm 2>/dev/null)"
    fi
    [ -z "$kernel_version" ] && kernel_version="Unknown"
    [ -z "$arch" ] && arch="Unknown"

    # --- Uptime ---
    local uptime_info=""
    if command_exists uptime; then
        # Not every version of "uptime" supports the "-p" (pretty) option,
        # so fall back to the plain output if "-p" gives nothing.
        uptime_info=$(uptime -p 2>/dev/null)
        [ -z "$uptime_info" ] && uptime_info=$(uptime 2>/dev/null)
    fi
    [ -z "$uptime_info" ] && uptime_info="Unavailable"

    echo "Hostname     : $host_name"
    echo "Distribution : $distro_name"
    echo "Kernel       : $kernel_version"
    echo "Architecture : $arch"
    echo "Uptime       : $uptime_info"
    echo
}

show_cpu_info() {
    log_info "Collecting CPU information"
    print_section_title "CPU INFORMATION"

    # --- CPU model name ---
    local cpu_model=""
    if [ -r /proc/cpuinfo ]; then
        cpu_model=$(grep -m 1 "model name" /proc/cpuinfo | cut -d ':' -f2- | sed 's/^ *//')
        # Some systems (for example ARM boards) do not have "model name"
        # in /proc/cpuinfo, but they usually have a "Hardware" line instead.
        if [ -z "$cpu_model" ]; then
            cpu_model=$(grep -m 1 "^Hardware" /proc/cpuinfo | cut -d ':' -f2- | sed 's/^ *//')
        fi
    fi
    [ -z "$cpu_model" ] && cpu_model="Unknown"

    # --- Number of CPU cores ---
    local cpu_cores=""
    if command_exists nproc; then
        cpu_cores=$(nproc 2>/dev/null)
    elif [ -r /proc/cpuinfo ]; then
        cpu_cores=$(grep -c "^processor" /proc/cpuinfo)
    fi
    [ -z "$cpu_cores" ] && cpu_cores="Unknown"

    echo "Model        : $cpu_model"
    echo "CPU cores    : $cpu_cores"

    # --- Load average ---
    # /proc/loadavg looks like: 0.12 0.09 0.05 1/234 5678
    # The first three numbers are the 1, 5 and 15 minute load averages.
    local load_1="Unavailable" load_5="Unavailable" load_15="Unavailable"
    if [ -r /proc/loadavg ]; then
        read -r load_1 load_5 load_15 _ < /proc/loadavg
    fi
    echo "Load average : $load_1 (1 min), $load_5 (5 min), $load_15 (15 min)"
    echo
}

show_memory_info() {
    log_info "Collecting memory information"
    print_section_title "MEMORY USAGE"

    if command_exists free; then
        free -h
    elif [ -r /proc/meminfo ]; then
        # Basic fallback when "free" is not installed: read the raw numbers
        # (in kilobytes) straight from /proc/meminfo and convert to MB.
        # One awk call reads both values instead of running awk twice.
        local total_kb avail_kb
        read -r total_kb avail_kb <<< "$(awk '
            /^MemTotal:/     {total = $2}
            /^MemAvailable:/ {avail = $2}
            /^MemFree:/      {if (avail == "") avail = $2}
            END              {print total, avail}
        ' /proc/meminfo)"

        if [ -n "$total_kb" ] && [ "$total_kb" -gt 0 ] 2>/dev/null; then
            [ -z "$avail_kb" ] && avail_kb=0
            local used_kb=$((total_kb - avail_kb))
            echo "Total memory     : $((total_kb / 1024)) MB"
            echo "Used memory      : $((used_kb / 1024)) MB"
            echo "Available memory : $((avail_kb / 1024)) MB"
        else
            echo "Memory information unavailable."
        fi
    else
        print_unavailable "'free'" "memory info"
    fi
    echo
}

show_disk_info() {
    log_info "Collecting disk usage information"
    print_section_title "DISK USAGE"

    if command_exists df; then
        # -h        : human readable sizes (GB/MB instead of raw bytes)
        # -x tmpfs  : hide temporary in-memory file systems
        # -x squashfs: hide squashfs mounts (e.g. Snap packages on Ubuntu),
        #             which are not real disks and just add noise
        if ! df -h -x tmpfs -x devtmpfs -x squashfs 2>/dev/null; then
            echo "Error: could not read disk usage information."
        fi
    elif command_exists stat; then
        # Very basic fallback for the root filesystem only, using "stat".
        # One "stat" call reads total blocks, free blocks, and block size
        # together instead of running the command three separate times.
        local total_blocks free_blocks block_size
        read -r total_blocks free_blocks block_size <<< "$(stat -f --format="%b %f %S" / 2>/dev/null)"

        if [ -n "$total_blocks" ] && [ "$total_blocks" -gt 0 ] 2>/dev/null \
           && [ -n "$block_size" ] && [ "$block_size" -gt 0 ] 2>/dev/null; then
            local used_blocks=$((total_blocks - free_blocks))
            local total_mb=$(((total_blocks * block_size) / 1024 / 1024))
            local used_mb=$(((used_blocks * block_size) / 1024 / 1024))
            echo "Root filesystem (/): ${used_mb} MB used of ${total_mb} MB total"
        else
            echo "Disk usage information unavailable."
        fi
    else
        print_unavailable "'df'" "disk info"
    fi
    echo
}

show_network_info() {
    log_info "Collecting network information"
    print_section_title "NETWORK INFORMATION"

    # --- IP address(es) ---
    local ip_list=""
    if command_exists hostname; then
        ip_list=$(hostname -I 2>/dev/null)
    fi
    if [ -z "$ip_list" ] && command_exists ip; then
        ip_list=$(ip -4 -o addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | tr '\n' ' ')
    fi
    # "hostname -I" and the "tr" fallback above both tend to leave one
    # trailing space at the end; trim it so the line looks clean.
    ip_list="${ip_list% }"
    [ -z "$ip_list" ] && ip_list="Unavailable (no active network connection?)"
    echo "IP address(es): $ip_list"
    echo

    # --- Network interfaces ---
    echo "Network interfaces:"
    local interface_list=""
    if command_exists ip; then
        interface_list=$(ip -brief addr show 2>/dev/null)
    elif command_exists ifconfig; then
        interface_list=$(ifconfig 2>/dev/null | awk '
            /^[a-zA-Z0-9]/ {iface=$1; sub(":", "", iface)}
            /inet /{print "  " iface "  " $2}')
    fi

    if [ -n "$interface_list" ]; then
        echo "$interface_list"
    elif command_exists ip || command_exists ifconfig; then
        echo "No network interfaces found."
    else
        print_unavailable "'ip' or 'ifconfig'" "interface list"
    fi
    echo
}

show_logged_in_users() {
    log_info "Checking logged in users"
    print_section_title "LOGGED IN USERS"

    local who_output=""
    if command_exists who; then
        who_output=$(who 2>/dev/null)
    elif command_exists w; then
        who_output=$(w 2>/dev/null)
    fi

    if [ -n "$who_output" ]; then
        echo "$who_output"
    elif command_exists who || command_exists w; then
        echo "No users currently logged in."
    else
        print_unavailable "'who' or 'w'" "this section"
    fi
    echo
}

show_internet_status() {
    log_info "Checking internet connectivity"
    print_section_title "INTERNET CONNECTIVITY"

    if command_exists ping; then
        # Send a single ping to a well known DNS server, wait at most 2 seconds.
        if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
            echo "Status: Connected to the internet"
        else
            echo "Status: No internet connection detected"
        fi
    else
        print_unavailable "'ping'" "connectivity check"
    fi
    echo
}

show_top_processes() {
    log_info "Collecting top CPU consuming processes"
    print_section_title "TOP 5 PROCESSES (by CPU usage)"

    if command_exists ps; then
        local process_list
        process_list=$(ps -eo pid,comm,%cpu,%mem --sort=-%cpu --no-headers 2>/dev/null | head -n 5)
        if [ -n "$process_list" ]; then
            printf "%-8s %-20s %-6s %-6s\n" "PID" "NAME" "CPU%" "MEM%"
            echo "$process_list" | awk '{printf "%-8s %-20s %-6s %-6s\n", $1, $2, $3, $4}'
        else
            echo "Could not retrieve process information."
        fi
    else
        print_unavailable "'ps'" "process info"
    fi
    echo
}

# --------------------------------------------------------------------------
# Builds the full report by calling each section function in order.
# --------------------------------------------------------------------------
generate_report() {
    echo "=========================================="
    echo "      SYSTEM INFORMATION REPORT"
    echo "      Generated on: $(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo Unknown)"
    echo "=========================================="
    echo

    show_os_info
    show_cpu_info
    show_memory_info
    show_disk_info
    show_network_info
    show_logged_in_users
    show_internet_status
    show_top_processes

    echo "=========================================="
    echo "              END OF REPORT"
    echo "=========================================="
}

# --------------------------------------------------------------------------
# Read command line options
#
# The leading ":" in ":o:vh" puts getopts into "silent error" mode, so we
# can print our own clear error messages instead of Bash's default ones.
# --------------------------------------------------------------------------
while getopts ":o:vh" cli_option; do
    case "$cli_option" in
        o)
            if [ -z "$OPTARG" ]; then
                echo "Error: -o requires a filename, e.g. -o report.txt" >&2
                exit 1
            fi
            OUTPUT_FILE="$OPTARG"
            ;;
        v)
            VERBOSE=true
            ;;
        h)
            show_help
            exit 0
            ;;
        \?)
            echo "Error: invalid option -$OPTARG" >&2
            show_help
            exit 1
            ;;
        :)
            echo "Error: option -$OPTARG requires an argument" >&2
            show_help
            exit 1
            ;;
    esac
done
shift $((OPTIND - 1))

# Any leftover arguments are not supported by this script.
if [ $# -gt 0 ]; then
    echo "Error: unexpected argument(s): $*" >&2
    show_help
    exit 1
fi

# --------------------------------------------------------------------------
# Main program
# --------------------------------------------------------------------------
if [ -n "$OUTPUT_FILE" ]; then
    # Make sure the folder we are writing into actually exists, so we can
    # give a clear error message instead of a confusing one from Bash.
    report_dir=$(dirname -- "$OUTPUT_FILE")
    if [ ! -d "$report_dir" ]; then
        echo "Error: directory '$report_dir' does not exist." >&2
        exit 1
    fi

    if generate_report > "$OUTPUT_FILE"; then
        echo "Report saved to: $OUTPUT_FILE"
    else
        echo "Error: could not write to '$OUTPUT_FILE'. Check the file path and permissions." >&2
        exit 1
    fi
else
    generate_report
fi

exit 0
