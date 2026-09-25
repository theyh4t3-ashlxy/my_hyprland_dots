#!/usr/bin/env python3
import os
import sys
import json
import time
import shutil
import random
import hashlib
import subprocess
import urllib.request
import urllib.parse
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor

XDG_CACHE_HOME = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
XDG_RUNTIME_DIR = Path(os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}"))
XDG_CONFIG_HOME = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))

APP_CACHE_DIR = XDG_CACHE_HOME / "quickshell"
THUMB_DIR = APP_CACHE_DIR / "thumbnails"
WALLPAPERS_DIR = Path.home() / ".wallpapers"
SETTINGS_CONF = XDG_CONFIG_HOME / "quickshell" / "settings.conf"

APP_CACHE_DIR.mkdir(parents=True, exist_ok=True)
THUMB_DIR.mkdir(parents=True, exist_ok=True)
WALLPAPERS_DIR.mkdir(parents=True, exist_ok=True)

CUR_WP_FILE = Path("/tmp/qs_current_wallpaper.txt")
VIDEO_THUMB = Path("/tmp/qs_video_thumb.jpg")
WALLPAPERS_JSON = Path("/tmp/qs_wallpapers.json")
LIVE_JSON = Path("/tmp/qs_live_wallpapers.json")

DEFAULT_SETTINGS = {
    "currentWallpaper": str(WALLPAPERS_DIR / "hyprland" / "hypr.png"),
    "matugenMode": "dark",
    "matugenScheme": "scheme-tonal-spot",
    "awwwTransitionType": "wipe",
    "awwwTransitionAngle": 30,
    "awwwTransitionStep": 90,
    "awwwTransitionDuration": 3,
    "awwwTransitionFps": 60,
    "awwwFilter": "Lanczos3",
    "awwwResize": "crop",
    "awwwTransitionPos": "center",
    "mpvPanscan": 1.0,
    "mpvAudio": False,
}

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

def load_settings() -> dict:
    settings = dict(DEFAULT_SETTINGS)
    if not SETTINGS_CONF.exists():
        return settings

    try:
        content = SETTINGS_CONF.read_text(encoding="utf-8")
        for line in content.splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, val = line.split("=", 1)
            key = key.strip()
            val = val.strip()
            if (val.startswith('"') and val.endswith('"')) or (val.startswith("'") and val.endswith("'")):
                val = val[1:-1]

            if key in {"awwwTransitionAngle", "awwwTransitionStep", "awwwTransitionDuration", "awwwTransitionFps"}:
                try:
                    settings[key] = int(val)
                except ValueError:
                    pass
            elif key in {"mpvPanscan"}:
                try:
                    settings[key] = float(val)
                except ValueError:
                    pass
            elif key in {"mpvAudio"}:
                settings[key] = val.lower() in ("true", "1", "yes")
            else:
                settings[key] = val
    except Exception as e:
        sys.stderr.write(f"Warning: Failed to parse {SETTINGS_CONF}: {e}\n")

    return settings

