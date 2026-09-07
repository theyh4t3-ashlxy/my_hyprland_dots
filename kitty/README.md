# kitty

gpu-accelerated terminal emulator where i type git commands i barely understand.

if your terminal emulator uses web technologies or takes more than three milliseconds to open a new tab, you are doing computing wrong. kitty draws text with opengl and runs directly on your graphics card.

## configs
- `kitty.conf`: internal window padding, background blur, tab bar aesthetics, keybinds, ligatures, and font overrides (jetbrains mono nerd font).
- `colors.conf`: the battleground. violently overwritten by matugen whenever you switch wallpapers so your terminal colors match whatever image you pulled from the internet.

if kitty doesn't update its palette after a wallpaper switch, blame a dead pid or run `pkill -USR1 kitty` to force the redraw.
