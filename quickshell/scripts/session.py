#!/usr/bin/env python3
import sys
import subprocess

def main():
    if len(sys.argv) < 2:
        return
    action = sys.argv[1].lower()

    if action in {"poweroff", "shutdown"}:
        subprocess.run(["systemctl", "poweroff"])
    elif action == "reboot":
        subprocess.run(["systemctl", "reboot"])
    elif action == "suspend":
        subprocess.run(["systemctl", "suspend"])
    elif action in {"logout", "exit"}:
        subprocess.run(["hyprctl", "dispatch", "exit"])
    elif action == "lock":
        # try quickshell ipc first, then loginctl, then hyprlock
        res = subprocess.run(["qs", "ipc", "call", "lock", "lock"], stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)
        if res.returncode != 0:
            res = subprocess.run(["loginctl", "lock-session"], stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)
            if res.returncode != 0:
                subprocess.Popen(["hyprlock"])

if __name__ == "__main__":
    main()
