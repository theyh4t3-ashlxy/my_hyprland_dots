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

# visual output helpers
log_info() { print -P "%F{141}󰄛%f $1" }
log_ok()   { print -P "%F{120}󰄲%f $1" }
log_warn() { print -P "%F{221}󰀦%f $1" }
log_err()  { print -P "%F{203}󰅚%f $1" }
log_step() { print -P "\n%F{117}󰁕%f %B$1%b" }

# prompt helper for boolean questions
ask_yn() {
    local prompt="$1"
    local default_ans="${2:-Y}" # Y or N
    local ans=""

    if [[ "$default_ans" == "Y" ]]; then
        print -Pn "%F{141}󰄛%f $prompt %F{244}[Y/n]:%f "
    else
        print -Pn "%F{141}󰄛%f $prompt %F{244}[y/N]:%f "
    fi

    if [[ -t 0 ]]; then
        read -r ans
    elif [[ -r /dev/tty ]]; then
        read -r ans </dev/tty
    else
        ans="$default_ans"
    fi

    ans="${ans:-$default_ans}"
    [[ "$ans" == [yY]* ]]
}

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

# --- Granular Package Definitions ---
typeset -A PKG_GROUPS_OFFICIAL
typeset -A PKG_GROUPS_AUR

PKG_GROUPS_OFFICIAL[desktop]="hyprland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk wl-clipboard"
PKG_GROUPS_AUR[desktop]="quickshell-git matugen-bin awww"

PKG_GROUPS_OFFICIAL[terminal]="kitty zsh fastfetch"
PKG_GROUPS_AUR[terminal]=""

PKG_GROUPS_OFFICIAL[tools]="eza zoxide fzf bat ripgrep fd jq yazi"
PKG_GROUPS_AUR[tools]=""

PKG_GROUPS_OFFICIAL[editors]="neovim micro"
PKG_GROUPS_AUR[editors]=""

PKG_GROUPS_OFFICIAL[media]="pipewire wireplumber playerctl brightnessctl ffmpeg"
PKG_GROUPS_AUR[media]="mpvpaper"

PKG_GROUPS_OFFICIAL[fonts]="ttf-jetbrains-mono-nerd noto-fonts noto-fonts-cjk noto-fonts-emoji"
PKG_GROUPS_AUR[fonts]=""

PKG_GROUPS_OFFICIAL[system]="bluez bluez-utils networkmanager python python-pillow hyprpicker"
PKG_GROUPS_AUR[system]=""

ALL_PKG_CATEGORIES=(desktop terminal tools editors media fonts system)

# --- Granular Dotfiles Definitions ---
ALL_DOTFILES=(
    "quickshell"
    "hypr"
    "matugen"
    "kitty"
    "zsh"
    "fastfetch"
    "yazi"
    "nvim"
    "gtk-3.0"
    "gtk-4.0"
)

