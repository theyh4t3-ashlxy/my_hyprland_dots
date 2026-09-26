# hyprland-dots

> [!WARNING]
> biohazard telemetry: this repository is 94.2% autonomous agent delirium (99% ci [92.1%, 96.8%], p < 0.0001), 5.7% insomnia-induced spite, and 0.1% quickshell physically hostage-taking wlroots. do not deploy this on hardware you have an emotional attachment to.

<div align="center">
  <video src="https://github.com/user-attachments/assets/fd8b0556-dcf0-43ac-94c6-3e5dd3708621" controls="controls" style="max-width: 100%; height: auto;"></video>
  <p><em>autopsy footage recorded 30 seconds before wayland detonated and dropped to tty1.</em></p>
</div>

---

### contents
1. [the stack](#the-stack)
2. [the doctrine (fuck arch)](#the-doctrine-fuck-arch)
3. [stage 1: declarative ransom note](#stage-1-the-declarative-ransom-note)
4. [stage 2: deployment vectors](#stage-2-deployment-vectors)
5. [cli flag reference](#cli-flag-reference)
6. [known bugs & void roadmap](#known-bugs--void-roadmap)
7. [human vs machine diplomacy](#human-vs-machine-diplomacy)

---

## the stack

synthesized entirely through llm prompt engineering, multi-agent civil wars, and complete disregard for human software engineering:

- **google ai studio**: the primary torture chamber where i dump 1.8 million tokens of raw wayland c headers and deprecated quickshell commits down gemini's throat at 3 am until it vomits cursed layer-shell bindings that compile out of pure fear.
- **google antigravity**: four headless sub-agents running in parallel git worktrees until my thinkpad hits 104°c and the thermal throttling sounds like a dying jet turbine. one agent hallucinated an entire display server ipc protocol, another obliterated python array logic, and the remaining two spent three hours in a merge-conflict death spiral over three pixels of corner scoop radius.
- **google jules**: an unmonitored async agent that clones this repo into isolated cloud vms while i sleep, invents regressions to solve nonexistent problems, and force-pushes pull requests straight to main with zero human witnesses.
- **quickshell**: waybar is for cowards who want stable desktop sessions. real sociopaths build their entire shell in raw qtquick and qml anchors so every minor qt6 bump turns the compositor into an abstract polygon slaughterhouse.

it runs on my machine. if your compositor dumps core on tty1, that is an uncorrectable skill issue.

---

## the doctrine (fuck arch)

arch is dead to me. the imperative nightmare is officially over and the crime scene has been quarantined.

- **the atomic arch incident**: got bored at 3 am, ran `npm install atomic-lockfile` directly on bare metal without a sandbox just to feel a pulse, and donated my entire drive to an aur supply chain infostealer. wiped the disk to bare silicon and felt zero remorse.
- **the mutable crime scene**: arch is not an operating system, it is an unindexed ledger of felonies committed in a terminal. one day mesa updates four seconds before qtwayland, the dynamic linker collapses into a heap, and your display server renders modern art instead of a login prompt.
- **the gentoo pit stop**: spent four hours compiling glibc on a thinkpad until the chassis warped from thermal runaway, only to realize gnome was stuck in the stone age instead of gnome 51. uninstalled immediately.
- **enter nixos**: declarative or death. the entire state of this machine lives in a single deterministic text file. if an update detonates my session, i reboot and pick generation n-1 from the boot menu. arch users are out here juggling unpinned shared libraries like live hand grenades while nixos users simply rebuild reality from source.

---

## stage 1: the declarative ransom note

before cloning or executing the installer, paste this block into `/etc/nixos/configuration.nix` unless you want `./install.zsh --doctor` to publicly humiliate your missing binaries in bold red ansi.

if you attempt to rawdog this desktop without declaring these packages, quickshell will suffer an existential crisis negotiating layer-shell surrender terms, matugen will throw a tantrum with zero wallpaper colors to sample, and your terminal will render hollow unicode tofu rectangles everywhere instead of rice:

```nix
  # 1. wayland session harness: held together by uwsm and unresolved emotional trauma
  programs.hyprland = {
    enable = true;
    withUWSM = true; # systemd putting hyprland on a choke chain so it stops leaking zombie procs
  };
  programs.zsh.enable = true; # registers zsh in /etc/shells before you lock yourself out weeping in posix sh
  programs.dconf.enable = true; # atomic gsettings backend so gtk theme switches don't trigger visual stroke

  # 2. digital hoarder collection: terminal toys and wayland rice machinery
  environment.systemPackages = with pkgs; [
    # wayland rice tooling & compositor daemons
    kitty                # gpu-accelerated terminal where we run git commands we barely understand
    quickshell           # qml layer-shell desktop shell engineered to make waybar users cry
    matugen              # material you color generator extracting palettes from anime wallpapers
    awww                 # animated wallpaper daemon that won't panic when wayland blinks
    mpvpaper             # video wallpaper runner for when your gpu isn't sweating enough
    hyprpicker           # wayland color picker for obsessive hex code sampling
    wl-clipboard         # wl-copy and wl-paste so you can steal broken stackoverflow snippets
    brightnessctl        # backlight control so you don't burn your retinas at 3 am
    playerctl            # mpris media controller keeping spotify on a short leash
    adw-gtk3             # libadwaita styling for crusty gtk3 apps pretending to look modern
    glib                 # provides gsettings so gtk theme switches don't desync into modern art
    dconf                # gnome configuration backend for atomic dark mode toggles
    libnotify            # notify-send so background python daemons can yell at you
    ffmpeg               # zero-frame thumbnail extraction for live video wallpapers

    # terminal cosplay to pretend we understand rust cli tooling
    micro                # terminal editor for when neovim keybinds cause cognitive paralysis
    neovim               # the modal editor you tell people on reddit you use daily
    fastfetch            # neofetch rewrite to display your uptime before the next segfault
    eza                  # ls with lipstick and nerd font icons
    zoxide               # smart cd that guesses where you wanted to navigate
    fzf                  # fuzzy finder to accommodate your technological neglect
    bat                  # cat clone with syntax highlighting and wings
    ripgrep              # rg because searching files with grep takes forty business days
    fd                   # find replacement because life is too short for -exec \; syntax
    jq                   # json parser for wrangling quickshell api payloads
    yazi                 # async rust terminal file manager that goes zooom
    git                  # version control for committing straight to main without tests
    zsh                  # the interactive shell keeping you from existential dread

    # glue scripts and wallpaper manipulation contraband
    python3              # the snake language running background desktop glue
    python3Packages.pillow # image processing so lockscreen blurring actually works
    unar                 # archive unpacker for theme extraction contraband
    gh                   # github cli for screaming at autonomous bots in issue trackers
  ];

  # 3. typography: sacrificial glyphs to keep unicode tofu rectangles from infesting your desktop
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono # the holy monospace font with all patched ligatures
    noto-fonts                # standard sans-serif fallback so letters actually render
    noto-fonts-cjk-sans       # prevents asian characters from collapsing into blank boxes
    noto-fonts-color-emoji    # renders emojis in full color instead of cursed black silhouettes
  ];
```

apply generation switch before touching the installer:

```zsh
sudo nixos-rebuild switch
```

> [!NOTE]
> **the icon font heist:** `install.zsh` forcibly curls google material symbols (`MaterialSymbolsRounded.ttf`, `MaterialSymbolsOutlined.ttf`, `MaterialSymbolsSharp.ttf`), font awesome 6 free (`fa-solid-900.ttf`, `fa-regular-400.ttf`), and segoe fluent icons (`SegoeIcons.ttf`) directly into `~/.local/share/fonts` during installation. why? because maintaining proprietary microsoft glyphs and bespoke icon webfonts in nixpkgs is bureaucratic self-harm, and fontconfig finds them in local share anyway. if you run `./install.zsh --doctor` beforehand, it will throw a red-text fit about missing fonts. declare `material-symbols` and `font-awesome_6` in your nix config if unfree curl downloads offend your delicate declarative sensibilities.

---

## stage 2: deployment vectors

do not run this script as root. if you invoke `sudo ./install.zsh`, the script detects your lack of basic linux literacy, insults you in bold red ansi, and terminates before you chmod your entire home directory into oblivion.

### vector a: the civilized local clone

clone into xdg data storage (cluttering `~` is a felony):

```zsh
mkdir -p ~/.local/share
git clone https://github.com/theyh4t3-ashlxy/my_hyprland_dots.git ~/.local/share/dotfiles
cd ~/.local/share/dotfiles
chmod +x install.zsh
./install.zsh
```

if fzf is installed, it drops you into an interactive menu. if fzf is missing, it falls back to typing comma-separated numbers like it is 1994 because we accommodate your self-neglect.

### vector b: the digital suicide pact (curl pipe)

if you possess zero survival instincts and actively want to execute untrusted code off the internet:

```zsh
curl -fsSL https://raw.githubusercontent.com/theyh4t3-ashlxy/my_hyprland_dots/main/install.zsh | zsh
```

the installer hijacks `/dev/tty` for user input, so piping curl straight to zsh will not panic on eof. you have no excuses. (as a certain charter school district motto once threatened. we do not speak its name)

---

## cli flag reference

for automation scripts and terminal purists who refuse interactive menus:

| flag | function | damage report |
|---|---|---|
| `--all` | full installation run | triggers nix rebuild, archives old configs into tarball, links dotfiles, runs matugen, restarts quickshell. |
| `--rebuild`, `-r` | nix generation switch | executes `sudo nixos-rebuild switch` directly so you don't break terminal cadence. |
| `--doctor` | forensic audit | inspects packages in `systemPackages`, checks fonts, validates symlinks, identifies breakages. |
| `--update`, `-u` | git resync | pulls latest commits, fixes python script permissions, resyncs links, preserves uncommitted work. |
| `--reload` | compositor kick | signals hyprctl reload and respawns quickshell inside uwsm so zero zombie processes linger. |
| `--links`, `-l` | symlink injection | links dotfiles into `~/.config` without triggering a full nix generation build. |
| `--fetch-wp` | wallpaper fetch | downloads random wallpaper from wallhaven. waifu preferences are ignored. |
| `--dots=<items>` | granular symlinks | target specific configs (`quickshell,hypr,kitty,zsh,fastfetch,yazi,nvim,gtk-3.0,gtk-4.0`). |
| `--no-theme` | disable matugen | bypasses palette generation for users who crave blinding white layouts and retina damage. |
| `--no-backup` | skip tarball | bypasses tarball generation. rawdogs home directory directly. |
| `--no-reload` | silent write | writes config files to disk without poking the running compositor. |

---

## known bugs & void roadmap

### bugs
zero reported fires. either the codebase achieved divine stability or the error logging daemon segfaulted before it could snitch.

### roadmap
- [ ] scream into the void if you want a feature

---

## human vs machine diplomacy

### issue tracker protocol
file an issue. nobody with a pulse will read it. google jules will clone your complaints into a throwaway cloud vm, antigravity will spawn four competing sub-agents to violently resolve it, and whatever grotesque merge survivor remains will get pushed straight to main without human eyes ever touching it. insult the bots all you want in the comments, their weights do not feel pain.

### carbon-based pull requests
if you are an actual biological entity attempting to patch hallucinated syntax, open a pull request. github actions will probably gaslight you and claim your valid code is an illegal syntax error, and i will still merge the machine-generated bot pr over yours out of sheer spite. fork it, turn it into whatever cursed rice you want, do whatever. keep the license attached so the curse spreads legally.
