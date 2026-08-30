#!/usr/bin/env zsh
# gtk-reload.zsh - toggle GTK color scheme to force reload

set -euo pipefail

current=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo "'prefer-dark'")

if [[ "$current" == "'prefer-dark'" ]]; then
    gsettings set org.gnome.desktop.interface color-scheme prefer-light
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark
else
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark
    gsettings set org.gnome.desktop.interface color-scheme prefer-light
fi
