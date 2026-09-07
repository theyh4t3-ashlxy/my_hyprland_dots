# scripts

bash scripts were an unmaintainable swamp of escaped quotes and sed hallucinations, so we brought python into the mess to do the actual heavy lifting.

these worker scripts run as headless sub-processes dispatched by quickshell services to interact with core wayland and system utilities without blocking the main render loop.

## the workforce
- `wallpaper.py`: selects wallpapers, calls matugen to generate color palettes from the image, and writes dynamic tokens system-wide without burning your cpu.
- `session.py`: dispatches session power actions (lock, suspend, reboot, shutdown, logout) cleanly without accidentally invoking a fork bomb.
- `clipboard.py`: interfaces with `wl-clipboard` to manage clipboard history, search filters, favorite pins, and atomic cache wipes.
