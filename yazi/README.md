# yazi

blazing fast terminal file manager written in rust because clicking around in electron or traversing nested directories with standard `cd` and `ls` is a test of human patience we refuse to take.

arrow keys and vim motions go zooom.

yazi renders asynchronous directory trees, previews syntax-highlighted code, extracts archive contents, and displays raw image previews directly in the terminal via kitty's graphics protocol without segfaulting.

## configs
- `theme.toml`: synched with matugen so file type badges, cursor bars, and selection borders match your desktop wallpaper.
- `keymap.toml`: custom keybindings tailored for lightning navigation.
- `package.toml`: package and plugin manifest.
- `plugins/`: custom yazi extensions like `smart-enter` to open files or enter directories seamlessly with a single key.