def update_settings(updates: dict):
    try:
        SETTINGS_CONF.parent.mkdir(parents=True, exist_ok=True)
        if SETTINGS_CONF.exists():
            real_conf = SETTINGS_CONF.resolve()
            lines = real_conf.read_text(encoding="utf-8").splitlines()
        else:
            real_conf = SETTINGS_CONF
            lines = [
                f'{k}="{v}"' if isinstance(v, str) else f'{k}={str(v).lower() if isinstance(v, bool) else v}'
                for k, v in DEFAULT_SETTINGS.items()
            ]

        keys_to_update = dict(updates)
        updated_lines = []

        for line in lines:
            trimmed = line.strip()
            if trimmed and not trimmed.startswith("#") and "=" in trimmed:
                k, _ = trimmed.split("=", 1)
                k = k.strip()
                if k in keys_to_update:
                    v = keys_to_update.pop(k)
                    if isinstance(v, bool):
                        updated_lines.append(f"{k}={'true' if v else 'false'}")
                    elif isinstance(v, (int, float)):
                        updated_lines.append(f"{k}={v}")
                    elif isinstance(v, str):
                        updated_lines.append(f'{k}="{v}"')
                    else:
                        updated_lines.append(f"{k}='{json.dumps(v)}'")
                    continue
            updated_lines.append(line)

        for k, v in keys_to_update.items():
            if isinstance(v, bool):
                updated_lines.append(f"{k}={'true' if v else 'false'}")
            elif isinstance(v, (int, float)):
                updated_lines.append(f"{k}={v}")
            elif isinstance(v, str):
                updated_lines.append(f'{k}="{v}"')
            else:
                updated_lines.append(f"{k}='{json.dumps(v)}'")

        tmp_conf = real_conf.with_suffix(".tmp")
        tmp_conf.write_text("\n".join(updated_lines) + "\n", encoding="utf-8")
        tmp_conf.replace(real_conf)
    except Exception as e:
        sys.stderr.write(f"Warning: Failed to update {SETTINGS_CONF}: {e}\n")

def atomic_write_json(file_path: Path, data):
    def _write(target: Path):
        try:
            target.parent.mkdir(parents=True, exist_ok=True)
            tmp = target.with_suffix(".tmp")
            tmp.write_text(json.dumps(data, indent=2))
            tmp.replace(target)
        except Exception:
            pass

    _write(file_path)
    if file_path == WALLPAPERS_JSON:
        _write(APP_CACHE_DIR / "wallpapers.json")
    elif file_path == LIVE_JSON:
        _write(APP_CACHE_DIR / "live_wallpapers.json")

def make_video_thumb(video_path: str, target_thumb: Path) -> bool:
    if target_thumb.exists() and target_thumb.stat().st_size > 0:
        return True
    try:
        target_thumb.parent.mkdir(parents=True, exist_ok=True)
        cmd = ["ffmpeg", "-y", "-ss", "00:00:00.5", "-i", video_path, "-vframes", "1", "-q:v", "2", str(target_thumb)]
        subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=8, check=True)
        return target_thumb.exists() and target_thumb.stat().st_size > 0
    except Exception:
        # short loops fail on offset seek, fallback to frame zero
        try:
            cmd = ["ffmpeg", "-y", "-i", video_path, "-vframes", "1", "-q:v", "2", str(target_thumb)]
            subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=8, check=True)
            return target_thumb.exists() and target_thumb.stat().st_size > 0
        except Exception:
            return False

def is_live_url(url: str) -> bool:
    clean = url.lower().split("?")[0]
    return any(clean.endswith(ext) for ext in [".gif", ".mp4", ".webm", ".mkv", ".mov", ".webp"]) or \
           "giphy.com" in clean or "tenor.com" in clean

def extract_filename(url: str, is_live: bool) -> str:
    parsed_path = urllib.parse.urlsplit(url).path
    stem = Path(parsed_path).stem
    suffix = Path(parsed_path).suffix.lower()
    h = hashlib.md5(url.encode()).hexdigest()[:10]

    generic = {"", "giphy", "image", "download", "wallpaper", "thumb", "200", "default", "view"}
    if not suffix or suffix not in ALL_EXTS:
        suffix = ".mp4" if is_live else ".jpg"

    if not stem or stem.lower() in generic:
        stem = f"live_{h}" if is_live else f"wp_{h}"
    else:
        stem = f"{stem}_{h}"

    return f"{stem}{suffix}"

def stream_download(url: str, dest_path: Path, timeout: int = 30) -> bool:
    dest_path.parent.mkdir(parents=True, exist_ok=True)
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
    # Quickshell monitors Theme.qml and settings.conf automatically without shell.qml touch churn
    pass

