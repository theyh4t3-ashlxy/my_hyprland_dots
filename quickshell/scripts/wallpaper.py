#!/usr/bin/env python3
import os
import sys
import json
import time
import shutil
import random
import hashlib
import argparse
import subprocess
import urllib.request
import urllib.parse
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor

# --- XDG Base Directory Setup ---
XDG_CACHE_HOME = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
XDG_RUNTIME_DIR = Path(os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}"))
XDG_CONFIG_HOME = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))

APP_CACHE_DIR = XDG_CACHE_HOME / "quickshell"
THUMB_DIR = APP_CACHE_DIR / "thumbnails"
WALLPAPERS_DIR = Path.home() / ".wallpapers"

APP_CACHE_DIR.mkdir(parents=True, exist_ok=True)
THUMB_DIR.mkdir(parents=True, exist_ok=True)
WALLPAPERS_DIR.mkdir(parents=True, exist_ok=True)

# Runtime state (session-only) & persistent cached databases
CUR_WP_FILE = Path("/tmp/qs_current_wallpaper.txt")
VIDEO_THUMB = Path("/tmp/qs_video_thumb.jpg")
WALLPAPERS_JSON = Path("/tmp/qs_wallpapers.json")
LIVE_JSON = Path("/tmp/qs_live_wallpapers.json")


IMAGE_EXTS = {".png", ".jpg", ".jpeg", ".webp", ".avif", ".svg", ".bmp", ".tiff", ".tga", ".pnm"}
ANIM_EXTS = {".gif"}
VIDEO_EXTS = {".mp4", ".webm", ".mkv", ".mov"}
ALL_EXTS = IMAGE_EXTS | ANIM_EXTS | VIDEO_EXTS

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

# --- Helpers ---

def atomic_write_json(file_path: Path, data):
    """Write JSON atomically to prevent corrupt files on abrupt kills."""
    tmp_path = file_path.with_suffix(".tmp")
    try:
        tmp_path.write_text(json.dumps(data, indent=2))
        tmp_path.replace(file_path)
        # Mirror to cache directory if different
        if file_path == WALLPAPERS_JSON:
            cache_target = APP_CACHE_DIR / "wallpapers.json"
            if cache_target != file_path:
                try:
                    cache_target.write_text(json.dumps(data, indent=2))
                except Exception:
                    pass
        elif file_path == LIVE_JSON:
            cache_target = APP_CACHE_DIR / "live_wallpapers.json"
            if cache_target != file_path:
                try:
                    cache_target.write_text(json.dumps(data, indent=2))
                except Exception:
                    pass
    except Exception as e:
        if tmp_path.exists():
            tmp_path.unlink()
        sys.stderr.write(f"Failed to write JSON {file_path}: {e}\n")


def make_video_thumb(video_path: str, target_thumb: Path) -> bool:
    """Generate a single-frame thumbnail from a video file."""
    if target_thumb.exists() and target_thumb.stat().st_size > 0:
        return True
    try:
        subprocess.run(
            ["ffmpeg", "-y", "-ss", "00:00:01", "-i", video_path, "-vframes", "1", "-q:v", "2", str(target_thumb)],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=8,
            check=True
        )
        return target_thumb.exists()
    except Exception:
        return False

def is_live_url(url: str) -> bool:
    clean = url.lower().split("?")[0]
    return any(clean.endswith(ext) for ext in [".gif", ".mp4", ".webm", ".mkv", ".mov", ".webp"]) or \
           "giphy.com" in clean or "tenor.com" in clean

def extract_filename(url: str, is_live: bool) -> str:
    parsed_path = urllib.parse.urlsplit(url).path
    filename = Path(parsed_path).name
    if not filename or "." not in filename:
        h = hashlib.md5(url.encode()).hexdigest()[:12]
        filename = f"live_{h}.mp4" if is_live else f"wp_{h}.jpg"
    return filename

def stream_download(url: str, dest_path: Path, timeout: int = 30) -> bool:
    """Stream download directly to a temporary file, then move to destination."""
    temp_dest = dest_path.with_name(f".part_{dest_path.name}")
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 quickshell/1.0"})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp, open(temp_dest, "wb") as out_file:
            shutil.copyfileobj(resp, out_file)
        temp_dest.replace(dest_path)
        return True
    except Exception as e:
        if temp_dest.exists():
            temp_dest.unlink()
        sys.stderr.write(f"Download failed for {url}: {e}\n")
        return False

