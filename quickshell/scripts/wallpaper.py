#!/usr/bin/env python3
import sys
import os
import json
import random
import hashlib
import subprocess
import urllib.request
import urllib.parse
from pathlib import Path

CUR_WP_FILE = Path("/tmp/qs_current_wallpaper.txt")
WALLPAPERS_JSON = Path("/tmp/qs_wallpapers.json")
LIVE_JSON = Path("/tmp/qs_live_wallpapers.json")
VIDEO_THUMB = Path("/tmp/qs_video_thumb.jpg")

CURATED_LIVE = [
    {
        "id": "pixel-rain",
        "title": "pixel city rain",
        "category": "pixel art",
        "url": "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExdWU0MXhnbG05Mm11YWN5a2RmcGlkMGt1dXpnNnRpdDJva24ya3A2ayZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/3o7TKTDnUxE6uQja4U/giphy.gif",
        "thumb": "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExdWU0MXhnbG05Mm11YWN5a2RmcGlkMGt1dXpnNnRpdDJva24ya3A2ayZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/3o7TKTDnUxE6uQja4U/200.gif"
    },
    {
        "id": "lofi-bedroom",
        "title": "lo-fi chill midnight",
        "category": "lo-fi",
        "url": "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExMHU2MnRhZW03NXpiOG1vd24xaWtvbTllYmg0cW81djE5OTl2YnBkayZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/LmNwrBhejkK9EFP504/giphy.gif",
        "thumb": "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExMHU2MnRhZW03NXpiOG1vd24xaWtvbTllYmg0cW81djE5OTl2YnBkayZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/LmNwrBhejkK9EFP504/200.gif"
    },
    {
        "id": "cyberpunk-train",
        "title": "neo tokyo train night",
        "category": "cyberpunk",
        "url": "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExNmtvaDVqbzZ2dHB1YXZsNWF5dWp2b3hpd2g4ODNsd28xNXc1OTU4NiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/3oKIPnAiaMCws8nOsE/giphy.gif",
        "thumb": "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExNmtvaDVqbzZ2dHB1YXZsNWF5dWp2b3hpd2g4ODNsd28xNXc1OTU4NiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/3oKIPnAiaMCws8nOsE/200.gif"
    },
    {
        "id": "space-nebula",
        "title": "cosmic galaxy nebula",
        "category": "space",
        "url": "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExOTR0NGh0d2R2dWd1dmZobnlvaHQ4MGoxbHRid2M4M21udmVvM3JmZSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/l0MYEqEzwMWFCg8rm/giphy.gif",
        "thumb": "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExOTR0NGh0d2R2dWd1dmZobnlvaHQ4MGoxbHRid2M4M21udmVvM3JmZSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/l0MYEqEzwMWFCg8rm/200.gif"
    },
    {
        "id": "anime-sunset",
        "title": "anime sunset clouds",
        "category": "anime",
        "url": "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExM3ZtNW1jM3pxdTF4d2U3OW1ld3F6Z2xyeHR5ZWU2cXhhNDgxbWV1eiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/l0HlBO7eyXzSZkJri/giphy.gif",
        "thumb": "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExM3ZtNW1jM3pxdTF4d2U3OW1ld3F6Z2xyeHR5ZWU2cXhhNDgxbWV1eiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/l0HlBO7eyXzSZkJri/200.gif"
    },
    {
        "id": "vaporwave-drive",
        "title": "outrun retro grid drive",
        "category": "synthwave",
        "url": "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExd2RtaXhmdGtrYm5yazN0NnprcXJtY2o3NXdja3E2cGxtZWNwd2s2ayZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/4Zo41lhzKt6iZ8xff9/giphy.gif",
        "thumb": "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExd2RtaXhmdGtrYm5yazN0NnprcXJtY2o3NXdja3E2cGxtZWNwd2s2ayZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/4Zo41lhzKt6iZ8xff9/200.gif"
    }
]

