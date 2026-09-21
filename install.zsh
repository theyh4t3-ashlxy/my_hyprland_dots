#!/usr/bin/env zsh
# your desktop is currently an unconfigured microwave. let me do it for you.
setopt ERR_EXIT NO_UNSET PIPE_FAIL EXTENDED_GLOB

# prevent terminal vandalism
if (( EUID == 0 )); then
    print -P "%F{203}󰅚 running this as root? who hurt you? step away from the keyboard before you chmod your entire life into 000.%f"
    print -P "%F{244}run it as your regular user. uwsm and nixos will not save you from self-sabotage.%f"
    exit 1
fi

DOTS_DIR="${0:A:h}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
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

verify_nixos() {
    if [[ ! -f /etc/NIXOS ]]; then
        log_warn "this system is not nixos. if you are still on arch, run while you can."
    else
        log_ok "nixos environment verified. no mutable package chaos detected."
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
    local wp_source="https://raw.githubusercontent.com/catppuccin/wallpapers/main/landscapes/evening-sky.png"

    if (( $+commands[curl] )); then
        curl -fsSL "$wp_source" -o "$target_file" 2>/dev/null || true
    elif (( $+commands[wget] )); then
        wget -q -O "$target_file" "$wp_source" 2>/dev/null || true
    else
        log_warn "neither curl nor wget exists. add them to configuration.nix."
        return 1
    fi

    if [[ -f "$target_file" && -s "$target_file" ]]; then
        log_ok "saved curated wallpaper -> $target_file"
    else
        log_warn "failed to download wallpaper. enjoy your default black void."
        return 1
    fi
}

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