def reload_quickshell():
    shell_qml = XDG_CONFIG_HOME / "quickshell" / "shell.qml"
    if shell_qml.exists():
        try:
            shell_qml.touch()
        except Exception:
            pass

# --- Core Commands ---

def scan():
    wallpapers = []
    seen_paths = set()
    videos_to_thumb = []

    for p in WALLPAPERS_DIR.rglob("*"):
        if not p.is_file():
            continue
        ext = p.suffix.lower()
        if ext not in ALL_EXTS:
            continue

        resolved = str(p.resolve())
        if resolved in seen_paths:
            continue
        seen_paths.add(resolved)

        try:
            rel_dir = p.parent.relative_to(WALLPAPERS_DIR)
            rel_parts = rel_dir.parts
            category = str(rel_dir) if str(rel_dir) != "." else "root"
            parent_category = rel_parts[0] if len(rel_parts) > 0 and rel_parts[0] != "." else "root"
            sub_category = rel_parts[1] if len(rel_parts) > 1 else ""
        except ValueError:
            category = "general"
            parent_category = "general"
            sub_category = ""

        is_video = ext in VIDEO_EXTS
        is_gif = ext in ANIM_EXTS
        thumb_path = resolved

        if is_video:
            h = hashlib.md5(resolved.encode()).hexdigest()
            t_file = THUMB_DIR / f"{h}.jpg"
            thumb_path = str(t_file.resolve())
            if not t_file.exists():
                videos_to_thumb.append((resolved, t_file))

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

    # Parallel thumbnail generation for new videos
    if videos_to_thumb:
        with ThreadPoolExecutor(max_workers=min(4, os.cpu_count() or 1)) as executor:
            executor.map(lambda item: make_video_thumb(item[0], item[1]), videos_to_thumb)

    wallpapers.sort(key=lambda w: (w["parentCategory"], w["subCategory"], w["name"].lower()))
    atomic_write_json(WALLPAPERS_JSON, wallpapers)
    return wallpapers