def scan():
    base_dir = Path.home() / ".wallpapers"
    base_dir.mkdir(parents=True, exist_ok=True)
    thumb_dir = Path.home() / ".cache" / "quickshell" / "thumbnails"
    thumb_dir.mkdir(parents=True, exist_ok=True)

    img_exts = {".png", ".jpg", ".jpeg", ".webp", ".avif", ".svg", ".bmp", ".tiff", ".tga", ".pnm"}
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

        is_video = ext in video_exts
        is_gif = ext in anim_exts
        thumb_path = resolved

        if is_video:
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
    WALLPAPERS_JSON.write_text(json.dumps(wallpapers, indent=2))
    return wallpapers

def set_wallpaper(args):
    if not args:
        return
    img_path = str(Path(args[0]).expanduser().resolve())
    if not os.path.isfile(img_path):
        return

    transition = args[1] if len(args) > 1 else "wipe"
    valid_transitions = {"simple", "fade", "left", "right", "top", "bottom", "wipe", "wave", "grow", "center", "any", "outer", "random", "none"}
    if transition not in valid_transitions:
        transition = "wipe"

    angle = args[2] if len(args) > 2 else "30"
    step = args[3] if len(args) > 3 else "90"
    duration = args[4] if len(args) > 4 else "3"
    fps = args[5] if len(args) > 5 else "60"
    filt = args[6] if len(args) > 6 else "Lanczos3"
    mode = args[7] if len(args) > 7 else "dark"
    scheme = args[8] if len(args) > 8 else "scheme-tonal-spot"
    target_mon = args[9] if len(args) > 9 else "all"
    panscan = args[10] if len(args) > 10 else "1.0"
    mpv_audio = args[11] if len(args) > 11 else "false"

    CUR_WP_FILE.write_text(img_path + "\n")
    ext_lower = Path(img_path).suffix.lower()

    if ext_lower in {".mp4", ".webm", ".mkv", ".mov"}:
        subprocess.run(["pkill", "-x", "mpvpaper"], stderr=subprocess.DEVNULL)
        try:
            subprocess.run(
                ["ffmpeg", "-y", "-ss", "00:00:01", "-i", img_path, "-vframes", "1", "-q:v", "2", str(VIDEO_THUMB)],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                timeout=5
            )
            if VIDEO_THUMB.exists():
                subprocess.run(["matugen", "image", str(VIDEO_THUMB), "-m", mode, "-t", scheme, "--source-color-index", "0"], stderr=subprocess.DEVNULL)
        except Exception:
            pass

        audio_flag = "volume=70" if mpv_audio.lower() == "true" else "no-audio"
        mpv_out = "*" if target_mon in {"all", "*", ""} else target_mon
        mpv_opts = f"loop-file=inf loop-playlist=inf panscan={panscan} {audio_flag} --hwdec=auto-safe --keep-open=yes"
        subprocess.Popen(["mpvpaper", "-f", "-o", mpv_opts, mpv_out, img_path], stderr=subprocess.DEVNULL)
    else:
        subprocess.run(["pkill", "-x", "mpvpaper"], stderr=subprocess.DEVNULL)
        try:
            res = subprocess.run(["awww", "query"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            if res.returncode != 0:
                subprocess.Popen(["awww", "init"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except Exception:
            pass

        awww_cmd = ["awww", "img"]
        if target_mon not in {"all", "*", ""}:
            awww_cmd.extend(["-o", target_mon])

        awww_cmd.extend([
            img_path,
            "--transition-type", transition,
            "--transition-angle", str(angle),
            "--transition-step", str(step),
            "--transition-duration", str(duration),
            "--transition-fps", str(fps),
            "--filter", filt
        ])
        subprocess.run(awww_cmd, stderr=subprocess.DEVNULL)
        subprocess.run(["matugen", "image", img_path, "-m", mode, "-t", scheme, "--source-color-index", "0"], stderr=subprocess.DEVNULL)

def random_wallpaper(args):
    filter_cat = args[0].lower() if len(args) > 0 else "all"
    wps = scan()
    if not wps:
        return

    if filter_cat not in {"all", ""}:
        filtered = [
            w["path"] for w in wps
            if filter_cat in w["category"].lower()
            or filter_cat in w["parentCategory"].lower()
            or filter_cat in w["subCategory"].lower()
        ]
        chosen = random.choice(filtered) if filtered else random.choice(wps)["path"]
    else:
        chosen = random.choice(wps)["path"]

    rest = args[1:] if len(args) > 1 else []
    set_wallpaper([chosen] + rest)

def download(args):
    if not args:
        return
    raw_url = args[0].strip()
    rest = args[1:]

    if raw_url.startswith("/") or raw_url.startswith("~") or raw_url.startswith("file://"):
        local_path = Path(raw_url.replace("file://", "")).expanduser()
        if local_path.is_file():
            set_wallpaper([str(local_path)] + rest)
            scan()
            return

    is_live = any(raw_url.lower().endswith(ext) for ext in [".gif", ".mp4", ".webm", ".mkv", ".mov", ".webp"]) or "giphy.com" in raw_url or "tenor.com" in raw_url
    save_dir = Path.home() / ".wallpapers" / ("live" if is_live else "downloaded")
    save_dir.mkdir(parents=True, exist_ok=True)

    filename = raw_url.split("?")[0].split("/")[-1]
    if not filename or "." not in filename:
        h = abs(hash(raw_url))
        filename = f"live_{h}.mp4" if is_live else f"wp_{h}.jpg"

    dest = save_dir / filename
    req = urllib.request.Request(raw_url, headers={"User-Agent": "Mozilla/5.0 quickshell/1.0"})
    try:
        with urllib.request.urlopen(req, timeout=30) as resp, open(dest, "wb") as f:
            f.write(resp.read())
        scan()
        set_wallpaper([str(dest)] + rest)
    except Exception as e:
        sys.stderr.write(f"download failed: {e}\n")

def set_color(args):
    hex_color = args[0] if len(args) > 0 else "#787756"
    mode = args[1] if len(args) > 1 else "dark"
    scheme = args[2] if len(args) > 2 else "scheme-tonal-spot"
    subprocess.run(["pkill", "-x", "mpvpaper"], stderr=subprocess.DEVNULL)
    subprocess.run(["matugen", "color", "hex", hex_color, "-m", mode, "-t", scheme], stderr=subprocess.DEVNULL)

def reapply(args):
    mode = args[0] if len(args) > 0 else "dark"
    scheme = args[1] if len(args) > 1 else "scheme-tonal-spot"
    cur_wp = CUR_WP_FILE.read_text().strip() if CUR_WP_FILE.exists() else ""
    if cur_wp and os.path.isfile(cur_wp):
        set_wallpaper([cur_wp, "wipe", "30", "90", "3", "60", "Lanczos3", mode, scheme, "all", "1.0", "false"])
    else:
        set_color(["#787756", mode, scheme])

def fetch_live(args):
    query = args[0].strip() if args else ""
    if not query:
        LIVE_JSON.write_text(json.dumps(CURATED_LIVE, indent=2))
        return

    try:
        encoded_q = urllib.parse.quote(query + " 1080p wallpaper loop")
        api_url = f"https://api.giphy.com/v1/gifs/search?api_key=dc6zaTOxFJmzC&q={encoded_q}&limit=16&rating=g"
        req = urllib.request.Request(api_url, headers={"User-Agent": "quickshell/1.0"})
        with urllib.request.urlopen(req, timeout=8) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            results = []
            for item in data.get("data", []):
                images = item.get("images", {})
                orig = images.get("original", {}).get("url")
                thumb = images.get("fixed_height_small", {}).get("url") or orig
                title = item.get("title", "live wallpaper")
                if orig:
                    results.append({
                        "id": item.get("id"),
                        "title": title,
                        "category": query,
                        "url": orig,
                        "thumb": thumb
                    })
            if results:
                LIVE_JSON.write_text(json.dumps(results, indent=2))
                return
    except Exception:
        pass

    filtered = [w for w in CURATED_LIVE if query.lower() in w["title"].lower() or query.lower() in w["category"].lower()]
    LIVE_JSON.write_text(json.dumps(filtered if filtered else CURATED_LIVE, indent=2))

def main():
    if len(sys.argv) < 2:
        return
    cmd = sys.argv[1].lower()
    args = sys.argv[2:]

    if cmd == "scan":
        scan()
    elif cmd == "set":
        set_wallpaper(args)
    elif cmd == "random":
        random_wallpaper(args)
    elif cmd == "download":
        download(args)
    elif cmd == "color":
        set_color(args)
    elif cmd == "reapply":
        reapply(args)
    elif cmd == "fetch-live":
        fetch_live(args)

if __name__ == "__main__":
    main()
