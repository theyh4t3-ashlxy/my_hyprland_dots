#!/usr/bin/env zsh
# 󰸉 wallhaven downloader — hyprnightmare edition
# drops wallpapers into ~/.wallpapers with exact res and applies via awww

# --- config ---
WALLHAVEN_API_KEY="${WALLHAVEN_API_KEY:-}"
WALLPAPER_DIR="$HOME/.wallpapers"
RESOLUTION="1920x1200"
PURITY="110"      # 100=sfw, 110=sfw+sketchy, 111=all (requires key for 111)
CATEGORIES="111"  # 100=general, 010=anime, 001=people, 111=all

# --- pre-flight checks ---
if ! command -v jq &>/dev/null; then
    echo "󰚌 jq is required but not installed. Install it with: sudo pacman -S jq"
    exit 1
fi

mkdir -p "$WALLPAPER_DIR"

# --- build the api url ---
SEARCH_URL="https://wallhaven.cc/api/v1/search"
QUERY="?resolutions=${RESOLUTION}&categories=${CATEGORIES}&purity=${PURITY}&sorting=random&page=1"

# --- fetch from api ---
echo "󱇱 Fetching wallpaper metadata..."
if [[ -n "$WALLHAVEN_API_KEY" ]]; then
    RESPONSE=$(curl -s -H "X-API-Key: $WALLHAVEN_API_KEY" "${SEARCH_URL}${QUERY}")
else
    RESPONSE=$(curl -s "${SEARCH_URL}${QUERY}")
fi

# --- parse json ---
WALLPAPER_URL=$(echo "$RESPONSE" | jq -r '.data[0].path' 2>/dev/null)
WALLPAPER_ID=$(echo "$RESPONSE" | jq -r '.data[0].id' 2>/dev/null)

if [[ -z "$WALLPAPER_URL" || "$WALLPAPER_URL" == "null" ]]; then
    echo "󰚌 Failed to fetch wallpaper metadata. Response:"
    echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
    exit 1
fi

# Dynamically pull correct extension (.jpg / .png) from url
EXTENSION="${WALLPAPER_URL##*.}"
FILENAME="${WALLPAPER_ID}.${EXTENSION}"
FILEPATH="${WALLPAPER_DIR}/${FILENAME}"

# --- download ---
echo " Downloading: $WALLPAPER_ID ($EXTENSION)..."
curl -s -L -o "$FILEPATH" "$WALLPAPER_URL"

if [[ $? -eq 0 && -f "$FILEPATH" ]]; then
    echo "󰸉 Saved to: $FILEPATH"
    
    # --- apply theme & wallpaper via python engine ---
    THEME_ENGINE="/home/ashley/.config/hypr/scripts/apply-theme.py"

    if [[ -f "$THEME_ENGINE" ]]; then
        echo "󰚌 Triggering theme engine: matugen + hyprland reload..."
        "$THEME_ENGINE" "$FILEPATH"
    else
        echo "󰚌 Theme engine not found at $THEME_ENGINE"
        echo "󰸉 Falling back to basic awww application..."
        if command -v awww &>/dev/null && pgrep -x "awww-daemon" &>/dev/null; then
            awww img "$FILEPATH" --transition-type fade --transition-duration 1.8 --transition-fps 90 --transition-bezier "0.25,1,0.5,1"
        else
            echo "󰚌 Could not apply wallpaper automatically."
        fi
    fi
else
    echo "󰚌 Download failed."
    exit 1
fi