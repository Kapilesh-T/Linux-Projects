#!/bin/bash
#
# Password Generator
# Generates a random password with a strength indicator, optional
# clipboard copy, and the option to save it to a file. Loops so you
# can generate more than one password per run.
#
# Usage: chmod +x password_generator.sh && ./password_generator.sh

# ! inside a string can trigger "event not found" in Git Bash if history
# expansion is on, so turn it off just in case.
set +H

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

UPPERCASE="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
LOWERCASE="abcdefghijklmnopqrstuvwxyz"
DIGITS="0123456789"
# the hyphen has to go last here — tr treats "()-_" as a *range* from ')'
# to '_' and pulls in a bunch of extra ASCII characters you didn't ask for.
# took me a while to figure out why the special chars looked wrong.
SPECIAL='!@#$%^&*()_=+[]{}|;:,.<>?-'
ALL_CHARS="${UPPERCASE}${LOWERCASE}${DIGITS}${SPECIAL}"

show_banner() {
    echo ""
    echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}${BOLD}║        Welcome to Password Generator     ║${RESET}"
    echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════╝${RESET}"
    echo ""
}

# makes sure the length the user typed is actually a usable number
validate_input() {
    local input="$1"

    if [ -z "$input" ]; then
        echo -e "${RED}  Error: No input provided. Please enter a number.${RESET}"
        return 1
    fi

    if echo "$input" | grep -qE '[^0-9]'; then
        echo -e "${RED}  Error: '$input' is not a valid number. Please enter a positive integer.${RESET}"
        return 1
    fi

    if [ "$input" -lt 4 ]; then
        echo -e "${RED}  Error: Minimum password length is 4 characters.${RESET}"
        return 1
    fi

    if [ "$input" -gt 128 ]; then
        echo -e "${RED}  Error: Maximum password length is 128 characters.${RESET}"
        return 1
    fi

    return 0
}

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

# builds the password. grabs one char from each category first so we're
# guaranteed at least one upper/lower/digit/special, fills the rest from
# the combined pool, then shuffles everything so the guaranteed chars
# aren't always sitting at the start.
generate_password() {
    local length="$1"
    local char_upper char_lower char_digit char_special char_rest combined password

    char_upper=$(tr -dc "$UPPERCASE" < /dev/urandom | head -c 1)
    char_lower=$(tr -dc "$LOWERCASE" < /dev/urandom | head -c 1)
    char_digit=$(tr -dc "$DIGITS"    < /dev/urandom | head -c 1)
    char_special=$(tr -dc "$SPECIAL" < /dev/urandom | head -c 1)

    local remaining=$(( length - 4 ))
    char_rest=$(tr -dc "$ALL_CHARS" < /dev/urandom | head -c "$remaining")

    combined="${char_upper}${char_lower}${char_digit}${char_special}${char_rest}"
    password=$(echo "$combined" | fold -w1 | shuf | tr -d '\n')

    echo "$password"
}

# tries xclip/xsel on Linux, clip.exe on Git Bash/Windows, and just
# skips it with a message if none of those are installed
copy_to_clipboard() {
    local password="$1"

    if command -v xclip &>/dev/null; then
        echo -n "$password" | xclip -selection clipboard
        echo -e "  ${GREEN}✔ Password copied to clipboard (xclip).${RESET}"
    elif command -v xsel &>/dev/null; then
        echo -n "$password" | xsel --clipboard --input
        echo -e "  ${GREEN}✔ Password copied to clipboard (xsel).${RESET}"
    elif command -v clip &>/dev/null; then
        echo -n "$password" | clip
        echo -e "  ${GREEN}✔ Password copied to clipboard (clip).${RESET}"
    else
        echo -e "  ${YELLOW}⚠ No clipboard tool found (xclip/xsel/clip). Skipping clipboard copy.${RESET}"
        echo -e "  ${YELLOW}  On Linux, install one with: sudo apt install xclip${RESET}"
    fi
}

# saves to generated_password.txt, asking to append/overwrite if it
# already exists so you don't lose old passwords by accident
save_password() {
    local password="$1"
    local filename="generated_password.txt"
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local entry="[${timestamp}]  ${password}"

    if [ -f "$filename" ]; then
        echo ""
        echo -e "  ${YELLOW}⚠ '$filename' already exists. What would you like to do?${RESET}"
        echo "     [1] Append  — add this password to the existing file"
        echo "     [2] Overwrite — replace the file with only this password"
        echo "     [3] Cancel  — do not save"
        echo ""
        echo -n "  Your choice (1/2/3): "
        read -r SAVE_MODE

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
        echo "$entry" > "$filename"
        echo -e "  ${GREEN}✔ Password saved to '$filename'.${RESET}"
    fi
}

show_banner

while true; do

    while true; do
        echo -ne "  Enter desired password length ${BOLD}(4 - 128)${RESET}: "
        read -r LENGTH
        validate_input "$LENGTH" && break
        echo ""
    done

    echo ""
    echo -e "  ${BLUE}Generating your password...${RESET}"
    echo ""

    PASSWORD=$(generate_password "$LENGTH")

    echo -e "${BOLD}  ╔══════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}  ║${RESET}  Password : ${GREEN}${BOLD}${PASSWORD}${RESET}"
    show_strength "$LENGTH"
    echo -e "${BOLD}  ╚══════════════════════════════════════════╝${RESET}"
    echo ""

    echo -ne "  Copy password to clipboard? ${BOLD}(yes/no)${RESET}: "
    read -r CLIP_CHOICE
    CLIP_CHOICE=$(echo "$CLIP_CHOICE" | tr '[:upper:]' '[:lower:]')
    if [ "$CLIP_CHOICE" = "yes" ] || [ "$CLIP_CHOICE" = "y" ]; then
        copy_to_clipboard "$PASSWORD"
    fi

    echo ""

    echo -ne "  Save password to 'generated_password.txt'? ${BOLD}(yes/no)${RESET}: "
    read -r SAVE_CHOICE
    SAVE_CHOICE=$(echo "$SAVE_CHOICE" | tr '[:upper:]' '[:lower:]')
    if [ "$SAVE_CHOICE" = "yes" ] || [ "$SAVE_CHOICE" = "y" ]; then
        save_password "$PASSWORD"
    else
        echo -e "  ${YELLOW}Password was not saved to file.${RESET}"
    fi

    echo ""

    echo -ne "  Generate another password? ${BOLD}(yes/no)${RESET}: "
    read -r AGAIN
    AGAIN=$(echo "$AGAIN" | tr '[:upper:]' '[:lower:]')
    echo ""

    if [ "$AGAIN" != "yes" ] && [ "$AGAIN" != "y" ]; then
        echo -e "${CYAN}${BOLD}  Thank you for using Password Generator. Stay safe!${RESET}"
        echo ""
        break
    fi

    echo -e "${CYAN}${BOLD}  ──────────────────────────────────────────${RESET}"
    echo ""

done
