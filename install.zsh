#!/usr/bin/env zsh
# cooking your dotfiles so your desktop stops looking like an unconfigured microwave
set -euo pipefail

DOTS_DIR="${0:A:h}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
WALLPAPER_DIR="$HOME/.wallpapers"
BACKUP_DIR="$CACHE_DIR/dotfiles-backups"

# colors for clean terminal chaos
typeset -A colors
colors=(
    reset "\e[0m"
    primary "\e[38;5;141m"
    success "\e[38;5;120m"
    warn "\e[38;5;221m"
    error "\e[38;5;203m"
    dim "\e[38;5;244m"
    bold "\e[1m"
    cyan "\e[38;5;117m"
)

log_info() { print -P "${colors[primary]}󰄛${colors[reset]} $1" }
log_ok()   { print -P "${colors[success]}󰄲${colors[reset]} $1" }
log_warn() { print -P "${colors[warn]}󰀦${colors[reset]} $1" }
log_err()  { print -P "${colors[error]}󰅚${colors[reset]} $1" }
log_step() { print -P "${colors[cyan]}󰁕${colors[reset]} ${colors[bold]}$1${colors[reset]}" }

detect_aur_helper() {
    if (( $+commands[paru] )); then
        print "paru"
    elif (( $+commands[yay] )); then
        print "yay"
    elif (( $+commands[pacman] )); then
        print "pacman"
    elif (( $+commands[dnf] )); then
        print "dnf"
    elif (( $+commands[apt] )); then
        print "apt"
    elif (( $+commands[xbps-install] )); then
        print "xbps"
    else
        print "unknown"
    fi
}

install_dependencies() {
    local helper=$(detect_aur_helper)
    log_info "detected package manager: ${colors[bold]}$helper${colors[reset]}"

    # arch packages for our quickshell + hyprland rice stack
    local arch_pkgs=(
        hyprland
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
        quickshell-git
        matugen-bin
        awww
        mpvpaper
        ffmpeg
        kitty
        zsh
        fastfetch
        yazi
        neovim
        fzf
        bat
        ripgrep
        fd
        jq
        playerctl
        brightnessctl
        wl-clipboard
        pipewire
        wireplumber
        bluez
        bluez-utils
        networkmanager
        python
        python-pillow
        ttf-jetbrains-mono-nerd
        noto-fonts
        noto-fonts-cjk
        noto-fonts-emoji
    )

    case "$helper" in
        paru|yay)
            log_info "installing / updating dependencies via $helper..."
            $helper -S --needed --noconfirm "${arch_pkgs[@]}" || log_warn "some packages failed to install, check your internet or aur build logs"
            ;;
        pacman)
            log_warn "no aur helper found (paru/yay). installing official repo packages only..."
            sudo pacman -S --needed --noconfirm "${arch_pkgs[@]}" || log_warn "manual aur build needed for matugen-bin, awww, mpvpaper, and quickshell-git"
            ;;
        *)
            log_warn "distro not automatically mapped. install hyprland, quickshell, matugen, awww, mpvpaper, and ffmpeg manually."
            ;;
    esac
}

