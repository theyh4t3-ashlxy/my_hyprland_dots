# lockscreen

hyprland lockscreen built directly into quickshell.

keep out unless you know the magic words

- `LockScreen.qml`: full-screen security surface with pam authentication, password input, clock, media playback controls, and battery status. hooks into quickshell's `qs ipc call lock lock` for instant manual locking.
