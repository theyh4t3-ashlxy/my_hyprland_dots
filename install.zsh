#!/usr/bin/env zsh
# cooking your dotfiles so your desktop stops looking like an unconfigured microwave
setopt ERR_EXIT NO_UNSET PIPE_FAIL EXTENDED_GLOB

# prevent accidental root execution
if (( EUID == 0 )); then
    print -P "%F{203}󰅚 do not run this script as root or with sudo! run it as your normal user.%f"
    exit 1
fi

DOTS_DIR="${0:A:h}"
if [[ ! -d "$DOTS_DIR/quickshell" ]]; then
    if [[ -d "$HOME/my-hyprland-dots/quickshell" ]]; then
        DOTS_DIR="$HOME/my-hyprland-dots"
    else
        print -P "%F{141}󰄛%f cloning repository to ~/my-hyprland-dots..."
        if ! (( $+commands[git] )); then
            print -P "%F{203}󰅚 git is not installed. please install git first.%f"
            exit 1
        fi
        git clone https://github.com/theyh4t3-ashlxy/my_hyprland_dots.git "$HOME/my-hyprland-dots"
        DOTS_DIR="$HOME/my-hyprland-dots"
    fi
fi

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
WALLPAPER_DIR="$HOME/.wallpapers"
BACKUP_DIR="$CACHE_DIR/dotfiles-backups"

# visual output helpers using native zsh formatting
log_info() { print -P "%F{141}󰄛%f $1" }
log_ok()   { print -P "%F{120}󰄲%f $1" }
log_warn() { print -P "%F{221}󰀦%f $1" }
log_err()  { print -P "%F{203}󰅚%f $1" }
log_step() { print -P "%F{117}󰁕%f %B$1%b" }

detect_aur_helper() {
    if (( $+commands[paru] )); then
        print "paru"
    elif (( $+commands[yay] )); then
        print "yay"
    elif (( $+commands[pacman] )); then
        print "pacman"
    else
        print "unknown"
    fi
}

