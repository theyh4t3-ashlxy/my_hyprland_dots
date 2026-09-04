# settings: interactive terminal and rice customizer

PREFS_FILE="${ZDOTDIR:-$HOME/.config/zsh}/user_prefs.conf"

# default preferences if not existing
[[ ! -f "$PREFS_FILE" ]] && cat << 'EOF' > "$PREFS_FILE"
# user customizable shell preferences
SHOW_FASTFETCH=true
SHOW_GREETING_ROAST=true
SHOW_GIT_PROMPT=true
SHOW_CMD_TIMER=true
ENABLE_PSYCHO_ROASTS=true
EOF

# load preferences
source "$PREFS_FILE" 2>/dev/null || true

_save_pref() {
    local key="$1"
    local val="$2"
    if grep -q "^${key}=" "$PREFS_FILE" 2>/dev/null; then
        sed -i "s|^${key}=.*|${key}=${val}|" "$PREFS_FILE"
    else
        echo "${key}=${val}" >> "$PREFS_FILE"
    fi
}

settings() {
    if ! (( $+commands[fzf] )); then
        print -P "%F{magenta}󰄛 shell settings%f"
        cat "$PREFS_FILE"
        return 0
    fi

    while true; do
        source "$PREFS_FILE" 2>/dev/null || true
        
        local ff_status="${SHOW_FASTFETCH:-true}"
        local gr_status="${SHOW_GREETING_ROAST:-true}"
        local git_status="${SHOW_GIT_PROMPT:-true}"
        local timer_status="${SHOW_CMD_TIMER:-true}"
        local psycho_status="${ENABLE_PSYCHO_ROASTS:-true}"
        local dnd_status="off"
        grep -q "^dnd=true" "$HOME/.config/quickshell/settings.conf" 2>/dev/null && dnd_status="on"

        local items=(
            "󰄛 fastfetch on open: [${ff_status}]"
            "󰄛 existential greeting on open: [${gr_status}]"
            "󰅚 psychological roaster on typo: [${psycho_status}]"
            " git details in prompt: [${git_status}]"
            "󰁕 execution timer in prompt: [${timer_status}]"
            "󰂛 do not disturb (mute notifications): [${dnd_status}]"
            "󰏘 vibe style (kaomoji / nerd / text)"
            "󰚰 recompile zsh bytecode (speedup)"
            "󰀦 purge .zwc bytecode cache (reset)"
            "󰅚 exit settings"
        )

        local choice=$(printf "%s\n" "${items[@]}" | fzf --header="[󰄛 terminal & shell settings - select to toggle]" --reverse --height=50%)
        [[ -z "$choice" || "$choice" == *"exit settings"* ]] && break

        case "$choice" in
            *"fastfetch"*)
                if [[ "$ff_status" == "true" ]]; then _save_pref "SHOW_FASTFETCH" "false"; else _save_pref "SHOW_FASTFETCH" "true"; fi
                ;;
            *"existential greeting"*)
                if [[ "$gr_status" == "true" ]]; then _save_pref "SHOW_GREETING_ROAST" "false"; else _save_pref "SHOW_GREETING_ROAST" "true"; fi
                ;;
            *"psychological roaster"*)
                if [[ "$psycho_status" == "true" ]]; then _save_pref "ENABLE_PSYCHO_ROASTS" "false"; else _save_pref "ENABLE_PSYCHO_ROASTS" "true"; fi
                ;;
            *"git details"*)
                if [[ "$git_status" == "true" ]]; then _save_pref "SHOW_GIT_PROMPT" "false"; else _save_pref "SHOW_GIT_PROMPT" "true"; fi
                ;;
            *"execution timer"*)
                if [[ "$timer_status" == "true" ]]; then _save_pref "SHOW_CMD_TIMER" "false"; else _save_pref "SHOW_CMD_TIMER" "true"; fi
                ;;
            *"do not disturb"*)
                dnd toggle
                sleep 0.5
                ;;
            *"vibe style"*)
                local v_choice=$(printf "%s\n" "(ﾉ◕ヮ◕)ﾉ kaomoji" "󰄛 nerd fonts" "󰦨 plain text" | fzf --header="[choose your desktop vibe style]" --reverse --height=25%)
                if [[ -n "$v_choice" ]]; then
                    local style="nerd"
                    [[ "$v_choice" == *"kaomoji"* ]] && style="kaomoji"
                    [[ "$v_choice" == *"text"* ]]    && style="text"
                    local qs_conf="$HOME/.config/quickshell/settings.conf"
                    if grep -q "^vibeStyle=" "$qs_conf" 2>/dev/null; then
                        sed -i "s|^vibeStyle=.*|vibeStyle=\"${style}\"|" "$qs_conf"
                    else
                        echo "vibeStyle=\"${style}\"" >> "$qs_conf"
                    fi
                    print -P "%F{green}󰄲 desktop vibe updated -> %B${style}%b%f"
                fi
                ;;
            *"recompile zsh"*)
                zrecompile 2>/dev/null || true
                sleep 1
                ;;
            *"purge .zwc"*)
                zclean 2>/dev/null || true
                sleep 1
                ;;
        esac
    done

    print -P "%F{green}󰄲 settings saved -> ${PREFS_FILE}%f"
}

alias rice-settings="settings"
