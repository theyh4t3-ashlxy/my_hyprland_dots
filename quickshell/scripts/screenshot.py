#!/usr/bin/env python3
import sys
import os
import shutil
import subprocess
from pathlib import Path

def notify(file_path: str, action: str):
    file_name = Path(file_path).name
    if action == "copy":
        body = "Copied capture directly to clipboard"
    elif action == "edit":
        body = f"Opened {file_name} in image editor"
    elif action == "save":
        body = f"Saved capture to {file_name}"
    else:
        body = f"Saved to {file_name} and copied to clipboard"

    try:
        subprocess.run(
            ["notify-send", "-a", "quickshell", "-i", file_path, "Screenshot Captured", body],
            check=False,
            timeout=3
        )
    except Exception:
        pass

def copy_to_clipboard(file_path: str) -> bool:
    if not os.path.exists(file_path):
        return False
    try:
        with open(file_path, "rb") as f:
            subprocess.run(
                ["wl-copy", "--type", "image/png"],
                stdin=f,
                check=True,
                timeout=5
            )
        return True
    except Exception:
        return False

def open_editor(file_path: str) -> bool:
    if not os.path.exists(file_path):
        return False
    for app in ["swappy", "satty"]:
        if shutil.which(app):
            try:
                subprocess.Popen([app, "-f", file_path])
                return True
            except Exception:
                pass
    return False

def handle_post_capture(action: str, file_path: str, send_notification: bool):
    if not os.path.exists(file_path):
        return

    if action in ("copy", "both"):
        copy_to_clipboard(file_path)

    if action == "edit":
        open_editor(file_path)

    if send_notification:
        notify(file_path, action)

def main():
    if len(sys.argv) < 2:
        return

    cmd = sys.argv[1].lower()

    if cmd == "post":
        action = sys.argv[2].lower() if len(sys.argv) > 2 else "both"
        file_path = sys.argv[3] if len(sys.argv) > 3 else ""
        send_note = sys.argv[4] == "1" if len(sys.argv) > 4 else True
        handle_post_capture(action, file_path, send_note)
    elif cmd == "copy":
        file_path = sys.argv[2] if len(sys.argv) > 2 else ""
        copy_to_clipboard(file_path)
    elif cmd == "edit":
        file_path = sys.argv[2] if len(sys.argv) > 2 else ""
        open_editor(file_path)
    elif cmd == "notify":
        file_path = sys.argv[2] if len(sys.argv) > 2 else ""
        action = sys.argv[3].lower() if len(sys.argv) > 3 else "save"
        notify(file_path, action)

if __name__ == "__main__":
    main()
