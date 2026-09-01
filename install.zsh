#!/usr/bin/env zsh
# cooking your dotfiles so your desktop stops looking like an unconfigured microwave
set -euo pipefail

DOTS_DIR="${0:A:h}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
WALLPAPER_DIR="$HOME/.wallpapers"

# colors for pretty terminal chaos
typeset -A colors
colors=(
    reset "\e[0m"
    primary "\e[38;5;141m"
    success "\e[38;5;120m"
    warn "\e[38;5;221m"
    error "\e[38;5;203m"
    dim "\e[38;5;244m"
    bold "\e[1m"
)

log_info() { print -P "${colors[primary]}󰄛${colors[reset]} $1" }
log_ok()   { print -P "${colors[success]}󰄲${colors[reset]} $1" }
log_warn() { print -P "${colors[warn]}󰀦${colors[reset]} $1" }
log_err()  { print -P "${colors[error]}󰅚${colors[reset]} $1" }

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

    # arch packages
    local arch_pkgs=(
        hyprland
        hypridle
        hyprlock
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
        awww
        matugen-bin
        quickshell-git
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
        pavucontrol
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
            log_info "installing packages via $helper..."
            # install packages without choking if some are already present
            $helper -S --needed --noconfirm "${arch_pkgs[@]}" || log_warn "some packages failed to install, check logs"
            ;;
        pacman)
            log_warn "no aur helper found (paru/yay). installing official repo packages only..."
            sudo pacman -S --needed --noconfirm "${arch_pkgs[@]}" || log_warn "manual aur build needed for matugen / quickshell"
            ;;
        *)
            log_warn "distro not automatically mapped. install hyprland, quickshell, matugen, and swww manually."
            ;;
    esac
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

        # backup existing real directory so we don't nuke user's life work
        if [[ -d "$target" && ! -L "$target" ]]; then
            local backup="${target}.bak.$(date +%s)"
            log_warn "backing up existing $target -> $backup"
            mv "$target" "$backup"
        fi

        ln -sfn "$src" "$target"
        log_ok "linked $folder -> $target"
    done

    # link zsh entrypoint to ~/.zshrc
    if [[ -f "$DOTS_DIR/zsh/sources.zsh" ]]; then
        local zshrc="$HOME/.zshrc"
        if ! grep -qs "sources.zsh" "$zshrc" 2>/dev/null; then
            print "\n# source the master wiring\nsource ~/.config/zsh/sources.zsh" >> "$zshrc"
            log_ok "wired ~/.zshrc -> ~/.config/zsh/sources.zsh"
        fi
    fi
}

setup_directories_and_permissions() {
    log_info "creating wallpaper and cache directories..."
    mkdir -p "$WALLPAPER_DIR"
    mkdir -p "$CACHE_DIR/quickshell/wallpapers"

    # make all helper scripts executable
    log_info "chmodding helper scripts..."
    chmod +x "$DOTS_DIR"/quickshell/scripts/*.sh(N)
    chmod +x "$DOTS_DIR"/quickshell/scripts/*.py(N)
    chmod +x "$DOTS_DIR"/matugen/post-hook-scripts/*.zsh(N)
    chmod +x "$DOTS_DIR"/install.zsh
    log_ok "permissions set"
}

initial_theming() {
    log_info "checking wallpaper & running initial matugen palette..."
    local sample_wp=( "$WALLPAPER_DIR"/*.(png|jpg|jpeg|webp)(N) )

    if (( ${#sample_wp[@]} > 0 )); then
        local first_wp="${sample_wp[1]}"
        log_info "applying theme from $first_wp..."
        if (( $+commands[matugen] )); then
            matugen image "$first_wp" 2>/dev/null || true
            log_ok "matugen initial theme generated"
        fi
    else
        log_warn "no wallpapers found in $WALLPAPER_DIR yet. put some images there to get colors."
    fi
}

show_help() {
    print "usage: ./install.zsh [options]"
    print ""
    print "options:"
    print "  -a, --all        full rice install (deps + links + permissions + theme)"
    print "  -l, --links      symlink configs only"
    print "  -d, --deps       install dependencies only"
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
        -l|--links)
            mode="links"
            shift
            ;;
        -d|--deps)
            mode="deps"
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

print -P "${colors[primary]}󰄛 rice installer: preparing pure visual dopamine${colors[reset]}"

if [[ "$mode" == "interactive" ]]; then
    print ""
    print "what do you want to do?"
    print "  1) full install (dependencies + symlinks + theming)"
    print "  2) symlink dotfiles only"
    print "  3) install packages only"
    print "  4) quit"
    print -n "choice [1-4]: "
    read -r choice
    case "$choice" in
        1) mode="all" ;;
        2) mode="links" ;;
        3) mode="deps" ;;
        *) print "quitting."; exit 0 ;;
    esac
fi

case "$mode" in
    all)
        install_dependencies
        setup_directories_and_permissions
        link_configurations
        initial_theming
        ;;
    links)
        setup_directories_and_permissions
        link_configurations
        initial_theming
        ;;
    deps)
        install_dependencies
        ;;
esac

print ""
log_ok "everything is set up. restart hyprland or run 'qs' to enjoy the rice."
