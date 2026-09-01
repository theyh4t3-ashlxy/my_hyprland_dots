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
        
    raw_url = sys.argv[1].strip()
    transition = sys.argv[2] if len(sys.argv) > 2 else "wipe"
    angle = sys.argv[3] if len(sys.argv) > 3 else "30"
    step = sys.argv[4] if len(sys.argv) > 4 else "90"
    duration = sys.argv[5] if len(sys.argv) > 5 else "3"
    fps = sys.argv[6] if len(sys.argv) > 6 else "60"
    filt = sys.argv[7] if len(sys.argv) > 7 else "Lanczos3"
    mode = sys.argv[8] if len(sys.argv) > 8 else "dark"
    scheme = sys.argv[9] if len(sys.argv) > 9 else "scheme-tonal-spot"
    
    script = Path.home() / ".config" / "quickshell" / "scripts" / "wallpaper.sh"
    scan_script = Path.home() / ".config" / "quickshell" / "scripts" / "scan_wallpapers.py"
    
    # Check if local path
    if raw_url.startswith("/") or raw_url.startswith("~") or raw_url.startswith("file://"):
        local_path = os.path.expanduser(raw_url.replace("file://", ""))
        if os.path.exists(local_path):
            subprocess.run([
                str(script), "set", local_path,
                transition, angle, step, duration, fps, filt, mode, scheme
            ], check=False)
            subprocess.run(["python3", str(scan_script)], check=False)
            sys.exit(0)
            
    # Online URL download
    is_live = any(raw_url.lower().endswith(ext) for ext in [".gif", ".mp4", ".webm", ".mkv", ".mov", ".webp"]) or "giphy.com" in raw_url or "tenor.com" in raw_url
    
    save_dir = Path.home() / ".wallpapers" / ("live" if is_live else "downloaded")
    save_dir.mkdir(parents=True, exist_ok=True)
    
    filename = raw_url.split("?")[0].split("/")[-1]
    if not filename or "." not in filename:
        filename = f"live_{abs(hash(raw_url))}.mp4" if is_live else f"wp_{abs(hash(raw_url))}.jpg"
        
    dest = save_dir / filename
    
    # Download with custom user-agent
    req = urllib.request.Request(raw_url, headers={"User-Agent": "Mozilla/5.0 quickshell/1.0"})
    with urllib.request.urlopen(req, timeout=40) as response, open(dest, "wb") as out_file:
        out_file.write(response.read())
        
    # Rescan local library so new wallpaper is recognized
    subprocess.run(["python3", str(scan_script)], check=False)
    
    # Apply using wallpaper.sh
    subprocess.run([
        str(script), "set", str(dest),
        transition, angle, step, duration, fps, filt, mode, scheme
    ], check=False)

if __name__ == "__main__":
    download_and_apply()
