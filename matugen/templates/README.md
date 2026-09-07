# templates

the blueprint graveyard for matugen.

curly braces, token placeholders, and raw hex targets everywhere you look.

when matugen is triggered by the wallpaper switcher, it processes every file in this directory and dumps the rendered output into the live app configs.

## the targets
- `Theme.qml`: the holy grail. quickshell's material 3 token bible and official google material symbols codepoint registry. backward compatibility was sacrificed here for pure unadulterated rendering glory.
- `hyprland-colors.lua`: active and inactive window border gradient tables for hyprland.
- `kitty-colors.conf`: 256-color palette and window background/foreground definitions for kitty.
- `fastfetch-colors.jsonc`: system info flex banner color tokens.
- `gtk3.css` & `gtk4.css`: injected css overrides to force gtk apps to match your desktop instead of blinding you with default themes.
- `nvim-colors.lua`: neovim syntax highlighting variables generated straight from your wallpaper's color harmony.
- `yazi-theme.toml`: terminal file manager file type colors and border highlights.
- `zsh-colors.zsh`: shell prompt gradient chips and error highlight colors.