def set_wallpaper(raw_args):
    """
    Sets the wallpaper. Supports named args or positional parameters
    for backwards-compatibility with quickshell QML scripts.
    """
    if not raw_args:
        return

    # Defaults
    defaults = {
        "img_path": "",
        "transition": "wipe",
        "angle": "30",
        "step": "90",
        "duration": "3",
        "fps": "60",
        "filt": "Lanczos3",
        "mode": "dark",
        "scheme": "scheme-tonal-spot",
        "target_mon": "all",
        "panscan": "1.0",
        "mpv_audio": "false"
    }

    # Map positional values for backward compatibility
    pos_keys = [
        "img_path", "transition", "angle", "step", "duration",
        "fps", "filt", "mode", "scheme", "target_mon", "panscan", "mpv_audio"
    ]
    for idx, val in enumerate(raw_args):
        if idx < len(pos_keys):
            defaults[pos_keys[idx]] = val

    img_path = str(Path(defaults["img_path"]).expanduser().resolve())
    if not os.path.isfile(img_path):
        sys.stderr.write(f"Error: Wallpaper file does not exist: {img_path}\n")
        return

    valid_transitions = {"simple", "fade", "left", "right", "top", "bottom", "wipe", "wave", "grow", "center", "any", "outer", "random", "none"}
    transition = defaults["transition"] if defaults["transition"] in valid_transitions else "wipe"

    CUR_WP_FILE.write_text(img_path + "\n")
    try:
        (XDG_RUNTIME_DIR / "qs_current_wallpaper.txt").write_text(img_path + "\n")
    except Exception:
        pass
    ext_lower = Path(img_path).suffix.lower()


    if ext_lower in VIDEO_EXTS:
        # Video wallpapers handled by mpvpaper
        subprocess.run(["awww", "kill"], stderr=subprocess.DEVNULL)
        subprocess.run(["pkill", "-x", "awww-daemon"], stderr=subprocess.DEVNULL)
        subprocess.run(["pkill", "-x", "mpvpaper"], stderr=subprocess.DEVNULL)

        if make_video_thumb(img_path, VIDEO_THUMB):
            subprocess.run([
                "matugen", "image", str(VIDEO_THUMB),
                "-m", defaults["mode"],
                "-t", defaults["scheme"],
                "--source-color-index", "0"
            ], stderr=subprocess.DEVNULL)

        audio_flag = "volume=70" if defaults["mpv_audio"].lower() == "true" else "no-audio"
        mpv_out = "*" if defaults["target_mon"] in {"all", "*", ""} else defaults["target_mon"]
        mpv_opts = f"loop-file=inf loop-playlist=inf panscan={defaults['panscan']} {audio_flag} --hwdec=auto-safe --keep-open=yes"
        
        subprocess.Popen(
            ["mpvpaper", "-f", "-o", mpv_opts, mpv_out, img_path],
            start_new_session=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
        reload_quickshell()
    else:
        # Static and GIF wallpapers handled by awww
        subprocess.run(["pkill", "-x", "mpvpaper"], stderr=subprocess.DEVNULL)
        try:
            res = subprocess.run(["awww", "query"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            if res.returncode != 0:
                if XDG_RUNTIME_DIR.exists():
                    for p in XDG_RUNTIME_DIR.glob("*awww-daemon*"):
                        try:
                            p.unlink()
                        except Exception:
                            pass
                subprocess.Popen(["awww-daemon", "--format", "argb"], start_new_session=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                time.sleep(0.3)
        except Exception:
            pass

        awww_cmd = ["awww", "img"]
        if defaults["target_mon"] not in {"all", "*", ""}:
            awww_cmd.extend(["-o", defaults["target_mon"]])

        awww_cmd.extend([
            img_path,
            "--transition-type", transition,
            "--transition-angle", str(defaults["angle"]),
            "--transition-step", str(defaults["step"]),
            "--transition-duration", str(defaults["duration"]),
            "--transition-fps", str(defaults["fps"]),
            "--filter", defaults["filt"]
        ])
        subprocess.run(awww_cmd, stderr=subprocess.DEVNULL)
        subprocess.run([
            "matugen", "image", img_path,
            "-m", defaults["mode"],
            "-t", defaults["scheme"],
            "--source-color-index", "0"
        ], stderr=subprocess.DEVNULL)
        reload_quickshell()

def random_wallpaper(args):
    filter_cat = args[0].lower() if args else "all"

    # Avoid rescanning entire disk on every random wallpaper toggle
    wps = []
    if WALLPAPERS_JSON.exists():
        try:
            wps = json.loads(WALLPAPERS_JSON.read_text())
        except Exception:
            wps = []
    if not wps:
        wps = scan()
    if not wps:
        return

    # Don't pick the exact same wallpaper if alternatives exist
    cur_wp = CUR_WP_FILE.read_text().strip() if CUR_WP_FILE.exists() else ""

    if filter_cat not in {"all", ""}:
        filtered = [
            w["path"] for w in wps
            if filter_cat in w["category"].lower()
            or filter_cat in w["parentCategory"].lower()
            or filter_cat in w["subCategory"].lower()
        ]
        candidates = filtered if filtered else [w["path"] for w in wps]
    else:
        candidates = [w["path"] for w in wps]

    if len(candidates) > 1 and cur_wp in candidates:
        candidates.remove(cur_wp)

    chosen = random.choice(candidates)
    rest = args[1:] if len(args) > 1 else []
    set_wallpaper([chosen] + rest)

def download(args):
    if not args:
        return
    raw_url = args[0].strip()
    rest = args[1:]

    # Local file handle
    if raw_url.startswith(("/", "~", "file://")):
        local_path = Path(raw_url.replace("file://", "")).expanduser()
        if local_path.is_file():
            set_wallpaper([str(local_path)] + rest)
            scan()
            return

    is_live = is_live_url(raw_url)
    save_dir = WALLPAPERS_DIR / ("live" if is_live else "wallhaven")
    save_dir.mkdir(parents=True, exist_ok=True)

    dest = save_dir / extract_filename(raw_url, is_live)
    if dest.exists() and dest.stat().st_size > 0:
        set_wallpaper([str(dest)] + rest)
        return

    if stream_download(raw_url, dest):
        scan()
        set_wallpaper([str(dest)] + rest)

def batch_download(args):
    if not args:
        return
    urls = []
    if len(args) == 1 and (args[0].startswith("[") or args[0].startswith("{")):
        try:
            parsed = json.loads(args[0])
            if isinstance(parsed, list):
                urls = [str(u).strip() for u in parsed if u]
        except Exception:
            urls = [args[0].strip()]
    else:
        urls = [a.strip() for a in args if a.strip()]

    if not urls:
        return

    save_dir_wh = WALLPAPERS_DIR / "wallhaven"
    save_dir_live = WALLPAPERS_DIR / "live"
    save_dir_wh.mkdir(parents=True, exist_ok=True)
    save_dir_live.mkdir(parents=True, exist_ok=True)

    def download_one(raw_url):
        is_live = is_live_url(raw_url)
        target_dir = save_dir_live if is_live else save_dir_wh
        dest = target_dir / extract_filename(raw_url, is_live)

        if dest.exists() and dest.stat().st_size > 0:
            return True
        return stream_download(raw_url, dest)

    with ThreadPoolExecutor(max_workers=6) as executor:
        results = list(executor.map(download_one, urls))

    success_count = sum(1 for r in results if r)
    scan()

    try:
        subprocess.run([
            "notify-send",
            "-a", "Wallpaper Browser",
            "-i", "preferences-desktop-wallpaper",
            "Batch Download Complete",
            f"Saved {success_count}/{len(urls)} wallpapers to ~/.wallpapers/"
        ], stderr=subprocess.DEVNULL)
    except Exception:
        pass

def set_color(args):
    hex_color = args[0] if len(args) > 0 else "#787756"
    mode = args[1] if len(args) > 1 else "dark"
    scheme = args[2] if len(args) > 2 else "scheme-tonal-spot"

    subprocess.run(["pkill", "-x", "mpvpaper"], stderr=subprocess.DEVNULL)
    try:
        clean_hex = hex_color.replace("#", "")
        subprocess.run(["awww", "clear", clean_hex], stderr=subprocess.DEVNULL)
    except Exception:
        pass

    subprocess.run(["matugen", "color", "hex", hex_color, "-m", mode, "-t", scheme], stderr=subprocess.DEVNULL)
    reload_quickshell()

def reapply(args):
    mode = args[0] if len(args) > 0 else "dark"
    scheme = args[1] if len(args) > 1 else "scheme-tonal-spot"
    cur_wp = CUR_WP_FILE.read_text().strip() if CUR_WP_FILE.exists() else ""

    if not cur_wp or not os.path.isfile(cur_wp):
        settings_conf = XDG_CONFIG_HOME / "quickshell" / "settings.conf"
        if settings_conf.exists():
            for line in settings_conf.read_text().splitlines():
                if line.startswith("currentWallpaper="):
                    candidate = line.split("=", 1)[1].strip().strip('"').strip("'")
                    if os.path.isfile(candidate):
                        cur_wp = candidate
                        break

    if not cur_wp or not os.path.isfile(cur_wp):
        default_wp = WALLPAPERS_DIR / "hyprland" / "hypr.png"
        if default_wp.is_file():
            cur_wp = str(default_wp)

    if cur_wp and os.path.isfile(cur_wp):
        set_wallpaper([cur_wp, "wipe", "30", "90", "3", "60", "Lanczos3", mode, scheme, "all", "1.0", "false"])
    else:
        set_color(["#787756", mode, scheme])

def fetch_live(args):
    query = args[0].strip() if args else ""
    if not query:
        atomic_write_json(LIVE_JSON, CURATED_LIVE)
        return

    try:
        encoded_q = urllib.parse.quote(f"{query} 1080p wallpaper loop")
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
                atomic_write_json(LIVE_JSON, results)
                return
    except Exception:
        pass

    # Fallback to local curated list
    filtered = [
        w for w in CURATED_LIVE
        if query.lower() in w["title"].lower() or query.lower() in w["category"].lower()
    ]
    atomic_write_json(LIVE_JSON, filtered if filtered else CURATED_LIVE)

def main():
    if len(sys.argv) < 2:
        return
    cmd = sys.argv[1].lower()
    args = sys.argv[2:]

    dispatch = {
        "scan": lambda: scan(),
        "set": lambda: set_wallpaper(args),
        "random": lambda: random_wallpaper(args),
        "download": lambda: download(args),
        "batch-download": lambda: batch_download(args),
        "color": lambda: set_color(args),
        "reapply": lambda: reapply(args),
        "fetch-live": lambda: fetch_live(args),
    }

    if cmd in dispatch:
        dispatch[cmd]()

if __name__ == "__main__":
    main()