def ensure_awww_daemon() -> bool:
    try:
        res = subprocess.run(["awww", "query"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if res.returncode == 0:
            return True
        if XDG_RUNTIME_DIR.exists():
            for p in XDG_RUNTIME_DIR.glob("*awww-daemon*"):
                try:
                    p.unlink()
                except Exception:
                    pass
        subprocess.Popen(["awww-daemon", "--format", "argb"], start_new_session=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        for _ in range(15):
            time.sleep(0.05)
            if subprocess.run(["awww", "query"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0:
                return True
    except Exception:
        pass
    return False

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

        try:
            resolved = str(p.resolve())
        except Exception:
            continue

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

    if videos_to_thumb:
        with ThreadPoolExecutor(max_workers=min(4, os.cpu_count() or 1)) as executor:
            executor.map(lambda item: make_video_thumb(item[0], item[1]), videos_to_thumb)

    wallpapers.sort(key=lambda w: (w["parentCategory"], w["subCategory"], w["name"].lower()))
    atomic_write_json(WALLPAPERS_JSON, wallpapers)
    return wallpapers

def parse_wallpaper_args(raw_args: list) -> dict:
    cfg = load_settings()
    opts = {
        "img_path": "",
        "transition": str(cfg.get("awwwTransitionType", "wipe")),
        "angle": str(cfg.get("awwwTransitionAngle", 30)),
        "step": str(cfg.get("awwwTransitionStep", 90)),
        "duration": str(cfg.get("awwwTransitionDuration", 3)),
        "fps": str(cfg.get("awwwTransitionFps", 60)),
        "filt": str(cfg.get("awwwFilter", "Lanczos3")),
        "mode": str(cfg.get("matugenMode", "dark")),
        "scheme": str(cfg.get("matugenScheme", "scheme-tonal-spot")),
        "target_mon": "all",
        "panscan": str(cfg.get("mpvPanscan", 1.0)),
        "mpv_audio": "true" if cfg.get("mpvAudio", False) else "false",
        "resize": str(cfg.get("awwwResize", "crop")),
        "transition_pos": str(cfg.get("awwwTransitionPos", "center")),
    }

    pos_keys = [
        "img_path", "transition", "angle", "step", "duration",
        "fps", "filt", "mode", "scheme", "target_mon", "panscan", "mpv_audio",
        "resize", "transition_pos"
    ]

    idx = 0
    pos_idx = 0
    while idx < len(raw_args):
        arg = str(raw_args[idx]).strip()
        if arg in ("--transition", "-t") and idx + 1 < len(raw_args):
            opts["transition"] = str(raw_args[idx + 1]).strip()
            idx += 2
        elif arg in ("--angle", "-a") and idx + 1 < len(raw_args):
            opts["angle"] = str(raw_args[idx + 1]).strip()
            idx += 2
        elif arg in ("--step", "-s") and idx + 1 < len(raw_args):
            opts["step"] = str(raw_args[idx + 1]).strip()
            idx += 2
        elif arg in ("--duration", "-d") and idx + 1 < len(raw_args):
            opts["duration"] = str(raw_args[idx + 1]).strip()
            idx += 2
        elif arg in ("--fps",) and idx + 1 < len(raw_args):
            opts["fps"] = str(raw_args[idx + 1]).strip()
            idx += 2
        elif arg in ("--filter", "--filt", "-f") and idx + 1 < len(raw_args):
            opts["filt"] = str(raw_args[idx + 1]).strip()
            idx += 2
        elif arg in ("--mode", "-m") and idx + 1 < len(raw_args):
            opts["mode"] = str(raw_args[idx + 1]).strip()
            idx += 2
        elif arg in ("--scheme",) and idx + 1 < len(raw_args):
            opts["scheme"] = str(raw_args[idx + 1]).strip()
            idx += 2
        elif arg in ("--monitor", "--mon", "-o") and idx + 1 < len(raw_args):
            opts["target_mon"] = str(raw_args[idx + 1]).strip()
            idx += 2
        elif arg in ("--panscan",) and idx + 1 < len(raw_args):
            opts["panscan"] = str(raw_args[idx + 1]).strip()
            idx += 2
        elif arg in ("--audio",):
            opts["mpv_audio"] = "true"
            idx += 1
        elif arg in ("--no-audio",):
            opts["mpv_audio"] = "false"
            idx += 1
        elif arg in ("--resize", "-r") and idx + 1 < len(raw_args):
            opts["resize"] = str(raw_args[idx + 1]).strip()
            idx += 2
        elif arg in ("--no-resize",):
            opts["resize"] = "no"
            idx += 1
        elif arg in ("--transition-pos", "--pos", "-p") and idx + 1 < len(raw_args):
            opts["transition_pos"] = str(raw_args[idx + 1]).strip()
            idx += 2
        elif not arg.startswith("-"):
            if pos_idx < len(pos_keys):
                if arg != "":
                    opts[pos_keys[pos_idx]] = arg
                pos_idx += 1
            idx += 1
        else:
            idx += 1

    return opts

def set_wallpaper(raw_args):
    if not raw_args:
        return

    opts = parse_wallpaper_args(raw_args)
    if not opts["img_path"]:
        return

    img_path = str(Path(opts["img_path"]).expanduser().resolve())
    if not os.path.isfile(img_path):
        sys.stderr.write(f"Error: Wallpaper file does not exist: {img_path}\n")
        return

    valid_transitions = {"simple", "fade", "left", "right", "top", "bottom", "wipe", "wave", "grow", "center", "any", "outer", "random", "none"}
    transition = opts["transition"] if opts["transition"] in valid_transitions else "wipe"

    valid_filters = {"Nearest", "Bilinear", "CatmullRom", "Mitchell", "Lanczos3"}
    filt = opts["filt"] if opts["filt"] in valid_filters else "Lanczos3"

    valid_resizes = {"crop", "fit", "stretch", "no"}
    resize = opts["resize"] if opts["resize"] in valid_resizes else "crop"

    # awww accepts float/coord or center, not compass words
    pos_map = {
        "center": "center",
        "top": "0.5,1.0",
        "bottom": "0.5,0.0",
        "left": "0.0,0.5",
        "right": "1.0,0.5",
        "top-left": "0.0,1.0",
        "top-right": "1.0,1.0",
        "bottom-left": "0.0,0.0",
        "bottom-right": "1.0,0.0",
    }
    raw_pos = opts["transition_pos"]
    pos = pos_map.get(raw_pos, raw_pos if ("," in raw_pos or raw_pos == "center") else "center")

    try:
        CUR_WP_FILE.write_text(img_path + "\n")
    except Exception:
        pass

    try:
        (XDG_RUNTIME_DIR / "qs_current_wallpaper.txt").write_text(img_path + "\n")
    except Exception:
        pass

    update_settings({
        "currentWallpaper": img_path,
        "matugenMode": opts["mode"],
        "matugenScheme": opts["scheme"],
    })

    ext_lower = Path(img_path).suffix.lower()

    if ext_lower in VIDEO_EXTS:
        try:
            subprocess.run(["awww", "kill"], stderr=subprocess.DEVNULL)
            subprocess.run(["pkill", "-x", "awww-daemon"], stderr=subprocess.DEVNULL)
            subprocess.run(["pkill", "-x", "mpvpaper"], stderr=subprocess.DEVNULL)
        except Exception:
            pass

        v_hash = hashlib.md5(img_path.encode()).hexdigest()
        v_thumb = THUMB_DIR / f"{v_hash}.jpg"
        if make_video_thumb(img_path, v_thumb):
            try:
                shutil.copyfile(v_thumb, VIDEO_THUMB)
            except Exception:
                pass
            try:
                subprocess.run([
                    "matugen", "image", str(v_thumb),
                    "-m", opts["mode"],
                    "-t", opts["scheme"],
                    "--source-color-index", "0"
                ], stderr=subprocess.DEVNULL)
            except Exception:
                pass

        audio_flag = "volume=70" if opts["mpv_audio"].lower() in ("true", "1", "yes") else "no-audio"
        mpv_out = "*" if opts["target_mon"] in {"all", "*", ""} else opts["target_mon"]
        mpv_opts = f"loop-file=inf loop-playlist=inf panscan={opts['panscan']} {audio_flag} --hwdec=auto-safe --keep-open=yes"

        try:
            subprocess.Popen(
                ["mpvpaper", "-f", "-o", mpv_opts, mpv_out, img_path],
                start_new_session=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
        except Exception as e:
            sys.stderr.write(f"Failed to spawn mpvpaper: {e}\n")
        reload_quickshell()
    else:
        try:
            subprocess.run(["pkill", "-x", "mpvpaper"], stderr=subprocess.DEVNULL)
        except Exception:
            pass

        ensure_awww_daemon()

        awww_cmd = ["awww", "img"]
        if opts["target_mon"] not in {"all", "*", ""}:
            awww_cmd.extend(["-o", opts["target_mon"]])

        if resize == "no":
            awww_cmd.append("--no-resize")
        else:
            awww_cmd.extend(["--resize", resize])

        awww_cmd.extend([
            img_path,
            "--transition-type", transition,
            "--transition-step", str(opts["step"]),
            "--transition-duration", str(opts["duration"]),
            "--transition-fps", str(opts["fps"]),
            "--filter", filt
        ])

        if transition in {"wipe", "wave"}:
            awww_cmd.extend(["--transition-angle", str(opts["angle"])])

        if transition in {"grow", "outer"}:
            awww_cmd.extend(["--transition-pos", pos])

        try:
            subprocess.run(awww_cmd, stderr=subprocess.DEVNULL)
        except Exception as e:
            sys.stderr.write(f"Failed to execute awww: {e}\n")

        try:
            subprocess.run([
                "matugen", "image", img_path,
                "-m", opts["mode"],
                "-t", opts["scheme"],
                "--source-color-index", "0"
            ], stderr=subprocess.DEVNULL)
        except Exception:
            pass
        reload_quickshell()

def random_wallpaper(args):
    filter_cat = args[0].lower() if args and not args[0].startswith("-") else "all"

    wps = []
    if WALLPAPERS_JSON.exists():
        try:
            wps = json.loads(WALLPAPERS_JSON.read_text())
        except Exception:
            wps = []

    if not wps:
        cache_fallback = APP_CACHE_DIR / "wallpapers.json"
        if cache_fallback.exists():
            try:
                wps = json.loads(cache_fallback.read_text())
            except Exception:
                wps = []

    if not wps:
        wps = scan()
    if not wps:
        return

    cur_wp = ""
    try:
        if (XDG_RUNTIME_DIR / "qs_current_wallpaper.txt").exists():
            cur_wp = (XDG_RUNTIME_DIR / "qs_current_wallpaper.txt").read_text().strip()
        elif CUR_WP_FILE.exists():
            cur_wp = CUR_WP_FILE.read_text().strip()
    except Exception:
        pass

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

    candidates = [p for p in candidates if os.path.isfile(p)]
    if not candidates:
        return

    if len(candidates) > 1 and cur_wp in candidates:
        candidates.remove(cur_wp)

    chosen = random.choice(candidates)
    rest = args[1:] if (args and not args[0].startswith("-")) else args
    set_wallpaper([chosen] + rest)

def download(args):
    if not args:
        return
    raw_url = args[0].strip()
    rest = args[1:]

    if raw_url.startswith(("/", "~", "file://")):
        local_path = Path(raw_url.replace("file://", "")).expanduser()
        if local_path.is_file():
            set_wallpaper([str(local_path)] + rest)
            scan()
            return

    is_live = is_live_url(raw_url)
    save_dir = WALLPAPERS_DIR / ("live" if is_live else "wallhaven")
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

    def download_one(raw_url):
        is_live = is_live_url(raw_url)
        target_dir = save_dir_live if is_live else save_dir_wh
        dest = target_dir / extract_filename(raw_url, is_live)

        if dest.exists() and dest.stat().st_size > 0:
            return True
        return stream_download(raw_url, dest)

    with ThreadPoolExecutor(max_workers=4) as executor:
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
    cfg = load_settings()
    hex_color = args[0] if len(args) > 0 and args[0] else "#787756"
    mode = args[1] if len(args) > 1 and args[1] else cfg.get("matugenMode", "dark")
    scheme = args[2] if len(args) > 2 and args[2] else cfg.get("matugenScheme", "scheme-tonal-spot")

    try:
        subprocess.run(["pkill", "-x", "mpvpaper"], stderr=subprocess.DEVNULL)
    except Exception:
        pass

    ensure_awww_daemon()

    clean_hex = hex_color.replace("#", "")
    try:
        subprocess.run(["awww", "clear", clean_hex], stderr=subprocess.DEVNULL)
    except Exception:
        pass

    try:
        subprocess.run(["matugen", "color", "hex", hex_color, "-m", mode, "-t", scheme], stderr=subprocess.DEVNULL)
    except Exception:
        pass

    update_settings({"matugenMode": mode, "matugenScheme": scheme})
    reload_quickshell()

def reapply(args):
    cfg = load_settings()
    mode = args[0] if len(args) > 0 and args[0] else cfg.get("matugenMode", "dark")
    scheme = args[1] if len(args) > 1 and args[1] else cfg.get("matugenScheme", "scheme-tonal-spot")

    cur_wp = ""
    try:
        if (XDG_RUNTIME_DIR / "qs_current_wallpaper.txt").exists():
            cur_wp = (XDG_RUNTIME_DIR / "qs_current_wallpaper.txt").read_text().strip()
        elif CUR_WP_FILE.exists():
            cur_wp = CUR_WP_FILE.read_text().strip()
    except Exception:
        pass

    if not cur_wp or not os.path.isfile(cur_wp):
        candidate = cfg.get("currentWallpaper", "")
        if candidate and os.path.isfile(candidate):
            cur_wp = candidate

    if not cur_wp or not os.path.isfile(cur_wp):
        default_wp = WALLPAPERS_DIR / "hyprland" / "hypr.png"
        if default_wp.is_file():
            cur_wp = str(default_wp)

    if cur_wp and os.path.isfile(cur_wp):
        set_wallpaper([cur_wp, "--mode", mode, "--scheme", scheme] + (args[2:] if len(args) > 2 else []))
    else:
        set_color(["#787756", mode, scheme])

def fetch_live(args):
    query = args[0].strip() if args else ""
    if not query:
        atomic_write_json(LIVE_JSON, CURATED_LIVE)
        return

    # public beta key is dead, filter curated local list directly
    filtered = [
        w for w in CURATED_LIVE
        if query.lower() in w["title"].lower() or query.lower() in w["category"].lower()
    ]
    atomic_write_json(LIVE_JSON, filtered if filtered else CURATED_LIVE)

def print_help():
    print("""quickshell wallpaper manager & matugen bridge

Usage:
  wallpaper.py scan
  wallpaper.py set <path> [options | positionals...]
  wallpaper.py random [category] [options | positionals...]
  wallpaper.py reapply [mode] [scheme]
  wallpaper.py color <#hex> [mode] [scheme]
  wallpaper.py download <url> [options...]
  wallpaper.py batch-download <url1> [url2...]
  wallpaper.py fetch-live [query]
""")

def main():
    if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help", "help"):
        print_help()
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
    else:
        if Path(sys.argv[1]).expanduser().is_file():
            set_wallpaper(sys.argv[1:])
        else:
            sys.stderr.write(f"Unknown command '{cmd}'. Run 'wallpaper.py --help' for usage.\n")

if __name__ == "__main__":
    main()