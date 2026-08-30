#!/usr/bin/env python3
import os
import glob
import json
from pathlib import Path

def scan_wallpapers():
    base_dir = Path.home() / ".wallpapers"
    base_dir.mkdir(parents=True, exist_ok=True)
    
    extensions = ("*.png", "*.jpg", "*.jpeg", "*.webp")
    wallpapers = []
    
    for ext in extensions:
        for p in base_dir.rglob(ext):
            try:
                rel_dir = p.parent.relative_to(base_dir)
                category = str(rel_dir) if str(rel_dir) != "." else "root"
            except ValueError:
                category = "general"
                
            wallpapers.append({
                "path": str(p.resolve()),
                "name": p.stem,
                "category": category
            })
            
    wallpapers.sort(key=lambda w: w["path"])
    
    out_file = Path("/tmp/qs_wallpapers.json")
    out_file.write_text(json.dumps(wallpapers, indent=2))

if __name__ == "__main__":
    scan_wallpapers()
