# matugen

the material you color engine that extracts dynamic palettes from wallpapers and terrorizes every config file on your filesystem.

one wallpaper to rule them all. one binary to bind them.

matugen reads your wallpaper image, runs color quantizer math on raw rgb vectors, generates harmonic material 3 palette tokens, and violently writes them across hyprland, kitty, quickshell, fastfetch, zsh, nvim, yazi, and gtk stylesheets simultaneously.

## components
- `config.toml`: the hit list. defines input templates, output destinations, keywords, and reload hooks. every app that matugen is legally permitted to assassinate is listed here.
- `templates/`: skeleton files filled with template variables waiting for fresh hex codes. this includes `Theme.qml` which houses our official google material symbols and color tokens.
- `post-hook-scripts/`: reactive shell scripts executed after templates compile to kick running daemons and force them to redraw their surfaces.

## life-saving invocation note
never run matugen interactively in automated background scripts without `--source-color-index 0` unless you enjoy having your terminal hang forever waiting for a phantom stdin input that will never come.
