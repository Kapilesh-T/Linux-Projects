#!/bin/bash

# =============================================================================
# Password Generator Script — Enhanced Edition
# Description : Generates a cryptographically random password with a strength
#               indicator, optional clipboard copy, flexible file saving, and
#               a re-run loop so you can create multiple passwords in one session.
# Usage       : bash password_generator.sh
#               chmod +x password_generator.sh && ./password_generator.sh
# =============================================================================

# Disable history expansion so that ! inside strings never triggers
# "event not found" errors.  This is a no-op on Linux (where histexpand is
# already off in non-interactive scripts) and fixes the root cause on Git Bash.
set +H

# --- ANSI color codes for a cleaner, more readable terminal experience ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# --- Character sets used to build the password ---
UPPERCASE="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
LOWERCASE="abcdefghijklmnopqrstuvwxyz"
DIGITS="0123456789"
# Single quotes prevent ! from triggering history expansion in Git Bash.
# The hyphen (-) is placed last so that tr never misreads it as a range
# operator (e.g. the original "()-_" was interpreted by tr as the range
# from ')' to '_', pulling ~50 extra ASCII characters into the keep-set).
SPECIAL='!@#$%^&*()_=+[]{}|;:,.<>?-'
ALL_CHARS="${UPPERCASE}${LOWERCASE}${DIGITS}${SPECIAL}"

# =============================================================================
# FUNCTION: show_banner
# Purpose : Prints the welcome header once at script startup.
# =============================================================================
show_banner() {
    echo ""
    echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}${BOLD}║        Welcome to Password Generator     ║${RESET}"
    echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════╝${RESET}"
    echo ""
}

# =============================================================================
# FUNCTION: validate_input
# Purpose : Checks that the user's length value is a valid number in range.
# Arguments: $1 — the raw string the user typed
# Returns  : 0 (success) if valid, 1 (failure) if not — also prints an error.
# =============================================================================
validate_input() {
    local input="$1"

    # Reject empty input
    if [ -z "$input" ]; then
        echo -e "${RED}  Error: No input provided. Please enter a number.${RESET}"
        return 1
    fi

    # Reject anything that contains a non-digit character (letters, spaces, dots…)
    if echo "$input" | grep -qE '[^0-9]'; then
        echo -e "${RED}  Error: '$input' is not a valid number. Please enter a positive integer.${RESET}"
        return 1
    fi

    # Enforce minimum length
    if [ "$input" -lt 4 ]; then
        echo -e "${RED}  Error: Minimum password length is 4 characters.${RESET}"
        return 1
    fi

    # Enforce maximum length to keep execution fast and sensible
    if [ "$input" -gt 128 ]; then
        echo -e "${RED}  Error: Maximum password length is 128 characters.${RESET}"
        return 1
    fi

    return 0
}

# =============================================================================
# FUNCTION: show_strength
# Purpose : Displays a color-coded strength label and a visual progress bar
#           based on the requested password length.
# Arguments: $1 — the password length (integer)
# =============================================================================
show_strength() {
    local length="$1"
    local label color bar

    if [ "$length" -lt 8 ]; then
        label="Weak";        color="${RED}";           bar="██░░░░░░░░"
    elif [ "$length" -lt 12 ]; then
        label="Fair";        color="${YELLOW}";        bar="████░░░░░░"
    elif [ "$length" -lt 16 ]; then
        label="Strong";      color="${GREEN}";         bar="███████░░░"
    else
        label="Very Strong"; color="${GREEN}${BOLD}";  bar="██████████"
    fi

    echo -e "  Strength : ${color}${bar}  ${label}${RESET}"
}

# =============================================================================
# FUNCTION: generate_password
# Purpose : Builds a random password that is guaranteed to contain at least
#           one uppercase letter, one lowercase letter, one digit, and one
#           special character. The rest is filled from the full character pool.
#           All characters are then shuffled so the guaranteed ones are not
#           predictably placed at the beginning.
# Arguments: $1 — desired password length (already validated)
# Output  : Prints the finished password to stdout.
# =============================================================================
generate_password() {
    local length="$1"
    local char_upper char_lower char_digit char_special char_rest combined password

    # Pull one guaranteed character from each required category
    char_upper=$(cat /dev/urandom | tr -dc "$UPPERCASE" | head -c 1)
    char_lower=$(cat /dev/urandom | tr -dc "$LOWERCASE" | head -c 1)
    char_digit=$(cat /dev/urandom | tr -dc "$DIGITS"    | head -c 1)
    char_special=$(cat /dev/urandom | tr -dc "$SPECIAL" | head -c 1)

    # Fill the remaining slots with characters from the full pool
    local remaining=$(( length - 4 ))
    char_rest=$(cat /dev/urandom | tr -dc "$ALL_CHARS" | head -c "$remaining")

    # Concatenate all parts, then shuffle character-by-character with 'shuf'
    combined="${char_upper}${char_lower}${char_digit}${char_special}${char_rest}"
    password=$(echo "$combined" | fold -w1 | shuf | tr -d '\n')

    echo "$password"
}

