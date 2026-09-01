# wp: interactive wallpaper control hub & instant reloader

reload-wp() {
    print -P "%F{magenta}󰄛 re-applying wallpaper & matugen theme...%f"
    ~/.config/quickshell/scripts/wallpaper.sh reapply 2>/dev/null || ~/.config/quickshell/scripts/wallpaper.sh random all
    print -P "%F{green}󰄲 wallpaper & colors refreshed%f"
}

wp() {
    local action="${1:-}"
    local wp_script="$HOME/.config/quickshell/scripts/wallpaper.sh"
    
    if [[ -n "$action" ]]; then
        case "$action" in
            reload|refresh)
                reload-wp
                return 0
                ;;
            random|roll)
                shift
                local cat="${1:-all}"
                "$wp_script" random "$cat"
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
        print(f"  • \033[38;5;141m{w["name"]}\033[0m (\033[38;5;120m{w["ext"]}\033[0m) -> {w["path"]}")
except Exception:
    print("no live wallpaper cache found. run wp scan first.")
'
                return 0
                ;;
            scan)
                python3 ~/.config/quickshell/scripts/scan_wallpapers.py
                print -P "%F{green}󰄲 wallpaper cache & thumbnails updated%f"
                return 0
                ;;
            set)
                shift
                if [[ -n "$1" && -f "$1" ]]; then
                    "$wp_script" set "$1"
                    print -P "%F{green}󰄲 applied wallpaper:%f $1"
                else
                    print -P "%F{red}󰅚 file not found:%f $1"
                fi
                return 0
                ;;
        esac
    fi

    # Interactive menu
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
        "🎲 Roll Random Wallpaper (All Categories)"
        "🌆 Select Wallpaper from Library (FZF Picker)"
        "🎬 Select Live Video / GIF Wallpaper"
        "🔄 Reload Current Wallpaper & Theme"
        "🎨 Rescan Library & Generate Thumbnails"
        "🌐 Download Wallpaper by URL"
    )

    local choice=$(printf "%s\n" "${options[@]}" | fzf --header="[󰄛 Wallpaper Hub - What do you want to do?]" --reverse --height=35%)
    [[ -z "$choice" ]] && return 0

    case "$choice" in
        "🎲 Roll Random Wallpaper"*)
            "$wp_script" random all
            print -P "%F{magenta}󰄛 rolled fresh random wallpaper%f"
            ;;
        "🌆 Select Wallpaper from Library"*)
            local wp_json="/tmp/qs_wallpapers.json"
            [[ ! -f "$wp_json" ]] && python3 ~/.config/quickshell/scripts/scan_wallpapers.py >/dev/null 2>&1
            local selected_file=$(python3 -c '
import json
try:
    with open("/tmp/qs_wallpapers.json") as f:
        wps = json.load(f)
    for w in wps:
        print(f"{w["path"]}	{w["category"]}	{w["name"]}")
except Exception:
    pass
' | fzf --with-nth=2,3 --delimiter="	" --header="[Select Wallpaper]" --preview="echo {} | awk '{print \$1}'" | awk -F"	" '{print $1}')
            if [[ -n "$selected_file" && -f "$selected_file" ]]; then
                "$wp_script" set "$selected_file"
                print -P "%F{green}󰄲 wallpaper applied:%f %F{cyan}${selected_file:t}%f"
            fi
            ;;
        "🎬 Select Live Video / GIF Wallpaper"*)
            local selected_live=$(python3 -c '
import json
try:
    with open("/tmp/qs_wallpapers.json") as f:
        wps = json.load(f)
    for w in wps:
        if w.get("isLive") or w.get("ext") in ["mp4", "webm", "gif"]:
            print(f"{w["path"]}	[LIVE {w["ext"]}]	{w["name"]}")
except Exception:
    pass
' | fzf --with-nth=2,3 --delimiter="	" --header="[Select Live Wallpaper]" | awk -F"	" '{print $1}')
            if [[ -n "$selected_live" && -f "$selected_live" ]]; then
                "$wp_script" set "$selected_live"
                print -P "%F{green}󰄲 live wallpaper applied:%f %F{cyan}${selected_live:t}%f"
            fi
            ;;
        "🔄 Reload Current Wallpaper & Theme"*)
            reload-wp
            ;;
        "🎨 Rescan Library & Generate Thumbnails"*)
            python3 ~/.config/quickshell/scripts/scan_wallpapers.py
            print -P "%F{green}󰄲 library scanned & thumbnails rebuilt%f"
            ;;
        "🌐 Download Wallpaper by URL"*)
            print -Pn "%F{cyan}enter wallpaper / video URL: %f"
            read -r dl_url
            if [[ -n "$dl_url" ]]; then
                print -P "%F{magenta}󰄛 downloading and applying...%f"
                python3 ~/.config/quickshell/scripts/download_wallpaper.py "$dl_url"
            fi
            ;;
    esac
}
