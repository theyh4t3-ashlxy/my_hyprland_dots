# settings: interactive zsh, prompt, and terminal customizer

PREFS_FILE="${ZDOTDIR:-$HOME/.config/zsh}/user_prefs.conf"

# default preferences if not existing
[[ ! -f "$PREFS_FILE" ]] && cat << 'EOF' > "$PREFS_FILE"
# user customizable shell preferences
SHOW_FASTFETCH=false
SHOW_GREETING_ROAST=false
SHOW_GIT_PROMPT=true
SHOW_CMD_TIMER=true
ENABLE_PSYCHO_ROASTS=true
PROMPT_STYLE=two-line
PROMPT_SYMBOL=❯
PROMPT_ACCENT=primary
KEY_BIND_MODE=emacs
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
    export "${key}=${val}"
    source "$PREFS_FILE" 2>/dev/null || true
    (( $+functions[set_prompt_colors] )) && set_prompt_colors 2>/dev/null
    (( $+functions[build_prompt] )) && build_prompt 2>/dev/null
}

settings() {
    local cmd="${1:-}"

    case "$cmd" in
        list|show)
            print -P "%F{141}󰄛 zsh preferences (%B${PREFS_FILE}%b)%f"
            command cat "$PREFS_FILE"
            return 0
            ;;
        prompt|style)
            if [[ -n "${2:-}" ]]; then
                _save_pref "PROMPT_STYLE" "$2"
                print -P "%F{green}󰄲 prompt style set -> %B$2%b%f"
                return 0
            fi
            ;;
        symbol)
            if [[ -n "${2:-}" ]]; then
                _save_pref "PROMPT_SYMBOL" "$2"
                print -P "%F{green}󰄲 prompt symbol set -> %B$2%b%f"
                return 0
            fi
            ;;
        accent)
            if [[ -n "${2:-}" ]]; then
                _save_pref "PROMPT_ACCENT" "$2"
                print -P "%F{green}󰄲 prompt accent set -> %B$2%b%f"
                return 0
            fi
            ;;
        git)
            local val="${2:-true}"
            _save_pref "SHOW_GIT_PROMPT" "$val"
            print -P "%F{green}󰄲 git prompt details -> %B$val%b%f"
            return 0
            ;;
        timer)
            local val="${2:-true}"
            _save_pref "SHOW_CMD_TIMER" "$val"
            print -P "%F{green}󰄲 execution timer -> %B$val%b%f"
            return 0
            ;;
        roasts|roast)
            local val="${2:-true}"
            _save_pref "ENABLE_PSYCHO_ROASTS" "$val"
            print -P "%F{green}󰄲 typo psychological roaster -> %B$val%b%f"
            return 0
            ;;
        greeting)
            local val="${2:-true}"
            _save_pref "SHOW_GREETING_ROAST" "$val"
            print -P "%F{green}󰄲 existential greeting on open -> %B$val%b%f"
            return 0
            ;;
        fastfetch)
            local val="${2:-true}"
            _save_pref "SHOW_FASTFETCH" "$val"
            print -P "%F{green}󰄲 fastfetch on open -> %B$val%b%f"
            return 0
            ;;
        reset)
            cat << 'EOF' > "$PREFS_FILE"
