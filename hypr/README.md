# hypr

lua-powered hyprland config because standard hyprland syntax wasn't psychotic enough.

configuring a wayland compositor with declarative brackets and quotes is for normal people. we run lua tables and functions because if our display server isn't running an embedded scripting runtime at 240hz, what are we even doing with our lives?

if your screen flickers or your windows start teleporting into the fourth dimension, check your monitor coordinates before crying to me.

## the architecture of chaos
- `hyprland.lua`: the entrypoint. the puppeteer holding the strings of your entire visual reality.
- `binds.lua`: muscle memory torture chamber. every combination of super, alt, shift, and ctrl mapped to quickshell toggles, terminal spawns, and scratchpad summoning.
- `rules.lua`: window rules forcing stubborn electron apps, picture-in-picture windows, and file pickers to float, tile, or get pinned where they belong.
- `anims.lua`: cubic bezier curves tuned so aggressively your gpu actually sweats just resizing a terminal.
- `startup.lua`: daemons and processes dragged kicking and screaming into existence on login (quickshell, hypridle, polkit, wireplumber).
- `monitors.lua`: display resolutions, scaling factors, and refresh rates. don't look directly at it or your edid will cry.
- `colors.lua`: auto-generated matugen paint. dynamically rewritten on wallpaper shifts. do not edit this by hand unless you enjoy having your changes mercilessly overwritten.
