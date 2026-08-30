#!/usr/bin/env python3
import subprocess
import json
from pathlib import Path

def scan_fonts():
    try:
        out = subprocess.check_output(['fc-list', ':', 'family'], text=True)
    except Exception:
        out = ""
        
    fams = set()
    banned_prefixes = {".", "mtx", "Noto Color Emoji", "Noto Emoji"}
    for line in out.splitlines():
        for f in line.split(','):
            name = f.strip()
            if not name:
                continue
            if any(name.startswith(b) for b in banned_prefixes):
                continue
            if name.lower() in {"mtx", "opensymbol"}:
                continue
            fams.add(name)
                
    fonts = sorted(fams)
    
    out_path = Path("/tmp/qs_fonts.json")
    out_path.write_text(json.dumps(fonts, indent=2))
    
    conf_fonts = Path.home() / ".config" / "quickshell" / "fonts.json"
    conf_fonts.write_text(json.dumps(fonts, indent=2))

if __name__ == "__main__":
    scan_fonts()