SHOW_FASTFETCH=false
SHOW_GREETING_ROAST=false
SHOW_GIT_PROMPT=true
SHOW_CMD_TIMER=true
ENABLE_PSYCHO_ROASTS=true
PROMPT_STYLE=two-line
PROMPT_SYMBOL=❯
PROMPT_ACCENT=primary
KEY_BIND_MODE=emacs
EOF
            source "$PREFS_FILE"
            (( $+functions[set_prompt_colors] )) && set_prompt_colors
            (( $+functions[build_prompt] )) && build_prompt
            print -P "%F{green}󰄲 reset zsh settings to factory stock%f"
            return 0
            ;;
    esac

    if ! (( $+commands[fzf] )); then
        print -P "%F{141}󰄛 zsh preferences%f"
        command cat "$PREFS_FILE"
        print -P "%F{244}tip: install fzf for the interactive menu or use 'settings <key> <val>'%f"
        return 0
    fi

    while true; do
        source "$PREFS_FILE" 2>/dev/null || true

        local ff_status="${SHOW_FASTFETCH:-false}"
        local gr_status="${SHOW_GREETING_ROAST:-false}"
        local git_status="${SHOW_GIT_PROMPT:-true}"
        local timer_status="${SHOW_CMD_TIMER:-true}"
        local psycho_status="${ENABLE_PSYCHO_ROASTS:-true}"
        local p_style="${PROMPT_STYLE:-two-line}"
        local p_sym="${PROMPT_SYMBOL:-❯}"
        local p_acc="${PROMPT_ACCENT:-primary}"
        local k_mode="${KEY_BIND_MODE:-emacs}"

        local items=(
            "󰞷 prompt style: [${p_style}]"
            "󰊠 prompt symbol: [${p_sym}]"
            "󰏘 prompt symbol accent: [${p_acc}]"
            " git details in prompt: [${git_status}]"
            "󰁕 execution timer in prompt: [${timer_status}]"
            "󰄛 fastfetch on open: [${ff_status}]"
            "󰄛 existential greeting on open: [${gr_status}]"
            "󰅚 psychological roaster on typo: [${psycho_status}]"
            "󰌌 keybinding mode: [${k_mode}]"
            "󰄲 view help cheatsheet"
            "󰚰 recompile zsh bytecode (.zwc speedup)"
            "󰀦 purge .zwc bytecode cache (reset)"
            "󰅚 exit settings"
        )

        local choice=$(printf "%s\n" "${items[@]}" | fzf --header="[󰄛 zsh & terminal settings - select to customize]" --reverse --height=55%)
        [[ -z "$choice" || "$choice" == *"exit settings"* ]] && break

        case "$choice" in
            *"prompt style"*)
                local s_choice=$(printf "%s\n" \
                    "two-line   (classic 2-line box with system, directory, and arrow)" \
                    "single-line (compact user@host in path ❯)" \
                    "minimal     (clean path ❯)" \
                    "bracket     ([user@host path] ❯)" \
                    "unhinged    (random mood kaomoji before prompt)" \
                    | fzf --header="[choose your prompt layout style]" --reverse --height=35%)
                if [[ -n "$s_choice" ]]; then
                    local sel="${s_choice%% *}"
                    _save_pref "PROMPT_STYLE" "$sel"
                fi
                ;;
            *"prompt symbol:"*)
                local sym_choice=$(printf "%s\n" \
                    "❯  (default sharp arrow)" \
                    "$  (unix classic)" \
                    "󰄛  (hypr cat)" \
                    "λ  (lambda)" \
                    ">  (simple chevron)" \
                    "%  (zsh percent)" \
                    ">> (double chevron)" \
                    | fzf --header="[choose your prompt symbol character]" --reverse --height=35%)
                if [[ -n "$sym_choice" ]]; then
                    local sel="${sym_choice%% *}"
                    _save_pref "PROMPT_SYMBOL" "$sel"
                fi
                ;;
            *"prompt symbol accent"*)
                local acc_choice=$(printf "%s\n" \
                    "primary    (wallpaper matugen primary accent)" \
                    "secondary  (wallpaper matugen secondary accent)" \
                    "tertiary   (wallpaper matugen tertiary accent)" \
                    "cyan       (bright cyan accent)" \
                    "green      (neon green accent)" \
                    "magenta    (lavender magenta accent)" \
                    "yellow     (golden yellow accent)" \
                    "white      (crisp white)" \
                    | fzf --header="[choose your prompt arrow color accent]" --reverse --height=40%)
                if [[ -n "$acc_choice" ]]; then
                    local sel="${acc_choice%% *}"
                    _save_pref "PROMPT_ACCENT" "$sel"
                fi
                ;;
            *"git details"*)
                if [[ "$git_status" == "true" ]]; then _save_pref "SHOW_GIT_PROMPT" "false"; else _save_pref "SHOW_GIT_PROMPT" "true"; fi
                ;;
            *"execution timer"*)
                if [[ "$timer_status" == "true" ]]; then _save_pref "SHOW_CMD_TIMER" "false"; else _save_pref "SHOW_CMD_TIMER" "true"; fi
                ;;
            *"fastfetch"*)
                if [[ "$ff_status" == "true" ]]; then _save_pref "SHOW_FASTFETCH" "false"; else _save_pref "SHOW_FASTFETCH" "true"; fi
                ;;
            *"existential greeting"*)
                if [[ "$gr_status" == "true" ]]; then _save_pref "SHOW_GREETING_ROAST" "false"; else _save_pref "SHOW_GREETING_ROAST" "true"; fi
                ;;
            *"psychological roaster"*)
                if [[ "$psycho_status" == "true" ]]; then _save_pref "ENABLE_PSYCHO_ROASTS" "false"; else _save_pref "ENABLE_PSYCHO_ROASTS" "true"; fi
                ;;
            *"keybinding mode"*)
                if [[ "$k_mode" == "emacs" ]]; then
                    _save_pref "KEY_BIND_MODE" "vi"
                    bindkey -v
                else
                    _save_pref "KEY_BIND_MODE" "emacs"
                    bindkey -e
                fi
                ;;
            *"view help cheatsheet"*)
                (( $+functions[help] )) && help
                print -Pn "\n%F{244}press enter to return to settings...%f"
                read -r </dev/tty 2>/dev/null || true
                ;;
            *"recompile zsh"*)
                zrecompile 2>/dev/null || true
                sleep 0.8
                ;;
            *"purge .zwc"*)
                zclean 2>/dev/null || true
                sleep 0.8
                ;;
        esac
    done

    print -P "%F{green}󰄲 zsh preferences synced -> ${PREFS_FILE}%f"
}

alias rice-settings="settings"
