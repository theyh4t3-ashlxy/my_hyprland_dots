#!/usr/bin/env python3
import json
import shutil
import subprocess
import sys
import time

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

def run_hyprctl(args: list[str]) -> bool:
    """hyprctl returns exit status 0 even on dispatch failure, so verify stdout."""
    if not shutil.which("hyprctl"):
        return False
    try:
        res = subprocess.run(
            ["hyprctl", *args],
            capture_output=True,
            text=True
        )
        return res.returncode == 0 and res.stdout.strip() == "ok"
    except Exception:
        return False

def lock_session() -> bool:
    """Lock screen via native Quickshell IPC with loginctl fallback."""
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
        "-a", "session manager",
        "-i", "system-lock-screen",
        "Screen lock failed",
        "Quickshell lock IPC did not respond!"
    ])
    return False

def toggle_caffeine():
    """Toggle Quickshell idle monitor on/off (Caffeine mode)."""
    if not shutil.which("qs"):
        run(["notify-send", "-u", "critical", "idle monitor", "qs executable not found!"])
        return False

    try:
        res = subprocess.run(
            ["qs", "ipc", "call", "idle", "toggle"],
            capture_output=True,
            text=True
        )
        if res.returncode == 0:
            raw = res.stdout.strip().lower()

            # Attempt to parse json / bool / int strings safely
            is_enabled = None
            try:
                parsed = json.loads(raw)
                if isinstance(parsed, bool):
                    is_enabled = parsed
                elif isinstance(parsed, dict) and "enabled" in parsed:
                    is_enabled = bool(parsed["enabled"])
            except Exception:
                pass

            if is_enabled is None:
                is_enabled = raw in ("true", "1", "on")

            new_state = "enabled" if is_enabled else "inhibited (caffeine active)"
            icon = "preferences-desktop-screensaver" if is_enabled else "caffeine"

            run([
                "notify-send",
                "-a", "idle monitor",
                "-i", icon,
                "Idle Timeout Changed",
                f"Quickshell idle is now {new_state}"
            ])
            return True
    except Exception:
        pass

    run(["notify-send", "-u", "critical", "idle monitor", "Failed to communicate with quickshell idle service!"])
    return False

def logout_session() -> bool:
    """Clean exit order: UWSM -> hyprshutdown -> hyprctl dispatch exit."""
    # 1. UWSM managed session
    if shutil.which("uwsm") and run(["uwsm", "stop"]):
        return True

    # 2. Dedicated shutdown helper
    if shutil.which("hyprshutdown") and run(["hyprshutdown"]):
        return True

    # 3. Hyprland dispatcher (check for 'ok' output)
    if run_hyprctl(["dispatch", "hl.dsp.exit()"]):
        return True
    if run_hyprctl(["dispatch", "exit"]):
        return True

    return False

def suspend_system():
    """Lock first, allow the lock surface to engage, then suspend."""
    if not lock_session():
        run([
            "notify-send",
            "-u", "critical",
            "-a", "power manager",
            "Suspend Aborted",
            "Refusing to suspend: screen locker failed to engage!"
        ])
        return

    # Give Wayland compositor breathing room to paint the lock surface
    time.sleep(0.4)
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
