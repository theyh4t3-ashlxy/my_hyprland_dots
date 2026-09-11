#!/usr/bin/env python3
import sys
import time
import shutil
import subprocess

def run(cmd: list[str]) -> bool:
    """Run command quietly and return True if exit code is 0."""
    if not shutil.which(cmd[0]):
        return False
    try:
        res = subprocess.run(
            cmd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
        return res.returncode == 0
    except Exception:
        return False

def lock_session() -> bool:
    """Lock screen via native Quickshell IPC."""
    # 1. Primary: Quickshell IPC lock
    if run(["qs", "ipc", "call", "lock", "lock"]):
        return True

    # 2. Fallback: logind lock-session
    if run(["loginctl", "lock-session"]):
        return True

    # Fallback notification if lock failed completely
    run([
        "notify-send",
        "-u", "critical",
        "-a", "Session Manager",
        "-i", "system-lock-screen",
        "Screen Lock Failed",
        "Quickshell lock IPC did not respond!"
    ])
    return False

def toggle_caffeine():
    """Toggle Quickshell idle monitor on/off (Caffeine mode)."""
    try:
        res = subprocess.run(
            ["qs", "ipc", "call", "idle", "toggle"],
            capture_output=True,
            text=True
        )
        if res.returncode == 0:
            # qs ipc prints the returned boolean value
            new_state = "enabled" if "true" in res.stdout.lower() else "inhibited (caffeine active)"
            icon = "caffeine" if "inhibited" in new_state else "preferences-desktop-screensaver"
            run([
                "notify-send",
                "-a", "Idle Monitor",
                "-i", icon,
                "Idle Timeout Changed",
                f"Quickshell idle is now {new_state}"
            ])
            return True
    except Exception:
        pass

    run(["notify-send", "-u", "critical", "Idle Monitor", "Failed to communicate with Quickshell idle service!"])
    return False

def logout_session() -> bool:
    """Clean exit order: UWSM -> hyprshutdown -> hyprctl dispatch exit."""
    teardown_cmds = [
        ["uwsm", "stop"],
        ["hyprshutdown"],
        ["hyprctl", "dispatch", "hl.dsp.exit()"],
        ["hyprctl", "dispatch", "exit"]
    ]
    for cmd in teardown_cmds:
        if run(cmd):
            return True
    return False

def suspend_system():
    """Lock first, allow the lock surface to engage, then suspend."""
    lock_session()
    time.sleep(0.2)  # Give Wayland compositor a split second to latch the lock surface
    run(["systemctl", "suspend"])

def main():
    if len(sys.argv) < 2:
        print("Usage: power.py [lock|logout|suspend|reboot|poweroff|hibernate|caffeine]", file=sys.stderr)
        sys.exit(1)

    action = sys.argv[1].lower()

    actions = {
        "lock": lock_session,
        "logout": logout_session,
        "exit": logout_session,
        "quit": logout_session,
        "suspend": suspend_system,
        "sleep": suspend_system,
        "caffeine": toggle_caffeine,
        "idle-toggle": toggle_caffeine,
        "reboot": lambda: run(["systemctl", "reboot"]),
        "poweroff": lambda: run(["systemctl", "poweroff"]),
        "shutdown": lambda: run(["systemctl", "poweroff"]),
        "hibernate": lambda: run(["systemctl", "hibernate"]),
    }

    handler = actions.get(action)
    if handler:
        handler()
    else:
        print(f"Unknown action: {action}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
