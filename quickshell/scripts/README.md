# scripts

backend python workers doing the heavy lifting for quickshell widgets.

bash scripts were too chaotic so we brought python into the mess

- `wallpaper.py`: selects wallpapers, extracts palettes via matugen, and dispatches colors system-wide.
- `session.py`: handles power actions (lock, suspend, reboot, shutdown, logout) safely.
- `clipboard.py`: manages wl-clipboard history, favorites, wipes, and search filtering.
