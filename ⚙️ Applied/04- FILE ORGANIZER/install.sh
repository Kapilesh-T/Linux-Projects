#!/usr/bin/env bash
# install.sh — install linux-file-organizer for the current user.
#
# Does NOT require root. Installs by symlinking organizer.sh (and its
# lib/ and config/ dependencies stay in place — the symlink resolution
# in organizer.sh finds them via its own real path) into a directory on
# the user's PATH.

set -Eeuo pipefail

readonly INSTALL_BIN_DIR="${HOME}/.local/bin"
readonly INSTALL_NAME="organizer"

SCRIPT_DIR="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
readonly SCRIPT_DIR
readonly SOURCE_SCRIPT="${SCRIPT_DIR}/organizer.sh"

if [[ ! -f "$SOURCE_SCRIPT" ]]; then
    echo "error: organizer.sh not found next to install.sh (looked in ${SCRIPT_DIR})" >&2
    exit 1
fi

mkdir -p -- "$INSTALL_BIN_DIR"

chmod +x -- "$SOURCE_SCRIPT"

target="${INSTALL_BIN_DIR}/${INSTALL_NAME}"
if [[ -e "$target" && ! -L "$target" ]]; then
    echo "error: ${target} already exists and is not a symlink managed by this installer." >&2
    echo "Remove it manually if you want to proceed." >&2
    exit 1
fi

ln -sf -- "$SOURCE_SCRIPT" "$target"
echo "Installed: ${target} -> ${SOURCE_SCRIPT}"

if [[ ":$PATH:" != *":${INSTALL_BIN_DIR}:"* ]]; then
    echo
    echo "NOTE: ${INSTALL_BIN_DIR} is not currently on your PATH."
    echo "Add this to your ~/.bashrc or ~/.profile:"
    echo
    echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo
fi

echo "Run 'organizer --help' (after opening a new shell, or PATH updates) to get started."
