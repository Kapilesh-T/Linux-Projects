#!/usr/bin/env bash
# uninstall.sh — remove the symlink created by install.sh.
#
# Only removes the exact symlink this project's installer creates, and
# only if it still points into this project directory. It will never
# delete an unrelated file that happens to share the name.

set -Eeuo pipefail

readonly INSTALL_BIN_DIR="${HOME}/.local/bin"
readonly INSTALL_NAME="organizer"

SCRIPT_DIR="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
readonly SCRIPT_DIR

target="${INSTALL_BIN_DIR}/${INSTALL_NAME}"

if [[ ! -e "$target" ]]; then
    echo "Nothing to do: ${target} does not exist."
    exit 0
fi

if [[ ! -L "$target" ]]; then
    echo "error: ${target} exists but is not a symlink — refusing to remove a real file." >&2
    exit 1
fi

link_dest="$(readlink -- "$target")"
if [[ "$link_dest" != "${SCRIPT_DIR}"/* ]]; then
    echo "error: ${target} does not point into this project (${SCRIPT_DIR}) — refusing to remove." >&2
    echo "It points to: ${link_dest}" >&2
    exit 1
fi

rm -- "$target"
echo "Removed: ${target}"
