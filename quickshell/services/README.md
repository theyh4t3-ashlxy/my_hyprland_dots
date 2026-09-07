# services

singleton system state daemons communicating between linux subsystems and quickshell ui.

the wiring behind the wallpaper

- `Settings.qml`: persistent json/conf engine managing user preferences and bar configuration.
- `NotificationService.qml`: freedesktop notification daemon implementation with ipc triggers.
- `NetworkService.qml`: networkmanager dbus listener for wifi and ethernet connections.
- `BrightnessService.qml`: backlight controller reading `/sys/class/backlight`.
- `IdleService.qml`: hypridle / idle inhibitor hooks.
- `WallpaperService.qml`: wallpaper selection and live preview manager.
