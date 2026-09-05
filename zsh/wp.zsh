# wp: interactive wallpaper control hub & instant reloader

reload-wp() {
    print -P "%F{magenta}󰄛 re-applying wallpaper & matugen theme...%f"
    python3 ~/.config/quickshell/scripts/wallpaper.py reapply 2>/dev/null || python3 ~/.config/quickshell/scripts/wallpaper.py random all
    print -P "%F{green}󰄲 wallpaper & colors refreshed%f"
}

wp() {
    local action="${1:-}"
    local wp_script="$HOME/.config/quickshell/scripts/wallpaper.py"
    
    if [[ -n "$action" ]]; then
        case "$action" in
            reload|refresh)
                reload-wp
                return 0
                ;;
            random|roll)
                shift
                local cat="${1:-all}"
                python3 "$wp_script" random "$cat"
                print -P "%F{magenta}󰄛 rolled random wallpaper (%F{cyan}$cat%f)"
                return 0
                ;;
            live)
                print -P "%F{cyan}󰄛 live wallpapers:%f"
                python3 -c '
import json
try:
    with open("/tmp/qs_wallpapers.json") as f:
        wps = json.load(f)
    live = [w for w in wps if w.get("isLive") or w.get("ext") in ["mp4", "webm", "gif"]]
    for w in live:
        print(f"  󰄛 \033[38;5;141m{w[\"name\"]}\033[0m (\033[38;5;120m{w[\"ext\"]}\033[0m) -> {w[\"path\"]}")
except Exception:
    print("no live wallpaper cache found. run wp scan first.")
'
                return 0
                ;;
            scan)
                python3 "$wp_script" scan
                print -P "%F{green}󰄲 wallpaper cache & thumbnails updated%f"
                return 0
                ;;
            set)
                shift
                if [[ -n "$1" && -f "$1" ]]; then
                    python3 "$wp_script" set "$1"
                    print -P "%F{green}󰄲 applied wallpaper:%f $1"
                else
                    print -P "%F{red}󰅚 file not found:%f $1"
                fi
                return 0
                ;;
            fetch|get)
                shift
                local query="${*:-}"
                python3 "$wp_script" fetch-live "$query"
                print -P "%F{green}󰄲 live wallpapers fetched for: ${query}%f"
                return 0
                ;;
            color)
                shift
                local hex="${1:-#787756}"
                python3 "$wp_script" color "$hex"
                print -P "%F{green}󰄲 applied color theme:%f $hex"
                return 0
                ;;
            help|-h|--help)
                print -P "%F{magenta}󰄛 wp - interactive wallpaper control hub%f"
                print "  wp                    open interactive fzf picker"
                print "  wp random [category]  roll random wallpaper (e.g. wp random anime)"
                print "  wp reload             re-apply current wallpaper & theme"
                print "  wp live               list all live video wallpapers"
                print "  wp fetch <query>      search & download live gifs/videos"
                print "  wp color <hex>        set custom theme color hex"
                print "  wp scan               rescan library & rebuild thumbnails"
                print "  wp set <file>         apply specific image/video file"
                return 0
                ;;
        esac
    fi

    # interactive fzf menu
    if ! (( $+commands[fzf] )); then
        print -P "%F{magenta}󰄛 wallpaper hub%f"
        print "  wp random [category]  roll random wallpaper"
        print "  wp reload             re-apply current wallpaper"
        print "  wp live               list live video wallpapers"
        print "  wp scan               rescan library & thumbnails"
        print "  wp set <file>         apply specific image/video"
        return 0
    fi

    local options=(
        "󰑐 roll random wallpaper (all categories)"
        "󰋩 select wallpaper from library (fzf picker)"
        "󰍹 select live video / gif wallpaper"
        "󰁕 reload current wallpaper & theme"
        "󰚰 rescan library & generate thumbnails"
        "󰏤 download wallpaper by url"
    )

    local choice=$(printf "%s\n" "${options[@]}" | fzf --header="[󰄛 wallpaper hub - what do you want to do?]" --reverse --height=35%)
    [[ -z "$choice" ]] && return 0

    case "$choice" in
        *"roll random wallpaper"*)
            python3 "$wp_script" random all
            print -P "%F{magenta}󰄛 rolled fresh random wallpaper%f"
            ;;
        *"select wallpaper from library"*)
            local wp_json="/tmp/qs_wallpapers.json"
            [[ ! -f "$wp_json" ]] && python3 "$wp_script" scan >/dev/null 2>&1
            local selected_file=$(python3 -c '
import json
try:
    with open("/tmp/qs_wallpapers.json") as f:
        wps = json.load(f)
    for w in wps:
        print(f"{w[\"path\"]}\t{w[\"category\"]}\t{w[\"name\"]}")
except Exception:
    pass
' | fzf --with-nth=2,3 --delimiter="\t" --header="[󰋩 select wallpaper]" | awk -F"\t" '{print $1}')
            if [[ -n "$selected_file" && -f "$selected_file" ]]; then
                python3 "$wp_script" set "$selected_file"
                print -P "%F{green}󰄲 wallpaper applied:%f %F{cyan}${selected_file:t}%f"
            fi
            ;;
        *"select live video"*)
            local selected_live=$(python3 -c '
import json
try:
    with open("/tmp/qs_wallpapers.json") as f:
        wps = json.load(f)
    for w in wps:
        if w.get("isLive") or w.get("ext") in ["mp4", "webm", "gif"]:
            print(f"{w[\"path\"]}\t[live {w[\"ext\"]}]\t{w[\"name\"]}")
except Exception:
    pass
' | fzf --with-nth=2,3 --delimiter="\t" --header="[󰍹 select live wallpaper]" | awk -F"\t" '{print $1}')
            if [[ -n "$selected_live" && -f "$selected_live" ]]; then
                python3 "$wp_script" set "$selected_live"
                print -P "%F{green}󰄲 live wallpaper applied:%f %F{cyan}${selected_live:t}%f"
            fi
            ;;
        *"reload current wallpaper"*)
            reload-wp
            ;;
        *"rescan library"*)
            python3 "$wp_script" scan
            print -P "%F{green}󰄲 library scanned & thumbnails rebuilt%f"
            ;;
        *"download wallpaper"*)
            print -Pn "%F{cyan}enter wallpaper / video url: %f"
            read -r dl_url
            if [[ -n "$dl_url" ]]; then
                print -P "%F{magenta}󰄛 downloading and applying...%f"
                python3 "$wp_script" download "$dl_url"
            fi
            ;;
    esac
}
