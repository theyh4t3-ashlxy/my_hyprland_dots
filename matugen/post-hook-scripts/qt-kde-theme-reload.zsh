#!/usr/bin/env zsh
# qt-kde-theme-reload.zsh - refresh Qt/KDE color schemes and notify running apps

# Double-tap with plasma-apply-colorscheme to force Plasma to re-read updated colors
if (( $+commands[plasma-apply-colorscheme] )); then
    plasma-apply-colorscheme BreezeDark >/dev/null 2>&1 || true
    plasma-apply-colorscheme Matugen >/dev/null 2>&1 || true
fi

# Sync accent color and dark widget style into KDE configs
if (( $+commands[kwriteconfig6] )); then
    accent=$(grep -m1 '^AccentColor=' "$HOME/.local/share/color-schemes/Matugen.colors" 2>/dev/null | cut -d= -f2)
    if [[ -n "$accent" ]]; then
        kwriteconfig6 --file kdeglobals --group "General" --key "AccentColor" "$accent" 2>/dev/null || true
        kwriteconfig6 --file kdeglobals --group "General" --key "LastUsedCustomAccentColor" "$accent" 2>/dev/null || true
    fi
    kwriteconfig6 --file katerc --group "KTextEditor Renderer" --key "Color Theme" "Breeze Dark" 2>/dev/null || true
    kwriteconfig6 --file katerc --group "KTextEditor Renderer" --key "Auto Color Theme Selection" "true" 2>/dev/null || true
    kwriteconfig6 --file kdeglobals --group "Icons" --key "Theme" "breeze-dark" 2>/dev/null || true
    kwriteconfig6 --file kdeglobals --group "KDE" --key "widgetStyle" "Breeze" 2>/dev/null || true
    kwriteconfig6 --file kdedefaults/kdeglobals --group "General" --key "ColorScheme" "Matugen" 2>/dev/null || true
fi

# Broadcast global settings change signal over DBus to update running Qt/KDE applications live
if (( $+commands[dbus-send] )); then
    dbus-send --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:0 int32:0 2>/dev/null || true
    dbus-send --type=signal /KWin org.kde.KWin.reloadConfig 2>/dev/null || true
fi

# Sync to Flatpak application configs
for app_colors in $HOME/.var/app/*/data/color-schemes(N/); do
    cp -f "$HOME/.local/share/color-schemes/Matugen.colors" "$app_colors/Matugen.colors" 2>/dev/null || true
done

for app_config in $HOME/.var/app/*/config(N/); do
    cp -f "$HOME/.config/kdeglobals" "$app_config/kdeglobals" 2>/dev/null || true
done