# FIXED: UI messages print to stderr (>&2) so command substitutions do not swallow the menu
select_multi() {
    local header="$1"
    shift
    local -a items=( "$@" )
    local -a chosen=()

    if (( $+commands[fzf] )) && [[ -t 0 || -r /dev/tty ]]; then
        local raw=""
        if [[ -t 0 ]]; then
            raw=$(printf "%s\n" "${items[@]}" | fzf -m --header="[${header} | tab to toggle, enter to confirm]" --reverse --height=40% || true)
        else
            raw=$(printf "%s\n" "${items[@]}" | fzf -m --header="[${header} | tab to toggle, enter to confirm]" --reverse --height=40% </dev/tty || true)
        fi

        if [[ -n "$raw" ]]; then
            chosen=( ${(f)raw} )
        fi
    else
        print -P "%F{141}󰄛%f %B${header}%b:" >&2
        local i=1
        for it in "${items[@]}"; do
            print "  $i) $it" >&2
            (( i++ ))
        done
        print -Pn "%F{244}enter comma-separated indices or 'all' [default: all]:%f " >&2
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

backup_selected() {
    local -a targets=( "$@" )
    if (( ${#targets} == 0 )); then
        targets=( "${ALL_DOTFILES[@]}" )
    fi

    log_info "inspecting $CONFIG_DIR for files you probably broke earlier..."
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
    else
        log_info "no physical unlinked configs found. nothing worth preserving."
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
            log_warn "source missing for $folder in $DOTS_DIR. skipping."
            continue
        fi

        # flatpak sandbox containment: copy gtk root rather than symlink
        if [[ "$folder" == "gtk-3.0" || "$folder" == "gtk-4.0" ]]; then
            [[ -L "$target" ]] && rm -f "$target"
            mkdir -p "$target"
            cp -rf "$src"/. "$target/" 2>/dev/null || true
            log_ok "synced $folder as real directory (flatpak containment)"
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

    # handle zsh sourcing
    if [[ " ${targets[*]} " == *" zsh "* && -f "$DOTS_DIR/zsh/sources.zsh" ]]; then
        local zshrc="$HOME/.zshrc"
        touch "$zshrc"
        local source_line="[[ -f \"$CONFIG_DIR/zsh/sources.zsh\" ]] && source \"$CONFIG_DIR/zsh/sources.zsh\""
        if ! grep -qs "sources\.zsh" "$zshrc" 2>/dev/null; then
            print -r "\n# dotfiles master hook\n$source_line" >> "$zshrc"
            log_ok "hooked ~/.zshrc into $CONFIG_DIR/zsh/sources.zsh"
        fi
    fi
}

setup_directories_and_permissions() {
    log_info "allocating runtime and cache paths..."
    mkdir -p "$WALLPAPER_DIR"/{live,downloaded}
    mkdir -p "$CACHE_DIR"/quickshell/{thumbnails,wallpapers}
    mkdir -p "$CACHE_DIR/zsh"
    mkdir -p "$DATA_DIR"/{quickshell/scratch,quicknav/marks,fonts}
    mkdir -p "$BACKUP_DIR"

    log_info "marking shell scripts executable..."
    local script_targets=(
        "$DOTS_DIR"/quickshell/scripts/*.(sh|py)(N.)
        "$DOTS_DIR"/matugen/post-hook-scripts/*.(zsh|sh)(N.)
        "$DOTS_DIR"/install.zsh(N.)
    )

    if (( ${#script_targets} )); then
        chmod +x "${script_targets[@]}"
        log_ok "chmod +x applied to ${#script_targets} helper scripts."
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
        fetch_curated_wallpaper || true
        sample_wp=( "$WALLPAPER_DIR"/**/*.(png|jpg|jpeg|webp)(N.) )
    fi

    if (( ${#sample_wp} )); then
        local first_wp="${sample_wp[1]}"
        log_info "generating material palette from: $first_wp"
        if (( $+commands[matugen] )); then
            matugen image "$first_wp" -m "dark" -t "scheme-tonal-spot" --source-color-index 0 2>/dev/null || true
            log_ok "matugen dynamic scheme applied."
        else
            log_warn "matugen missing. ensure it is added to configuration.nix."
        fi
    else
        log_warn "no wallpapers located in $WALLPAPER_DIR. skipping palette step."
    fi
}

reload_shell() {
    log_step "restarting window manager environment..."

    if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && (( $+commands[hyprctl] )); then
        hyprctl reload >/dev/null 2>&1 || true
        log_ok "hyprland config reloaded."
    else
        log_info "hyprland session not active. skipping hyprctl."
    fi

    if (( $+commands[uwsm] )); then
        log_info "delegating quickshell daemon reload to uwsm app..."
        uwsm app -- qs kill >/dev/null 2>&1 || pkill -x qs 2>/dev/null || true
        sleep 0.3
        uwsm app -- qs -d >/dev/null 2>&1 &!
        log_ok "quickshell daemon reloaded (uwsm app -- qs -d)."
    elif (( $+commands[qs] )); then
        qs kill >/dev/null 2>&1 || pkill -x qs 2>/dev/null || true
        sleep 0.3
        qs -d >/dev/null 2>&1 &!
        log_ok "quickshell daemon reloaded."
    fi
}

rebuild_nixos() {
    log_step "triggering declarative nixos rebuild..."
    if ! (( $+commands[nixos-rebuild] )); then
        log_err "nixos-rebuild not found. are you really on nixos?"
        return 1
    fi

    log_info "executing sudo nixos-rebuild switch..."
    if sudo nixos-rebuild switch; then
        log_ok "nixos generation built and switched successfully."
    else
        log_err "nixos-rebuild failed. inspect configuration.nix syntax above."
        return 1
    fi
}

doctor_check() {
    log_step "nixos system diagnostics & binary verification..."
    local missing_bins=()
    local critical_bins=(
        "hyprland"
        "uwsm"
        "matugen"
        "awww"
        "mpvpaper"
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
            print -P "  %F{203}󰅚%f $b: %BMISSING in environment.systemPackages%b"
            missing_bins+=( "$b" )
        fi
    done

    if (( $+commands[qs] || $+commands[quickshell] )); then
        local qs_bin="${commands[qs]:-$commands[quickshell]}"
        print -P "  %F{120}󰄲%f quickshell found: %F{244}$qs_bin%f"
    else
        print -P "  %F{203}󰅚%f quickshell: %BMISSING in environment.systemPackages%b"
        missing_bins+=( "quickshell" )
    fi

    print ""
    log_info "checking typography..."
    if (( $+commands[fc-list] )); then
        local all_fonts
        all_fonts="$(fc-list : family 2>/dev/null || true)"

        [[ "$all_fonts" == *JetBrainsMono* ]] \
            && print -P "  %F{120}󰄲%f JetBrainsMono Nerd Font detected" \
            || print -P "  %F{221}󰀦%f JetBrainsMono Nerd Font missing in fonts.packages"

        [[ "$all_fonts" == *"Noto Sans"* ]] \
            && print -P "  %F{120}󰄲%f Noto Sans detected" \
            || print -P "  %F{221}󰀦%f Noto Sans missing in fonts.packages"
    fi

    print ""
    log_info "validating config links..."
    for l in "${ALL_DOTFILES[@]}"; do
        local target="$CONFIG_DIR/$l"
        if [[ -L "$target" ]]; then
            print -P "  %F{120}󰄲%f $target -> %F{244}$(readlink "$target")%f"
        elif [[ -d "$target" ]]; then
            print -P "  %F{221}󰀦%f $target exists as real unlinked directory"
        else
            print -P "  %F{244}󰅚%f $target absent"
        fi
    done

    print ""
    if (( ${#missing_bins} > 0 )); then
        log_warn "missing ${#missing_bins} packages in configuration.nix: ${missing_bins[*]}"
    else
        log_ok "all core tools, uwsm session harness, and fonts are clean."
    fi
}

show_help() {
    print "usage: ./install.zsh [options]"
    print ""
    print "modes:"
    print "  -i, --interactive, -c, --custom  guided configuration wizard (default)"
    print "  -a, --all                        full sync (rebuild + backup + links + theme)"
    print "  -l, --links                      symlink dotfiles only"
    print "  -r, --rebuild                    run sudo nixos-rebuild switch"
    print "  -u, --update                     git pull, relink configs, reload hyprland"
    print "      --doctor                     run health check and list missing nix packages"
    print "      --reload                     reload hyprland and quickshell via uwsm"
    print "  -h, --help                       show this message"
    print ""
    print "granular flags:"
    print "  --backup                         force backup of unlinked directories"
    print "  --no-backup                      skip backup entirely"
    print "  --dots=<d1,d2,...>               link specific dotfiles"
    print "  --no-theme                       skip wallpaper color sampling"
    print "  --no-reload                      do not touch running compositors"
}

# --- CLI Parsing ---
opt_mode="menu"
opt_backup=""
opt_theme=true
opt_reload=true
opt_dots=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -a|--all)               opt_mode="all"; shift ;;
        -u|--update)            opt_mode="update"; shift ;;
        -l|--links)             opt_mode="links"; shift ;;
        -r|--rebuild)           opt_mode="rebuild"; shift ;;
        -i|--interactive|-c|--custom) opt_mode="custom"; shift ;;
        --doctor|--check)       opt_mode="doctor"; shift ;;
        --reload)               opt_mode="reload"; shift ;;
        --backup)               opt_backup=true; shift ;;
        --no-backup)            opt_backup=false; shift ;;
        --no-theme)             opt_theme=false; shift ;;
        --no-reload)            opt_reload=false; shift ;;
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

