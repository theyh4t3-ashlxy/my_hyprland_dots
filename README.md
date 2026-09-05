> [!warning]
> there is ai slop all over this repo!! you have been warned!

hi! this is my hyprland dots.   
gemini through antigravity and ai studio vibecoded this.  
(sometimes it just hallucinates bad, hence why ai studio exists)

ok actual shell starts here dont cry

# what got fixed & unfucked

- [x] bar layout studio: live interactive widget reordering (left/center/right) with liquid concave scoop docking, zero restart required
- [x] app launcher resurrected: stopped rendering at 0x0 invisible ghost pixels
- [x] python script unification: deleted fragmented shell forks in favor of unified python scripts (wallpaper.py, session.py, clipboard.py)
- [x] pure black actually delivered: pure black mode is genuinely #000000 pitch black across the bar, cards, pills, and screen scoops instead of dark grey fraud
- [x] glass vs regular split: distinct solid regular theme vs true frosted glass blur via layer-shell rules
- [x] continuous screen frame borders: corner scoops now connect with continuous pixel-perfect borders wrapping the display
- [x] top bar layout overlap & clipping: eradicated nested animations and width clipping so hover expansions never overlap adjacent widgets
- [x] settings engine schema-driven: wiped manual serialization boilerplate in favor of a clean unified schema
- [x] curl pipe installer fixed: install.zsh reads from /dev/tty so curl piping doesn't immediately quit on eof
- [x] zsh settings & prompt customizer: interactive terminal customizer with prompt styles (two-line, single-line, minimal, bracket, unhinged), custom symbols, colors, and live prompt updates
- [x] help cheatsheet command: added instant colorized help command for dotfile shortcuts, quickshell, and hyprland keybindings

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
- `./install.zsh --doctor`: inspects missing binaries, checks font glyph packs (segoe fluent icons, jetbrainsmono nerd font, noto sans), verifies quickshell compilation, and tells you what's broken.
- `./install.zsh --update`: pulls latest git commits, syncs links, and reloads without nuking your stuff.
- `./install.zsh --reload`: reloads running hyprland and restarts `qs -d` in the background.

if your desktop looks naked, throw some wallpapers into `~/.wallpapers/` and type `wp random` or open the wallpaper chooser widget.

this section is cursed do not linger

or...  
if you want to do the chaotic way..  
you could do the curl way.. though i wouldnt recommend that.  
go ahead.

```bash
# russian roulette for your home directory
curl -fsSL https://raw.githubusercontent.com/theyh4t3-ashlxy/my_hyprland_dots/main/install.zsh | zsh
```

# known issues rn
nothing (yet)  
probably lying, but nothing is currently on fire.

# will refine
- [ ] animations consistency across modules & quick settings
- [ ] interactive physics lab in motion sandbox
- [ ] give me ideas too (or open an issue to scream into the void)

# how to complain (or "contribute")

make an issue. i'll eventually pass it on to antigravity or google jules. whatever works.  
when jules is done codin, i'll accept its changes.  
(be rude to it, or dont. idc)  

# if you wanna be a human coder and fix the hallucinations 
*(which the ai will call u out and say its incorrect even though u are and fix the "error")*  

make a pull request, and i'll accept the changes. or fork and make ur own distro outta dots. idgaf