install_dependencies() {
    local helper=$(detect_aur_helper)
    log_info "detected package manager: %B$helper%b"

    # official repository packages
    local official_pkgs=(
        hyprland
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
        ffmpeg
        kitty
        zsh
        fastfetch
        yazi
        neovim
        micro
        hyprpicker
        eza
        zoxide
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

    # aur-only packages
    local aur_pkgs=(
        quickshell-git
        matugen-bin
        awww
        mpvpaper
    )

    case "$helper" in
        paru|yay)
            log_info "installing/updating dependencies via $helper..."
            $helper -S --needed --noconfirm "${official_pkgs[@]}" "${aur_pkgs[@]}" || \
                log_warn "some packages failed to install, check aur build logs or network"
            ;;
        pacman)
            log_warn "no aur helper found (paru/yay). installing official repo packages only..."
            sudo pacman -S --needed --noconfirm "${official_pkgs[@]}" || \
                log_warn "some official packages failed to install"
            log_warn "AUR packages not installed: ${aur_pkgs[*]}"
            log_warn "install an AUR helper (paru or yay) or build them manually"
            ;;
        *)
            log_warn "distro not automatically mapped. ensure hyprland, quickshell, matugen, and awww are installed."
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
            existing_targets+=( "$folder" )
        fi
    done

    if (( ${#existing_targets} )); then
        tar -czf "$target_archive" -C "$CONFIG_DIR" "${existing_targets[@]}" 2>/dev/null || true
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
            local gtk_files=( "$src"/*(N.) )
            if (( ${#gtk_files} )); then
                cp -f "${gtk_files[@]}" "$target/"
            fi
            log_ok "synced $folder real files -> $target (flatpak safe)"
            continue
        fi

        # skip if target already points to the right source
        if [[ -L "$target" && "$target:A" == "$src:A" ]]; then
            log_ok "$folder already correctly linked"
            continue
        fi

        # remove old link or back up real directory
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

    # wire zsh entrypoint to ~/.zshrc safely
    if [[ -f "$DOTS_DIR/zsh/sources.zsh" ]]; then
        local zshrc="$HOME/.zshrc"
        local source_line="[[ -f \"$CONFIG_DIR/zsh/sources.zsh\" ]] && source \"$CONFIG_DIR/zsh/sources.zsh\""
        if ! grep -qs "sources\.zsh" "$zshrc" 2>/dev/null; then
            print -P "\n# dotfiles master wiring\n$source_line" >> "$zshrc"
            log_ok "wired ~/.zshrc -> $CONFIG_DIR/zsh/sources.zsh"
        fi
    fi

    # pre-compile zsh configs into .zwc bytecode
    autoload -Uz zrecompile 2>/dev/null || true
    if (( $+functions[zrecompile] )) && [[ -d "$CONFIG_DIR/zsh" ]]; then
        log_info "pre-compiling zsh configs to .zwc bytecode..."
        local zsh_files=( "$CONFIG_DIR"/zsh/**/*.zsh(N.) )
        if (( ${#zsh_files} )); then
            for zf in "${zsh_files[@]}"; do
                zrecompile -pq "$zf" 2>/dev/null || true
            done
            log_ok "pre-compiled ${#zsh_files} zsh script(s) to bytecode"
        fi
    fi
}

setup_directories_and_permissions() {
    log_info "creating wallpaper, notes, and cache directories..."
    mkdir -p "$WALLPAPER_DIR"/{live,downloaded}
    mkdir -p "$CACHE_DIR"/quickshell/{thumbnails,wallpapers}
    mkdir -p "$CACHE_DIR/zsh"
    mkdir -p "$HOME"/.local/share/{quickshell/scratch,quicknav/marks,fonts}
    mkdir -p "$BACKUP_DIR"

    # make helper scripts executable safely without empty-glob crashes
    log_info "chmodding helper scripts and tools..."
    local script_targets=(
        "$DOTS_DIR"/quickshell/scripts/*.(sh|py)(N.)
        "$DOTS_DIR"/matugen/post-hook-scripts/*.(zsh|sh)(N.)
        "$DOTS_DIR"/install.zsh(N.)
    )

    if (( ${#script_targets} )); then
        chmod +x "${script_targets[@]}"
        log_ok "script permissions set (${#script_targets} files)"
    else
        log_warn "no helper scripts found to chmod"
    fi
}

initial_theming() {
    log_info "checking wallpaper & running initial matugen palette..."

    # seed wallpapers from dots repo if user directory is empty
    if [[ -d "$DOTS_DIR/wallpapers" ]]; then
        local repo_wps=( "$DOTS_DIR"/wallpapers/*.(png|jpg|jpeg|webp)(N.) )
        if (( ${#repo_wps} )); then
            cp -n "${repo_wps[@]}" "$WALLPAPER_DIR/" 2>/dev/null || true
        fi
    fi

    local sample_wp=( "$WALLPAPER_DIR"/**/*.(png|jpg|jpeg|webp)(N.) )

    if (( ${#sample_wp} )); then
        local first_wp="${sample_wp[1]}"
        log_info "applying theme from $first_wp..."
        if (( $+commands[matugen] )); then
            matugen image "$first_wp" -m "dark" -t "scheme-tonal-spot" --source-color-index 0 2>/dev/null || true
            log_ok "matugen initial theme generated"
        else
            log_warn "matugen not found in PATH; skipping palette generation"
        fi
    else
        log_warn "no wallpapers found in $WALLPAPER_DIR. drop some images there to generate colors."
    fi
}

update_dots() {
    log_step "updating dotfiles repository..."
    if [[ -d "$DOTS_DIR/.git" ]]; then
        log_info "pulling latest commits from git remote..."
        git -C "$DOTS_DIR" pull --rebase || {
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

    # reload hyprland if active
    if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && (( $+commands[hyprctl] )); then
        hyprctl reload >/dev/null 2>&1 || true
        log_ok "hyprland config reloaded"
    else
        log_info "hyprland instance not running; skipping hyprctl reload"
    fi

    # restart quickshell cleanly
    log_info "reloading quickshell daemon..."
    if (( $+commands[qs] )); then
        qs kill >/dev/null 2>&1 || pkill -x qs 2>/dev/null || true
        sleep 0.4
        qs -d >/dev/null 2>&1 &!
        log_ok "quickshell daemon reloaded via qs -d"
    elif (( $+commands[quickshell] )); then
        pkill -x quickshell 2>/dev/null || true
        sleep 0.4
        quickshell -p "$CONFIG_DIR/quickshell/shell.qml" >/dev/null 2>&1 &!
        log_ok "quickshell reloaded in background"
    else
        log_warn "neither qs nor quickshell found in PATH"
    fi
}

doctor_check() {
    log_step "running system health check & diagnostics..."
    local missing_bins=()
    local critical_bins=(
        "hyprland"
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
        "micro"
        "hyprpicker"
        "eza"
        "zoxide"
        "fzf"
        "bat"
        "rg"
        "fd"
    )

    for b in "${critical_bins[@]}"; do
        if (( $+commands[$b] )); then
            print -P "  %F{120}󰄲%f $b found: %F{244}$commands[$b]%f"
        else
            print -P "  %F{203}󰅚%f $b: %BMISSING%b"
            missing_bins+=( "$b" )
        fi
    done

    # quickshell binary detection
    if (( $+commands[qs] || $+commands[quickshell] )); then
        local qs_bin="${commands[qs]:-$commands[quickshell]}"
        print -P "  %F{120}󰄲%f quickshell found: %F{244}$qs_bin%f"
    else
        print -P "  %F{203}󰅚%f quickshell: %BMISSING%b"
        missing_bins+=( "quickshell" )
    fi

    # font verification
    print ""
    log_info "checking typography & glyph packs..."
    if (( $+commands[fc-list] )); then
        local all_fonts
        all_fonts="$(fc-list : family 2>/dev/null)"

        if [[ "$all_fonts" == *JetBrainsMono* ]]; then
            print -P "  %F{120}󰄲%f JetBrainsMono Nerd Font found"
        else
            print -P "  %F{221}󰀦%f JetBrainsMono Nerd Font missing"
        fi

        if [[ "$all_fonts" == *"Segoe Fluent Icons"* ]] || [[ -f "$HOME/.local/share/fonts/SegoeIcons.ttf" ]]; then
            print -P "  %F{120}󰄲%f Segoe Fluent Icons font found"
        else
            print -P "  %F{221}󰀦%f Segoe Fluent Icons missing"
        fi

        if [[ "$all_fonts" == *"Noto Sans"* ]]; then
            print -P "  %F{120}󰄲%f Noto Sans font found"
        else
            print -P "  %F{221}󰀦%f Noto Sans missing"
        fi
    else
        print -P "  %F{221}󰀦%f fontconfig (fc-list) not installed; font checks skipped"
    fi

    # symlink audit
    print ""
    log_info "verifying config symlinks..."
    local check_links=("hypr" "quickshell" "matugen" "kitty" "zsh" "yazi" "nvim" "fastfetch")
    for l in "${check_links[@]}"; do
        local target="$CONFIG_DIR/$l"
        if [[ -L "$target" ]]; then
            print -P "  %F{120}󰄲%f $target -> %F{244}$(readlink "$target")%f"
        elif [[ -d "$target" ]]; then
            print -P "  %F{221}󰀦%f $target exists but is a real directory (not symlinked)"
        else
            print -P "  %F{203}󰅚%f $target missing"
        fi
    done

    # quickshell daemon status
    print ""
    log_info "checking quickshell status..."
    if pgrep -x quickshell >/dev/null 2>&1 || pgrep -x qs >/dev/null 2>&1; then
        print -P "  %F{120}󰄲%f quickshell daemon is currently %Brunning%b"
    else
        print -P "  %F{221}󰀦%f quickshell daemon is not running (start with: %F{141}qs -d%f)"
    fi

    # zsh bytecode status
    local sample_zwc="$CONFIG_DIR/zsh/sources.zsh.zwc"
    if [[ -f "$sample_zwc" ]]; then
        print -P "  %F{120}󰄲%f zsh bytecode: pre-compiled .zwc active"
    else
        print -P "  %F{221}󰀦%f zsh bytecode: not compiled"
    fi

    print ""
    if (( ${#missing_bins} > 0 )); then
        log_warn "missing ${#missing_bins} dependencies: ${missing_bins[*]}"
        print -P "  run %F{141}./install.zsh --deps%f to install them"
    else
        log_ok "all core tools, fonts, and configurations are healthy"
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
        -a|--all)             mode="all"; shift ;;
        -u|--update)          mode="update"; shift ;;
        -l|--links)           mode="links"; shift ;;
        -d|--deps)            mode="deps"; shift ;;
        -c|--doctor|--check)  mode="doctor"; shift ;;
        -r|--reload)          mode="reload"; shift ;;
        -h|--help)            show_help; exit 0 ;;
        *)
            log_err "unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

print -P "%F{141}󰄛 rice manager: keeping your setup immaculate%f"

if [[ "$mode" == "interactive" ]]; then
    print ""
    print "what do you want to do?"
    print "  1) 󰏤 full install (dependencies + symlinks + theming)"
    print "  2) 󰑐 update dotfiles (git pull + sync + reload shell)"
    print "  3) 󰌢 symlink dotfiles only"
    print "  4) 󰚰 install dependencies only"
    print "  5) 󰄲 doctor / system health check"
    print "  6) 󰁕 reload running shell (hyprland + quickshell)"
    print "  7) 󰅚 quit"
    print -Pn "choice [1-7]: "

    choice=""
    if [[ -t 0 ]]; then
        read -k 1 choice
        print ""
    elif [[ -r /dev/tty ]]; then
        read -k 1 choice </dev/tty
        print ""
    else
        print "\nquitting (no interactive tty attached)."
        exit 0
    fi

    case "$choice" in
        1) mode="all" ;;
        2) mode="update" ;;
        3) mode="links" ;;
        4) mode="deps" ;;
        5) mode="doctor" ;;
        6) mode="reload" ;;
        7|q|Q) print "quitting."; exit 0 ;;
        *) log_warn "invalid choice: $choice"; exit 1 ;;
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
