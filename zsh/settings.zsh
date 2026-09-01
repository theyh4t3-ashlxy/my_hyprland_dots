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

        local items=(
            "1. Fastfetch on terminal open: [${ff_status}]"
            "2. Existential greeting quote: [${gr_status}]"
            "3. Psychological roaster on typo: [${psycho_status}]"
            "4. Git details in prompt: [${git_status}]"
            "5. Command execution timer: [${timer_status}]"
            "6. Recompile Zsh bytecode (speedup)"
            "7. Exit settings"
        )

        local choice=$(printf "%s\n" "${items[@]}" | fzf --header="[󰄛 Terminal & Shell Settings - Select to toggle]" --reverse --height=40%)
        [[ -z "$choice" || "$choice" == *"Exit settings"* ]] && break

        case "$choice" in
            *"Fastfetch"*)
                if [[ "$ff_status" == "true" ]]; then _save_pref "SHOW_FASTFETCH" "false"; else _save_pref "SHOW_FASTFETCH" "true"; fi
                ;;
            *"Existential greeting"*)
                if [[ "$gr_status" == "true" ]]; then _save_pref "SHOW_GREETING_ROAST" "false"; else _save_pref "SHOW_GREETING_ROAST" "true"; fi
                ;;
            *"Psychological roaster"*)
                if [[ "$psycho_status" == "true" ]]; then _save_pref "ENABLE_PSYCHO_ROASTS" "false"; else _save_pref "ENABLE_PSYCHO_ROASTS" "true"; fi
                ;;
            *"Git details"*)
                if [[ "$git_status" == "true" ]]; then _save_pref "SHOW_GIT_PROMPT" "false"; else _save_pref "SHOW_GIT_PROMPT" "true"; fi
                ;;
            *"execution timer"*)
                if [[ "$timer_status" == "true" ]]; then _save_pref "SHOW_CMD_TIMER" "false"; else _save_pref "SHOW_CMD_TIMER" "true"; fi
                ;;
            *"Recompile Zsh"*)
                zrecompile 2>/dev/null || true
                sleep 1
                ;;
        esac
    done

    print -P "%F{green}󰄲 settings saved -> ${PREFS_FILE}%f"
}

alias rice-settings="settings"
