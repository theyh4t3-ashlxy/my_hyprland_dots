#!/usr/bin/env python3
import sys
import os
import urllib.request
import subprocess
from pathlib import Path

def download_and_apply():
    if len(sys.argv) < 2:
        print("Usage: download_wallpaper.py <url> [transition] [angle] [step] [duration] [fps] [filter] [mode] [scheme]")
        sys.exit(1)
        
    url = sys.argv[1]
    transition = sys.argv[2] if len(sys.argv) > 2 else "wipe"
    angle = sys.argv[3] if len(sys.argv) > 3 else "30"
    step = sys.argv[4] if len(sys.argv) > 4 else "90"
    duration = sys.argv[5] if len(sys.argv) > 5 else "3"
    fps = sys.argv[6] if len(sys.argv) > 6 else "60"
    filt = sys.argv[7] if len(sys.argv) > 7 else "Lanczos3"
    mode = sys.argv[8] if len(sys.argv) > 8 else "dark"
    scheme = sys.argv[9] if len(sys.argv) > 9 else "scheme-tonal-spot"
    
    save_dir = Path.home() / ".wallpapers" / "wallhaven"
    save_dir.mkdir(parents=True, exist_ok=True)
    
    filename = url.split("?")[0].split("/")[-1]
    dest = save_dir / filename
    
    # Download with custom user-agent
    req = urllib.request.Request(url, headers={"User-Agent": "quickshell/1.0"})
    with urllib.request.urlopen(req, timeout=30) as response, open(dest, 'wb') as out_file:
        out_file.write(response.read())
        
    # Apply using wallpaper.sh
    script = Path.home() / ".config" / "quickshell" / "scripts" / "wallpaper.sh"
    subprocess.run([
        str(script), "set", str(dest),
        transition, angle, step, duration, fps, filt, mode, scheme
    ], check=False)

if __name__ == "__main__":
    download_and_apply()
