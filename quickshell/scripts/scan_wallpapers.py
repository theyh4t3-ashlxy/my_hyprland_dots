#!/usr/bin/env python3
# crawling subfolders so we can rice properly
import os
import json
from pathlib import Path

def scan_wallpapers():
    base_dir = Path.home() / ".wallpapers"
    base_dir.mkdir(parents=True, exist_ok=True)
    
    extensions = ("*.png", "*.jpg", "*.jpeg", "*.webp", "*.PNG", "*.JPG", "*.JPEG", "*.WEBP")
    wallpapers = []
    seen_paths = set()
    
    for ext in extensions:
        for p in base_dir.rglob(ext):
            resolved = str(p.resolve())
            if resolved in seen_paths or not p.is_file():
                continue
            seen_paths.add(resolved)
            
            try:
                rel_dir = p.parent.relative_to(base_dir)
                rel_parts = rel_dir.parts
                category = str(rel_dir) if str(rel_dir) != "." else "root"
                parent_category = rel_parts[0] if len(rel_parts) > 0 and rel_parts[0] != "." else "root"
                sub_category = rel_parts[1] if len(rel_parts) > 1 else ""
            except ValueError:
                category = "general"
                parent_category = "general"
                sub_category = ""
                
            wallpapers.append({
                "path": resolved,
                "name": p.stem,
                "category": category,
                "parentCategory": parent_category,
                "subCategory": sub_category,
            })
            
    wallpapers.sort(key=lambda w: (w["parentCategory"], w["subCategory"], w["name"].lower()))
    
    out_file = Path("/tmp/qs_wallpapers.json")
    out_file.write_text(json.dumps(wallpapers, indent=2))

if __name__ == "__main__":
    scan_wallpapers()
