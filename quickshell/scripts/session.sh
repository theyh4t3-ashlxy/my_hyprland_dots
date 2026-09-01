#!/usr/bin/env bash
set -euo pipefail

action="${1:-}"

case "$action" in
    poweroff|shutdown)
        systemctl poweroff
        ;;
    reboot)
        systemctl reboot
        ;;
    suspend)
        systemctl suspend
        ;;
    logout|exit)
        hyprctl dispatch exit || true
        ;;
    lock)
        loginctl lock-session || true
        ;;
    *)
        echo "Usage: $0 {poweroff|reboot|suspend|logout|lock}"
        exit 1
        ;;
esac
