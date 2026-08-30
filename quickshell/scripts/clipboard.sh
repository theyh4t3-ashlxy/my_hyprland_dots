#!/usr/bin/env bash
set -euo pipefail

CLIP_FILE="/tmp/qs_curclip.txt"
action="${1:-sync}"

case "$action" in
    sync)
        wl-paste > "$CLIP_FILE" 2>/dev/null || true
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
