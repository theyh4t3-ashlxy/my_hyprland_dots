#!/usr/bin/env bash
set -euo pipefail

PID_FILE="/tmp/qs_caffeine.pid"
action="${1:-toggle}"

is_running() {
    if [[ -f "$PID_FILE" ]]; then
        local pid
        pid=$(cat "$PID_FILE" 2>/dev/null || echo "")
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            return 0
        fi
    fi
    return 1
}

case "$action" in
    start)
        if ! is_running; then
            systemd-inhibit --what=idle --who=quickshell --why='caffeine' sleep infinity &
            echo $! > "$PID_FILE"
        fi
        ;;
    stop)
        if [[ -f "$PID_FILE" ]]; then
            pid=$(cat "$PID_FILE" 2>/dev/null || echo "")
            if [[ -n "$pid" ]]; then
                kill "$pid" 2>/dev/null || true
            fi
            rm -f "$PID_FILE"
        fi
        ;;
    toggle)
        if is_running; then
            "$0" stop
        else
            "$0" start
        fi
        ;;
    status)
        if is_running; then
            echo "active"
            exit 0
        else
            echo "inactive"
            exit 1
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|toggle|status}"
        exit 1
        ;;
esac
