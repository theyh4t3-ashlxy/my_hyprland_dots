#!/usr/bin/env python3
import sys
from pathlib import Path

def save_settings():
    if len(sys.argv) < 2:
        return
        
    text = sys.argv[1]
    conf_path = Path.home() / ".config" / "quickshell" / "settings.conf"
    conf_path.write_text(text.strip() + "\n")

if __name__ == "__main__":
    save_settings()
