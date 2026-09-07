# hyprland dots: the hallucination edition

> biohazard warning: this repository is 90% ai slop, 9% sleep deprivation, and 1% quickshell fighting for its life. enter at your own risk.

this is my hyprland setup. gemini, antigravity, and ai studio vibecoded this entire monstrosity because writing layer-shell qml and wayland protocol glue by hand is an insult to whatever sanity i have left. sometimes the model hallucinates an imaginary display server and everything breaks. it runs on my machine. if it doesn't run on yours, skill issue.

# what got unfucked

- google material symbols migration: burned legacy nerd font mdi glyphs in a fire and migrated to official google material symbols with runtime variant switching (rounded, outlined, sharp).
- wallpaper browser binding loop massacre: eradicated 50+ recursive qml binding loops so your cpu doesn't melt while opening the wallpaper grid.
- bar layout studio: live interactive widget reordering (left, center, right) with liquid concave scoops. zero restarts, infinite hubris.
- app launcher: no longer renders at 0x0 invisible ghost pixels in the shadow realm.
- python script unification: deleted fragmented shell forks in favor of unified python scripts (wallpaper.py, session.py, clipboard.py) because bash arrays are cursed.
- pure black delivered: pitch black #000000 across the bar, cards, pills, and screen scoops instead of washed-out dark grey fraud.
- glass split: actual frosted blur via layer-shell rules instead of broken opacity hacks.
- continuous screen borders: corner scoops now connect with continuous pixel-perfect borders wrapping the monitor like a cage.
- top bar clipping dead: eradicated nested animations and width clipping so hover expansions never eat adjacent widgets alive.
- schema-driven settings: murdered manual serialization boilerplate in favor of a clean unified schema.
- curl pipe installer fixed: install.zsh reads from /dev/tty so piping curl doesn't instantly die on eof.
- zsh prompt customizer: live interactive customizer with prompt styles (two-line, single-line, minimal, bracket, unhinged), custom symbols, and colors for artificial dopamine.
- help cheatsheet: instant colorized keybind cheat sheet so you remember what keys you remapped at 4 am.
- unhinged readme overhaul: purged corporate chatbot drivel from every directory in this repository.

# how to destroy your display server

clone this repo somewhere that won't trigger an existential crisis:

```bash
git clone https://github.com/theyh4t3-ashlxy/my_hyprland_dots.git ~/my-hyprland-dots
cd ~/my-hyprland-dots
```

run the installer so you don't have to copy-paste symlinks like a medieval peasant:

```bash
chmod +x install.zsh
./install.zsh
```

it boots an interactive menu. if you want zero questions and maximum system jeopardy:
- `./install.zsh --all`: full send. dumps your existing config into `~/.cache/dotfiles-backups`, symlinks everything, compiles zsh bytecode, generates palette colors, boots quickshell, offers zero apologies.
- `./install.zsh --doctor`: inspects missing fonts (segoe fluent icons, jetbrainsmono nerd font, noto sans), validates quickshell compilation, and tells you why your desktop is crying.
- `./install.zsh --update`: pulls latest commits, syncs links, and reloads without nuking your stuff.
- `./install.zsh --reload`: kicks running hyprland and restarts `qs -d` in the background.

if your desktop looks like an abandoned void, throw some wallpapers into `~/.wallpapers/` and run `wp random` or open the wallpaper chooser.

# the cursed route (do not do this)

if you have zero self-preservation instincts and actively hate your life as we speak:

```bash
# home directory russian roulette
curl -fsSL https://raw.githubusercontent.com/theyh4t3-ashlxy/my_hyprland_dots/main/install.zsh | zsh
```

# known bugs

nothing currently on fire. either it runs or the error logging daemon segfaulted before it could tell you.

# todo / future graveyard

- [ ] animation consistency across modules and quick settings
- [ ] interactive physics lab in motion sandbox
- [ ] open an issue to scream into the void if you want something added

# how to complain (or "contribute")

open an issue. i'll eventually feed the text into antigravity or google jules and let the bots fight about it. when jules spits out a patch, i'll merge it without reading a single line. feel free to insult the ai, it doesn't have feelings anyway.

# human pull requests

if you are an actual carbon-based entity and want to fix hallucinated logic, open a pull request. the ai reviewer will probably gaslight you and claim your valid code is an error, but i'll merge it over the bot's objections. fork it, turn it into your own esoteric rice, do whatever. just don't ping me when your tty freezes during a presentation.
