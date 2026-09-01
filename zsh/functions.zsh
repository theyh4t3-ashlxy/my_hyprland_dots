# interactive functions & chaos helpers

take() {
    if [[ -z "$1" ]]; then
        echo "take what?"
        return 1
    fi
    mkdir -p "$1" && cd "$1"
}

reload-qs() {
    { qs kill; qs -d; } > /dev/null 2>&1
    echo "quickshell daemon reloaded :3"
}
restart-qs() { reload-qs; }

# custom command not found handler with sassy roasts
command_not_found_handler() {
    local cmd="$1"
    local roasts=(
        "(╯°□°)╯ what the fuck is '$cmd'? did your keyboard melt?"
        "bruh '$cmd' is not a command. are you typing with your elbows?"
        "zsh: '$cmd' does not exist. maybe try spelling it right next time?"
        "(っ- ‸ - ς) '$cmd' not found. bro cannot type today."
        "404: brain and '$cmd' not found."
        "nice typo bro. '$cmd' is literally not a thing."
        "(★ω★) '$cmd'? never heard of her."
        "skill issue detected: command '$cmd' does not exist."
    )
    local random_roast="${roasts[$(( RANDOM % ${#roasts[@]} + 1 ))]}"
    print -P "%F{red}󰅚%f %F{yellow}${random_roast}%f"
    
    # Check if command is available as an arch package
    if (( $+commands[pacman] )); then
        local pkg=$(pacman -Fq "$cmd" 2>/dev/null | head -n 1)
        if [[ -n "$pkg" ]]; then
            print -P "  %F{cyan}󰄛 hint:%f '$cmd' is inside package %F{green}%B${pkg}%b%f (run: %F{magenta}paru -S ${pkg}%f)"
        fi
    fi
    return 127
}

# nyae - personal desktop and rice helper
nyae() {
    local sub="${1:-}"
    case "$sub" in
        wp|wallpaper)
            shift
            local cat="${1:-all}"
            ~/.config/quickshell/scripts/wallpaper.sh random "$cat"
            print -P "%F{magenta}󰄛 nyae:%f rolled a fresh wallpaper (%F{cyan}$cat%f)"
            ;;
        live)
            print -P "%F{cyan}󰄛 live wallpapers in library:%f"
            python3 -c '
import json
try:
    with open("/tmp/qs_wallpapers.json") as f:
        wps = json.load(f)
    live = [w for w in wps if w.get("isLive") or w.get("ext") in ["mp4", "webm", "gif"]]
    if live:
        for w in live[:10]:
            print(f"  • \033[38;5;141m{w["name"]}\033[0m (\033[38;5;120m{w["ext"]}\033[0m) -> {w["category"]}")
        print(f"\n  total: {len(live)} live wallpapers")
    else:
        print("  no live wallpapers found in ~/.wallpapers/")
except Exception:
    print("  run nyae scan first")
' 2>/dev/null
            ;;
        scan)
            python3 ~/.config/quickshell/scripts/scan_wallpapers.py
            print -P "%F{green}󰄲 nyae:%f scanned all wallpapers and generated thumbnails"
            ;;
        reload|restart)
            reload-qs
            ;;
        doctor)
            ~/my-hyprland-dots/install.zsh --doctor
            ;;
        clean|cleanup)
            print -P "%F{yellow}󰄛 purging orphans & build caches...%f"
            paru -Rns $(paru -Qtdq) 2>/dev/null || true
            rm -rf ~/.cache/paru/clone/* 2>/dev/null || true
            print -P "%F{green}󰄲 clean as fuck.%f"
            ;;
        roast)
            local roasts=(
                "you stare at your terminal more than grass."
                "your ricing is nice, now write some actual code."
                "zero errors, zero warnings, zero bitches."
                "60fps bezier curves won't fix your sleep schedule."
                "you spent 4 hours choosing a wallpaper."
                "bro has 10 workspaces and 1 active terminal."
            )
            print -P "%F{magenta}󰄛 nyae says:%f ${roasts[$(( RANDOM % ${#roasts[@]} + 1 ))]}"
            ;;
        help|*)
            print -P "%F{magenta}󰄛 nyae%f - your personal desktop and rice helper"
            print -P "  %F{cyan}nyae wp [category]%f   roll a random wallpaper (e.g. nyae wp anime)"
            print -P "  %F{cyan}nyae live%f            list all live video & gif wallpapers"
            print -P "  %F{cyan}nyae scan%f            rescan ~/.wallpapers/ & rebuild thumbnails"
            print -P "  %F{cyan}nyae reload%f          reload quickshell daemon & hyprland"
            print -P "  %F{cyan}nyae clean%f           purge orphan packages & aur build caches"
            print -P "  %F{cyan}nyae doctor%f          run system diagnostics & health check"
            print -P "  %F{cyan}nyae roast%f           sassy daily roast"
            ;;
    esac
}

# fuzzy find inside files with ripgrep and bat preview
fif() {
    if ! (( $+commands[rg] )) || ! (( $+commands[fzf] )); then
        echo "rg or fzf missing"
        return 1
    fi
    local file_line
    file_line=$(rg --color=always --line-number --no-heading --smart-case "${*:-}" 2>/dev/null |
        fzf --ansi             --delimiter :             --preview 'bat --style=numbers --color=always {1} --highlight-line {2}'             --preview-window 'right,60%,border-left,+{2}+3/3,~3')
    if [[ -n "$file_line" ]]; then
        local file="${file_line%%:*}"
        local rest="${file_line#*:}"
        local line="${rest%%:*}"
        ${EDITOR:-micro} "+${line}" "$file"
    fi
}

# fuzzy kill process
fkill() {
    local pid
    pid=$(ps -ef | sed 1d | fzf -m --header="[kill process]" | awk '{print $2}')
    if [[ -n "$pid" ]]; then
        echo "$pid" | xargs kill -${1:-9}
    fi
}

# fuzzy interactive package install
in() {
    if (( $+commands[paru] )); then
        local pkgs
        pkgs=$(paru -Slq | fzf --multi --preview 'paru -Si {1}' --preview-window=right:60%:wrap --header="[install package]")
        [[ -n "$pkgs" ]] && echo "$pkgs" | xargs -ro paru -S
    fi
}

# fuzzy interactive package remove
un() {
    if (( $+commands[paru] )); then
        local pkgs
        pkgs=$(paru -Qq | fzf --multi --preview 'paru -Qi {1}' --preview-window=right:60%:wrap --header="[remove package]")
        [[ -n "$pkgs" ]] && echo "$pkgs" | xargs -ro paru -Rns
    fi
}

# fuzzy edit file
fe() {
    local file
    file=$(fzf --preview 'bat --style=numbers --color=always --line-range :100 {} 2>/dev/null || head -n 100 {}' --header="[open file]")
    [[ -n "$file" ]] && ${EDITOR:-micro} "$file"
}