# Helper to multi-select via fzf or manual prompt
select_multi() {
    local header="$1"
    shift
    local -a items=( "$@" )
    local -a chosen=()

    if (( $+commands[fzf] )) && [[ -t 0 || -r /dev/tty ]]; then
        local tty_in=""
        [[ -t 0 ]] || tty_in="</dev/tty"
        local raw
        raw=$(printf "%s\n" "${items[@]}" | eval "fzf -m --header='[${header} | tab to toggle, enter to confirm]' --reverse --height=40% ${tty_in}")
        if [[ -n "$raw" ]]; then
            chosen=( ${(f)raw} )
        fi
    else
        print -P "%F{141}󰄛%f %B${header}%b:"
        local i=1
        for it in "${items[@]}"; do
            print "  $i) $it"
            (( i++ ))
        done
        print -Pn "%F{244}enter comma-separated numbers or 'all' [default: all]:%f "
        local inp=""
        if [[ -t 0 ]]; then read -r inp; elif [[ -r /dev/tty ]]; then read -r inp </dev/tty; fi
        inp="${inp:-all}"
        if [[ "$inp" == "all" ]]; then
            chosen=( "${items[@]}" )
        else
            local -a indices=( ${(s:,:)inp} )
            for idx in "${indices[@]}"; do
                idx="${idx//[[:space:]]/}"
                if [[ "$idx" =~ ^[0-9]+$ ]] && (( idx >= 1 && idx <= ${#items} )); then
                    chosen+=( "${items[$idx]}" )
                fi
            done
        fi
    fi

    print "${chosen[@]}"
}

install_selected_dependencies() {
    local -a cats=( "$@" )
    if (( ${#cats} == 0 )); then
        log_info "no package categories selected to install"
        return 0
    fi

    local helper=$(detect_aur_helper)
    log_info "detected package manager: %B$helper%b"

    local -a to_install_official=()
    local -a to_install_aur=()

    for c in "${cats[@]}"; do
        if [[ -n "${PKG_GROUPS_OFFICIAL[$c]:-}" ]]; then
            to_install_official+=( ${(s: :)PKG_GROUPS_OFFICIAL[$c]} )
        fi
        if [[ -n "${PKG_GROUPS_AUR[$c]:-}" ]]; then
            to_install_aur+=( ${(s: :)PKG_GROUPS_AUR[$c]} )
        fi
    done

    # deduplicate
    to_install_official=( ${(u)to_install_official} )
    to_install_aur=( ${(u)to_install_aur} )

    log_step "installing packages for: ${cats[*]}"

    case "$helper" in
        paru|yay)
            local -a all_target_pkgs=( "${to_install_official[@]}" "${to_install_aur[@]}" )
            if (( ${#all_target_pkgs} )); then
                log_info "running $helper -S --needed for ${#all_target_pkgs} packages..."
                $helper -S --needed --noconfirm "${all_target_pkgs[@]}" || \
                    log_warn "some packages failed to install, check aur build logs or network"
            fi
            ;;
        pacman)
            if (( ${#to_install_official} )); then
                log_info "running sudo pacman -S --needed for ${#to_install_official} official packages..."
                sudo pacman -S --needed --noconfirm "${to_install_official[@]}" || \
                    log_warn "some official packages failed to install"
            fi
            if (( ${#to_install_aur} )); then
                log_warn "no aur helper found (paru/yay). skipping AUR packages: ${to_install_aur[*]}"
                log_warn "install an AUR helper to install quickshell-git, matugen-bin, awww"
            fi
            ;;
        *)
            log_warn "unrecognized package manager. please install manually: ${to_install_official[*]} ${to_install_aur[*]}"
            ;;
    esac
}

backup_selected() {
    local -a targets=( "$@" )
    if (( ${#targets} == 0 )); then
        targets=( "${ALL_DOTFILES[@]}" )
    fi

    log_info "checking for existing configs to backup in $CONFIG_DIR..."
    mkdir -p "$BACKUP_DIR"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local target_archive="$BACKUP_DIR/backup_${timestamp}.tar.gz"

    local existing_targets=()
    for t in "${targets[@]}"; do
        if [[ -e "$CONFIG_DIR/$t" && ! -L "$CONFIG_DIR/$t" ]]; then
            existing_targets+=( "$t" )
        fi
    done

    if (( ${#existing_targets} )); then
        tar -czf "$target_archive" -C "$CONFIG_DIR" "${existing_targets[@]}" 2>/dev/null || true
        log_ok "backed up ${#existing_targets} unlinked config(s) -> $target_archive"
        for et in "${existing_targets[@]}"; do
            print -P "    %F{244}󰄲 archived:%f $CONFIG_DIR/$et"
        done
    else
        log_info "no unlinked physical directories required archiving"
    fi
}

link_selected_configurations() {
    local -a targets=( "$@" )
    if (( ${#targets} == 0 )); then
        log_info "no dotfile configurations selected to link"
        return 0
    fi

    log_step "linking selected dotfiles (${#targets} modules)..."
    mkdir -p "$CONFIG_DIR"

    for folder in "${targets[@]}"; do
        local src="$DOTS_DIR/$folder"
        local target="$CONFIG_DIR/$folder"

        if [[ ! -d "$src" ]]; then
            log_warn "skipping $folder (source directory not found in dots repo)"
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

        # skip if already linked properly
        if [[ -L "$target" && "$target:A" == "$src:A" ]]; then
            log_ok "$folder already correctly linked"
            continue
        fi

        # handle collisions safely
        if [[ -L "$target" ]]; then
            rm -f "$target"
        elif [[ -d "$target" ]]; then
            local backup="${target}.bak.$(date +%s)"
            log_warn "moving existing real directory $target -> $backup"
            mv "$target" "$backup"
        fi

        ln -sfn "$src" "$target"
        log_ok "linked $folder -> $target"
    done

    # wire zsh if zsh was selected
    if [[ " ${targets[*]} " == *" zsh "* && -f "$DOTS_DIR/zsh/sources.zsh" ]]; then
        local zshrc="$HOME/.zshrc"
        local source_line="[[ -f \"$CONFIG_DIR/zsh/sources.zsh\" ]] && source \"$CONFIG_DIR/zsh/sources.zsh\""
        if ! grep -qs "sources\.zsh" "$zshrc" 2>/dev/null; then
            print -P "\n# dotfiles master wiring\n$source_line" >> "$zshrc"
            log_ok "wired ~/.zshrc -> $CONFIG_DIR/zsh/sources.zsh"
        fi
    fi
}

setup_directories_and_permissions() {
    log_info "creating runtime, cache, and wallpaper directories..."
    mkdir -p "$WALLPAPER_DIR"/{live,downloaded}
    mkdir -p "$CACHE_DIR"/quickshell/{thumbnails,wallpapers}
    mkdir -p "$CACHE_DIR/zsh"
    mkdir -p "$HOME"/.local/share/{quickshell/scratch,quicknav/marks,fonts}
    mkdir -p "$BACKUP_DIR"

    log_info "setting execute permissions on helper scripts..."
    local script_targets=(
        "$DOTS_DIR"/quickshell/scripts/*.(sh|py)(N.)
        "$DOTS_DIR"/matugen/post-hook-scripts/*.(zsh|sh)(N.)
        "$DOTS_DIR"/install.zsh(N.)
    )

    if (( ${#script_targets} )); then
        chmod +x "${script_targets[@]}"
        log_ok "made ${#script_targets} helper script(s) executable"
    fi
}

initial_theming() {
    log_step "wallpaper seeding & dynamic matugen palette..."

    if [[ -d "$DOTS_DIR/wallpapers" ]]; then
        local repo_wps=( "$DOTS_DIR"/wallpapers/*.(png|jpg|jpeg|webp)(N.) )
        if (( ${#repo_wps} )); then
            cp -n "${repo_wps[@]}" "$WALLPAPER_DIR/" 2>/dev/null || true
        fi
    fi

    local sample_wp=( "$WALLPAPER_DIR"/**/*.(png|jpg|jpeg|webp)(N.) )

    if (( ${#sample_wp} )); then
        local first_wp="${sample_wp[1]}"
        log_info "applying matugen palette from: $first_wp..."
        if (( $+commands[matugen] )); then
            matugen image "$first_wp" -m "dark" -t "scheme-tonal-spot" --source-color-index 0 2>/dev/null || true
            log_ok "matugen initial theme generated successfully"
        else
            log_warn "matugen not found in PATH; skipping palette generation"
        fi
    else
        log_warn "no wallpapers found in $WALLPAPER_DIR to sample"
    fi
}

reload_shell() {
    log_step "reloading shell and compositors..."

    if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && (( $+commands[hyprctl] )); then
        hyprctl reload >/dev/null 2>&1 || true
        log_ok "hyprland reloaded"
    else
        log_info "hyprland not active, skipping hyprctl reload"
    fi

    if (( $+commands[qs] )); then
        qs kill >/dev/null 2>&1 || pkill -x qs 2>/dev/null || true
        sleep 0.3
        qs -d >/dev/null 2>&1 &!
        log_ok "quickshell daemon reloaded (qs -d)"
    elif (( $+commands[quickshell] )); then
        pkill -x quickshell 2>/dev/null || true
        sleep 0.3
        quickshell -p "$CONFIG_DIR/quickshell/shell.qml" >/dev/null 2>&1 &!
        log_ok "quickshell background process restarted"
    fi
}

doctor_check() {
    log_step "system health check & diagnostics..."
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

    if (( $+commands[qs] || $+commands[quickshell] )); then
        local qs_bin="${commands[qs]:-$commands[quickshell]}"
        print -P "  %F{120}󰄲%f quickshell found: %F{244}$qs_bin%f"
    else
        print -P "  %F{203}󰅚%f quickshell: %BMISSING%b"
        missing_bins+=( "quickshell" )
    fi

    print ""
    log_info "checking typography & glyph packs..."
    if (( $+commands[fc-list] )); then
        local all_fonts
        all_fonts="$(fc-list : family 2>/dev/null)"

        [[ "$all_fonts" == *JetBrainsMono* ]] \
            && print -P "  %F{120}󰄲%f JetBrainsMono Nerd Font found" \
            || print -P "  %F{221}󰀦%f JetBrainsMono Nerd Font missing"

        ([[ "$all_fonts" == *"Segoe Fluent Icons"* ]] || [[ -f "$HOME/.local/share/fonts/SegoeIcons.ttf" ]]) \
            && print -P "  %F{120}󰄲%f Segoe Fluent Icons found" \
            || print -P "  %F{221}󰀦%f Segoe Fluent Icons missing"

        [[ "$all_fonts" == *"Noto Sans"* ]] \
            && print -P "  %F{120}󰄲%f Noto Sans found" \
            || print -P "  %F{221}󰀦%f Noto Sans missing"
    fi

    print ""
    log_info "verifying config symlinks..."
    for l in "${ALL_DOTFILES[@]}"; do
        local target="$CONFIG_DIR/$l"
        if [[ -L "$target" ]]; then
            print -P "  %F{120}󰄲%f $target -> %F{244}$(readlink "$target")%f"
        elif [[ -d "$target" ]]; then
            print -P "  %F{221}󰀦%f $target exists as physical directory"
        else
            print -P "  %F{244}󰅚%f $target not linked"
        fi
    done

    print ""
    if (( ${#missing_bins} > 0 )); then
        log_warn "missing ${#missing_bins} dependencies: ${missing_bins[*]}"
        print -P "  run %F{141}./install.zsh --deps%f or select them in the custom installer"
    else
        log_ok "all core tools, fonts, and configurations are healthy"
    fi
}

show_help() {
    print "usage: ./install.zsh [options]"
    print ""
    print "modes:"
    print "  -i, --interactive, -c, --custom  granular step-by-step installation wizard (default)"
    print "  -a, --all                        full automatic install (all packages + backup + all links + theme)"
    print "  -u, --update                     git pull remote dots, re-link, and reload shell"
    print "  -l, --links                      symlink dotfiles only"
    print "  -d, --deps                       install package dependencies only"
    print "      --doctor                     run diagnostics and health checks"
    print "      --reload                     reload running hyprland & quickshell"
    print "  -h, --help                       show this help message"
    print ""
    print "granular flags:"
    print "  --backup                         force safety backup of unlinked ~/.config directories"
    print "  --no-backup                      skip backup entirely"
    print "  --pkgs=<cat1,cat2,...>           install specific package groups (desktop,terminal,tools,editors,media,fonts,system)"
    print "  --dots=<dir1,dir2,...>           link specific dotfiles (quickshell,hypr,matugen,kitty,zsh,yazi,nvim,fastfetch,gtk-3.0,gtk-4.0)"
    print "  --no-theme                       skip initial matugen wallpaper sampling"
    print "  --no-reload                      do not restart quickshell / hyprland after linking"
}

# --- CLI Argument Parsing ---
opt_mode="menu"
opt_backup=""
opt_theme=true
opt_reload=true
opt_pkg_cats=()
opt_dots=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -a|--all)               opt_mode="all"; shift ;;
        -u|--update)            opt_mode="update"; shift ;;
        -l|--links)             opt_mode="links"; shift ;;
        -d|--deps)              opt_mode="deps"; shift ;;
        -i|--interactive|-c|--custom) opt_mode="custom"; shift ;;
        --doctor|--check)       opt_mode="doctor"; shift ;;
        --reload)               opt_mode="reload"; shift ;;
        --backup)               opt_backup=true; shift ;;
        --no-backup)            opt_backup=false; shift ;;
        --no-theme)             opt_theme=false; shift ;;
        --no-reload)            opt_reload=false; shift ;;
        --pkgs=*)
            local val="${1#*=}"
            opt_pkg_cats=( ${(s:,:)val} )
            shift
            ;;
        --dots=*)
            local val="${1#*=}"
            opt_dots=( ${(s:,:)val} )
            shift
            ;;
        -h|--help)              show_help; exit 0 ;;
        *)
            log_err "unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

print -P "%F{141}󰄛 rice installer & dotfiles manager%f"

# --- Interactive Main Menu ---
if [[ "$opt_mode" == "menu" ]]; then
    print ""
    print "how do you want to proceed?"
    print "  1) 󰚰 custom / granular install (pick packages, backup choice, select dotfiles)"
    print "  2) 󰏤 full install (all packages + backup + all links + theme)"
    print "  3) 󰌢 symlink dotfiles only (choose which dotfiles to link)"
    print "  4) 󰏖 install dependencies only (choose package groups)"
    print "  5) 󰑐 update dotfiles (git pull + sync links + reload shell)"
    print "  6) 󰄲 doctor / diagnostics check"
    print "  7) 󰁕 reload running shell (hyprland + quickshell)"
    print "  8) 󰅚 exit"
    print -Pn "choice [1-8, default 1]: "

    local choice=""
    if [[ -t 0 ]]; then
        read -r choice
    elif [[ -r /dev/tty ]]; then
        read -r choice </dev/tty
    else
        choice="1"
    fi
    choice="${choice:-1}"

    case "$choice" in
        1) opt_mode="custom" ;;
        2) opt_mode="all" ;;
        3) opt_mode="links" ;;
        4) opt_mode="deps" ;;
        5) opt_mode="update" ;;
        6) opt_mode="doctor" ;;
        7) opt_mode="reload" ;;
        8|q|Q) print "exiting."; exit 0 ;;
        *) log_warn "invalid choice: $choice, defaulting to custom wizard"; opt_mode="custom" ;;
    esac
fi

# --- Execution Pathways ---

if [[ "$opt_mode" == "doctor" ]]; then
    doctor_check
    exit 0
elif [[ "$opt_mode" == "reload" ]]; then
    reload_shell
    exit 0
elif [[ "$opt_mode" == "update" ]]; then
    log_step "updating dotfiles repository..."
    if [[ -d "$DOTS_DIR/.git" ]]; then
        git -C "$DOTS_DIR" pull --rebase || log_warn "git pull encountered conflicts"
        log_ok "repository up to date"
    fi
    setup_directories_and_permissions
    link_selected_configurations "${ALL_DOTFILES[@]}"
    initial_theming
    reload_shell
    log_ok "update complete!"
    exit 0
fi

# --- Granular Custom Installation Wizard ---
if [[ "$opt_mode" == "custom" ]]; then
    log_step "granular dotfiles configuration wizard"

    # 1. Backup Decision
    if [[ -z "$opt_backup" ]]; then
        if ask_yn "create a safety backup of existing unlinked ~/.config folders?" "Y"; then
            opt_backup=true
        else
            opt_backup=false
        fi
    fi

    # 2. Package Installation Decision
    local do_pkgs=false
    if (( ${#opt_pkg_cats} > 0 )); then
        do_pkgs=true
    elif ask_yn "install or update package dependencies via pacman/aur?" "Y"; then
        do_pkgs=true
        print ""
        local chosen_raw
        chosen_raw=$(select_multi "select package groups to install" "${ALL_PKG_CATEGORIES[@]}")
        opt_pkg_cats=( ${(s: :)chosen_raw} )
    fi

    # 3. Dotfiles Linking Decision
    local do_links=false
    if (( ${#opt_dots} > 0 )); then
        do_links=true
    elif ask_yn "symlink dotfile configurations into ~/.config?" "Y"; then
        do_links=true
        print ""
        local chosen_dots_raw
        chosen_dots_raw=$(select_multi "select dotfile modules to link" "${ALL_DOTFILES[@]}")
        opt_dots=( ${(s: :)chosen_dots_raw} )
    fi

    # 4. Theming Decision
    if ask_yn "run initial wallpaper seeding & matugen theme generation?" "Y"; then
        opt_theme=true
    else
        opt_theme=false
    fi

    # 5. Shell Reload Decision
    if ask_yn "reload running desktop shell (hyprland + quickshell) when done?" "Y"; then
        opt_reload=true
    else
        opt_reload=false
    fi

    # --- Apply Wizard Selections ---
    setup_directories_and_permissions

    if [[ "$opt_backup" == "true" ]]; then
        backup_selected "${opt_dots[@]}"
    fi

    if [[ "$do_pkgs" == "true" && ${#opt_pkg_cats} -gt 0 ]]; then
        install_selected_dependencies "${opt_pkg_cats[@]}"
    fi

    if [[ "$do_links" == "true" && ${#opt_dots} -gt 0 ]]; then
        link_selected_configurations "${opt_dots[@]}"
    fi

    if [[ "$opt_theme" == "true" ]]; then
        initial_theming
    fi

    if [[ "$opt_reload" == "true" ]]; then
        reload_shell
    fi

elif [[ "$opt_mode" == "all" ]]; then
    setup_directories_and_permissions
    [[ "$opt_backup" != "false" ]] && backup_selected "${ALL_DOTFILES[@]}"
    install_selected_dependencies "${ALL_PKG_CATEGORIES[@]}"
    link_selected_configurations "${ALL_DOTFILES[@]}"
    [[ "$opt_theme" == "true" ]] && initial_theming
    [[ "$opt_reload" == "true" ]] && reload_shell

elif [[ "$opt_mode" == "links" ]]; then
    setup_directories_and_permissions
    if (( ${#opt_dots} == 0 )); then
        local chosen_raw
        chosen_raw=$(select_multi "select dotfile modules to link" "${ALL_DOTFILES[@]}")
        opt_dots=( ${(s: :)chosen_raw} )
    fi
    [[ "$opt_backup" == "true" ]] && backup_selected "${opt_dots[@]}"
    link_selected_configurations "${opt_dots[@]}"
    [[ "$opt_theme" == "true" ]] && initial_theming
    [[ "$opt_reload" == "true" ]] && reload_shell

elif [[ "$opt_mode" == "deps" ]]; then
    if (( ${#opt_pkg_cats} == 0 )); then
        local chosen_raw
        chosen_raw=$(select_multi "select package groups to install" "${ALL_PKG_CATEGORIES[@]}")
        opt_pkg_cats=( ${(s: :)chosen_raw} )
    fi
    install_selected_dependencies "${opt_pkg_cats[@]}"
fi

print ""
log_ok "installer finished. everything configured to your specifications."