# =============================================================================
# FUNCTION: copy_to_clipboard
# Purpose : Copies the password to the system clipboard using the first
#           available tool: xclip or xsel (Linux), clip.exe (Git Bash /
#           Windows). Warns the user if none is found.
# Arguments: $1 — the password string
# =============================================================================
copy_to_clipboard() {
    local password="$1"

    # 'command -v' checks whether a program is installed without running it
    if command -v xclip &>/dev/null; then
        echo -n "$password" | xclip -selection clipboard
        echo -e "  ${GREEN}✔ Password copied to clipboard (xclip).${RESET}"
    elif command -v xsel &>/dev/null; then
        echo -n "$password" | xsel --clipboard --input
        echo -e "  ${GREEN}✔ Password copied to clipboard (xsel).${RESET}"
    elif command -v clip &>/dev/null; then
        # clip.exe is the native Windows clipboard tool available in Git Bash
        echo -n "$password" | clip
        echo -e "  ${GREEN}✔ Password copied to clipboard (clip).${RESET}"
    else
        echo -e "  ${YELLOW}⚠ No clipboard tool found (xclip/xsel/clip). Skipping clipboard copy.${RESET}"
        echo -e "  ${YELLOW}  On Linux, install one with: sudo apt install xclip${RESET}"
    fi
}

# =============================================================================
# FUNCTION: save_password
# Purpose : Saves the password to 'generated_password.txt' in the current
#           directory. If the file already exists, the user can choose to
#           append (keeping history), overwrite, or cancel. Each saved entry
#           is prefixed with a timestamp for easy reference.
# Arguments: $1 — the password string
# =============================================================================
save_password() {
    local password="$1"
    local filename="generated_password.txt"
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")      # e.g. 2025-06-15 14:30:00
    local entry="[${timestamp}]  ${password}"

    if [ -f "$filename" ]; then
        # File already exists — ask the user how to proceed
        echo ""
        echo -e "  ${YELLOW}⚠ '$filename' already exists. What would you like to do?${RESET}"
        echo "     [1] Append  — add this password to the existing file"
        echo "     [2] Overwrite — replace the file with only this password"
        echo "     [3] Cancel  — do not save"
        echo ""
        echo -n "  Your choice (1/2/3): "
        read SAVE_MODE

        case "$SAVE_MODE" in
            1)
                echo "$entry" >> "$filename"
                echo -e "  ${GREEN}✔ Password appended to '$filename'.${RESET}"
                ;;
            2)
                echo "$entry" > "$filename"
                echo -e "  ${GREEN}✔ '$filename' overwritten with the new password.${RESET}"
                ;;
            *)
                echo -e "  ${YELLOW}Save cancelled.${RESET}"
                ;;
        esac
    else
        # File does not exist yet — create it
        echo "$entry" > "$filename"
        echo -e "  ${GREEN}✔ Password saved to '$filename'.${RESET}"
    fi
}

# =============================================================================
# MAIN LOOP
# The script keeps running until the user chooses not to generate another
# password, making it possible to create several passwords in one session.
# =============================================================================
show_banner

while true; do

    # ── STEP 1: Prompt for length — loop until valid input is given ──────────
    while true; do
        echo -ne "  Enter desired password length ${BOLD}(4 - 128)${RESET}: "
        read LENGTH
        validate_input "$LENGTH" && break
        echo ""
    done

    echo ""
    echo -e "  ${BLUE}Generating your password...${RESET}"
    echo ""

    # ── STEP 2: Generate the password ────────────────────────────────────────
    PASSWORD=$(generate_password "$LENGTH")

    # ── STEP 3: Display the password and its strength rating ─────────────────
    echo -e "${BOLD}  ╔══════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}  ║${RESET}  Password : ${GREEN}${BOLD}${PASSWORD}${RESET}"
    show_strength "$LENGTH"
    echo -e "${BOLD}  ╚══════════════════════════════════════════╝${RESET}"
    echo ""

    # ── STEP 4: Offer clipboard copy ─────────────────────────────────────────
    echo -ne "  Copy password to clipboard? ${BOLD}(yes/no)${RESET}: "
    read CLIP_CHOICE
    CLIP_CHOICE=$(echo "$CLIP_CHOICE" | tr '[:upper:]' '[:lower:]')
    if [ "$CLIP_CHOICE" = "yes" ] || [ "$CLIP_CHOICE" = "y" ]; then
        copy_to_clipboard "$PASSWORD"
    fi

    echo ""

    # ── STEP 5: Offer to save to file ────────────────────────────────────────
    echo -ne "  Save password to 'generated_password.txt'? ${BOLD}(yes/no)${RESET}: "
    read SAVE_CHOICE
    SAVE_CHOICE=$(echo "$SAVE_CHOICE" | tr '[:upper:]' '[:lower:]')
    if [ "$SAVE_CHOICE" = "yes" ] || [ "$SAVE_CHOICE" = "y" ]; then
        save_password "$PASSWORD"
    else
        echo -e "  ${YELLOW}Password was not saved to file.${RESET}"
    fi

    echo ""

    # ── STEP 6: Ask whether to generate another password ─────────────────────
    echo -ne "  Generate another password? ${BOLD}(yes/no)${RESET}: "
    read AGAIN
    AGAIN=$(echo "$AGAIN" | tr '[:upper:]' '[:lower:]')
    echo ""

    # Exit the loop (and the script) if the user says anything other than yes/y
    if [ "$AGAIN" != "yes" ] && [ "$AGAIN" != "y" ]; then
        echo -e "${CYAN}${BOLD}  Thank you for using Password Generator. Stay safe!${RESET}"
        echo ""
        break
    fi

    # Divider before the next iteration
    echo -e "${CYAN}${BOLD}  ──────────────────────────────────────────${RESET}"
    echo ""

done
