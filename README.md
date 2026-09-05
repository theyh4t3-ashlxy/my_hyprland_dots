> [!WARNING]
> THERE IS AI SLOP ALL OVER THIS REPO!! you have been warned!

> [!IMPORTANT]
> ok so i upgraded it a bit, same old commit but at least things are fixed, and pure black is actually black. glass theme uses layer rules (would've def wanted to do it on qs itself tho but ok google)
> still had to go to older commit 

hi! this is my hyprland dots.   
gemini through antigravity and ai studio vibecoded this.  
(sometimes it just halucinates BAD, hence why ai studio exists)

ok actual shell starts here dont cry

# what got fixed & unfucked

- [x] bar got unfucked, 4-way docking works seamlessly in top, bottom, left, and right with dynamic transforms
- [x] widget loader visibility deadlock dead and buried (all 15 widgets load instantly)
- [x] native layer-shell osd overlay for volume, mic mute, and brightness changes
- [x] dynamic multi-tier battery glyphs (11 levels, charging, saver, and vertical bar orientation)
- [x] multi-pack iconography: Microsoft Segoe Fluent Icons, Material Design, and Font Awesome with automatic nerd font fallback
- [x] screen corner scoops match matugen theme instead of pitch black bars
- [x] screen corners auto-hide in fullscreen so movies and games aren't cursed
- [x] local wi-fi ssid renaming right inside the network status card
- [x] lock screen running on native `PamContext` (hyprlock nuked)
- [x] `nmcli` script hacks eradicated in favor of native `Quickshell.Networking`
- [x] settings organized into clean categorized groups with 100% synchronous `FileView` persistence
- [x] calendar day header token bug squashed (no more "day DDD of 2026")
- [x] hyprland 0.55 lua dispatch syntax restored for workspaces
- [x] bar layouts unified: murdered ~350 lines of duplicate horizontal/vertical loader spaghetti with `BarWidgetLoader`
- [x] repeater incubator crash patched: snapshotted workspaces list model so quickshell stops segfaulting on desktop switch
- [x] backlight auto-detection: scans `/sys/class/backlight/` dynamically instead of dying on non-intel gpus
- [x] settings engine schema-driven: wiped 200 lines of manual serialization boilerplate
- [x] notification timer drift eradicated with timestamp delta tracking and duplicate toast suppression
- [x] zsh overhauled: compinit cached, bytecode auto-compilation, zero dead imports, 50+ existential roasts

dont run this as root unless you want your drive atomized

# how to install (or destroy your system)

clone this repo somewhere that won't give u an existential crisis:

```bash
git clone https://github.com/theyh4t3-ashlxy/my_hyprland_dots.git ~/my-hyprland-dots
cd ~/my-hyprland-dots
```

then run the installer so you don't have to copy-paste symlinks like an animal:

```bash
chmod +x install.zsh
./install.zsh
```

it gives you an interactive menu. if you want zero questions and maximum commitment:
- `./install.zsh --all`: grabs all packages, backs up your existing trash into `~/.cache/dotfiles-backups`, symlinks everything, generates wallpaper colors, pre-compiles zsh bytecode, and boots quickshell.
- `./install.zsh --doctor`: inspects missing binaries, checks font glyph packs (Segoe, JetBrainsMono, Noto), verifies quickshell compilation, and tells you what's broken.
- `./install.zsh --update`: pulls latest git commits, syncs links, and reloads without nuking your stuff.
- `./install.zsh --reload`: reloads running hyprland and restarts `qs -d` in the background.

if your desktop looks naked, throw some wallpapers into `~/.wallpapers/` and type `wp random` or open the wallpaper chooser widget.

this section is cursed do not linger

# known issues rn
*(will fix when claude models go back in antigravity, which is in like 2 hours. idk)*

- [ ] inconsistencies around the ui (specifically animations, but also some refinements)
- [ ] animations not matching. [settings](quickshell/widgets/QuickSettings.qml) (technically its all animation presets not just hyprland anims file)

# will refine

- [ ] interactive physics lab in motion sandbox
- [ ] give me ideas too  

# how to complain (or "contribute")

make an issue. i'll eventually pass it on to antigravity or google jules. whatever works.  
when jules is done codin, i'll accept its changes.  
(be rude to it, or dont. idc)  

# if you wanna be a human coder and fix the hallucinations 
*(which the ai will call u out and say its incorrect even though u are and fix the "error")*  

make a pull request, and i'll accept the changes. or fork and make ur own distro outta dots. idgaf  
