#!/usr/bin/env zsh
# bootstrap and manage quickshell dotfiles on nixos
setopt ERR_EXIT NO_UNSET PIPE_FAIL EXTENDED_GLOB

# trap interruptions gracefully
trap 'print -P "\n%F{203}󰅚 aborted by user. nothing caught fire.%f"; exit 130' INT TERM

# paths and state
DOTS_DIR="${0:A:h}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
WALLPAPER_DIR="$HOME/.wallpapers"
BACKUP_DIR="$CACHE_DIR/dotfiles-backups"

DRY_RUN=false
FETCH_WP=false

# discover config directories in repo, excluding wallpapers
ALL_DOTFILES=( "$DOTS_DIR"/*(/N:t) )
ALL_DOTFILES=( ${ALL_DOTFILES:#wallpapers} )

# logging helpers
log_info() { print -P "%F{141}󰄛%f $1" }
log_ok()   { print -P "%F{120}󰄲%f $1" }
log_warn() { print -P "%F{221}󰀦%f $1" }
log_err()  { print -P "%F{203}󰅚%f $1" >&2 }
log_step() { print -P "\n%F{117}󰁕%f %B$1%b" }
log_dry()  { print -P "%F{244}[dry-run]%f %F{141}$1%f" }

# dry-run execution wrapper
execute() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "$*"
        return 0
    fi
    "$@"
}

# interactive yes/no prompt
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

# check if running on nixos
verify_nixos() {
    if [[ ! -f /etc/NIXOS ]]; then
        log_warn "this system is not nixos. proceed at your own risk."
    else
        log_ok "nixos environment verified."
    fi
}

# fetch a random wallpaper from wallhaven and store path in $REPLY
fetch_wallhaven_wallpaper() {
    REPLY=""
    log_step "fetching wallpaper from wallhaven..."
    execute mkdir -p "$WALLPAPER_DIR"/{live,wallhaven}

    local wh_dir="$WALLPAPER_DIR/wallhaven"
    local target_file=""

    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "query wallhaven api -> download random wallpaper to $wh_dir"
        REPLY="$wh_dir/dry_run_wallpaper.png"
        return 0
    fi

    log_info "querying wallhaven api (categories=100, purity=100)..."
    local api_url="https://wallhaven.cc/api/v1/search?sorting=random&categories=100&purity=100"
    local json_payload=""

    if (( $+commands[curl] )); then
        json_payload=$(curl -fsSL --connect-timeout 8 "$api_url" 2>/dev/null || true)
    elif (( $+commands[wget] )); then
        json_payload=$(wget -q --timeout=8 -O - "$api_url" 2>/dev/null || true)
    fi

    local img_url=""
    if [[ -n "$json_payload" ]]; then
        if (( $+commands[jq] )); then
            img_url=$(print -r -- "$json_payload" | jq -r '.data[0].path // empty' 2>/dev/null || true)
        elif (( $+commands[python3] )); then
            img_url=$(print -r -- "$json_payload" | python3 -c '
import sys, json
try:
    data = json.load(sys.stdin).get("data", [])
    if data:
        print(data[0].get("path", ""))
except Exception:
    pass
' 2>/dev/null || true)
        fi
    fi

    if [[ -n "$img_url" && "$img_url" == http* ]]; then
        local img_name="${img_url:t}"
        target_file="$wh_dir/$img_name"

        if [[ -f "$target_file" && -s "$target_file" ]]; then
            log_ok "wallhaven wallpaper already cached -> $target_file"
            REPLY="$target_file"
            return 0
        fi

        log_info "downloading wallhaven wallpaper ($img_name)..."
        local dl_ok=false
        if (( $+commands[curl] )); then
            curl -fsSL --connect-timeout 10 "$img_url" -o "$target_file" 2>/dev/null && dl_ok=true || true
        elif (( $+commands[wget] )); then
            wget -q --timeout=10 -O "$target_file" "$img_url" 2>/dev/null && dl_ok=true || true
        fi

        if [[ "$dl_ok" == "true" && -s "$target_file" ]]; then
            log_ok "saved wallhaven wallpaper -> $target_file"
            REPLY="$target_file"
            return 0
        fi
    fi

    log_warn "wallhaven unreachable or rate-limited. checking local cache..."
    local cached=( "$WALLPAPER_DIR"/**/*.(png|jpg|jpeg|webp)(N.) )
    if (( ${#cached} )); then
        log_info "using cached wallpaper -> ${cached[1]}"
        REPLY="${cached[1]}"
        return 0
    fi

    log_err "failed to acquire any wallpaper from wallhaven or local cache."
    return 1
}

# multi-select menu via fzf or numbered prompt
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
            (( ++i ))
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

    if (( ${#chosen} > 0 )); then
        print -l "${chosen[@]}"
    fi
}

# archive unmanaged config directories before overwriting
backup_selected() {
    local -a targets=( "$@" )
    if (( ${#targets} == 0 )); then
        targets=( "${ALL_DOTFILES[@]}" )
    fi

    log_info "inspecting $CONFIG_DIR for unmanaged files to backup..."
    execute mkdir -p "$BACKUP_DIR"
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local target_archive="$BACKUP_DIR/backup_${timestamp}.tar.gz"

    local -a existing_targets=()
    for t in "${targets[@]}"; do
        if [[ -e "$CONFIG_DIR/$t" && ! -L "$CONFIG_DIR/$t" ]]; then
            existing_targets+=( "$t" )
        fi
    done

    if (( ${#existing_targets} > 0 )); then
        if [[ "$DRY_RUN" == "true" ]]; then
            log_dry "tar -czf $target_archive -C $CONFIG_DIR ${existing_targets[*]}"
        else
            tar -czf "$target_archive" -C "$CONFIG_DIR" "${existing_targets[@]}" 2>/dev/null || true
            log_ok "archived ${#existing_targets} folder(s) -> $target_archive"
        fi
    else
        log_info "no unlinked physical configs found. skipping backup."
    fi
}

# symlink selected dotfiles into ~/.config
link_selected_configurations() {
    local -a targets=( "$@" )
    if (( ${#targets} == 0 )); then
        log_info "no configs selected for symlinking."
        return 0
    fi

    log_step "symlinking configurations (${#targets} modules)..."
    execute mkdir -p "$CONFIG_DIR"

    for folder in "${targets[@]}"; do
        local src="$DOTS_DIR/$folder"
        local target="$CONFIG_DIR/$folder"

        if [[ ! -d "$src" ]]; then
            log_warn "source missing for $folder in $DOTS_DIR. skipping."
            continue
        fi

        if [[ -L "$target" ]]; then
            local current_dest
            current_dest=$(readlink -f "$target" 2>/dev/null || true)
            if [[ "$current_dest" == /nix/store/* ]]; then
                log_warn "$target is managed by nix (/nix/store)."
                if ! ask_yn "force replace nix-managed symlink for $folder?" "N"; then
                    log_info "skipping $folder."
                    continue
                fi
            fi
        fi

        # copy gtk configs as real directories for flatpak compatibility
        if [[ "$folder" == "gtk-3.0" || "$folder" == "gtk-4.0" ]]; then
            execute rm -rf "$target"
            execute mkdir -p "$target"
            if (( $+commands[rsync] )); then
                execute rsync -a --delete "$src/" "$target/"
            else
                execute cp -rf "$src"/. "$target/"
            fi

            if [[ -f "$target/bookmarks" ]]; then
                execute sed -i -E "s|file:///home/[^/]+/|file://$HOME/|g" "$target/bookmarks" 2>/dev/null || true
            fi
            log_ok "synced $folder as real directory (flatpak compatibility)"
            continue
        fi

        if [[ -L "$target" && "${target:A}" == "${src:A}" ]]; then
            log_ok "$folder already linked."
            continue
        fi

        if [[ -L "$target" ]]; then
            execute rm -f "$target"
        elif [[ -d "$target" ]]; then
            local backup="${target}.stale.$(date +%s)"
            log_warn "moving existing directory $target -> $backup"
            execute mv "$target" "$backup"
        fi

        execute ln -sfn "$src" "$target"
        log_ok "linked $folder -> $target"
    done

    # hook zsh config into ~/.zshrc if zsh module was selected
    if (( ${targets[(Ie)zsh]} )) && [[ -f "$DOTS_DIR/zsh/sources.zsh" ]]; then
        local zshrc="$HOME/.zshrc"
        local source_line="[[ -f \"$CONFIG_DIR/zsh/sources.zsh\" ]] && source \"$CONFIG_DIR/zsh/sources.zsh\""

        if [[ -L "$zshrc" ]]; then
            local zshrc_target
            zshrc_target=$(readlink -f "$zshrc" 2>/dev/null || true)
            if [[ "$zshrc_target" == /nix/store/* ]]; then
                log_warn "~/.zshrc is a read-only nix store symlink. cannot append safely."
                log_info "add this manually to your nixos or home-manager zsh config:"
                print -P "      %F{117}$source_line%f"
                return 0
            fi
        fi

        if [[ "$DRY_RUN" == "true" ]]; then
            log_dry "append source hook to $zshrc"
        else
            touch "$zshrc"
            if ! grep -qs "sources\.zsh" "$zshrc" 2>/dev/null; then
                print -r "\n# dotfiles hook\n$source_line" >> "$zshrc"
                log_ok "hooked ~/.zshrc into $CONFIG_DIR/zsh/sources.zsh"
            fi
        fi
    fi
}

# create runtime directories, install helpers, and fetch missing icon fonts
setup_directories_and_permissions() {
    log_info "setting up runtime and cache directories..."
    execute mkdir -p "$WALLPAPER_DIR"/{live,wallhaven}
    execute mkdir -p "$CACHE_DIR"/quickshell/{thumbnails,wallpapers}
    execute mkdir -p "$CACHE_DIR/zsh"
    execute mkdir -p "$DATA_DIR"/{quickshell/scratch,quicknav/marks,fonts}
    execute mkdir -p "$HOME/.local/bin" "$HOME/.local/state/quickshell"
    execute mkdir -p "$BACKUP_DIR"

    for helper in qs-switch qs-action; do
        if [[ -f "$DOTS_DIR/quickshell/scripts/$helper" ]]; then
            execute cp -f "$DOTS_DIR/quickshell/scripts/$helper" "$HOME/.local/bin/$helper"
            execute chmod +x "$HOME/.local/bin/$helper"
            log_ok "installed $helper -> ~/.local/bin/$helper"
        fi
    done

    # fetch icon fonts if missing from ~/.local/share/fonts
    local font_dir="$DATA_DIR/fonts"
    local -A font_urls=(
        "MaterialSymbolsRounded.ttf"  "https://raw.githubusercontent.com/google/material-design-icons/master/variablefont/MaterialSymbolsRounded%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf"
        "MaterialSymbolsOutlined.ttf" "https://raw.githubusercontent.com/google/material-design-icons/master/variablefont/MaterialSymbolsOutlined%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf"
        "MaterialSymbolsSharp.ttf"    "https://raw.githubusercontent.com/google/material-design-icons/master/variablefont/MaterialSymbolsSharp%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf"
        "FontAwesome6Free-Solid.ttf"  "https://raw.githubusercontent.com/FortAwesome/Font-Awesome/6.x/webfonts/fa-solid-900.ttf"
        "FontAwesome6Free-Regular.ttf" "https://raw.githubusercontent.com/FortAwesome/Font-Awesome/6.x/webfonts/fa-regular-400.ttf"
        "SegoeIcons.ttf"              "https://github.com/bdlukaa/fluent_ui/raw/master/fonts/SegoeIcons.ttf"
    )

    local fonts_updated=false
    for font_file url in "${(@kv)font_urls}"; do
        if [[ ! -s "$font_dir/$font_file" ]]; then
            log_info "fetching $font_file..."
            if [[ "$DRY_RUN" == "true" ]]; then
                log_dry "curl -fsSL $url -o $font_dir/$font_file"
            else
                curl -fsSL "$url" -o "$font_dir/$font_file" 2>/dev/null || log_warn "failed to download $font_file"
                fonts_updated=true
            fi
        fi
    done

    if [[ "$fonts_updated" == "true" ]] && (( $+commands[fc-cache] )); then
        execute fc-cache -f "$font_dir" >/dev/null 2>&1 || true
    fi

    if [[ -w "$DOTS_DIR" ]]; then
        local -a script_targets=(
            "$DOTS_DIR"/quickshell/scripts/*.(sh|py)(N.)
            "$DOTS_DIR"/quickshell/scripts/qs-switch(N.)
            "$DOTS_DIR"/quickshell/scripts/qs-action(N.)
            "$DOTS_DIR"/matugen/post-hook-scripts/*.(zsh|sh)(N.)
            "$DOTS_DIR"/install.zsh(N.)
        )

        if (( ${#script_targets} > 0 )); then
            execute chmod +x "${script_targets[@]}"
            log_ok "marked ${#script_targets} helper scripts executable."
        fi
    fi
}

# set wallpaper and generate matugen palette
initial_theming() {
    log_step "initializing wallpaper and color scheme..."

    if [[ -d "$DOTS_DIR/wallpapers" ]]; then
        local -a repo_wps=( "$DOTS_DIR"/wallpapers/*.(png|jpg|jpeg|webp)(N.) )
        if (( ${#repo_wps} > 0 )); then
            execute cp -n "${repo_wps[@]}" "$WALLPAPER_DIR/" 2>/dev/null || true
        fi
    fi

    local target_wp=""
    local -a existing_wps=( "$WALLPAPER_DIR"/**/*.(png|jpg|jpeg|webp)(N.) )

    if [[ "$FETCH_WP" == "true" ]] || (( ${#existing_wps} == 0 )); then
        if fetch_wallhaven_wallpaper; then
            target_wp="$REPLY"
        fi
    else
        target_wp="${existing_wps[1]}"
    fi

    if [[ -z "$target_wp" ]] || [[ "$DRY_RUN" != "true" && ! -f "$target_wp" ]]; then
        log_warn "no valid wallpaper available in $WALLPAPER_DIR. skipping theme generation."
        return 1
    fi

    log_info "active wallpaper -> $target_wp"

    local runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$EUID}"
    execute mkdir -p "$runtime_dir"
    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "write $target_wp to $runtime_dir/qs_current_wallpaper.txt and settings.conf"
    else
        print -r -- "$target_wp" > "$runtime_dir/qs_current_wallpaper.txt" 2>/dev/null || true

        local -a conf_targets=(
            "$HOME/.local/state/quickshell/settings.conf"
            "$CONFIG_DIR/quickshell/settings.conf"
        )
        for cf in "${conf_targets[@]}"; do
            mkdir -p "${cf:h}"
            if [[ -f "$cf" ]] && grep -qs "^currentWallpaper=" "$cf"; then
                sed -i "s|^currentWallpaper=.*|currentWallpaper=\"$target_wp\"|" "$cf" 2>/dev/null || true
            else
                print -r -- "currentWallpaper=\"$target_wp\"" >> "$cf" 2>/dev/null || true
            fi
        done
    fi

    if (( $+commands[matugen] )); then
        log_info "generating material palette via matugen..."
        execute matugen image "$target_wp" -m "dark" -t "scheme-tonal-spot" --source-color-index 0 || log_warn "matugen exited with non-zero status."
        log_ok "matugen dynamic scheme applied."
    else
        log_warn "matugen not found. skipping palette generation."
    fi

    if [[ -f "$DOTS_DIR/quickshell/scripts/wallpaper.py" ]] && (( $+commands[python3] )); then
        log_info "indexing ~/.wallpapers gallery..."
        execute python3 "$DOTS_DIR/quickshell/scripts/wallpaper.py" scan >/dev/null 2>&1 || true
        log_ok "wallpaper gallery indexed."
    fi

    if [[ -n "${WAYLAND_DISPLAY:-}" || -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        if (( $+commands[awww] )); then
            log_info "applying wallpaper via awww..."
            if ! awww query >/dev/null 2>&1; then
                execute awww-daemon --format argb >/dev/null 2>&1 &!
                sleep 0.5
            fi
            execute awww img "$target_wp" --transition-type wipe --transition-step 90 --transition-duration 2 >/dev/null 2>&1 || true
            log_ok "wallpaper applied to display outputs."
        fi
    fi
}

# reload hyprland and restart quickshell daemon
reload_shell() {
    log_step "reloading window manager and shell..."

    if [[ -z "${WAYLAND_DISPLAY:-}" && -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        log_info "no active wayland session detected. skipping reload."
        return 0
    fi

    if (( $+commands[hyprctl] )) && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        execute hyprctl reload >/dev/null 2>&1 || true
        log_ok "hyprland config reloaded."
    fi

    if (( $+commands[uwsm] )); then
        log_info "restarting quickshell via uwsm..."
        execute uwsm app -- qs kill >/dev/null 2>&1 || pkill -x qs 2>/dev/null || true
        sleep 0.3
        execute uwsm app -- qs -d >/dev/null 2>&1 &!
        log_ok "quickshell reloaded (uwsm app -- qs -d)."
    elif (( $+commands[qs] )); then
        execute qs kill >/dev/null 2>&1 || pkill -x qs 2>/dev/null || true
        sleep 0.3
        execute qs -d >/dev/null 2>&1 &!
        log_ok "quickshell reloaded."
    fi
}

# switch nixos configuration
rebuild_nixos() {
    log_step "triggering nixos rebuild..."
    if ! (( $+commands[nixos-rebuild] )); then
        log_err "nixos-rebuild not found."
        return 1
    fi

    local -a rebuild_cmd=( sudo nixos-rebuild switch )

    if [[ -f "$DOTS_DIR/flake.nix" ]]; then
        local host="${HOST:-$(hostname 2>/dev/null || true)}"
        if [[ -z "$host" || "$host" == "nixos" || "$host" == "localhost" ]]; then
            log_warn "generic hostname detected. using flake 'default' output."
            host="default"
        fi
        log_info "detected flake in $DOTS_DIR (target: ${host})"
        rebuild_cmd=( sudo nixos-rebuild switch --flake "$DOTS_DIR#${host}" )
    elif [[ -f /etc/nixos/flake.nix ]]; then
        log_info "detected flake in /etc/nixos"
        rebuild_cmd=( sudo nixos-rebuild switch --flake /etc/nixos )
    elif [[ -f /etc/nixos/configuration.nix ]]; then
        log_info "detected /etc/nixos/configuration.nix"
    else
        log_warn "no flake.nix or /etc/nixos/configuration.nix found."
    fi

    log_info "executing: ${rebuild_cmd[*]}"
    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "${rebuild_cmd[*]}"
        return 0
    fi

    if "${rebuild_cmd[@]}"; then
        log_ok "nixos rebuild completed."
    else
        log_err "nixos-rebuild failed."
        return 1
    fi
}

# verify required binaries, fonts, and symlinks
doctor_check() {
    log_step "running system diagnostics..."
    local -a missing_bins=()
    local -a missing_fonts=()
    local -a critical_bins=(
        hyprland uwsm matugen awww mpvpaper
        kitty zsh wl-copy brightnessctl playerctl
        python3 micro hyprpicker eza zoxide
        fzf bat rg fd
    )

    for b in "${critical_bins[@]}"; do
        if (( $+commands[$b] )); then
            print -P "  %F{120}󰄲%f $b: %F{244}$commands[$b]%f"
        else
            print -P "  %F{203}󰅚%f $b: %BMISSING%b"
            missing_bins+=( "$b" )
        fi
    done

    if (( $+commands[qs] || $+commands[quickshell] )); then
        local qs_bin="${commands[qs]:-$commands[quickshell]}"
        print -P "  %F{120}󰄲%f quickshell: %F{244}$qs_bin%f"
    else
        print -P "  %F{203}󰅚%f quickshell: %BMISSING%b"
        missing_bins+=( "quickshell" )
    fi

    print ""
    log_info "checking fonts..."
    local all_fonts=""
    if (( $+commands[fc-list] )); then
        all_fonts="$(fc-list : family 2>/dev/null || true)"
    fi

    local -A required_fonts=(
        "JetBrainsMono Nerd Font"   "JetBrainsMono"
        "Noto Sans"                 "Noto Sans"
        "Material Symbols Rounded"  "Material Symbols Rounded"
        "Material Symbols Outlined" "Material Symbols Outlined"
        "Material Symbols Sharp"    "Material Symbols Sharp"
        "Font Awesome 6 Free"       "Font Awesome 6 Free"
        "Segoe Fluent Icons"        "Segoe"
    )

    for label pattern in "${(@kv)required_fonts}"; do
        if [[ "$all_fonts" == *"$pattern"* ]]; then
            print -P "  %F{120}󰄲%f $label detected"
        else
            print -P "  %F{203}󰅚%f $label missing"
            missing_fonts+=( "$label" )
        fi
    done

    print ""
    log_info "checking config links..."
    for l in "${ALL_DOTFILES[@]}"; do
        local target="$CONFIG_DIR/$l"
        if [[ -L "$target" ]]; then
            local dest
            dest="$(readlink "$target")"
            if [[ "$dest" == /nix/store/* ]]; then
                print -P "  %F{221}󰄲%f $target -> %F{244}(nix store: $dest)%f"
            else
                print -P "  %F{120}󰄲%f $target -> %F{244}$dest%f"
            fi
        elif [[ -d "$target" ]]; then
            if [[ "$l" == "gtk-3.0" || "$l" == "gtk-4.0" ]]; then
                print -P "  %F{120}󰄲%f $target (synced directory)"
            else
                print -P "  %F{221}󰀦%f $target (unlinked physical directory)"
            fi
        else
            print -P "  %F{244}󰅚%f $target absent"
        fi
    done

    print ""
    local has_errors=false
    if (( ${#missing_bins} > 0 )); then
        log_warn "missing ${#missing_bins} packages: ${missing_bins[*]}"
        has_errors=true
    fi
    if (( ${#missing_fonts} > 0 )); then
        log_warn "missing ${#missing_fonts} fonts: ${missing_fonts[*]}"
        has_errors=true
    fi

    if [[ "$has_errors" == "true" ]]; then
        return 1
    fi

    log_ok "all core packages, fonts, and links verified."
    return 0
}

show_help() {
    print "usage: ./install.zsh [options]"
    print ""
    print "modes:"
    print "  -i, --interactive, -c, --custom  guided configuration wizard (default)"
    print "  -a, --all                        full sync (rebuild + backup + links + theme)"
    print "  -l, --links                      symlink dotfiles only"
    print "  -r, --rebuild                    run nixos-rebuild switch"
    print "  -u, --update                     git pull, relink configs, reload shell"
    print "      --doctor                     check system binaries, fonts, and links"
    print "      --reload                     reload hyprland and quickshell"
    print "      --fetch-wp                   fetch a random wallpaper from wallhaven"
    print "  -h, --help                       show this message"
    print ""
    print "flags:"
    print "  -n, --dry-run                    simulate actions without modifying files"
    print "  --backup                         force backup of unlinked directories"
    print "  --no-backup                      skip backup"
    print "  --dots=<d1,d2,...>               link specific dotfiles"
    print "  --no-theme                       skip wallpaper and matugen step"
    print "  --no-reload                      skip compositor and shell reload"
}

main() {
    if (( EUID == 0 )); then
        log_err "do not run this script as root. run it as your regular user."
        exit 1
    fi

    local opt_mode="menu"
    local opt_backup=""
    local opt_theme=true
    local opt_reload=true
    local -a opt_dots=()

    while (( $# > 0 )); do
        case "$1" in
            -a|--all)                     opt_mode="all"; shift ;;
            -u|--update)                  opt_mode="update"; shift ;;
            -l|--links)                   opt_mode="links"; shift ;;
            -r|--rebuild)                 opt_mode="rebuild"; shift ;;
            -i|--interactive|-c|--custom) opt_mode="custom"; shift ;;
            --doctor|--check)             opt_mode="doctor"; shift ;;
            --reload)                     opt_mode="reload"; shift ;;
            --fetch-wp)                   FETCH_WP=true; [[ "$opt_mode" == "menu" ]] && opt_mode="fetch_wp"; shift ;;
            -n|--dry-run)                 DRY_RUN=true; shift ;;
            --backup)                     opt_backup=true; shift ;;
            --no-backup)                  opt_backup=false; shift ;;
            --no-theme)                   opt_theme=false; shift ;;
            --no-reload)                  opt_reload=false; shift ;;
            --dots=*)
                local val="${1#*=}"
                opt_dots=( ${(s:,:)val} )
                shift
                ;;
            -h|--help)                    show_help; exit 0 ;;
            *)
                log_err "unrecognized option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    print -P "%F{141}󰄛 quickshell dotfiles installer%f"
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warn "dry-run mode enabled. filesystem will not be modified."
    fi
    verify_nixos

    if [[ "$opt_mode" == "menu" ]]; then
        print ""
        print "select an action:"
        print "  1) 󰚰 custom wizard (pick dotfiles, backups, symlinks)"
        print "  2) 󰏤 full sync (nixos-rebuild + backup + symlinks + theme)"
        print "  3) 󰌢 symlink dotfiles only"
        print "  4) 󰏖 rebuild nixos"
        print "  5) 󰑐 update dotfiles (git pull + sync + reload)"
        print "  6) 󰄲 doctor diagnostic check"
        print "  7) 󰁕 reload hyprland & quickshell"
        print "  8) 󰋩 fetch wallhaven wallpaper & apply theme"
        print "  9) 󰅚 quit"
        print -Pn "choice [1-9, default 1]: "

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
            8) opt_mode="fetch_wp" ;;
            9|q|Q) print "aborting."; exit 0 ;;
            *) log_warn "invalid input. defaulting to custom wizard."; opt_mode="custom" ;;
        esac
    fi

    case "$opt_mode" in
        doctor)
            doctor_check
            ;;
        reload)
            reload_shell
            ;;
        rebuild)
            rebuild_nixos || true
            ;;
        update)
            log_step "updating repository..."
            if [[ -d "$DOTS_DIR/.git" ]]; then
                execute git -C "$DOTS_DIR" pull --rebase || log_warn "git pull failed or had conflicts."
            fi
            setup_directories_and_permissions
            link_selected_configurations "${ALL_DOTFILES[@]}"
            if [[ "$opt_theme" == "true" ]]; then initial_theming; fi
            if [[ "$opt_reload" == "true" ]]; then reload_shell; fi
            log_ok "update finished."
            ;;
        fetch_wp)
            setup_directories_and_permissions
            FETCH_WP=true
            initial_theming
            if [[ "$opt_reload" == "true" ]]; then reload_shell; fi
            ;;
        custom)
            log_step "interactive configuration wizard"

            if ask_yn "run nixos rebuild first?" "N"; then
                rebuild_nixos || log_warn "rebuild failed. continuing wizard."
            fi

            if [[ -z "$opt_backup" ]]; then
                if ask_yn "backup unlinked folders in ~/.config?" "Y"; then
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
                local chosen_raw
                chosen_raw=$(select_multi "select config targets" "${ALL_DOTFILES[@]}")
                if [[ -n "$chosen_raw" ]]; then
                    opt_dots=( ${(f)chosen_raw} )
                fi
            fi

            if ask_yn "generate matugen palette from wallpaper?" "Y"; then
                opt_theme=true
                if ask_yn "fetch a new random wallpaper from wallhaven?" "N"; then
                    FETCH_WP=true
                fi
            else
                opt_theme=false
            fi

            if ask_yn "reload hyprland & quickshell when done?" "Y"; then
                opt_reload=true
            else
                opt_reload=false
            fi

            setup_directories_and_permissions

            if [[ "$opt_backup" == "true" ]]; then
                backup_selected "${opt_dots[@]}"
            fi

            if [[ "$do_links" == "true" ]] && (( ${#opt_dots} > 0 )); then
                link_selected_configurations "${opt_dots[@]}"
            fi

            if [[ "$opt_theme" == "true" ]]; then initial_theming; fi
            if [[ "$opt_reload" == "true" ]]; then reload_shell; fi
            ;;
        all)
            setup_directories_and_permissions
            rebuild_nixos || log_warn "rebuild failed. continuing setup."
            if [[ "$opt_backup" != "false" ]]; then
                backup_selected "${ALL_DOTFILES[@]}"
            fi
            link_selected_configurations "${ALL_DOTFILES[@]}"
            if [[ "$opt_theme" == "true" ]]; then initial_theming; fi
            if [[ "$opt_reload" == "true" ]]; then reload_shell; fi
            ;;
        links)
            setup_directories_and_permissions
            if (( ${#opt_dots} == 0 )); then
                local chosen_raw
                chosen_raw=$(select_multi "select config targets" "${ALL_DOTFILES[@]}")
                if [[ -n "$chosen_raw" ]]; then
                    opt_dots=( ${(f)chosen_raw} )
                else
                    opt_dots=( "${ALL_DOTFILES[@]}" )
                fi
            fi
            if [[ "$opt_backup" == "true" ]]; then
                backup_selected "${opt_dots[@]}"
            fi
            link_selected_configurations "${opt_dots[@]}"
            if [[ "$opt_theme" == "true" ]]; then initial_theming; fi
            if [[ "$opt_reload" == "true" ]]; then reload_shell; fi
            ;;
    esac

    print ""
    log_ok "all tasks complete."
}

main "$@"
