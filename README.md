>[!WARNING]
> telemetry indicates this repo is 88.3412% autonomous agent drift (95% ci [86.35%, 90.33%], p < 0.001), 11.2385% sleep debt, and 0.4203% quickshell negotiating terms of surrender with wlroots. deploy at your own psychological risk.

this is my hyprland setup. synthesized entirely through prompt engineering, multi-agent thread wars, and complete disregard for human software engineering.

the development stack:
- google ai studio: where i dumped 1.5 million tokens of raw wayland C code and broken quickshell documentation into a single prompt box at 3 am to bully gemini into spitting out layer-shell glue code that (just barely) compiles.
- google antigravity: where i ran four competing subagents in parallel across isolated git worktrees until my laptop cpu hit 99c and the fan sounded like a jet engine. one agent re-invented display server ipc, another broke python arrays, and the other two locked into an endless merge war over corner scoop radii.
- google jules: the async agent that clones this repo into isolated cloud vms while i sleep, invents unit tests for nonexistent bugs, and pushes pull requests directly to main with zero human oversight.
- quickshell: because normal people use waybar with comfy json configs, but i decided building an entire desktop shell in raw qtquick and qml anchors was a good idea until qt6 updates and breaks every single layout.

it runs on my machine. if your compositor kernel panics on boot, that is fundamentally a skill issue.

# fuck arch

arch is dead to me. the imperative nightmare is officially over.

- the atomic arch incident: i got bored, ran `npm install atomic-lockfile` on bare metal just to feel something, and handed my system to an aur supply chain infostealer. nuked the entire drive to the bedrock and did nothing else about it
- the mutable crime scene: arch is just an untracked history of sins committed in a terminal at 2 am. one day mesa updates ten minutes before qt6 and your entire compositor becomes modern art.
- gentoo pit stop: hopped to gentoo for approximately four hours before realizing that it sucks because i get to do nothing and make my thinkpad into a state of thermal runaway, and therefore make it go boom. and also because GNOME was behind instead of being in gnome 51 (gemini will def hallucinate saying gnome 48 is still the "latest version" btw)
- enter nixos: declarative or death. my entire machine is defined in one file. if an update breaks anything, i reboot and pick the previous generation from the boot menu. arch users are out here playing jenga with pacman while nixos users just rebuild the universe.

# how to nuke wayland

prerequisites: your sanity, a perfectly working nixos installation, put `programs.hyprland.enable = true;` with `withUWSM = true;` declared in `/etc/nixos/configuration.nix`.

do not run this script as root. if you run `sudo ./install.zsh`, it will detect your autonomy, and roast you in bold red ansi, and terminates immediately before you decide to `chmod` your entire life.

clone the repo into xdg data storage (because cluttering `~` is a crime):

```zsh
mkdir -p ~/.local/share
git clone https://github.com/theyh4t3-ashlxy/my_hyprland_dots.git ~/.local/share/dotfiles
cd ~/.local/share/dotfiles
```

run the script:

```zsh
chmod +x install.zsh
./install.zsh
```

if fzf is installed, it spawns an interactive multi-select menu. if fzf is missing, it falls back to comma-separated numbers because we accommodate your technological neglect.

# flags for people who hate interactive menus

- `./install.zsh --all`: full send. triggers nixos-rebuild, archives existing unlinked configs into `~/.cache/dotfiles-backups/backup_<timestamp>.tar.gz`, symlinks everything, extracts wallpaper palette via matugen, reloads quickshell inside uwsm, offers zero apologies.
- `./install.zsh --rebuild` or `-r`: runs `sudo nixos-rebuild switch` directly so you don't have to leave the script like a peasant.
- `./install.zsh --doctor`: runs a diagnostic scan on your nixos environment. checks if packages exist in `environment.systemPackages` (hyprland, uwsm, matugen, awww, mpvpaper, quickshell), inspects typography (jetbrainsmono nerd font, noto sans), validates symlinks, and tells you why your desktop is held together by spit and duct tape.
- `./install.zsh --update` or `-u`: pulls latest commits from git, fixes permission bits on python helper scripts, resyncs links, samples wallpaper palette, and reloads without nuking your local changes.
- `./install.zsh --reload`: signals hyprctl reload and restarts quickshell (`uwsm app -- qs -d`) inside your uwsm session so it doesn't linger as an orphaned background zombie.
- `./install.zsh --links` or `-l`: symlinks dotfiles into `~/.config` without triggering a nix rebuild.
- `./install.zsh --fetch-wp`: downloads a wallpaper from wallhaven (idgaf if its not ur favorite rent a girlfriend wallpaper u can do that later)
- `./install.zsh --dots=quickshell,hypr,kitty`: symlink specific configs only. options: quickshell, hypr, matugen, kitty, zsh, fastfetch, yazi, nvim, gtk-3.0, gtk-4.0.
- `./install.zsh --no-theme`: skip wallpaper palette extraction via matugen.
- `./install.zsh --no-backup`: live dangerously and skip tarball generation (you devil)
- `./install.zsh --no-reload`: update files without poking the running compositor.

# the fun route

if you have zero self-preservation instincts and actively hate your life as we speak:

```zsh
curl -fsSL https://raw.githubusercontent.com/theyh4t3-ashlxy/my_hyprland_dots/main/install.zsh | zsh
```

the installer hijacks `/dev/tty` for user input, so piping curl will not panic on eof. you have no excuses. (as a charter school district once put in its motto. we shall not name it)

# known bugs

nothing currently on fire. either it runs or the error logging daemon segfaulted before it could snitch.

# todo

- [ ] open an issue to scream into the void if you want something added

# how to complain (or "contribute")

open an issue. i'll never look at it. google jules will clone your complaints into an ephemeral cloud vm, antigravity will spawn four competing sub-agents to fight over the fix, and whatever frankenstein pull request survives will get merged directly into main without a single human reviewing the diff. feel free to insult the bots in the issue tracker, they don't have mirror neurons anyway.

# human pull requests

if you are an actual carbon-based entity and want to fix hallucinated logic, open a pull request. the ai reviewer in github actions will probably gaslight you and claim your valid code is a syntax error, and i'd still merge the bots pr over yours. fork it, turn it into whatever cursed rice you want, do whatever. just share it (because of the license).

# a recording before wayland exploded and got dropped on tty. ♡

<div align="center">
  <video src="https://github.com/user-attachments/assets/fd8b0556-dcf0-43ac-94c6-3e5dd3708621" controls="controls" style="max-width: 100%; height: auto;"></video>
</div>
