# quickshell

the crown jewel of this desktop. pure qml + c++ layer-shell magic.

wayland bars are hard. quickshell makes them art.

handles the status bar, concave screen corners, notification popups, lockscreen, app launcher, quick settings, audio osd, and wallpaper switcher.

- `shell.qml`: root orchestrator. spawns bars, overlays, and registers ipc endpoints (`notifs`, `lock`).
- `Theme.qml`: dynamic material design token bible. colors, metrics, animation curves.
- `settings.conf`: persisted user preferences (bar position, sizes, padding, toggles).
- `bar/`: status bar layout engine.
- `corners/`: liquid concave screen corners and continuous display frame borders.
- `widgets/`: modular desktop pills, sliders, and panels.
- `services/`: system state providers (audio, network, battery, notifications, settings).
- `controls/`: reusable design system components.
- `notifications/`: floating toast alert windows.
- `lockscreen/`: pam authentication layer-shell lockscreen.
- `osd/`: on-screen volume and brightness pill popups.
- `scripts/`: unified python helper scripts for backend duties.
