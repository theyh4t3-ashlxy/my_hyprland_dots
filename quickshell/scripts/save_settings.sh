#!/usr/bin/env bash
set -euo pipefail

CONF_FILE="$HOME/.config/quickshell/settings.conf"
payload="${1:-}"

if [[ -z "$payload" ]]; then
    payload=$(cat)
fi

printf "%s\n" "$payload" > "$CONF_FILE.tmp"
mv "$CONF_FILE.tmp" "$CONF_FILE"
