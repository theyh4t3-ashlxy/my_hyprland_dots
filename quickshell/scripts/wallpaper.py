#!/usr/bin/env python3
import hashlib
import json
import os
import random
import shutil
import subprocess
import sys
import time
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from typing import List, Optional

# --- ANSI Colors & Glyphs ---
C_RESET = "\033[0m"
C_BOLD = "\033[1m"
C_MAGENTA = "\033[38;5;141m"
C_GREEN = "\033[38;5;120m"
C_CYAN = "\033[38;5;81m"
C_YELLOW = "\033[38;5;221m"
C_RED = "\033[38;5;203m"


def log_info(msg: str):
  print(f"{C_MAGENTA}󰄛 {msg}{C_RESET}")


def log_success(msg: str, val: str = ""):
  print(f"{C_GREEN}󰄲 {msg}{C_RESET} {C_CYAN}{val}{C_RESET}")


def log_warn(msg: str):
  print(f"{C_YELLOW}󰅚 {msg}{C_RESET}")


def log_err(msg: str):
  sys.stderr.write(f"{C_RED}󰅚 {msg}{C_RESET}\n")


# --- XDG Paths ---
XDG_CACHE_HOME = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
XDG_RUNTIME_DIR = Path(
    os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
)
XDG_CONFIG_HOME = Path(
    os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")
)
XDG_STATE_HOME = Path(
    os.environ.get("XDG_STATE_HOME", Path.home() / ".local" / "state")
)

APP_CACHE_DIR = XDG_CACHE_HOME / "quickshell"
APP_STATE_DIR = XDG_STATE_HOME / "quickshell"
THUMB_DIR = APP_CACHE_DIR / "thumbnails"
WALLPAPERS_DIR = Path.home() / ".wallpapers"
SETTINGS_CONF = APP_STATE_DIR / "settings.conf"
FALLBACK_SETTINGS_CONF = XDG_CONFIG_HOME / "quickshell" / "settings.conf"

APP_CACHE_DIR.mkdir(parents=True, exist_ok=True)
APP_STATE_DIR.mkdir(parents=True, exist_ok=True)
THUMB_DIR.mkdir(parents=True, exist_ok=True)
WALLPAPERS_DIR.mkdir(parents=True, exist_ok=True)

CUR_WP_FILE = Path("/tmp/qs_current_wallpaper.txt")
VIDEO_THUMB = Path("/tmp/qs_video_thumb.jpg")
WALLPAPERS_JSON = Path("/tmp/qs_wallpapers.json")
LIVE_JSON = Path("/tmp/qs_live_wallpapers.json")

CURR_WALL_SYMLINK = Path.home() / ".curr_wall"
CURR_WALL_STATIC = Path.home() / ".curr_wall_static.jpg"
CACHE_WALLPAPER = APP_CACHE_DIR / "current_wallpaper"
GLOBAL_CACHE_WALLPAPER = XDG_CACHE_HOME / "current_wallpaper"
FALLBACK_WALLPAPER = WALLPAPERS_DIR / "hyprland" / "hypr.png"

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
    "wallhavenApiKey": "",
    "wallhavenRatios": "16x9,16x10,21x9",
    "wallhavenAtleast": "1920x1080",
}

IMAGE_EXTS = {
    ".png",
    ".jpg",
    ".jpeg",
    ".webp",
    ".avif",
    ".svg",
    ".bmp",
    ".tiff",
    ".tga",
    ".pnm",
}
ANIM_EXTS = {".gif"}
VIDEO_EXTS = {".mp4", ".webm", ".mkv", ".mov"}
ALL_EXTS = IMAGE_EXTS | ANIM_EXTS | VIDEO_EXTS


# --- Settings Engine ---
def load_settings() -> dict:
  settings = dict(DEFAULT_SETTINGS)
  conf_path = (
      SETTINGS_CONF if SETTINGS_CONF.exists() else FALLBACK_SETTINGS_CONF
  )
  if not conf_path.exists():
    return settings

  try:
    content = conf_path.read_text(encoding="utf-8")
    for line in content.splitlines():
      line = line.strip()
      if not line or line.startswith("#") or "=" not in line:
        continue
      key, val = line.split("=", 1)
      key, val = key.strip(), val.strip()
      if (val.startswith('"') and val.endswith('"')) or (
          val.startswith("'") and val.endswith("'")
      ):
        val = val[1:-1]

      if key in {
          "awwwTransitionAngle",
          "awwwTransitionStep",
          "awwwTransitionDuration",
          "awwwTransitionFps",
      }:
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
    sys.stderr.write(f"Warning: Failed to parse {conf_path}: {e}\n")

  return settings


