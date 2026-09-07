# lockscreen

keep out unless you know the magic words.

hyprlock is fine if you like plaintext configs, but having your lockscreen wired directly into the quickshell layer-shell engine means zero flickering, seamless token sharing, and total aesthetic continuity.

## the bouncer
- `LockScreen.qml`: full-screen security surface backed by native pam authentication. includes a live digital clock, material battery and wifi status pills, media playback controls with mpris album art, and a password field that shivers aggressively when you fat-finger your credentials. hooks into `qs ipc call lock lock` for instant manual locking from keybindings.
