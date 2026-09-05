#!/usr/bin/env python3
import sys
import subprocess
from pathlib import Path

CLIP_FILE = Path("/tmp/qs_curclip.txt")

def main():
    if len(sys.argv) < 2:
        return
    action = sys.argv[1].lower()

    if action == "sync":
        try:
            res = subprocess.run(["wl-paste", "--type", "text"], capture_output=True, timeout=2)
            if res.returncode == 0 and res.stdout:
                text = res.stdout[:100000].decode("utf-8", errors="replace")
                CLIP_FILE.write_text(text)
        except Exception:
            pass
    elif action == "copy":
        content = sys.argv[2] if len(sys.argv) > 2 else ""
        try:
            subprocess.run(["wl-copy", "--", content], check=False)
        except Exception:
            pass

if __name__ == "__main__":
    main()
