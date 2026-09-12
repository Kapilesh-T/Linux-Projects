#!/usr/bin/env bash
# lib/categorize.sh
#
# Defines the extension -> category mapping used to decide which folder
# a file is moved into, and the lookup function that uses it.
#
# This file is *sourced*, not executed, so it deliberately does not have
# its own shebang-executed logic beyond variable/function definitions.
# shellcheck shell=bash

# Guard against being sourced twice in the same shell (e.g. by both
# organizer.sh and the test suite).
if [[ -n "${_ORGANIZER_CATEGORIZE_LOADED:-}" ]]; then
    return 0
fi
_ORGANIZER_CATEGORIZE_LOADED=1

# Associative array: lowercase extension (no leading dot) -> category
# folder name. This is the single source of truth for categorization.
#
# Design note: an associative array gives O(1) lookup and, importantly,
# can be extended at runtime by config/organizer.conf without touching
# this file — see load_config() in organizer.sh.
declare -gA EXT_TO_CATEGORY=(
    # Images
    [jpg]="Images" [jpeg]="Images" [png]="Images" [gif]="Images"
    [webp]="Images" [svg]="Images" [bmp]="Images"

    # Videos
    [mp4]="Videos" [mkv]="Videos" [avi]="Videos" [mov]="Videos"
    [webm]="Videos" [flv]="Videos"

    # Audio
    [mp3]="Audio" [wav]="Audio" [flac]="Audio" [aac]="Audio"
    [ogg]="Audio" [m4a]="Audio"

    # Documents
    [pdf]="Documents" [doc]="Documents" [docx]="Documents"
    [txt]="Documents" [odt]="Documents" [rtf]="Documents"

    # Spreadsheets
    [xls]="Spreadsheets" [xlsx]="Spreadsheets" [csv]="Spreadsheets"
    [ods]="Spreadsheets"

    # Presentations
    [ppt]="Presentations" [pptx]="Presentations" [odp]="Presentations"

    # Archives
    [zip]="Archives" [tar]="Archives" [gz]="Archives" [bz2]="Archives"
    [xz]="Archives" [7z]="Archives" [rar]="Archives"

    # Code
    [c]="Code" [cpp]="Code" [h]="Code" [hpp]="Code" [py]="Code"
    [js]="Code" [ts]="Code" [java]="Code" [go]="Code" [rs]="Code"
    [php]="Code" [sh]="Code" [html]="Code" [css]="Code"

    # Disk images
    [iso]="DiskImages" [img]="DiskImages"

    # Executables / packages
    [deb]="Packages" [rpm]="Packages" [appimage]="Packages"
)

# The name used for anything that doesn't match a known extension,
# and for extensionless files.
readonly CATEGORY_OTHERS="Others"

# category_for_file FILENAME
#
# Prints the category folder name for a given filename (basename or full
# path — only the extension is inspected). Falls back to $CATEGORY_OTHERS
# for unknown or missing extensions.
#
# Multi-dot filenames (e.g. archive.tar.gz) intentionally use only the
# *last* extension component (".gz"), matching common OS/file-manager
# behavior. This is documented in docs/usage.md since "tar.gz" ending up
# in Archives via ".gz" rather than a dedicated "tar.gz" rule is a
# deliberate simplification, not an oversight.
category_for_file() {
    local filename="$1"
    local base ext

    base="${filename##*/}"

    # No dot, or dotfile with no extension after the leading dot
    # (e.g. ".bashrc" has no "real" extension) -> Others.
    if [[ "$base" != *.* ]] || [[ "$base" == .* && "$base" != *.*.* ]]; then
        printf '%s\n' "$CATEGORY_OTHERS"
        return 0
    fi

    ext="${base##*.}"
    ext="${ext,,}" # lowercase, for case-insensitive matching (JPG == jpg)

    printf '%s\n' "${EXT_TO_CATEGORY[$ext]:-$CATEGORY_OTHERS}"
}

# all_category_names
#
# Prints every distinct category folder name currently in the mapping,
# one per line, plus $CATEGORY_OTHERS. Used by fsops.sh to build the
# recursive-scan exclusion (prune) list so the organizer never re-scans
# its own output directories.
all_category_names() {
    local -A seen=()
    local cat
    for cat in "${EXT_TO_CATEGORY[@]}"; do
        seen["$cat"]=1
    done
    seen["$CATEGORY_OTHERS"]=1
    printf '%s\n' "${!seen[@]}"
}