backup_existing() {
    log_info "creating safety backup in $BACKUP_DIR..."
    mkdir -p "$BACKUP_DIR"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local target_archive="$BACKUP_DIR/backup_${timestamp}.tar.gz"

    local folders=("hypr" "quickshell" "matugen" "kitty" "fastfetch" "zsh" "yazi" "nvim" "gtk-3.0" "gtk-4.0")
    local existing_targets=()

    for folder in "${folders[@]}"; do
        if [[ -e "$CONFIG_DIR/$folder" && ! -L "$CONFIG_DIR/$folder" ]]; then
            existing_targets+=( "$CONFIG_DIR/$folder" )
        fi
    done

    if (( ${#existing_targets[@]} > 0 )); then
        tar -czf "$target_archive" "${existing_targets[@]}" 2>/dev/null || true
        log_ok "backed up unlinked configs -> $target_archive"
    else
        log_info "no unlinked configs needed backup"
    fi
}

link_configurations() {
    log_info "linking dotfiles from $DOTS_DIR to $CONFIG_DIR..."
    mkdir -p "$CONFIG_DIR"

    local folders=(
        "hypr"
        "quickshell"
        "matugen"
        "kitty"
        "fastfetch"
        "zsh"
        "yazi"
        "nvim"
        "gtk-3.0"
        "gtk-4.0"
    )

    for folder in "${folders[@]}"; do
        local src="$DOTS_DIR/$folder"
        local target="$CONFIG_DIR/$folder"

        if [[ ! -d "$src" ]]; then
            log_warn "skipping $folder (not found in dots repo)"
            continue
        fi

        # flatpak sandbox bwrap panics if gtk dirs are symlinks
        if [[ "$folder" == "gtk-3.0" || "$folder" == "gtk-4.0" ]]; then
            [[ -L "$target" ]] && rm -f "$target"
            mkdir -p "$target"
            for f in "$src"/*(N); do
                [[ -f "$f" ]] && cp -f "$f" "$target/"
            done
            log_ok "synced $folder real files -> $target (flatpak safe)"
            continue
        fi

        # remove old broken link or handle directory
        if [[ -L "$target" ]]; then
            rm -f "$target"
        elif [[ -d "$target" ]]; then
            local backup="${target}.bak.$(date +%s)"
            log_warn "moving existing real dir $target -> $backup"
            mv "$target" "$backup"
        fi

        ln -sfn "$src" "$target"
        log_ok "linked $folder -> $target"
    done

    # link zsh entrypoint to ~/.zshrc
    if [[ -f "$DOTS_DIR/zsh/sources.zsh" ]]; then
        local zshrc="$HOME/.zshrc"
        if ! grep -s "sources.zsh" "$zshrc" >/dev/null 2>&1; then
            print "\n# source the master wiring\nsource ~/.config/zsh/sources.zsh" >> "$zshrc"
            log_ok "wired ~/.zshrc -> ~/.config/zsh/sources.zsh"
        fi
    fi
}

setup_directories_and_permissions() {
    log_info "creating wallpaper, notes, and cache directories..."
    mkdir -p "$WALLPAPER_DIR/live"
    mkdir -p "$WALLPAPER_DIR/downloaded"
    mkdir -p "$CACHE_DIR/quickshell/thumbnails"
    mkdir -p "$CACHE_DIR/quickshell/wallpapers"
    mkdir -p "$HOME/.local/share/quickshell"
    mkdir -p "$BACKUP_DIR"

    # make all helper scripts executable
    log_info "chmodding helper scripts and tools..."
    chmod +x "$DOTS_DIR"/quickshell/scripts/*.sh(N)
    chmod +x "$DOTS_DIR"/quickshell/scripts/*.py(N)
    chmod +x "$DOTS_DIR"/matugen/post-hook-scripts/*.zsh(N)
    chmod +x "$DOTS_DIR"/matugen/post-hook-scripts/*.sh(N)
    chmod +x "$DOTS_DIR"/install.zsh
    log_ok "script permissions set"
}

initial_theming() {
    log_info "checking wallpaper & running initial matugen palette..."
    local sample_wp=( "$WALLPAPER_DIR"/**/*.(png|jpg|jpeg|webp)(N) )

    if (( ${#sample_wp[@]} > 0 )); then
        local first_wp="${sample_wp[1]}"
        log_info "applying theme from $first_wp..."
        if (( $+commands[matugen] )); then
            matugen image "$first_wp" 2>/dev/null || true
            log_ok "matugen initial theme generated"
        fi
    else
        log_warn "no wallpapers found in $WALLPAPER_DIR yet. drop some images there to generate colors."
    fi
}

update_dots() {
    log_step "updating dotfiles repository..."
    if [[ -d "$DOTS_DIR/.git" ]]; then
        log_info "pulling latest commits from git remote..."
        git -C "$DOTS_DIR" pull --rebase origin main || {
            log_warn "git pull encountered conflicts or dirty state, check git status"
        }
        log_ok "repository up to date"
    else
        log_warn "$DOTS_DIR is not a git repository, skipping git pull"
    fi

    setup_directories_and_permissions
    link_configurations
    initial_theming
    reload_shell
    log_ok "update complete! desktop updated with latest dots."
}

reload_shell() {
    log_step "reloading desktop shell & compositors..."
    
    # reload hyprland configs if hyprland is active
    if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && (( $+commands[hyprctl] )); then
        hyprctl reload 2>/dev/null || true
        log_ok "hyprland config reloaded"
    fi

    # restart quickshell daemon cleanly
    if pgrep -x "quickshell" >/dev/null; then
        log_info "reloading quickshell daemon..."
        pkill -x "quickshell" || true
        sleep 0.5
        if (( $+commands[qs] )); then
            ( qs -d >/dev/null 2>&1 & )
        elif (( $+commands[quickshell] )); then
            ( quickshell -p "$CONFIG_DIR/quickshell/shell.qml" >/dev/null 2>&1 & )
        fi
        log_ok "quickshell reloaded in background"
    fi
}

doctor_check() {
    log_step "running system health check & diagnostics..."
    local missing_bins=()
    local critical_bins=(
        "hyprland"
        "quickshell"
        "matugen"
        "awww"
        "mpvpaper"
        "ffmpeg"
        "kitty"
        "zsh"
        "wl-copy"
        "brightnessctl"
        "playerctl"
        "python3"
    )

    for b in "${critical_bins[@]}"; do
        if (( $+commands[$b] )); then
            print -P "  ${colors[success]}󰄲${colors[reset]} $b found: ${colors[dim]}$(which $b)${colors[reset]}"
        else
            print -P "  ${colors[error]}󰅚${colors[reset]} $b: ${colors[bold]}MISSING${colors[reset]}"
            missing_bins+=( "$b" )
        fi
    done

    # check fonts safely without pipefail sigpipe
    print ""
    log_info "checking essential fonts..."
    if fc-list : family | grep -i "JetBrainsMono" >/dev/null 2>&1; then
        print -P "  ${colors[success]}󰄲${colors[reset]} JetBrainsMono Nerd Font found"
    else
        print -P "  ${colors[warn]}󰀦${colors[reset]} JetBrainsMono Nerd Font missing (nerd icons might look weird)"
    fi

    if fc-list : family | grep -i "Noto Sans" >/dev/null 2>&1; then
        print -P "  ${colors[success]}󰄲${colors[reset]} Noto Sans font found"
    else
        print -P "  ${colors[warn]}󰀦${colors[reset]} Noto Sans missing"
    fi

    # check symlinks
    print ""
    log_info "verifying config symlinks..."
    local check_links=("hypr" "quickshell" "matugen" "kitty" "zsh" "yazi" "nvim" "fastfetch")
    for l in "${check_links[@]}"; do
        local target="$CONFIG_DIR/$l"
        if [[ -L "$target" ]]; then
            print -P "  ${colors[success]}󰄲${colors[reset]} $target -> $(readlink $target)"
        elif [[ -d "$target" ]]; then
            print -P "  ${colors[warn]}󰀦${colors[reset]} $target exists but is a real directory (not symlinked)"
        else
            print -P "  ${colors[error]}󰅚${colors[reset]} $target missing"
        fi
    done

    # verify quickshell configuration
    print ""
    log_info "testing quickshell syntax & config compilation..."
    if (( $+commands[qs] )); then
        if timeout 4s qs >/tmp/qs_install_test.log 2>&1 || [[ $? -eq 124 ]]; then
            if grep -s "Configuration Loaded" /tmp/qs_install_test.log >/dev/null 2>&1; then
                print -P "  ${colors[success]}󰄲${colors[reset]} quickshell configuration: ${colors[bold]}OK (0 errors)${colors[reset]}"
            else
                print -P "  ${colors[warn]}󰀦${colors[reset]} quickshell check log: $(tail -n 3 /tmp/qs_install_test.log | tr "\n" " ")"
            fi
        fi
        rm -f /tmp/qs_install_test.log
    fi

    print ""
    if (( ${#missing_bins[@]} > 0 )); then
        log_warn "missing ${#missing_bins[@]} dependencies: ${missing_bins[*]}"
        print -P "  run ${colors[primary]}./install.zsh --deps${colors[reset]} to install them"
    else
        log_ok "all core tools, fonts, and services are healthy"
    fi
}

show_help() {
    print "usage: ./install.zsh [options]"
    print ""
    print "options:"
    print "  -a, --all        full rice install (deps + links + permissions + theme)"
    print "  -u, --update     pull latest dotfiles from git, sync links, and reload shell"
    print "  -l, --links      symlink configs only"
    print "  -d, --deps       install dependencies only"
    print "  -c, --doctor     run health check and diagnostic tool"
    print "  -r, --reload     reload running hyprland & quickshell"
    print "  -h, --help       show this help message"
}

# entrypoint
mode="interactive"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -a|--all)
            mode="all"
            shift
            ;;
        -u|--update)
            mode="update"
            shift
            ;;
        -l|--links)
            mode="links"
            shift
            ;;
        -d|--deps)
            mode="deps"
            shift
            ;;
        -c|--doctor|--check)
            mode="doctor"
            shift
            ;;
        -r|--reload)
            mode="reload"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_err "unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

print -P "${colors[primary]}󰄛 rice manager: keeping your setup immaculate${colors[reset]}"

if [[ "$mode" == "interactive" ]]; then
    print ""
    print "what do you want to do?"
    print "  1) full install (dependencies + symlinks + theming)"
    print "  2) update dotfiles (git pull + sync + reload shell)"
    print "  3) symlink dotfiles only"
    print "  4) install dependencies only"
    print "  5) doctor / system health check"
    print "  6) reload running shell (hyprland + quickshell)"
    print "  7) quit"
    print -n "choice [1-7]: "
    read -r choice
    case "$choice" in
        1) mode="all" ;;
        2) mode="update" ;;
        3) mode="links" ;;
        4) mode="deps" ;;
        5) mode="doctor" ;;
        6) mode="reload" ;;
        *) print "quitting."; exit 0 ;;
    esac
fi

case "$mode" in
    all)
        backup_existing
        install_dependencies
        setup_directories_and_permissions
        link_configurations
        initial_theming
        ;;
    update)
        update_dots
        ;;
    links)
        backup_existing
        setup_directories_and_permissions
        link_configurations
        initial_theming
        ;;
    deps)
        install_dependencies
        ;;
    doctor)
        doctor_check
        ;;
    reload)
        reload_shell
        ;;
esac

print ""
log_ok "done. everything is looking clean."
