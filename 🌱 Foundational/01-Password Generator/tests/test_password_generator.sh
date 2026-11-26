#!/usr/bin/env bash
set -euo pipefail
script="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/password_generator.sh"
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT
cd "$tmp"
# Exercise the interactive UI with synthetic passwords, never real secrets.
printf '08\nno\nyes\nno\n' | timeout 15 bash "$script" >/dev/null
[[ "$(stat -c %a generated_password.txt)" == 600 ]]
[[ "$(awk '{print length($NF)}' generated_password.txt)" == 8 ]]
rm -- generated_password.txt
printf 'sentinel\n' > protected.txt
ln -s protected.txt generated_password.txt
printf '16\nno\nyes\nno\n' | timeout 15 bash "$script" >/dev/null 2>&1
[[ "$(cat protected.txt)" == sentinel ]]
[[ -L generated_password.txt ]]
timeout 5 bash "$script" </dev/null >/dev/null
echo 'Password generator regression checks passed.'
