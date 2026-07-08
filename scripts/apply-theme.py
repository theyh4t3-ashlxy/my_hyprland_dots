#!/usr/bin/env python3
import sys
import os
import subprocess

if len(sys.argv) < 2:
    print("󰚌 bro, give me a wallpaper path first. i am not a mind reader.")
    sys.exit(1)

# FIXED: Correctly index the first argument string
wallpaper = os.path.abspath(sys.argv[1])

if not os.path.exists(wallpaper):
    print(f"󰚌 uhh... that file '{wallpaper}' doesn't even exist? check your spelling.")
    sys.exit(1)

print(f"󰸉 setting wallpaper: {wallpaper}")
# added your sleek bezier transition string directly to the engine call
subprocess.run([
    "awww", "img", wallpaper, 
    "--transition-type", "fade", 
    "--transition-duration", "1.8", 
    "--transition-fps", "90", 
    "--transition-bezier", "0.25,1,0.5,1"
], check=True)

print("󱇱 running matugen (hyprland, quickshell, kitty, fastfetch)...")
config = os.path.expanduser("~/.config/matugen/config.toml")

# FIXED: Added --source-color-index 0 to prevent the script from freezing/hanging
result = subprocess.run(
    [
        "matugen",
        "--prefer",
        "darkness",
        "--source-color-index",
        "0",
        "-c",
        config,
        "image",
        wallpaper,
    ],
    capture_output=True,
    text=True,
)

if result.returncode != 0:
    print("󰚌 matugen exploded:", result.stderr or result.stdout)
    sys.exit(result.returncode)

print("󰚌 nudging hyprland to refresh itself...")
# FIXED: Fallback file touch method
hyprland_lua = os.path.expanduser("~/.config/hypr/hyprland.lua")
if os.path.exists(hyprland_lua):
    os.utime(hyprland_lua, None)

# FIXED: Explicitly force Hyprland to reload right now via hyprctl
subprocess.run(["hyprctl", "reload"], capture_output=True)

print("󰸉 done! enjoy the pretty colors.")