def update_settings(updates: dict):
  try:
    SETTINGS_CONF.parent.mkdir(parents=True, exist_ok=True)
    if SETTINGS_CONF.exists():
      real_conf = SETTINGS_CONF.resolve()
      lines = real_conf.read_text(encoding="utf-8").splitlines()
    elif FALLBACK_SETTINGS_CONF.exists():
      real_conf = SETTINGS_CONF
      lines = FALLBACK_SETTINGS_CONF.read_text(encoding="utf-8").splitlines()
    else:
      real_conf = SETTINGS_CONF
      lines = [
          f'{k}="{v}"'
          if isinstance(v, str)
          else f"{k}={str(v).lower() if isinstance(v, bool) else v}"
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

    tmp_conf = real_conf.with_suffix(f".tmp_{os.getpid()}")
    tmp_conf.write_text("\n".join(updated_lines) + "\n", encoding="utf-8")
    tmp_conf.replace(real_conf)
  except Exception as e:
    sys.stderr.write(f"Warning: Failed to update {SETTINGS_CONF}: {e}\n")


def atomic_write_json(file_path: Path, data):
  def _write(target: Path):
    try:
      target.parent.mkdir(parents=True, exist_ok=True)
      tmp = target.with_suffix(f".tmp_{os.getpid()}")
      tmp.write_text(json.dumps(data, indent=2), encoding="utf-8")
      tmp.replace(target)
    except Exception as e:
      sys.stderr.write(f"Warning: Failed to write JSON to {target}: {e}\n")

  _write(file_path)
  if file_path == WALLPAPERS_JSON:
    _write(APP_CACHE_DIR / "wallpapers.json")
  elif file_path == LIVE_JSON:
    _write(APP_CACHE_DIR / "live_wallpapers.json")


# --- Helper Process Executions ---
def make_video_thumb(video_path: str, target_thumb: Path) -> bool:
  if target_thumb.exists() and target_thumb.stat().st_size > 0:
    return True
  target_thumb.parent.mkdir(parents=True, exist_ok=True)
  try:
    cmd = [
        "ffmpeg",
        "-y",
        "-ss",
        "00:00:00.5",
        "-i",
        video_path,
        "-vframes",
        "1",
        "-q:v",
        "2",
        str(target_thumb),
    ]
    subprocess.run(
        cmd,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        timeout=8,
        check=True,
    )
    if target_thumb.exists() and target_thumb.stat().st_size > 0:
      return True
  except Exception:
    pass

  try:
    cmd = [
        "ffmpeg",
        "-y",
        "-i",
        video_path,
        "-vframes",
        "1",
        "-q:v",
        "2",
        str(target_thumb),
    ]
    subprocess.run(
        cmd,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        timeout=8,
        check=True,
    )
    if target_thumb.exists() and target_thumb.stat().st_size > 0:
      return True
  except Exception:
    pass

  try:
    if shutil.which("magick"):
      cmd = ["magick", f"{video_path}[0]", str(target_thumb)]
      subprocess.run(
          cmd,
          stdout=subprocess.DEVNULL,
          stderr=subprocess.DEVNULL,
          timeout=8,
          check=True,
      )
      if target_thumb.exists() and target_thumb.stat().st_size > 0:
        return True
  except Exception:
    pass
  return False


def is_live_url(url: str) -> bool:
  clean = url.lower().split("?")[0]
  return (
      any(
          clean.endswith(ext)
          for ext in [".gif", ".mp4", ".webm", ".mkv", ".mov"]
      )
      or "giphy.com" in clean
      or "tenor.com" in clean
  )


def extract_filename(url: str, is_live: bool) -> str:
  parsed_path = urllib.parse.urlsplit(url).path
  decoded_path = urllib.parse.unquote(parsed_path)
  stem = Path(decoded_path).stem
  suffix = Path(decoded_path).suffix.lower()
  h = hashlib.md5(url.encode()).hexdigest()[:10]

  generic = {
      "",
      "giphy",
      "image",
      "download",
      "wallpaper",
      "thumb",
      "200",
      "default",
      "view",
  }
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
  req = urllib.request.Request(
      url, headers={"User-Agent": "Mozilla/5.0 quickshell/1.0"}
  )
  try:
    with (
        urllib.request.urlopen(req, timeout=timeout) as resp,
        open(temp_dest, "wb") as out_file,
    ):
      shutil.copyfileobj(resp, out_file)
    temp_dest.replace(dest_path)
    return True
  except Exception as e:
    if temp_dest.exists():
      temp_dest.unlink()
    log_err(f"Download failed for {url}: {e}")
    return False


def ensure_awww_daemon() -> bool:
  try:
    res = subprocess.run(
        ["awww", "query"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
    )
    if res.returncode == 0:
      return True
    if XDG_RUNTIME_DIR.exists():
      for p in XDG_RUNTIME_DIR.glob("*awww-daemon*"):
        try:
          p.unlink()
        except Exception:
          pass
    subprocess.Popen(
        ["awww-daemon", "--format", "argb"],
        start_new_session=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    for _ in range(15):
      time.sleep(0.05)
      if (
          subprocess.run(
              ["awww", "query"],
              stdout=subprocess.DEVNULL,
              stderr=subprocess.DEVNULL,
          ).returncode
          == 0
      ):
        return True
  except Exception:
    pass
  return False


def kill_mpvpaper() -> bool:
  try:
    subprocess.run(["pkill", "-9", "-x", "mpvpaper"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return True
  except Exception:
    return False


def scan() -> list:
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
      parent_category = (
          rel_parts[0] if len(rel_parts) > 0 and rel_parts[0] != "." else "root"
      )
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
    with ThreadPoolExecutor(
        max_workers=min(4, os.cpu_count() or 1)
    ) as executor:
      list(
          executor.map(
              lambda item: make_video_thumb(item[0], item[1]), videos_to_thumb
          )
      )

  wallpapers.sort(
      key=lambda w: (w["parentCategory"], w["subCategory"], w["name"].lower())
  )
  atomic_write_json(WALLPAPERS_JSON, wallpapers)
  return wallpapers


def atomic_symlink(target_path: Path, symlink_path: Path):
  target_str = str(target_path.resolve())
  symlink_path.parent.mkdir(parents=True, exist_ok=True)
  tmp_link = symlink_path.parent / f".tmp_{symlink_path.name}_{os.getpid()}"
  try:
    if tmp_link.is_symlink() or tmp_link.exists():
      tmp_link.unlink()
    tmp_link.symlink_to(target_str)
    os.replace(tmp_link, symlink_path)
  except Exception:
    try:
      if symlink_path.is_symlink() or symlink_path.exists():
        symlink_path.unlink()
      symlink_path.symlink_to(target_str)
    except Exception:
      pass


def resolve_wallpaper_path(path_str: Optional[str] = None) -> Optional[str]:
  if path_str:
    p = Path(path_str).expanduser()
    if p.is_file():
      return str(p.resolve())

  if CURR_WALL_SYMLINK.is_symlink() or CURR_WALL_SYMLINK.exists():
    try:
      target = CURR_WALL_SYMLINK.resolve()
      if target.is_file():
        return str(target)
    except Exception:
      pass

  for cache_p in (CACHE_WALLPAPER, GLOBAL_CACHE_WALLPAPER):
    if cache_p.exists():
      try:
        line = cache_p.read_text(encoding="utf-8").strip()
        if line and os.path.isfile(line):
          return str(Path(line).resolve())
      except Exception:
        pass

  try:
    cfg = load_settings()
    cw = cfg.get("currentWallpaper", "")
    if cw and os.path.isfile(cw):
      return str(Path(cw).resolve())
  except Exception:
    pass

  candidates = [
      FALLBACK_WALLPAPER,
      WALLPAPERS_DIR / "endermanch" / "img0.jpg",
      WALLPAPERS_DIR / "endermanch" / "Bliss.png",
      WALLPAPERS_DIR / "Windows" / "Wallpaper" / "Windows" / "img0.jpg",
  ]
  for c in candidates:
    if c.is_file():
      return str(c.resolve())

  if WALLPAPERS_DIR.is_dir():
    for root, _, files in os.walk(WALLPAPERS_DIR):
      for f in files:
        if Path(f).suffix.lower() in IMAGE_EXTS:
          cand = Path(root) / f
          if cand.is_file():
            return str(cand.resolve())

  return None


def update_wallpaper_symlinks(img_path: str) -> bool:
  target = Path(img_path).resolve()
  if not target.is_file():
    fallback = resolve_wallpaper_path(None)
    if not fallback:
      return False
    target = Path(fallback).resolve()

  atomic_symlink(target, CURR_WALL_SYMLINK)

  ext_lower = target.suffix.lower()
  if ext_lower in VIDEO_EXTS or ext_lower in ANIM_EXTS:
    v_hash = hashlib.md5(str(target).encode()).hexdigest()
    v_thumb = THUMB_DIR / f"{v_hash}.jpg"
    if not v_thumb.exists() or v_thumb.stat().st_size == 0:
      make_video_thumb(str(target), v_thumb)
    if v_thumb.exists() and v_thumb.stat().st_size > 0:
      atomic_symlink(v_thumb, CURR_WALL_STATIC)
    else:
      fallback_img = resolve_wallpaper_path(str(FALLBACK_WALLPAPER))
      if fallback_img and os.path.isfile(fallback_img):
        atomic_symlink(Path(fallback_img), CURR_WALL_STATIC)
  else:
    atomic_symlink(target, CURR_WALL_STATIC)

  for cp in (CACHE_WALLPAPER, GLOBAL_CACHE_WALLPAPER):
    try:
      cp.parent.mkdir(parents=True, exist_ok=True)
      cp.write_text(str(target) + "\n", encoding="utf-8")
    except Exception:
      pass

  return True


def ensure_symlinks_valid():
  needs_repair = False
  if not CURR_WALL_SYMLINK.is_symlink():
    needs_repair = True
  else:
    try:
      if not CURR_WALL_SYMLINK.resolve().is_file():
        needs_repair = True
    except Exception:
      needs_repair = True

  if not CURR_WALL_STATIC.is_symlink():
    needs_repair = True
  else:
    try:
      if not CURR_WALL_STATIC.resolve().is_file():
        needs_repair = True
    except Exception:
      needs_repair = True

  if needs_repair:
    resolved = resolve_wallpaper_path(None)
    if resolved:
      update_wallpaper_symlinks(resolved)


# --- Core Command Logic ---
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
      "img_path",
      "transition",
      "angle",
      "step",
      "duration",
      "fps",
      "filt",
      "mode",
      "scheme",
      "target_mon",
      "panscan",
      "mpv_audio",
      "resize",
      "transition_pos",
  ]

  explicit_flags = set()
  idx = 0
  pos_idx = 0

  while idx < len(raw_args):
    arg = str(raw_args[idx]).strip()
    if arg in ("--transition", "-t") and idx + 1 < len(raw_args):
      opts["transition"] = str(raw_args[idx + 1]).strip()
      explicit_flags.add("transition")
      idx += 2
    elif arg in ("--angle", "-a") and idx + 1 < len(raw_args):
      opts["angle"] = str(raw_args[idx + 1]).strip()
      explicit_flags.add("angle")
      idx += 2
    elif arg in ("--step", "-s") and idx + 1 < len(raw_args):
      opts["step"] = str(raw_args[idx + 1]).strip()
      explicit_flags.add("step")
      idx += 2
    elif arg in ("--duration", "-d") and idx + 1 < len(raw_args):
      opts["duration"] = str(raw_args[idx + 1]).strip()
      explicit_flags.add("duration")
      idx += 2
    elif arg in ("--fps",) and idx + 1 < len(raw_args):
      opts["fps"] = str(raw_args[idx + 1]).strip()
      explicit_flags.add("fps")
      idx += 2
    elif arg in ("--filter", "--filt", "-f") and idx + 1 < len(raw_args):
      opts["filt"] = str(raw_args[idx + 1]).strip()
      explicit_flags.add("filt")
      idx += 2
    elif arg in ("--mode", "-m") and idx + 1 < len(raw_args):
      opts["mode"] = str(raw_args[idx + 1]).strip()
      explicit_flags.add("mode")
      idx += 2
    elif arg in ("--scheme",) and idx + 1 < len(raw_args):
      opts["scheme"] = str(raw_args[idx + 1]).strip()
      explicit_flags.add("scheme")
      idx += 2
    elif arg in ("--monitor", "--mon", "-o") and idx + 1 < len(raw_args):
      opts["target_mon"] = str(raw_args[idx + 1]).strip()
      explicit_flags.add("target_mon")
      idx += 2
    elif arg in ("--panscan",) and idx + 1 < len(raw_args):
      opts["panscan"] = str(raw_args[idx + 1]).strip()
      explicit_flags.add("panscan")
      idx += 2
    elif arg in ("--audio",):
      opts["mpv_audio"] = "true"
      explicit_flags.add("mpv_audio")
      idx += 1
    elif arg in ("--no-audio",):
      opts["mpv_audio"] = "false"
      explicit_flags.add("mpv_audio")
      idx += 1
    elif arg in ("--resize", "-r") and idx + 1 < len(raw_args):
      opts["resize"] = str(raw_args[idx + 1]).strip()
      explicit_flags.add("resize")
      idx += 2
    elif arg in ("--no-resize",):
      opts["resize"] = "no"
      explicit_flags.add("resize")
      idx += 1
    elif arg in ("--transition-pos", "--pos", "-p") and idx + 1 < len(raw_args):
      opts["transition_pos"] = str(raw_args[idx + 1]).strip()
      explicit_flags.add("transition_pos")
      idx += 2
    elif not arg.startswith("-"):
      while pos_idx < len(pos_keys) and pos_keys[pos_idx] in explicit_flags:
        pos_idx += 1
      if pos_idx < len(pos_keys):
        opts[pos_keys[pos_idx]] = arg
        pos_idx += 1
      idx += 1
    else:
      idx += 1

  return opts


def set_wallpaper(raw_args) -> bool:
  if not raw_args:
    return False

  opts = parse_wallpaper_args(raw_args)
  if not opts["img_path"]:
    return False

  resolved = resolve_wallpaper_path(opts["img_path"])
  if not resolved:
    log_err(f"Wallpaper file does not exist: {opts['img_path']}")
    return False

  img_path = resolved
  update_wallpaper_symlinks(img_path)

  valid_transitions = {
      "simple",
      "fade",
      "left",
      "right",
      "top",
      "bottom",
      "wipe",
      "wave",
      "grow",
      "center",
      "any",
      "outer",
      "random",
      "none",
  }
  transition = (
      opts["transition"] if opts["transition"] in valid_transitions else "wipe"
  )
  valid_filters = {"Nearest", "Bilinear", "CatmullRom", "Mitchell", "Lanczos3"}
  filt = opts["filt"] if opts["filt"] in valid_filters else "Lanczos3"
  valid_resizes = {"crop", "fit", "stretch", "no"}
  resize = opts["resize"] if opts["resize"] in valid_resizes else "crop"

  # Coordinates: (0,0) is TOP-LEFT, (1,1) is BOTTOM-RIGHT
  pos_map = {
      "center": "center",
      "top": "0.5,0.0",
      "bottom": "0.5,1.0",
      "left": "0.0,0.5",
      "right": "1.0,0.5",
      "top-left": "0.0,0.0",
      "top-right": "1.0,0.0",
      "bottom-left": "0.0,1.0",
      "bottom-right": "1.0,1.0",
  }
  raw_pos = opts["transition_pos"]
  pos = pos_map.get(
      raw_pos,
      raw_pos if ("," in raw_pos or raw_pos == "center") else "center",
  )

  try:
    CUR_WP_FILE.write_text(img_path + "\n", encoding="utf-8")
    (XDG_RUNTIME_DIR / "qs_current_wallpaper.txt").write_text(
        img_path + "\n", encoding="utf-8"
    )
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
    except Exception:
      pass
    kill_mpvpaper()

    v_hash = hashlib.md5(img_path.encode()).hexdigest()
    v_thumb = THUMB_DIR / f"{v_hash}.jpg"
    if make_video_thumb(img_path, v_thumb):
      try:
        shutil.copyfile(v_thumb, VIDEO_THUMB)
      except Exception:
        pass
      try:
        subprocess.run(
            [
                "matugen",
                "image",
                str(v_thumb),
                "-m",
                opts["mode"],
                "-t",
                opts["scheme"],
                "--source-color-index",
                "0",
            ],
            stderr=subprocess.DEVNULL,
        )
      except Exception:
        pass

    audio_flag = (
        "volume=70"
        if opts["mpv_audio"].lower() in ("true", "1", "yes")
        else "no-audio"
    )
    mpv_out = (
        "*" if opts["target_mon"] in {"all", "*", ""} else opts["target_mon"]
    )
    mpv_opts = (
        f"loop-file=inf loop-playlist=inf panscan={opts['panscan']} {audio_flag}"
        " hwdec=auto-safe keep-open=yes"
    )

    try:
      subprocess.Popen(
          ["mpvpaper", "-f", "-o", mpv_opts, mpv_out, img_path],
          start_new_session=True,
          stdout=subprocess.DEVNULL,
          stderr=subprocess.DEVNULL,
      )
      log_success("Live video wallpaper applied:", Path(img_path).name)
      return True
    except Exception as e:
      log_err(f"Failed to spawn mpvpaper: {e}")
      return False
  else:
    kill_mpvpaper()
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
        "--transition-type",
        transition,
        "--transition-step",
        str(opts["step"]),
        "--transition-duration",
        str(opts["duration"]),
        "--transition-fps",
        str(opts["fps"]),
        "--filter",
        filt,
    ])

    if transition in {"wipe", "wave"}:
      awww_cmd.extend(["--transition-angle", str(opts["angle"])])
    if transition in {"grow", "outer"}:
      awww_cmd.extend(["--transition-pos", pos])

    success = True
    try:
      subprocess.run(awww_cmd, check=True, stderr=subprocess.DEVNULL)
    except Exception as e:
      log_err(f"Failed to execute awww: {e}")
      success = False

    try:
      matugen_target = (
          str(CURR_WALL_STATIC.resolve())
          if CURR_WALL_STATIC.is_symlink()
          else img_path
      )
      subprocess.run(
          [
              "matugen",
              "image",
              matugen_target,
              "-m",
              opts["mode"],
              "-t",
              opts["scheme"],
              "--source-color-index",
              "0",
          ],
          stderr=subprocess.DEVNULL,
      )
    except Exception:
      pass

    log_success("Wallpaper applied:", Path(img_path).name)
    return success


def random_wallpaper(args) -> bool:
  filter_cat = (
      args[0].lower() if args and not args[0].startswith("-") else "all"
  )

  if filter_cat in ("online", "wallhaven", "wh"):
    return random_wallhaven(args[1:])

  wps = []
  if WALLPAPERS_JSON.exists():
    try:
      wps = json.loads(WALLPAPERS_JSON.read_text(encoding="utf-8"))
    except Exception:
      wps = []

  if not wps:
    wps = scan()
  if not wps:
    log_err("No wallpapers found in library. Run scan first.")
    return False

  cur_wp = ""
  if CURR_WALL_SYMLINK.is_symlink():
    try:
      target = CURR_WALL_SYMLINK.resolve()
      if target.is_file():
        cur_wp = str(target)
    except Exception:
      pass

  if filter_cat not in {"all", ""}:
    filtered = [
        w["path"]
        for w in wps
        if filter_cat in w["category"].lower()
        or filter_cat in w["parentCategory"].lower()
        or filter_cat in w["subCategory"].lower()
    ]
    candidates = filtered if filtered else [w["path"] for w in wps]
  else:
    candidates = [w["path"] for w in wps]

  candidates = [p for p in candidates if os.path.isfile(p)]
  if not candidates:
    return False

  if len(candidates) > 1 and cur_wp in candidates:
    candidates.remove(cur_wp)

  chosen = random.choice(candidates)
  rest = args[1:] if (args and not args[0].startswith("-")) else args
  log_info(f"Rolled random wallpaper ({C_CYAN}{filter_cat}{C_RESET})")
  return set_wallpaper([chosen] + rest)


# --- Wallhaven Online Roll ---
def fetch_wallhaven_wallpaper(
    query: str = "", category: str = "all", sorting: str = "random"
) -> Optional[str]:
  cfg = load_settings()
  api_key = (
      os.environ.get("WALLHAVEN_API_KEY", "")
      or cfg.get("wallhavenApiKey", "").strip()
  )
  ratios = cfg.get("wallhavenRatios", "16x9,16x10,21x9")
  atleast = cfg.get("wallhavenAtleast", "1920x1080")

  cat_map = {"all": "111", "general": "100", "anime": "010", "people": "001"}
  cat_code = cat_map.get(category.lower(), "111")

  params = {
      "sorting": sorting,
      "purity": "100",
      "categories": cat_code,
      "ratios": ratios,
      "atleast": atleast,
  }
  if query:
    params["q"] = query
  if api_key:
    params["apikey"] = api_key

  api_url = f"https://wallhaven.cc/api/v1/search?{urllib.parse.urlencode(params)}"
  req = urllib.request.Request(
      api_url,
      headers={
          "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) quickshell/1.0"
      },
  )

  try:
    with urllib.request.urlopen(req, timeout=12) as resp:
      data = json.loads(resp.read().decode("utf-8"))
      wps = data.get("data", [])
      if not wps:
        return None
      return random.choice(wps).get("path")
  except Exception as e:
    log_err(f"Wallhaven API error: {e}")
    return None


def random_wallhaven(args) -> bool:
  query = ""
  rest = []
  if args and not args[0].startswith("-"):
    query = args[0].strip()
    rest = args[1:]
  else:
    rest = args

  log_info(
      f"Fetching random wallpaper from Wallhaven"
      + (f" ({C_CYAN}{query}{C_RESET})" if query else "...")
  )
  img_url = fetch_wallhaven_wallpaper(query=query)
  if not img_url:
    log_err(f"No wallpaper found on Wallhaven for: '{query}'")
    return False

  save_dir = WALLPAPERS_DIR / "wallhaven"
  dest = save_dir / extract_filename(img_url, is_live=False)

  if dest.exists() and dest.stat().st_size > 0:
    return set_wallpaper([str(dest)] + rest)

  if stream_download(img_url, dest):
    scan()
    return set_wallpaper([str(dest)] + rest)
  return False


def set_color(args) -> bool:
  cfg = load_settings()
  raw_hex = args[0] if len(args) > 0 and args[0] else "#787756"
  raw_hex = raw_hex.lstrip("#")
  hex_color = f"#{raw_hex}"
  mode = (
      args[1] if len(args) > 1 and args[1] else cfg.get("matugenMode", "dark")
  )
  scheme = (
      args[2]
      if len(args) > 2 and args[2]
      else cfg.get("matugenScheme", "scheme-tonal-spot")
  )

  kill_mpvpaper()
  ensure_awww_daemon()

  try:
    subprocess.run(["awww", "clear", raw_hex], stderr=subprocess.DEVNULL)
    subprocess.run(
        ["matugen", "color", "hex", hex_color, "-m", mode, "-t", scheme],
        stderr=subprocess.DEVNULL,
    )
  except Exception:
    pass

  update_settings({"matugenMode": mode, "matugenScheme": scheme})
  log_success("Applied color theme:", hex_color)
  return True


def reapply(args) -> bool:
  log_info("Re-applying current wallpaper & matugen theme...")
  cfg = load_settings()
  mode = (
      args[0] if len(args) > 0 and args[0] else cfg.get("matugenMode", "dark")
  )
  scheme = (
      args[1]
      if len(args) > 1 and args[1]
      else cfg.get("matugenScheme", "scheme-tonal-spot")
  )

  cur_wp = ""
  if CURR_WALL_SYMLINK.is_symlink():
    try:
      target = CURR_WALL_SYMLINK.resolve()
      if target.is_file():
        cur_wp = str(target)
    except Exception:
      pass

  if not cur_wp or not os.path.isfile(cur_wp):
    cur_wp = resolve_wallpaper_path(cfg.get("currentWallpaper", ""))

  if cur_wp and os.path.isfile(cur_wp):
    return set_wallpaper(
        [cur_wp, "--mode", mode, "--scheme", scheme]
        + (args[2:] if len(args) > 2 else [])
    )
  else:
    log_warn("No active wallpaper to reapply. Falling back to theme color.")
    return set_color(["#787756", mode, scheme])


def download(args) -> bool:
  if not args:
    log_err("Usage: wp download <url>")
    return False
  raw_url = args[0].strip()
  rest = args[1:]

  if raw_url.startswith(("/", "~", "file://")):
    local_path = Path(raw_url.replace("file://", "")).expanduser()
    if local_path.is_file():
      res = set_wallpaper([str(local_path)] + rest)
      scan()
      return res

  is_live = is_live_url(raw_url)
  save_dir = WALLPAPERS_DIR / ("live" if is_live else "wallhaven")
  dest = save_dir / extract_filename(raw_url, is_live)

  if dest.exists() and dest.stat().st_size > 0:
    return set_wallpaper([str(dest)] + rest)

  log_info("Downloading wallpaper...")
  if stream_download(raw_url, dest):
    scan()
    return set_wallpaper([str(dest)] + rest)
  return False


# --- Native FZF Interactive Engine ---
def fzf_prompt(lines: List[str], fzf_args: List[str]) -> Optional[str]:
  if not shutil.which("fzf"):
    log_warn("fzf not found. Install fzf for interactive pickers.")
    return None
  try:
    proc = subprocess.run(
        ["fzf"] + fzf_args,
        input="\n".join(lines),
        text=True,
        capture_output=True,
    )
    if proc.returncode == 0:
      return proc.stdout.strip()
  except Exception:
    pass
  return None


def interactive_picker():
  if not shutil.which("fzf"):
    print_help()
    return

  options = [
      "󰑐 roll random local wallpaper",
      "󰖟 roll random online wallpaper (wallhaven)",
      "󰋩 select wallpaper from library",
      "󰍹 select live video / gif wallpaper",
      "󰁕 reload current wallpaper & theme",
      "󰚰 rescan library & thumbnails",
      "󰏤 download wallpaper by url",
  ]

  choice = fzf_prompt(
      options,
      [
          "--header=[󰄛 wallpaper hub - what do you want to do?]",
          "--reverse",
          "--height=40%",
      ],
  )
  if not choice:
    return

  if "roll random local" in choice:
    random_wallpaper(["all"])
  elif "roll random online" in choice:
    try:
      q = (
          input(f"{C_CYAN}enter search query (leave blank for random): {C_RESET}")
          .strip()
      )
    except (EOFError, KeyboardInterrupt):
      return
    random_wallhaven([q] if q else [])
  elif "select wallpaper from library" in choice:
    if not WALLPAPERS_JSON.exists():
      scan()
    wps = json.loads(WALLPAPERS_JSON.read_text(encoding="utf-8"))
    lines = [f"{w['path']}\t{w['category']}\t{w['name']}" for w in wps]
    res = fzf_prompt(
        lines,
        [
            "--with-nth=2,3",
            "--delimiter=\t",
            "--header=[󰋩 select wallpaper]",
            "--reverse",
            "--height=50%",
        ],
    )
    if res:
      set_wallpaper([res.split("\t")[0]])
  elif "select live video" in choice:
    if not WALLPAPERS_JSON.exists():
      scan()
    wps = json.loads(WALLPAPERS_JSON.read_text(encoding="utf-8"))
    live = [w for w in wps if w.get("isLive")]
    lines = [
        f"{w['path']}\t[live {w.get('ext')}]\t{w.get('name')}" for w in live
    ]
    res = fzf_prompt(
        lines,
        [
            "--with-nth=2,3",
            "--delimiter=\t",
            "--header=[󰍹 select live wallpaper]",
            "--reverse",
            "--height=50%",
        ],
    )
    if res:
      set_wallpaper([res.split("\t")[0]])
  elif "reload current" in choice:
    reapply([])
  elif "rescan library" in choice:
    scan()
    log_success("Library rescanned & thumbnails updated.")
  elif "download wallpaper" in choice:
    try:
      url = input(f"{C_CYAN}enter wallpaper / video url: {C_RESET}").strip()
    except (EOFError, KeyboardInterrupt):
      return
    if url:
      download([url])


def print_help():
  print(f"""{C_MAGENTA}󰄛 wp - interactive wallpaper control hub{C_RESET}

{C_BOLD}Usage:{C_RESET}
  wp                           Open interactive fzf picker
  wp random [category|online]  Roll random wallpaper (e.g. wp random anime)
  wp wh [query]                Roll random online wallpaper from Wallhaven
  wp reload                    Re-apply current wallpaper & theme
  wp set <file> [options...]   Apply specific image or video file
  wp color <#hex>              Set custom solid color theme
  wp scan                      Rescan local library & generate thumbnails
  wp download <url>            Download image/video and apply
  wp stop                      Kill running live video wallpapers (mpvpaper)
  wp get                       Print current wallpaper path
""")


def main():
  if len(sys.argv) < 2:
    interactive_picker()
    sys.exit(0)

  arg = sys.argv[1].lower()
  if arg in ("-h", "--help", "help"):
    print_help()
    sys.exit(0)

  ensure_symlinks_valid()
  args = sys.argv[2:]

  dispatch = {
      "scan": lambda: (scan(), log_success("Wallpaper library rescanned."), True)[2],
      "set": lambda: set_wallpaper(args),
      "random": lambda: random_wallpaper(args),
      "roll": lambda: random_wallpaper(args),
      "wallhaven": lambda: random_wallhaven(args),
      "wh": lambda: random_wallhaven(args),
      "online": lambda: random_wallhaven(args),
      "reload": lambda: reapply(args),
      "refresh": lambda: reapply(args),
      "reapply": lambda: reapply(args),
      "color": lambda: set_color(args),
      "download": lambda: download(args),
      "stop": lambda: (kill_mpvpaper(), log_success("Stopped live wallpapers."), True)[2],
      "kill": lambda: (kill_mpvpaper(), log_success("Stopped live wallpapers."), True)[2],
      "get": lambda: (print(resolve_wallpaper_path(None) or "none"), True)[1],
      "current": lambda: (print(resolve_wallpaper_path(None) or "none"), True)[1],
  }

  if arg in dispatch:
    success = dispatch[arg]()
    sys.exit(0 if success else 1)
  elif Path(sys.argv[1]).expanduser().is_file():
    success = set_wallpaper(sys.argv[1:])
    sys.exit(0 if success else 1)
  else:
    log_err(f"Unknown command '{arg}'. Run 'wp --help' for usage.")
    sys.exit(1)


if __name__ == "__main__":
  main()
