#!/usr/bin/env bash
# linking my sanity before i lose it again
set -euo pipefail

DOTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

mkdir -p "$CONFIG_DIR"

FOLDERS=(
    "hypr"
    "quickshell"
    "matugen"
    "kitty"
    "fastfetch"
    "zsh"
    "yazi"
    "gtk-3.0"
    "gtk-4.0"
)

echo "linking configs from $DOTS_DIR to $CONFIG_DIR..."

for folder in "${FOLDERS[@]}"; do
    src="$DOTS_DIR/$folder"
    target="$CONFIG_DIR/$folder"

    if [[ ! -d "$src" ]]; then
        echo "skipping $folder (not found in repo)"
        continue
    fi

    # flatpak sandbox bwrap breaks if gtk-3.0 / gtk-4.0 or their internal files are external symlinks
    if [[ "$folder" == "gtk-3.0" || "$folder" == "gtk-4.0" ]]; then
        [[ -L "$target" ]] && rm -f "$target"
        mkdir -p "$target"
        for file in "$src"/*; do
            [[ -f "$file" ]] && cp -f "$file" "$target/"
        done
        echo "synced $folder real files -> $target (flatpak sandbox safe)"
        continue
    fi

    # if real folder exists, back it up so we dont destroy anything
    if [[ -d "$target" && ! -L "$target" ]]; then
        backup="${target}.bak.$(date +%s)"
        echo "backing up existing $target -> $backup"
        mv "$target" "$backup"
    fi

    ln -sfn "$src" "$target"
    echo "linked $folder -> $target"
done

echo "all configs linked cleanly. go touch grass."
