# hyprland dots: the hallucination edition

>[!WARNING]
> this repo is 90% autonomous ai slop, 9% sleep deprivation, and 1% quickshell negotiating terms of surrender with wlroots. deploy at your own psychological peril.

this is my hyprland setup. synthesized entirely through prompt engineering, multi-agent thread wars, and complete disregard for human software engineering.

the development stack:
- google ai studio: where i dumped 1.5 million tokens of raw wayland xml protocols and broken quickshell documentation into a single prompt box at 3 am to force gemini to hallucinate layer-shell glue code.
- google antigravity: where i ran four competing agent threads in parallel inside an electron fork until my laptop could cook an egg. one agent hallucinated display server protocols, another broke python arrays, and the other two fought over corner scoop radii.
- google jules: the async agent that clones this repo into isolated cloud vms while i sleep, invents unit tests for nonexistent bugs, and throws unhinged pull requests at main with zero human oversight.

it runs on my machine. if your compositor kernel panics on boot, that is fundamentally a skill issue.

# new shit

- material symbols: burned legacy nerd font mdi glyphs in a dumpster. switched to official google material symbols with runtime switching between rounded, outlined, and sharp because misaligned glyphs gave me psychic damage.
- wallpaper browser loop massacre: killed 50+ recursive qml binding loops so your cpu doesn't turn into an air fryer every time you open the wallpaper grid.
- bar layout studio: live interactive widget drag and drop (left, center, right) with liquid concave scoops. zero restarts, infinite hubris. spend three hours moving a clock two pixels to the left instead of doing homework.
- app launcher: no longer renders at 0x0 invisible ghost pixels in the shadow realm while swallowing your keystrokes.
- python script unification: deleted fragmented shell forks in favor of unified python scripts (wallpaper.py, session.py, clipboard.py) because writing bash arrays feels like being hexed by a medieval peasant.
- absolute #000000 black: pitch black across the bar, cards, pills, and screen scoops. no washed-out dark grey fraud. discord dark theme could never.
- glass split: real frosted blur via layer-shell rules instead of broken opacity hacks that look like grease on a screen.
- continuous screen borders: corner scoops now connect with continuous pixel-perfect borders wrapping the monitor like an ankle monitor.
- top bar clipping dead: eradicated nested animations and width clipping so hovering over one icon doesn't eat adjacent widgets alive.
- schema-driven settings: murdered manual serialization boilerplate. dynamic schema or bust.
- flatpak sandbox containment: gtk-3.0 and gtk-4.0 configs are synced as physical directories instead of symlinks because bubblewrap throws a tantrum if it encounters symlinks across container boundaries.
- curl pipe installer fixed: install.zsh reads directly from /dev/tty so piping remote curl commands doesn't immediately choke on eof like a coward.
- zsh prompt customizer: live interactive customizer with prompt styles (two-line, single-line, minimal, bracket, full mental breakdown), custom symbols, and colors for artificial dopamine when code won't compile.
- help cheatsheet: instant colorized keybind cheat sheet so you remember what keys you remapped while dissociated at 4 am.
- unhinged readme overhaul: purged sanitized corporate chatbot drivel from every single file here.

# how to nuke wayland

prerequisites: an arch-based distro, zsh, and a complete lack of regard for your system stability.

do not run this script as root. if you run `sudo ./install.zsh`, the script detects your hubris, roasts you in bold red ansi, and terminates immediately before you chmod your entire life into 000.

clone the repo:

```zsh
git clone https://github.com/theyh4t3-ashlxy/my_hyprland_dots.git ~/my-hyprland-dots
cd ~/my-hyprland-dots
```

run the harness:

```zsh
chmod +x install.zsh
./install.zsh
```

if fzf is installed, it spawns an interactive multi-select menu. if fzf is missing, it falls back to comma-separated numbers because we accommodate your technological neglect.

# flags for people who hate interactive menus

- `./install.zsh --all`: full send. archives existing configs into `~/.cache/dotfiles-backups/backup_<timestamp>.tar.gz`, pulls packages, symlinks everything, compiles zsh bytecode, runs matugen, starts quickshell via uwsm, offers zero apologies.
- `./install.zsh --doctor`: runs a diagnostic scan on your machine. checks for missing binaries (hyprland, uwsm, matugen, awww, mpvpaper, quickshell), inspects typography (jetbrainsmono nerd font, noto sans), validates symlinks, and tells you why your desktop is held together by spit and duct tape.
- `./install.zsh --update`: pulls latest commits from git, fixes permission bits on python helper scripts, resyncs links, samples wallpaper palette, and reloads without nuking your local changes.
- `./install.zsh --reload`: signals hyprctl reload and restarts quickshell (`qs -d`) inside your uwsm session so it doesn't linger as an orphaned background zombie.
- `./install.zsh --links`: symlinks dotfiles into `~/.config` without touching system packages.
- `./install.zsh --deps`: installs dependencies without touching your existing dotfiles.
- `./install.zsh --aur`: bootstraps `paru-bin` via makepkg if you are on arch without an aur helper. arch without the aur is just debian with anxiety.
- `./install.zsh --fetch-wp`: downloads a clean catppuccin landscape wallpaper into `~/.wallpapers/downloaded/` so your desktop doesn't look like an abandoned void.
- `./install.zsh --pkgs=desktop,terminal,media`: install specific package categories only. options: desktop, terminal, tools, editors, media, fonts, system.
- `./install.zsh --dots=quickshell,hypr,kitty`: symlink specific configs only. options: quickshell, hypr, matugen, kitty, zsh, fastfetch, yazi, nvim, gtk-3.0, gtk-4.0.
- `./install.zsh --no-theme`: skip wallpaper palette extraction via matugen.
- `./install.zsh --no-backup`: live dangerously and skip tarball generation.

# the fun route

if you have zero self-preservation instincts and actively hate your life as we speak:

```zsh
curl -fsSL https://raw.githubusercontent.com/theyh4t3-ashlxy/my_hyprland_dots/main/install.zsh | zsh
```

the installer hijacks `/dev/tty` for user input, so piping curl will not panic on eof. you have no excuse.

# known bugs

nothing currently on fire. either it runs or the error logging daemon segfaulted before it could snitch.

# todo / future graveyard

- [ ] fix animation consistency across modules before someone gets a migraine
- [ ] interactive physics lab in motion sandbox because a window manager totally needs spring physics
- [ ] open an issue to scream into the void if you want something added

# how to complain (or "contribute")

open an issue. i'll never look at it. google jules will clone your complaints into an ephemeral cloud vm, antigravity will spawn four competing sub-agents to fight over the fix, and whatever frankenstein pull request survives will get merged directly into main without a single human reviewing the diff. feel free to insult the bots in the issue tracker, they don't have mirror neurons anyway.

# human pull requests

if you are an actual carbon-based entity and want to fix hallucinated logic, open a pull request. the ai reviewer in github actions will probably gaslight you and claim your valid code is a syntax error, but i'll merge it over the bot's dead body out of pure spite. fork it, turn it into your own esoteric rice, do whatever. just don't ping me when your tty freezes during a presentation.
