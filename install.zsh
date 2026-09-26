#!/usr/bin/env zsh
# your desktop is currently an unconfigured microwave. let me do it for you.
setopt ERR_EXIT NO_UNSET PIPE_FAIL EXTENDED_GLOB

# trap interruptions gracefully
trap 'print -P "\n%F{203}󰅚 aborted by user. nothing caught fire.%f"; exit 130' INT TERM

# --- Constants & State ---
DOTS_DIR="${0:A:h}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
WALLPAPER_DIR="$HOME/.wallpapers"
BACKUP_DIR="$CACHE_DIR/dotfiles-backups"

DRY_RUN=false

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

# --- Visual Helpers ---
log_info() { print -P "%F{141}󰄛%f $1" }
log_ok()   { print -P "%F{120}󰄲%f $1" }
log_warn() { print -P "%F{221}󰀦%f $1" }
log_err()  { print -P "%F{203}󰅚%f $1" }
log_step() { print -P "\n%F{117}󰁕%f %B$1%b" }
log_dry()  { print -P "%F{244}[dry-run]%f %F{141}$1%f" }

# Dry-run execution runner
execute() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "$*"
        return 0
    fi
    "$@"
}

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

fetch_wallhaven_wallpaper() {
    log_step "wallpaper acquisition from wallhaven (waifu preferences ignored)..."
    execute mkdir -p "$WALLPAPER_DIR"/{live,downloaded,wallhaven}

    local wh_dir="$WALLPAPER_DIR/wallhaven"
    local target_file=""

    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "query wallhaven api -> download random wallpaper to $wh_dir"
        print "$wh_dir/dry_run_wallpaper.png"
        return 0
    fi

    log_info "querying wallhaven api for random wallpaper (categories=111, purity=100)..."

    local api_url="https://wallhaven.cc/api/v1/search?sorting=random&categories=111&purity=100"
    local json_payload=""

    if (( $+commands[curl] )); then
        json_payload=$(curl -fsSL --connect-timeout 8 "$api_url" 2>/dev/null || true)
    elif (( $+commands[wget] )); then
        json_payload=$(wget -q --timeout=8 -O - "$api_url" 2>/dev/null || true)
    fi

    local img_url=""
    if [[ -n "$json_payload" ]]; then
        if (( $+commands[python3] )); then
            img_url=$(print -r -- "$json_payload" | python3 -c '
import sys, json
try:
    data = json.load(sys.stdin).get("data", [])
    if data and len(data) > 0:
        print(data[0].get("path", ""))
except Exception:
    pass
' 2>/dev/null || true)
        elif (( $+commands[jq] )); then
            img_url=$(print -r -- "$json_payload" | jq -r '.data[0].path // empty' 2>/dev/null || true)
        fi
    fi

    if [[ -n "$img_url" && "$img_url" == http* ]]; then
        local img_name="${img_url:t}"
        target_file="$wh_dir/$img_name"

        if [[ -f "$target_file" && -s "$target_file" ]]; then
            log_ok "wallhaven wallpaper already cached -> $target_file"
            print -r "$target_file"
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
            log_ok "captured random wallpaper from wallhaven: $img_name (waifu preferences successfully ignored)"
            print -r "$target_file"
            return 0
        fi
    fi

    log_warn "wallhaven api choked, unreachable, or rate-limited. attempting emergency fallback..."

    # Check if we already have any image in $WALLPAPER_DIR
    local cached=( "$WALLPAPER_DIR"/**/*.(png|jpg|jpeg|webp)(N.) )
    if (( ${#cached} )); then
        log_info "using existing cached wallpaper -> ${cached[1]}"
        print -r "${cached[1]}"
        return 0
    fi

    # Fallback to static catppuccin download
    local fallback_file="$WALLPAPER_DIR/downloaded/catppuccin_evening_sky.png"
    local fallback_source="https://raw.githubusercontent.com/catppuccin/wallpapers/main/landscapes/evening-sky.png"
    if (( $+commands[curl] )); then
        curl -fsSL --connect-timeout 6 "$fallback_source" -o "$fallback_file" 2>/dev/null || true
    elif (( $+commands[wget] )); then
        wget -q --timeout=6 -O "$fallback_file" "$fallback_source" 2>/dev/null || true
    fi

    if [[ -s "$fallback_file" ]]; then
        log_ok "emergency fallback wallpaper saved -> $fallback_file"
        print -r "$fallback_file"
        return 0
    fi

    log_err "failed to acquire any wallpaper. enjoy the existential void."
    return 1
}

fetch_curated_wallpaper() {
    fetch_wallhaven_wallpaper "$@"
}

# Returns selected items separated by newlines
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

    # Output newline-separated elements
    if (( ${#chosen} )); then
        print -l "${chosen[@]}"
    fi
}

backup_selected() {
    local -a targets=( "$@" )
    if (( ${#targets} == 0 )); then
        targets=( "${ALL_DOTFILES[@]}" )
    fi

    log_info "inspecting $CONFIG_DIR for unmanaged files to preserve..."
    execute mkdir -p "$BACKUP_DIR"
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local target_archive="$BACKUP_DIR/backup_${timestamp}.tar.gz"

    local existing_targets=()
    for t in "${targets[@]}"; do
        # Only backup real files/dirs, not symlinks (especially not nix-store links)
        if [[ -e "$CONFIG_DIR/$t" && ! -L "$CONFIG_DIR/$t" ]]; then
            existing_targets+=( "$t" )
        fi
    done

    if (( ${#existing_targets} )); then
        if [[ "$DRY_RUN" == "true" ]]; then
            log_dry "tar -czf $target_archive -C $CONFIG_DIR ${existing_targets[*]}"
        else
            tar -czf "$target_archive" -C "$CONFIG_DIR" "${existing_targets[@]}" 2>/dev/null || true
            log_ok "archived ${#existing_targets} folder(s) -> $target_archive"
        fi
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
    execute mkdir -p "$CONFIG_DIR"

    for folder in "${targets[@]}"; do
        local src="$DOTS_DIR/$folder"
        local target="$CONFIG_DIR/$folder"

        if [[ ! -d "$src" ]]; then
            log_warn "source missing for $folder in $DOTS_DIR. skipping."
            continue
        fi

        # Check if target is a Nix Store symlink (Home Manager or NixOS managed)
        if [[ -L "$target" ]]; then
            local current_dest
            current_dest=$(readlink -f "$target" 2>/dev/null || true)
            if [[ "$current_dest" == /nix/store/* ]]; then
                log_warn "$target is managed by Home Manager or NixOS (/nix/store)."
                if ! ask_yn "Force replace Nix-managed symlink for $folder?" "N"; then
                    log_info "skipping $folder to prevent collision."
                    continue
                fi
            fi
        fi

        # Flatpak sandbox containment: sync directory rather than symlink
        if [[ "$folder" == "gtk-3.0" || "$folder" == "gtk-4.0" ]]; then
            execute rm -rf "$target"
            execute mkdir -p "$target"
            if (( $+commands[rsync] )); then
                execute rsync -a --delete "$src/" "$target/"
            else
                execute cp -rf "$src"/. "$target/"
            fi
            if [[ -f "$target/bookmarks" ]]; then
                execute sed -i "s|/home/ashley|$HOME|g" "$target/bookmarks" 2>/dev/null || true
            fi
            log_ok "synced $folder as real directory (flatpak containment)"
            continue
        fi

        # If symlink already points to source, skip
        if [[ -L "$target" && "$target:A" == "$src:A" ]]; then
            log_ok "$folder already pointed to repo."
            continue
        fi

        if [[ -L "$target" ]]; then
            execute rm -f "$target"
        elif [[ -d "$target" ]]; then
            local backup="${target}.stale.$(date +%s)"
            log_warn "moving old physical directory $target -> $backup"
            execute mv "$target" "$backup"
        fi

        execute ln -sfn "$src" "$target"
        log_ok "linked $folder -> $target"
    done

    # Handle ~/.zshrc integration safely
    if [[ " ${targets[*]} " == *" zsh "* && -f "$DOTS_DIR/zsh/sources.zsh" ]]; then
        local zshrc="$HOME/.zshrc"
        local source_line="[[ -f \"$CONFIG_DIR/zsh/sources.zsh\" ]] && source \"$CONFIG_DIR/zsh/sources.zsh\""

        if [[ -L "$zshrc" ]]; then
            local zshrc_target
            zshrc_target=$(readlink -f "$zshrc" 2>/dev/null || true)
            if [[ "$zshrc_target" == /nix/store/* ]]; then
                log_warn "~/.zshrc is a read-only Nix store symlink. Cannot append safely."
                log_info "Add this manually to your home-manager or configuration.nix zsh config:"
                print -P "      %F{117}$source_line%f"
                return 0
            fi
        fi

        if [[ "$DRY_RUN" == "true" ]]; then
            log_dry "append hook to $zshrc"
        else
            execute touch "$zshrc"
            if ! grep -qs "sources\.zsh" "$zshrc" 2>/dev/null; then
                print -r "\n# dotfiles master hook\n$source_line" >> "$zshrc"
                log_ok "hooked ~/.zshrc into $CONFIG_DIR/zsh/sources.zsh"
            fi
        fi
    fi
}

setup_directories_and_permissions() {
    log_info "allocating runtime and cache paths..."
    execute mkdir -p "$WALLPAPER_DIR"/{live,downloaded,wallhaven}
    execute mkdir -p "$CACHE_DIR"/quickshell/{thumbnails,wallpapers}
    execute mkdir -p "$CACHE_DIR/zsh"
    execute mkdir -p "$DATA_DIR"/{quickshell/scratch,quicknav/marks,fonts}
    execute mkdir -p "$HOME/.local/bin" "$HOME/.local/state/quickshell" "$CONFIG_DIR/nvim/lua/config"
    execute mkdir -p "$BACKUP_DIR"

    # install qs-switch helper into ~/.local/bin
    if [[ -f "$DOTS_DIR/quickshell/scripts/qs-switch" ]]; then
        execute cp -f "$DOTS_DIR/quickshell/scripts/qs-switch" "$HOME/.local/bin/qs-switch"
        execute chmod +x "$HOME/.local/bin/qs-switch"
        log_ok "installed qs-switch helper into ~/.local/bin/qs-switch"
    fi

    # ensure icon fonts in ~/.local/share/fonts for nixos
    local font_dir="$DATA_DIR/fonts"
    if [[ ! -f "$font_dir/MaterialSymbolsRounded.ttf" ]]; then
        log_info "fetching Material Symbols Rounded to ~/.local/share/fonts..."
        curl -sL "https://raw.githubusercontent.com/google/material-design-icons/master/variablefont/MaterialSymbolsRounded%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf" -o "$font_dir/MaterialSymbolsRounded.ttf" 2>/dev/null || true
    fi
    if [[ ! -f "$font_dir/MaterialSymbolsOutlined.ttf" ]]; then
        curl -sL "https://raw.githubusercontent.com/google/material-design-icons/master/variablefont/MaterialSymbolsOutlined%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf" -o "$font_dir/MaterialSymbolsOutlined.ttf" 2>/dev/null || true
    fi
    if [[ ! -f "$font_dir/MaterialSymbolsSharp.ttf" ]]; then
        curl -sL "https://raw.githubusercontent.com/google/material-design-icons/master/variablefont/MaterialSymbolsSharp%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf" -o "$font_dir/MaterialSymbolsSharp.ttf" 2>/dev/null || true
    fi
    if [[ ! -f "$font_dir/FontAwesome6Free-Solid.otf" ]]; then
        curl -sL "https://raw.githubusercontent.com/FortAwesome/Font-Awesome/6.x/webfonts/fa-solid-900.ttf" -o "$font_dir/FontAwesome6Free-Solid.otf" 2>/dev/null || true
    fi
    if [[ ! -f "$font_dir/FontAwesome6Free-Regular.otf" ]]; then
        curl -sL "https://raw.githubusercontent.com/FortAwesome/Font-Awesome/6.x/webfonts/fa-regular-400.ttf" -o "$font_dir/FontAwesome6Free-Regular.otf" 2>/dev/null || true
    fi
    if [[ ! -f "$font_dir/SegoeIcons.ttf" ]]; then
        curl -sL "https://github.com/bdlukaa/fluent_ui/raw/master/fonts/SegoeIcons.ttf" -o "$font_dir/SegoeIcons.ttf" 2>/dev/null || true
    fi
    if (( $+commands[fc-cache] )); then
        fc-cache -f "$font_dir" >/dev/null 2>&1 || true
    fi

    # Only mark executable if dotfiles directory is writable
    if [[ -w "$DOTS_DIR" ]]; then
        log_info "marking shell scripts executable..."
        local script_targets=(
            "$DOTS_DIR"/quickshell/scripts/*.(sh|py)(N.)
            "$DOTS_DIR"/quickshell/scripts/qs-switch(N.)
            "$DOTS_DIR"/matugen/post-hook-scripts/*.(zsh|sh)(N.)
            "$DOTS_DIR"/install.zsh(N.)
        )

        if (( ${#script_targets} )); then
            execute chmod +x "${script_targets[@]}"
            log_ok "chmod +x applied to ${#script_targets} helper scripts."
        fi
    fi
}

initial_theming() {
    log_step "commencing desktop initialization ritual..."

    # 1. Directory sanitation & preparation
    execute mkdir -p "$WALLPAPER_DIR"/{live,downloaded,wallhaven}
    execute mkdir -p "$CONFIG_DIR"/nvim/lua/config
    execute mkdir -p "$HOME/.local/state/quickshell"
    execute mkdir -p "$CACHE_DIR"/quickshell/{thumbnails,wallpapers}

    if [[ -d "$DOTS_DIR/wallpapers" ]]; then
        local repo_wps=( "$DOTS_DIR"/wallpapers/*.(png|jpg|jpeg|webp)(N.) )
        if (( ${#repo_wps} )); then
            execute cp -n "${repo_wps[@]}" "$WALLPAPER_DIR/" 2>/dev/null || true
        fi
    fi

    local target_wp=""
    local existing_wps=( "$WALLPAPER_DIR"/**/*.(png|jpg|jpeg|webp)(N.) )

    # If --fetch-wp or no wallpapers exist, pull from Wallhaven
    if [[ "$opt_fetch_wp" == "true" || ${#existing_wps} -eq 0 ]]; then
        target_wp="$(fetch_wallhaven_wallpaper)" || true
        target_wp="${target_wp##*$'\n'}"
    else
        target_wp="${existing_wps[1]}"
    fi

    if [[ -z "$target_wp" || ! -f "$target_wp" ]]; then
        local any_wps=( "$WALLPAPER_DIR"/**/*.(png|jpg|jpeg|webp)(N.) )
        if (( ${#any_wps} )); then
            target_wp="${any_wps[1]}"
        fi
    fi

    if [[ -z "$target_wp" || ! -f "$target_wp" ]]; then
        log_warn "no valid wallpaper located in $WALLPAPER_DIR. skipping theme ritual."
        return 1
    fi

    log_info "active ritual wallpaper -> $target_wp"

    # 2. Update Quickshell runtime markers and settings
    execute mkdir -p "${XDG_RUNTIME_DIR:-/run/user/$EUID}"
    if [[ "$DRY_RUN" != "true" ]]; then
        print -r "$target_wp" > "/tmp/qs_current_wallpaper.txt" 2>/dev/null || true
        print -r "$target_wp" > "${XDG_RUNTIME_DIR:-/run/user/$EUID}/qs_current_wallpaper.txt" 2>/dev/null || true
    fi

    # Update settings.conf in state and config so Quickshell boots with the wallpaper
    local conf_targets=(
        "$HOME/.local/state/quickshell/settings.conf"
        "$CONFIG_DIR/quickshell/settings.conf"
    )
    for cf in "${conf_targets[@]}"; do
        if [[ -f "$cf" ]]; then
            if grep -qs "^currentWallpaper=" "$cf"; then
                execute sed -i "s|^currentWallpaper=.*|currentWallpaper=\"$target_wp\"|" "$cf" 2>/dev/null || true
            else
                print "currentWallpaper=\"$target_wp\"" >> "$cf" 2>/dev/null || true
            fi
        else
            execute mkdir -p "${cf:h}"
            print "currentWallpaper=\"$target_wp\"" > "$cf" 2>/dev/null || true
        fi
    done

    # 3. Matugen dynamic palette generation
    if (( $+commands[matugen] )); then
        log_info "generating material palette tokens via matugen..."
        execute matugen image "$target_wp" -m "dark" -t "scheme-tonal-spot" --source-color-index 0
        log_ok "matugen dynamic scheme propagated across hyprland, quickshell, gtk, and kitty."
    else
        log_warn "matugen missing. declare it in configuration.nix or enjoy unstyled chaos."
    fi

    # 4. Trigger wallpaper indexer so Quickshell WallpaperBrowser is pre-populated
    if [[ -f "$DOTS_DIR/quickshell/scripts/wallpaper.py" ]] && (( $+commands[python3] )); then
        log_info "indexing ~/.wallpapers gallery into cache..."
        execute python3 "$DOTS_DIR/quickshell/scripts/wallpaper.py" scan >/dev/null 2>&1 || true
        log_ok "wallpaper gallery indexed into /tmp/qs_wallpapers.json."
    fi

    # 5. If running inside active Wayland session, apply wallpaper live to screen via awww
    if [[ -n "${WAYLAND_DISPLAY:-}" || -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        if (( $+commands[awww] )); then
            log_info "arming awww daemon and casting wallpaper to display..."
            if ! awww query >/dev/null 2>&1; then
                execute awww-daemon --format argb >/dev/null 2>&1 &!
                sleep 0.5
            fi
            execute awww img "$target_wp" --transition-type wipe --transition-step 90 --transition-duration 2 >/dev/null 2>&1 || true
            log_ok "wallpaper deployed to display outputs."
        fi
    fi
}

reload_shell() {
    log_step "restarting window manager environment..."

    if [[ -z "${WAYLAND_DISPLAY:-}" && -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        log_info "no active wayland compositor detected. skipping hyprctl & quickshell reload."
        return 0
    fi

    if (( $+commands[hyprctl] )) && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        execute hyprctl reload >/dev/null 2>&1 || true
        log_ok "hyprland config reloaded."
    fi

    if (( $+commands[uwsm] )); then
        log_info "delegating quickshell daemon reload to uwsm..."
        execute uwsm app -- qs kill >/dev/null 2>&1 || pkill -x qs 2>/dev/null || true
        sleep 0.3
        execute uwsm app -- qs -d >/dev/null 2>&1 &!
        log_ok "quickshell daemon reloaded (uwsm app -- qs -d)."
    elif (( $+commands[qs] )); then
        execute qs kill >/dev/null 2>&1 || pkill -x qs 2>/dev/null || true
        sleep 0.3
        execute qs -d >/dev/null 2>&1 &!
        log_ok "quickshell daemon reloaded."
    fi
}

rebuild_nixos() {
    log_step "triggering declarative nixos rebuild..."
    if ! (( $+commands[nixos-rebuild] )); then
        log_err "nixos-rebuild not found. are you really on nixos?"
        return 1
    fi

    local rebuild_cmd=( sudo nixos-rebuild switch )

    # Auto-detect Flake setup
    if [[ -f "$DOTS_DIR/flake.nix" ]]; then
        local host="${HOST:-$(hostname 2>/dev/null || true)}"
        log_info "detected flake in $DOTS_DIR (target host: ${host:-default})"
        rebuild_cmd=( sudo nixos-rebuild switch --flake "$DOTS_DIR#${host}" )
    elif [[ -f /etc/nixos/flake.nix ]]; then
        log_info "detected flake in /etc/nixos"
        rebuild_cmd=( sudo nixos-rebuild switch --flake /etc/nixos )
    elif [[ -f /etc/nixos/configuration.nix ]]; then
        log_info "detected standard channels configuration (/etc/nixos/configuration.nix)"
    else
        log_warn "neither flake.nix nor /etc/nixos/configuration.nix identified."
    fi

    log_info "executing: ${rebuild_cmd[*]}"
    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "${rebuild_cmd[*]}"
        return 0
    fi

    if "${rebuild_cmd[@]}"; then
        log_ok "nixos generation built and switched successfully."
    else
        log_err "nixos-rebuild failed. inspect syntax or sudo credentials above."
        return 1
    fi
}

doctor_check() {
    log_step "nixos system diagnostics & binary verification..."
    local missing_bins=()
    local missing_fonts=()
    local critical_bins=(
        "hyprland" "uwsm" "matugen" "awww" "mpvpaper"
        "kitty" "zsh" "wl-copy" "brightnessctl" "playerctl"
        "python3" "micro" "hyprpicker" "eza" "zoxide"
        "fzf" "bat" "rg" "fd"
    )

    for b in "${critical_bins[@]}"; do
        if (( $+commands[$b] )); then
            print -P "  %F{120}󰄲%f $b found: %F{244}$commands[$b]%f"
        else
            print -P "  %F{203}󰅚%f $b: %BMISSING in nix environment%b"
            missing_bins+=( "$b" )
        fi
    done

    if (( $+commands[qs] || $+commands[quickshell] )); then
        local qs_bin="${commands[qs]:-$commands[quickshell]}"
        print -P "  %F{120}󰄲%f quickshell found: %F{244}$qs_bin%f"
    else
        print -P "  %F{203}󰅚%f quickshell: %BMISSING in nix environment%b"
        missing_bins+=( "quickshell" )
    fi

    print ""
    log_info "checking typography..."
    local all_fonts=""
    if (( $+commands[fc-list] )); then
        all_fonts="$(fc-list : family 2>/dev/null || true)"
    fi

    # 1. JetBrainsMono Nerd Font (NixOS fonts.packages or local share)
    if [[ "$all_fonts" == *JetBrainsMono* || -s "$DATA_DIR/fonts/JetBrainsMono"* || -s "$DATA_DIR/fonts/JetBrains Mono"* ]]; then
        print -P "  %F{120}󰄲%f JetBrainsMono Nerd Font detected"
    else
        print -P "  %F{203}󰅚%f JetBrainsMono Nerd Font missing (check fonts.packages or ~/.local/share/fonts)"
        missing_fonts+=( "JetBrainsMono Nerd Font" )
    fi

    # 2. Noto Sans (NixOS fonts.packages or local share)
    if [[ "$all_fonts" == *"Noto Sans"* || -s "$DATA_DIR/fonts/NotoSans"* || -s "$DATA_DIR/fonts/Noto Sans"* ]]; then
        print -P "  %F{120}󰄲%f Noto Sans detected"
    else
        print -P "  %F{203}󰅚%f Noto Sans missing (check fonts.packages or ~/.local/share/fonts)"
        missing_fonts+=( "Noto Sans" )
    fi

    # 3. Material Symbols Rounded
    if [[ "$all_fonts" == *"Material Symbols Rounded"* || -s "$DATA_DIR/fonts/MaterialSymbolsRounded.ttf" ]]; then
        print -P "  %F{120}󰄲%f Material Symbols Rounded detected in local share"
    else
        print -P "  %F{203}󰅚%f Material Symbols Rounded missing in ~/.local/share/fonts"
        missing_fonts+=( "Material Symbols Rounded" )
    fi

    # 4. Material Symbols Outlined
    if [[ "$all_fonts" == *"Material Symbols Outlined"* || -s "$DATA_DIR/fonts/MaterialSymbolsOutlined.ttf" ]]; then
        print -P "  %F{120}󰄲%f Material Symbols Outlined detected in local share"
    else
        print -P "  %F{203}󰅚%f Material Symbols Outlined missing in ~/.local/share/fonts"
        missing_fonts+=( "Material Symbols Outlined" )
    fi

    # 5. Material Symbols Sharp
    if [[ "$all_fonts" == *"Material Symbols Sharp"* || -s "$DATA_DIR/fonts/MaterialSymbolsSharp.ttf" ]]; then
        print -P "  %F{120}󰄲%f Material Symbols Sharp detected in local share"
    else
        print -P "  %F{203}󰅚%f Material Symbols Sharp missing in ~/.local/share/fonts"
        missing_fonts+=( "Material Symbols Sharp" )
    fi

    # 6. Font Awesome 6 Free Solid
    if [[ "$all_fonts" == *"Font Awesome 6 Free Solid"* || "$all_fonts" == *"Font Awesome 6 Free"*Solid* || -s "$DATA_DIR/fonts/FontAwesome6Free-Solid.otf" ]]; then
        print -P "  %F{120}󰄲%f Font Awesome 6 Free Solid detected in local share"
    else
        print -P "  %F{203}󰅚%f Font Awesome 6 Free Solid missing in ~/.local/share/fonts"
        missing_fonts+=( "Font Awesome 6 Free Solid" )
    fi

    # 7. Font Awesome 6 Free Regular
    if [[ "$all_fonts" == *"Font Awesome 6 Free Regular"* || "$all_fonts" == *"Font Awesome 6 Free"*Regular* || -s "$DATA_DIR/fonts/FontAwesome6Free-Regular.otf" ]]; then
        print -P "  %F{120}󰄲%f Font Awesome 6 Free Regular detected in local share"
    else
        print -P "  %F{203}󰅚%f Font Awesome 6 Free Regular missing in ~/.local/share/fonts"
        missing_fonts+=( "Font Awesome 6 Free Regular" )
    fi

    # 8. Segoe Fluent Icons
    if [[ "$all_fonts" == *"Segoe Fluent Icons"* || "$all_fonts" == *"Segoe"* || -s "$DATA_DIR/fonts/SegoeIcons.ttf" ]]; then
        print -P "  %F{120}󰄲%f Segoe Fluent Icons detected in local share"
    else
        print -P "  %F{203}󰅚%f Segoe Fluent Icons missing in ~/.local/share/fonts"
        missing_fonts+=( "Segoe Fluent Icons" )
    fi

    print ""
    log_info "validating config links..."
    for l in "${ALL_DOTFILES[@]}"; do
        local target="$CONFIG_DIR/$l"
        if [[ -L "$target" ]]; then
            local dest=""
            dest="$(readlink "$target")"
            if [[ "$dest" == /nix/store/* ]]; then
                print -P "  %F{221}󰄲%f $target -> %F{244}(Nix Store: $dest)%f"
            else
                print -P "  %F{120}󰄲%f $target -> %F{244}$dest%f"
            fi
        elif [[ -d "$target" ]]; then
            if [[ "$l" == "gtk-3.0" || "$l" == "gtk-4.0" ]]; then
                print -P "  %F{120}󰄲%f $target synced directory (flatpak containment)"
            else
                print -P "  %F{221}󰀦%f $target exists as real unlinked directory"
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
        log_warn "missing ${#missing_fonts} essential fonts: ${missing_fonts[*]}"
        has_errors=true
    fi

    if [[ "$has_errors" == "true" ]]; then
        return 1
    else
        log_ok "all core tools, uwsm session harness, and fonts verified."
        return 0
    fi
}

show_help() {
    print "usage: ./install.zsh [options]"
    print ""
    print "modes:"
    print "  -i, --interactive, -c, --custom  guided configuration wizard (default)"
    print "  -a, --all                        full sync (rebuild + backup + links + theme)"
    print "  -l, --links                      symlink dotfiles only"
    print "  -r, --rebuild                    run nixos-rebuild switch"
    print "  -u, --update                     git pull, relink configs, reload hyprland"
    print "      --doctor                     run health check and list missing packages"
    print "      --reload                     reload hyprland and quickshell via uwsm"
    print "      --fetch-wp                   fetch a random wallpaper from wallhaven"
    print "  -h, --help                       show this message"
    print ""
    print "granular flags:"
    print "  -n, --dry-run                    simulate actions without altering filesystem"
    print "  --backup                         force backup of unlinked directories"
    print "  --no-backup                      skip backup entirely"
    print "  --dots=<d1,d2,...>               link specific dotfiles"
    print "  --no-theme                       skip wallpaper color sampling"
    print "  --no-reload                      do not touch running compositors"
}

# --- Main Entry Point ---
main() {
    if (( EUID == 0 )); then
        print -P "%F{203}󰅚 running this as root? who hurt you? step away from the keyboard before you chmod your entire life into 000.%f"
        print -P "%F{244}run it as your regular user. uwsm and nixos will not save you from self-sabotage.%f"
        exit 1
    fi

    local opt_mode="menu"
    local opt_backup=""
    local opt_theme=true
    local opt_reload=true
    local opt_fetch_wp=false
    local -a opt_dots=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -a|--all)               opt_mode="all"; shift ;;
            -u|--update)            opt_mode="update"; shift ;;
            -l|--links)             opt_mode="links"; shift ;;
            -r|--rebuild)           opt_mode="rebuild"; shift ;;
            -i|--interactive|-c|--custom) opt_mode="custom"; shift ;;
            --doctor|--check)       opt_mode="doctor"; shift ;;
            --reload)               opt_mode="reload"; shift ;;
            --fetch-wp)             opt_fetch_wp=true; [[ "$opt_mode" == "menu" ]] && opt_mode="fetch_wp"; shift ;;
            -n|--dry-run)           DRY_RUN=true; shift ;;
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
    [[ "$DRY_RUN" == "true" ]] && log_warn "DRY-RUN MODE ENGAGED. Filesystem will remain untouched."
    verify_nixos

    if [[ "$opt_mode" == "menu" ]]; then
        print ""
        print "choose an action before i lose what is left of my patience:"
        print "  1) 󰚰 custom wizard (pick dotfiles, backups, symlinks)"
        print "  2) 󰏤 full sync (nixos-rebuild + backup + symlinks + palette)"
        print "  3) 󰌢 symlink dotfiles only"
        print "  4) 󰏖 rebuild nixos (auto-detected flake or channel)"
        print "  5) 󰑐 update dotfiles (git pull + sync + reload)"
        print "  6) 󰄲 doctor diagnostic scan"
        print "  7) 󰁕 reload compositors & quickshell"
        print "  8) 󰋩 fetch wallhaven wallpaper & execute theme ritual"
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
            *) log_warn "invalid input. falling back to wizard."; opt_mode="custom" ;;
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
            log_step "syncing repository..."
            if [[ -d "$DOTS_DIR/.git" ]]; then
                execute git -C "$DOTS_DIR" pull --rebase || log_warn "merge conflict detected."
            fi
            setup_directories_and_permissions
            link_selected_configurations "${ALL_DOTFILES[@]}"
            [[ "$opt_theme" == "true" ]] && initial_theming
            [[ "$opt_reload" == "true" ]] && reload_shell
            log_ok "update finished."
            ;;
        fetch_wp)
            setup_directories_and_permissions
            opt_fetch_wp=true
            initial_theming
            [[ "$opt_reload" == "true" ]] && reload_shell
            ;;
        custom)
            log_step "interactive nixos dotfiles wizard"

            if ask_yn "run nixos rebuild first?" "N"; then
                rebuild_nixos || log_warn "rebuild returned non-zero. continuing wizard anyway."
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
                local chosen_raw
                chosen_raw=$(select_multi "select config targets" "${ALL_DOTFILES[@]}")
                if [[ -n "$chosen_raw" ]]; then
                    opt_dots=( ${(f)chosen_raw} )
                fi
            fi

            if ask_yn "run wallpaper seed & matugen dynamic palette generation?" "Y"; then
                opt_theme=true
                if ask_yn "fetch fresh random wallpaper from wallhaven (waifu preferences ignored)?" "N"; then
                    opt_fetch_wp=true
                fi
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

            [[ "$opt_theme" == "true" ]] && initial_theming
            [[ "$opt_reload" == "true" ]] && reload_shell
            ;;
        all)
            setup_directories_and_permissions
            rebuild_nixos || log_warn "rebuild failed. continuing setup."
            [[ "$opt_backup" != "false" ]] && backup_selected "${ALL_DOTFILES[@]}"
            link_selected_configurations "${ALL_DOTFILES[@]}"
            [[ "$opt_theme" == "true" ]] && initial_theming
            [[ "$opt_reload" == "true" ]] && reload_shell
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
            [[ "$opt_backup" == "true" ]] && backup_selected "${opt_dots[@]}"
            link_selected_configurations "${opt_dots[@]}"
            [[ "$opt_theme" == "true" ]] && initial_theming
            [[ "$opt_reload" == "true" ]] && reload_shell
            ;;
    esac

    print ""
    log_ok "process complete. nixos declarative packages & dotfiles unified."
}

main "$@"
