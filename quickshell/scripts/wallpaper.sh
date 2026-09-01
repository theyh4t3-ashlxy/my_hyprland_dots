#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CUR_WP_FILE="/tmp/qs_current_wallpaper.txt"

action="${1:-}"

case "$action" in
    scan)
        python3 "$SCRIPT_DIR/scan_wallpapers.py"
        ;;

    random)
        filter_cat="${2:-all}"
        transition="${3:-wipe}"
        angle="${4:-30}"
        step="${5:-90}"
        duration="${6:-3}"
        fps="${7:-60}"
        filt="${8:-Lanczos3}"
        mode="${9:-dark}"
        scheme="${10:-scheme-tonal-spot}"

        python3 "$SCRIPT_DIR/scan_wallpapers.py"
        selected_wp=$(python3 -c '
import json, random, sys
cat = sys.argv[1].lower() if len(sys.argv) > 1 else "all"
try:
    with open("/tmp/qs_wallpapers.json") as f:
        wps = json.load(f)
    if cat != "all" and cat != "":
        filtered = [w["path"] for w in wps if cat in w["category"].lower() or cat in w["parentCategory"].lower() or cat in w["subCategory"].lower()]
        if filtered:
            print(random.choice(filtered))
            sys.exit(0)
    if wps:
        print(random.choice([w["path"] for w in wps]))
except Exception:
    pass
' "$filter_cat")

        if [[ -n "$selected_wp" && -f "$selected_wp" ]]; then
            echo "$selected_wp" > "$CUR_WP_FILE"
            awww img "$selected_wp" \
                --transition-type "$transition" \
                --transition-angle "$angle" \
                --transition-step "$step" \
                --transition-duration "$duration" \
                --transition-fps "$fps" \
                --filter "$filt" 2>/dev/null || true

            matugen image "$selected_wp" -m "$mode" -t "$scheme" --source-color-index 0 2>/dev/null || true
        fi
        ;;

    download)
        shift
        python3 "$SCRIPT_DIR/download_wallpaper.py" "$@"
        ;;

    set)
        img_path="${2:-}"
        if [[ -z "$img_path" || ! -f "$img_path" ]]; then
            exit 1
        fi
        
        transition="${3:-wipe}"
        angle="${4:-30}"
        step="${5:-90}"
        duration="${6:-3}"
        fps="${7:-60}"
        filter="${8:-Lanczos3}"
        mode="${9:-dark}"
        scheme="${10:-scheme-tonal-spot}"

        echo "$img_path" > "$CUR_WP_FILE"
        ext="${img_path##*.}"
        ext_lower=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

        awww img "$img_path" \
            --transition-type "$transition" \
            --transition-angle "$angle" \
            --transition-step "$step" \
            --transition-duration "$duration" \
            --transition-fps "$fps" \
            --filter "$filter" 2>/dev/null || true

        if [[ "$ext_lower" =~ ^(mp4|webm|mkv|mov)$ ]]; then
            ffmpeg -y -ss 00:00:01 -i "$img_path" -vframes 1 -q:v 2 /tmp/qs_video_thumb.jpg 2>/dev/null || true
            if [[ -f /tmp/qs_video_thumb.jpg ]]; then
                matugen image /tmp/qs_video_thumb.jpg -m "$mode" -t "$scheme" --source-color-index 0 2>/dev/null || true
            fi
        else
            matugen image "$img_path" -m "$mode" -t "$scheme" --source-color-index 0 2>/dev/null || true
        fi
        ;;

    color)
        hex_color="${2:-#787756}"
        mode="${3:-dark}"
        scheme="${4:-scheme-tonal-spot}"

        matugen color hex "$hex_color" -m "$mode" -t "$scheme" 2>/dev/null || true
        ;;

    reapply)
        mode="${2:-dark}"
        scheme="${3:-scheme-tonal-spot}"
        cur_wp=""
        if [[ -f "$CUR_WP_FILE" ]]; then
            cur_wp=$(cat "$CUR_WP_FILE")
        fi

        if [[ -n "$cur_wp" && -f "$cur_wp" ]]; then
            matugen image "$cur_wp" -m "$mode" -t "$scheme" --source-color-index 0 2>/dev/null || true
        else
            matugen color hex "#787756" -m "$mode" -t "$scheme" 2>/dev/null || true
        fi
        ;;

    *)
        echo "Usage: $0 {scan|download <url> [opts...]|set <path> [opts...]|color <hex> [mode] [scheme]|reapply [mode] [scheme]}"
        exit 1
        ;;
esac