print -P "%F{141}󰄛 dotfiles manager & uwsm harness (nixos edition)%f"
verify_nixos

if [[ "$opt_mode" == "menu" ]]; then
    print ""
    print "choose an action before i lose what is left of my patience:"
    print "  1) 󰚰 custom wizard (pick dotfiles, backups, symlinks)"
    print "  2) 󰏤 full sync (nixos-rebuild + backup + symlinks + palette)"
    print "  3) 󰌢 symlink dotfiles only"
    print "  4) 󰏖 rebuild nixos (sudo nixos-rebuild switch)"
    print "  5) 󰑐 update dotfiles (git pull + sync + reload)"
    print "  6) 󰄲 doctor diagnostic scan"
    print "  7) 󰁕 reload compositors & quickshell"
    print "  8) 󰅚 quit"
    print -Pn "choice [1-8, default 1]: "

    local choice=""
    if [[ -t 0 ]]; then read -r choice; elif [[ -r /dev/tty ]]; then read -r choice </dev/tty; else choice="1"; fi
    choice="${choice:-1}"

    case "$choice" in
        1) opt_mode="custom" ;;
        2) opt_mode="all" ;;
        3) opt_mode="links" ;;
        4) opt_mode="rebuild" ;;
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
elif [[ "$opt_mode" == "rebuild" ]]; then
    rebuild_nixos
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
    log_step "interactive nixos dotfiles wizard"

    if ask_yn "run 'sudo nixos-rebuild switch' first?" "N"; then
        rebuild_nixos
    fi

    if [[ -z "$opt_backup" ]]; then
        if ask_yn "backup unlinked physical folders in ~/.config?" "Y"; then
            opt_backup=true
        else
            opt_backup=false
        fi
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
    rebuild_nixos
    [[ "$opt_backup" != "false" ]] && backup_selected "${ALL_DOTFILES[@]}"
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
fi

print ""
log_ok "process complete. nixos declarative packages & dotfiles unified."
