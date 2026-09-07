# zsh

an over-engineered zsh environment compiled to bytecode (`.zwc`) for instant startup.

if your interactive shell takes more than ten milliseconds to render a prompt, you have failed as an engineer and your ancestors are disappointed in you. no heavy frameworks, no ten-layer ruby plugins, just clean compiled zsh modules and raw speed.

## modules
- `core.zsh`: shell options, smart history deduplication, and line editor keybindings.
- `prompt.zsh`: dynamic prompt engine with hot-switchable styles (two-line, single-line, minimal, bracket, unhinged) with git branch indicators and exit code colors.
- `settings.zsh`: interactive terminal customizer allowing you to tweak prompt symbols and behavior without manually hacking scripts.
- `roast.zsh`: the self-esteem executioner. hooks into `command_not_found_handler` to track your spelling errors and violently roast your cognitive decline directly in your terminal.
- `dnd.zsh`: instant do-not-disturb toggle switch right from the command line.
- `wp.zsh`: wallpaper manager commands (`wp random`, `wp set <path>`, `wp next`) communicating with quickshell and matugen.
- `aliases.zsh`: muscle memory shortcuts saving thousands of keystrokes per day.
- `help.zsh`: colorized instant cheat sheet so you remember what keys you remapped at 3 am.
- `nuke.zsh`: emergency cleanup utilities for cleaning caches and killing rogue tasks.
- `matugen.zsh`: shell prompt gradient colors piped straight from matugen's generated palette.
