#!/usr/bin/env zsh
# gtk-themes-reload.zsh - refresh GTK3/4 themes and notify xsettingsd

# Prioritize dconf on NixOS standalone sessions, fall back to gsettings if schemas exist
if (( $+commands[dconf] )); then
    current=$(dconf read /org/gnome/desktop/interface/color-scheme 2>/dev/null || echo "'prefer-dark'")
    if [[ "$current" == "'prefer-dark'" ]]; then
        dconf write /org/gnome/desktop/interface/color-scheme "'prefer-light'"
        dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
    else
        dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
        dconf write /org/gnome/desktop/interface/color-scheme "'prefer-light'"
    fi

    current_theme=$(dconf read /org/gnome/desktop/interface/gtk-theme 2>/dev/null || echo "'adw-gtk3-dark'")
    [[ -z "$current_theme" || "$current_theme" == "''" ]] && current_theme="'adw-gtk3-dark'"
    dconf write /org/gnome/desktop/interface/gtk-theme "''"
    dconf write /org/gnome/desktop/interface/gtk-theme "$current_theme"
elif (( $+commands[gsettings] )); then
    current=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo "'prefer-dark'")
    if [[ "$current" == "'prefer-dark'" ]]; then
        gsettings set org.gnome.desktop.interface color-scheme prefer-light 2>/dev/null || true
        gsettings set org.gnome.desktop.interface color-scheme prefer-dark 2>/dev/null || true
    else
        gsettings set org.gnome.desktop.interface color-scheme prefer-dark 2>/dev/null || true
        gsettings set org.gnome.desktop.interface color-scheme prefer-light 2>/dev/null || true
    fi

    current_theme=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'" || echo "adw-gtk3-dark")
    [[ -z "$current_theme" ]] && current_theme="adw-gtk3-dark"
    gsettings set org.gnome.desktop.interface gtk-theme "" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme "$current_theme" 2>/dev/null || true
fi

# Sync theme tokens to active flatpak application config directories
for app_gtk4 in $HOME/.var/app/*/config/gtk-4.0(N/); do
    cp -f "$HOME/.config/gtk-4.0/colors.css" "$app_gtk4/colors.css" 2>/dev/null || true
    cp -f "$HOME/.config/gtk-4.0/gtk.css" "$app_gtk4/gtk.css" 2>/dev/null || true
    cp -f "$HOME/.config/gtk-4.0/gtk-dark.css" "$app_gtk4/gtk-dark.css" 2>/dev/null || true
done

for app_gtk3 in $HOME/.var/app/*/config/gtk-3.0(N/); do
    cp -f "$HOME/.config/gtk-3.0/colors.css" "$app_gtk3/colors.css" 2>/dev/null || true
    cp -f "$HOME/.config/gtk-3.0/gtk.css" "$app_gtk3/gtk.css" 2>/dev/null || true
done

# poke xsettingsd if running
if pgrep -x "xsettingsd" > /dev/null 2>&1; then
    pkill -HUP xsettingsd 2>/dev/null || true
fi
