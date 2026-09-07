# matugen

material you color engine that extracts palettes from wallpapers and terrorizes every config file on the system.

one wallpaper to rule them all

reads an image, does math on color vectors, and dumps synchronized hex codes into hyprland, kitty, quickshell, fastfetch, zsh, nvim, yazi, and gtk.

- `config.toml`: the hit list of every config file matugen is allowed to assassinate.
- `templates/`: raw files with template tokens waiting for fresh hex codes.
- `post-hook-scripts/`: reload hooks that smack programs upside the head so they notice the theme changed.
