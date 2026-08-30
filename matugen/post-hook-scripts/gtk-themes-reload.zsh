#!/usr/bin/env zsh
# gtk-themes-reload.zsh - refresh GTK3/4 themes and notify xsettingsd

set -euo pipefail

# double-tap gtk4 / libadwaita
current=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo "'prefer-dark'")
if [[ "$current" == "'prefer-dark'" ]]; then
    gsettings set org.gnome.desktop.interface color-scheme prefer-light
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark
else
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark
    gsettings set org.gnome.desktop.interface color-scheme prefer-light
fi

# double-tap gtk3
current_theme=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'" || echo "Adwaita")
[[ -z "$current_theme" ]] && current_theme="Adwaita"

gsettings set org.gnome.desktop.interface gtk-theme ""
gsettings set org.gnome.desktop.interface gtk-theme "$current_theme"

# poke xsettingsd if running
if pgrep -x "xsettingsd" > /dev/null 2>&1; then
    pkill -HUP xsettingsd 2>/dev/null || true
fi
