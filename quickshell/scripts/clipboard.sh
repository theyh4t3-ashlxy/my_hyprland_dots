#!/usr/bin/env bash
set -euo pipefail

CLIP_FILE="/tmp/qs_curclip.txt"
action="${1:-sync}"

case "$action" in
    sync)
        wl-paste --type text 2>/dev/null | head -c 100000 > "$CLIP_FILE" || true
        ;;
    copy)
        shift
        wl-copy -- "$@"
        ;;
    *)
        echo "Usage: $0 {sync|copy <content>}"
        exit 1
        ;;
esac
