#!/usr/bin/env python3
# crawling subfolders and live wallpapers so we can rice properly
import os
import json
import hashlib
import subprocess
from pathlib import Path

def scan_wallpapers():
    base_dir = Path.home() / ".wallpapers"
    base_dir.mkdir(parents=True, exist_ok=True)
    thumb_dir = Path.home() / ".cache" / "quickshell" / "thumbnails"
    thumb_dir.mkdir(parents=True, exist_ok=True)
    
    # Static image extensions
    img_exts = {".png", ".jpg", ".jpeg", ".webp", ".avif", ".svg", ".bmp", ".tiff", ".tga", ".pnm"}
    # Animated and Live video extensions
    anim_exts = {".gif"}
    video_exts = {".mp4", ".webm", ".mkv", ".mov"}
    all_exts = img_exts | anim_exts | video_exts
    
    wallpapers = []
    seen_paths = set()
    
    for p in base_dir.rglob("*"):
        if not p.is_file():
            continue
        ext = p.suffix.lower()
        if ext not in all_exts:
            continue
            
        resolved = str(p.resolve())
        if resolved in seen_paths:
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
            
        # Determine media type
        is_video = ext in video_exts
        is_gif = ext in anim_exts
        thumb_path = resolved
        
        if is_video:
            # Generate thumbnail for video
            h = hashlib.md5(resolved.encode()).hexdigest()
            t_file = thumb_dir / f"{h}.jpg"
            if not t_file.exists():
                try:
                    subprocess.run(
                        ["ffmpeg", "-y", "-ss", "00:00:01", "-i", resolved, "-vframes", "1", "-q:v", "2", str(t_file)],
                        stdout=subprocess.DEVNULL,
                        stderr=subprocess.DEVNULL,
                        timeout=5
                    )
                except Exception:
                    pass
            if t_file.exists():
                thumb_path = str(t_file.resolve())
                
        wallpapers.append({
            "path": resolved,
            "thumb": thumb_path,
            "name": p.stem,
            "ext": ext.replace(".", ""),
            "isVideo": is_video,
            "isGif": is_gif,
            "isLive": is_video or is_gif,
            "category": category,
            "parentCategory": parent_category,
            "subCategory": sub_category,
        })
        
    wallpapers.sort(key=lambda w: (w["parentCategory"], w["subCategory"], w["name"].lower()))
    
    out_file = Path("/tmp/qs_wallpapers.json")
    out_file.write_text(json.dumps(wallpapers, indent=2))

if __name__ == "__main__":
    scan_wallpapers()
