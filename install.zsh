#!/usr/bin/env zsh
# your desktop is currently an unconfigured microwave. let us fix that.
setopt ERR_EXIT NO_UNSET PIPE_FAIL EXTENDED_GLOB

# prevent terminal terrorism
if (( EUID == 0 )); then
    print -P "%F{203}󰅚 running a desktop rice installer as root? who hurt you? step away from the keyboard before you chmod your entire personality to 000.%f"
    print -P "%F{244}run it as your regular user. sudo exists for a reason.%f"
    exit 1
fi

DOTS_DIR="${0:A:h}"
if [[ ! -d "$DOTS_DIR/quickshell" ]]; then
    if [[ -d "$HOME/my-hyprland-dots/quickshell" ]]; then
        DOTS_DIR="$HOME/my-hyprland-dots"
    else
        print -P "%F{141}󰄛%f cloning repo because you apparently cannot clone it yourself..."
        if ! (( $+commands[git] )); then
            print -P "%F{203}󰅚 git is not even installed. what were you doing on this machine before today, watching paint dry?%f"
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

ask_yn() {
    local prompt="$1"
    local default_ans="${2:-Y}"
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

install_aur_helper() {
    log_step "resolving aur deficiency..."
    log_warn "no aur helper detected. arch without the aur is just debian with anxiety."

    if ! ask_yn "automatically compile and install paru-bin right now?" "Y"; then
        log_warn "enjoy manually compiling pkgbuilds in nano like it is 2004."
        return 1
    fi

    log_info "verifying base-devel and git..."
    sudo pacman -S --needed --noconfirm base-devel git || {
        log_err "pacman choked on base-devel. check your mirrorlist or internet."
        return 1
    }

    local tmp_aur
    tmp_aur=$(mktemp -d /tmp/paru_build_XXXXXX)
    log_info "fetching paru-bin PKGBUILD into $tmp_aur..."

    if ! git clone "https://aur.archlinux.org/paru-bin.git" "$tmp_aur"; then
        log_err "git failed to clone paru-bin. aur might be rate limiting you."
        rm -rf "$tmp_aur"
        return 1
    fi

    (
        cd "$tmp_aur" || exit 1
        log_info "compiling paru-bin via makepkg..."
        makepkg -si --noconfirm
    )
    local status=$?
    rm -rf "$tmp_aur"

    if (( status == 0 )); then
        log_ok "paru installed. your machine is slightly less useless now."
        return 0
    else
        log_err "makepkg crashed. inspect the terminal carnage above."
        return 1
    fi
}

fetch_curated_wallpaper() {
    log_step "wallpaper acquisition..."
    mkdir -p "$WALLPAPER_DIR"/{live,downloaded}

    local target_file="$WALLPAPER_DIR/downloaded/default_nordic_minimal.png"
    if [[ -f "$target_file" ]]; then
        log_info "wallpaper already cached at $target_file"
        return 0
    fi

    log_info "fetching a wallpaper that will not embarrass you during screen shares..."
    # direct reliable uncompressed raw asset
    local wp_source="https://raw.githubusercontent.com/catppuccin/wallpapers/main/landscapes/evening-sky.png"

    if (( $+commands[curl] )); then
        curl -fsSL "$wp_source" -o "$target_file" || true
    elif (( $+commands[wget] )); then
        wget -q -O "$target_file" "$wp_source" || true
    else
        log_warn "neither curl nor wget exists. how did you even acquire this script?"
        return 1
    fi

    if [[ -f "$target_file" && -s "$target_file" ]]; then
        log_ok "saved curated wallpaper -> $target_file"
    else
        log_warn "failed to download wallpaper. the black void remains your aesthetic."
        return 1
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

select_multi() {
    local header="$1"
    shift
    local -a items=( "$@" )
    local -a chosen=()

    if (( $+commands[fzf] )) && [[ -t 0 || -r /dev/tty ]]; then
        local raw=""
        if [[ -t 0 ]]; then
            raw=$(printf "%s\n" "${items[@]}" | fzf -m --header="[${header} | tab to toggle, enter to confirm]" --reverse --height=40%)
        else
            raw=$(printf "%s\n" "${items[@]}" | fzf -m --header="[${header} | tab to toggle, enter to confirm]" --reverse --height=40% </dev/tty)
        fi

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
        print -Pn "%F{244}enter comma-separated indices or 'all' [default: all]:%f "
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
        log_info "zero package groups picked. moving on without installing anything."
        return 0
    fi

    local helper=$(detect_aur_helper)

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

    to_install_official=( ${(u)to_install_official} )
    to_install_aur=( ${(u)to_install_aur} )

    if [[ "$helper" == "pacman" && ${#to_install_aur} -gt 0 ]]; then
        log_warn "you selected aur packages (${to_install_aur[*]}) but have no aur helper."
        if install_aur_helper; then
            helper=$(detect_aur_helper)
        fi
    fi

    log_step "commencing package installation for: ${cats[*]}"
    log_info "using backend: %B$helper%b"

    case "$helper" in
        paru|yay)
            local -a all_target_pkgs=( "${to_install_official[@]}" "${to_install_aur[@]}" )
            if (( ${#all_target_pkgs} )); then
                log_info "executing $helper -S --needed for ${#all_target_pkgs} targets..."
                $helper -S --needed --noconfirm "${all_target_pkgs[@]}" || \
                    log_warn "some packages broke during install. check aur compile logs."
            fi
            ;;
        pacman)
            if (( ${#to_install_official} )); then
                log_info "running sudo pacman -S --needed for official repos..."
                sudo pacman -S --needed --noconfirm "${to_install_official[@]}" || \
                    log_warn "pacman encountered errors."
            fi
            if (( ${#to_install_aur} )); then
                log_err "skipped aur packages due to lack of helper: ${to_install_aur[*]}"
                log_err "install quickshell-git, matugen-bin, awww manually or run with an aur helper."
            fi
            ;;
        *)
            log_err "unknown packaging system. install these manually or switch to a real distro:"
            print "  official: ${to_install_official[*]}"
            print "  aur: ${to_install_aur[*]}"
            ;;
    esac
}

backup_selected() {
    local -a targets=( "$@" )
    if (( ${#targets} == 0 )); then
        targets=( "${ALL_DOTFILES[@]}" )
    fi

    log_info "inspecting $CONFIG_DIR for files you probably did not mean to leave there..."
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
        log_ok "archived ${#existing_targets} unlinked folder(s) -> $target_archive"
        log_info "keep them so you can reminisce about your broken configs later."
    else
        log_info "no physical unlinked configs found. nothing worth saving."
    fi
}

link_selected_configurations() {
    local -a targets=( "$@" )
    if (( ${#targets} == 0 )); then
        log_info "no configs selected for symlinking."
        return 0
    fi

    log_step "symlinking configurations (${#targets} modules)..."
    mkdir -p "$CONFIG_DIR"

    for folder in "${targets[@]}"; do
        local src="$DOTS_DIR/$folder"
        local target="$CONFIG_DIR/$folder"

        if [[ ! -d "$src" ]]; then
            log_warn "source missing for $folder. skipping nonexistent directory."
            continue
        fi

        # flatpak sandbox bwrap breaks on symlinked gtk themes
        if [[ "$folder" == "gtk-3.0" || "$folder" == "gtk-4.0" ]]; then
            [[ -L "$target" ]] && rm -f "$target"
            mkdir -p "$target"
            local gtk_files=( "$src"/*(N.) )
            if (( ${#gtk_files} )); then
                cp -f "${gtk_files[@]}" "$target/"
            fi
            log_ok "synced $folder as real directory (flatpak sandbox containment)"
            continue
        fi

        if [[ -L "$target" && "$target:A" == "$src:A" ]]; then
            log_ok "$folder already pointed to repo."
            continue
        fi

        if [[ -L "$target" ]]; then
            rm -f "$target"
        elif [[ -d "$target" ]]; then
            local backup="${target}.stale.$(date +%s)"
            log_warn "moving old physical directory $target -> $backup"
            mv "$target" "$backup"
        fi

        ln -sfn "$src" "$target"
        log_ok "linked $folder -> $target"
    done

    if [[ " ${targets[*]} " == *" zsh "* && -f "$DOTS_DIR/zsh/sources.zsh" ]]; then
        local zshrc="$HOME/.zshrc"
        touch "$zshrc"
        local source_line="[[ -f \"$CONFIG_DIR/zsh/sources.zsh\" ]] && source \"$CONFIG_DIR/zsh/sources.zsh\""
        if ! grep -qs "sources\.zsh" "$zshrc" 2>/dev/null; then
            print -P "\n# dotfiles master hook\n$source_line" >> "$zshrc"
            log_ok "hooked ~/.zshrc into $CONFIG_DIR/zsh/sources.zsh"
        fi
    fi
}

setup_directories_and_permissions() {
    log_info "allocating runtime and cache paths..."
    mkdir -p "$WALLPAPER_DIR"/{live,downloaded}
    mkdir -p "$CACHE_DIR"/quickshell/{thumbnails,wallpapers}
    mkdir -p "$CACHE_DIR/zsh"
    mkdir -p "$HOME"/.local/share/{quickshell/scratch,quicknav/marks,fonts}
    mkdir -p "$BACKUP_DIR"

    log_info "marking shell scripts executable..."
    local script_targets=(
        "$DOTS_DIR"/quickshell/scripts/*.(sh|py)(N.)
        "$DOTS_DIR"/matugen/post-hook-scripts/*.(zsh|sh)(N.)
        "$DOTS_DIR"/install.zsh(N.)
    )

    if (( ${#script_targets} )); then
        chmod +x "${script_targets[@]}"
        log_ok "chmod +x applied to ${#script_targets} helper binary/script targets."
    fi
}

initial_theming() {
    log_step "palette extraction via matugen..."

    if [[ -d "$DOTS_DIR/wallpapers" ]]; then
        local repo_wps=( "$DOTS_DIR"/wallpapers/*.(png|jpg|jpeg|webp)(N.) )
        if (( ${#repo_wps} )); then
            cp -n "${repo_wps[@]}" "$WALLPAPER_DIR/" 2>/dev/null || true
        fi
    fi

    local sample_wp=( "$WALLPAPER_DIR"/**/*.(png|jpg|jpeg|webp)(N.) )

    if (( ${#sample_wp} == 0 )); then
        fetch_curated_wallpaper
        sample_wp=( "$WALLPAPER_DIR"/**/*.(png|jpg|jpeg|webp)(N.) )
    fi

    if (( ${#sample_wp} )); then
        local first_wp="${sample_wp[1]}"
        log_info "generating material palette from: $first_wp"
        if (( $+commands[matugen] )); then
            matugen image "$first_wp" -m "dark" -t "scheme-tonal-spot" --source-color-index 0 2>/dev/null || true
            log_ok "matugen dynamic scheme applied."
        else
            log_warn "matugen binary missing. colors remain default and sad."
        fi
    else
        log_warn "no images located in $WALLPAPER_DIR. skipping theming step."
    fi
}

reload_shell() {
    log_step "restarting window manager environment..."

    if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && (( $+commands[hyprctl] )); then
        hyprctl reload >/dev/null 2>&1 || true
        log_ok "hyprland config reloaded."
    else
        log_info "hyprland session not detected. skipping hyprctl."
    fi

    if (( $+commands[qs] )); then
        qs kill >/dev/null 2>&1 || pkill -x qs 2>/dev/null || true
        sleep 0.3
        qs -d >/dev/null 2>&1 &!
        log_ok "quickshell daemon reloaded (qs -d)."
    elif (( $+commands[quickshell] )); then
        pkill -x quickshell 2>/dev/null || true
        sleep 0.3
        quickshell -p "$CONFIG_DIR/quickshell/shell.qml" >/dev/null 2>&1 &!
        log_ok "quickshell restarted."
    fi
}

doctor_check() {
    log_step "system diagnostics..."
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
    log_info "checking typography..."
    if (( $+commands[fc-list] )); then
        local all_fonts
        all_fonts="$(fc-list : family 2>/dev/null)"

        [[ "$all_fonts" == *JetBrainsMono* ]] \
            && print -P "  %F{120}󰄲%f JetBrainsMono Nerd Font detected" \
            || print -P "  %F{221}󰀦%f JetBrainsMono Nerd Font missing"

        [[ "$all_fonts" == *"Noto Sans"* ]] \
            && print -P "  %F{120}󰄲%f Noto Sans detected" \
            || print -P "  %F{221}󰀦%f Noto Sans missing"
    fi

    print ""
    log_info "validating config links..."
    for l in "${ALL_DOTFILES[@]}"; do
        local target="$CONFIG_DIR/$l"
        if [[ -L "$target" ]]; then
            print -P "  %F{120}󰄲%f $target -> %F{244}$(readlink "$target")%f"
        elif [[ -d "$target" ]]; then
            print -P "  %F{221}󰀦%f $target exists as unlinked directory"
        else
            print -P "  %F{244}󰅚%f $target absent"
        fi
    done

    print ""
    if (( ${#missing_bins} > 0 )); then
        log_warn "missing ${#missing_bins} binaries: ${missing_bins[*]}"
        print -P "  your desktop is currently held together by spit and duct tape."
    else
        log_ok "all core tools and glyph packs are present. remarkable."
    fi
}

show_help() {
    print "usage: ./install.zsh [options]"
    print ""
    print "modes:"
    print "  -i, --interactive, -c, --custom  run guided configuration wizard (default)"
    print "  -a, --all                        unattended full install (pkgs + backup + links + theme)"
    print "  -u, --update                     git pull, relink configs, reload hyprland"
    print "  -l, --links                      symlink dotfiles only"
    print "  -d, --deps                       install package dependencies only"
    print "      --doctor                     run health check and list missing packages"
    print "      --reload                     reload hyprland and quickshell"
    print "  -h, --help                       show this message"
    print ""
    print "granular flags:"
    print "  --aur                            bootstrap paru-bin immediately if missing"
    print "  --fetch-wp                       download clean wallpaper asset immediately"
    print "  --backup                         force backup of unlinked directories"
    print "  --no-backup                      skip backup entirely"
    print "  --pkgs=<c1,c2,...>               install specific categories"
    print "  --dots=<d1,d2,...>               link specific dotfiles"
    print "  --no-theme                       skip wallpaper color sampling"
    print "  --no-reload                      do not touch running compositors"
}

# --- CLI Parsing ---
opt_mode="menu"
opt_backup=""
opt_theme=true
opt_reload=true
opt_fetch_wp=false
opt_bootstrap_aur=false
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
        --aur)                  opt_bootstrap_aur=true; shift ;;
        --fetch-wp)             opt_fetch_wp=true; shift ;;
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
            log_err "unrecognized option: $1"
            show_help
            exit 1
            ;;
    esac
done

print -P "%F{141}󰄛 dotfiles manager & setup harness%f"

if [[ "$opt_bootstrap_aur" == "true" ]]; then
    install_aur_helper
fi

if [[ "$opt_fetch_wp" == "true" ]]; then
    fetch_curated_wallpaper
fi

if [[ "$opt_mode" == "menu" ]]; then
    print ""
    print "choose an action before i lose what is left of my patience:"
    print "  1) 󰚰 custom wizard (pick package groups, backups, symlinks)"
    print "  2) 󰏤 full install (packages + backup + symlinks + palette)"
    print "  3) 󰌢 symlink dotfiles only"
    print "  4) 󰏖 install dependencies only"
    print "  5) 󰑐 update dotfiles (git pull + sync + reload)"
    print "  6) 󰄲 doctor diagnostic scan"
    print "  7) 󰁕 reload compositors"
    print "  8) 󰅚 quit"
    print -Pn "choice [1-8, default 1]: "

    local choice=""
    if [[ -t 0 ]]; then read -r choice; elif [[ -r /dev/tty ]]; then read -r choice </dev/tty; else choice="1"; fi
    choice="${choice:-1}"

    case "$choice" in
        1) opt_mode="custom" ;;
        2) opt_mode="all" ;;
        3) opt_mode="links" ;;
        4) opt_mode="deps" ;;
        5) opt_mode="update" ;;
        6) opt_mode="doctor" ;;
        7) opt_mode="reload" ;;
        8|q|Q) print "aborting."; exit 0 ;;
        *) log_warn "invalid input. falling back to wizard."; opt_mode="custom" ;;
    esac
fi

if [[ "$opt_mode" == "doctor" ]]; then
    doctor_check
    exit 0
elif [[ "$opt_mode" == "reload" ]]; then
    reload_shell
    exit 0
elif [[ "$opt_mode" == "update" ]]; then
    log_step "syncing repository..."
    if [[ -d "$DOTS_DIR/.git" ]]; then
        git -C "$DOTS_DIR" pull --rebase || log_warn "merge conflict detected."
    fi
    setup_directories_and_permissions
    link_selected_configurations "${ALL_DOTFILES[@]}"
    initial_theming
    reload_shell
    log_ok "update finished."
    exit 0
fi

if [[ "$opt_mode" == "custom" ]]; then
    log_step "interactive installer setup"

    if [[ -z "$opt_backup" ]]; then
        if ask_yn "backup unlinked physical folders in ~/.config?" "Y"; then
            opt_backup=true
        else
            opt_backup=false
        fi
    fi

    local do_pkgs=false
    if (( ${#opt_pkg_cats} > 0 )); then
        do_pkgs=true
    elif ask_yn "install system/aur packages via detected helper?" "Y"; then
        do_pkgs=true
        print ""
        local chosen_raw
        chosen_raw=$(select_multi "select package categories" "${ALL_PKG_CATEGORIES[@]}")
        opt_pkg_cats=( ${(s: :)chosen_raw} )
    fi

    local do_links=false
    if (( ${#opt_dots} > 0 )); then
        do_links=true
    elif ask_yn "symlink dotfiles into ~/.config?" "Y"; then
        do_links=true
        print ""
        local chosen_dots_raw
        chosen_dots_raw=$(select_multi "select config targets" "${ALL_DOTFILES[@]}")
        opt_dots=( ${(s: :)chosen_dots_raw} )
    fi

    if ask_yn "run wallpaper seed & matugen dynamic palette generation?" "Y"; then
        opt_theme=true
    else
        opt_theme=false
    fi

    if ask_yn "reload hyprland & quickshell upon completion?" "Y"; then
        opt_reload=true
    else
        opt_reload=false
    fi

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
        chosen_raw=$(select_multi "select config targets" "${ALL_DOTFILES[@]}")
        opt_dots=( ${(s: :)chosen_raw} )
    fi
    [[ "$opt_backup" == "true" ]] && backup_selected "${opt_dots[@]}"
    link_selected_configurations "${opt_dots[@]}"
    [[ "$opt_theme" == "true" ]] && initial_theming
    [[ "$opt_reload" == "true" ]] && reload_shell

elif [[ "$opt_mode" == "deps" ]]; then
    if (( ${#opt_pkg_cats} == 0 )); then
        local chosen_raw
        chosen_raw=$(select_multi "select package categories" "${ALL_PKG_CATEGORIES[@]}")
        opt_pkg_cats=( ${(s: :)chosen_raw} )
    fi
    install_selected_dependencies "${opt_pkg_cats[@]}"
fi

print ""
log_ok "process complete. your machine looks less like an unrendered source engine map."
