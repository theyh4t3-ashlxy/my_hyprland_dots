# settings: interactive zsh, prompt, and terminal customizer

PREFS_FILE="${ZDOTDIR:-$HOME/.config/zsh}/user_prefs.conf"

# single source of truth for stock defaults
typeset -ga DEFAULT_PREFS=(
    "SHOW_FASTFETCH=false"
    "SHOW_GREETING_ROAST=false"
    "SHOW_GIT_PROMPT=true"
    "SHOW_CMD_TIMER=true"
    "ENABLE_PSYCHO_ROASTS=true"
    "PROMPT_STYLE=two-line"
    "PROMPT_SYMBOL=❯"
    "PROMPT_ACCENT=primary"
    "KEY_BIND_MODE=emacs"
)

_init_prefs() {
    print -l "${DEFAULT_PREFS[@]}" > "$PREFS_FILE"
}

# initialize if missing
[[ ! -f "$PREFS_FILE" ]] && _init_prefs

# load preferences into shell scope
source "$PREFS_FILE" 2>/dev/null || true

_reload_prompt() {
    (( $+functions[set_prompt_colors] )) && set_prompt_colors 2>/dev/null
    (( $+functions[build_prompt] )) && build_prompt 2>/dev/null
}

_save_pref() {
    local key="$1"
    local val="$2"

    if grep -q "^${key}=" "$PREFS_FILE" 2>/dev/null; then
        sed -i "s|^${key}=.*|${key}=${val}|" "$PREFS_FILE"
    else
        echo "${key}=${val}" >> "$PREFS_FILE"
    fi

    # assign to global shell scope without polluting subprocess environment tables
    typeset -g "${key}=${val}"
    _reload_prompt
}

# generic boolean toggle using zsh indirect parameter expansion
_toggle_pref() {
    local key="$1"
    local cur="${(P)key}"
    local next="true"
    [[ "$cur" == "true" ]] && next="false"
    _save_pref "$key" "$next"
}

settings() {
    local cmd="${1:-}"
    local arg="${2:-}"

    case "$cmd" in
        list|show)
            print -P "%F{141}󰄛 zsh preferences (%B${PREFS_FILE}%b)%f"
            command cat "$PREFS_FILE"
            return 0
            ;;
        prompt|style)
            if [[ -n "$arg" ]]; then
                _save_pref "PROMPT_STYLE" "$arg"
                print -P "%F{green}󰄲 prompt style set -> %B$arg%b%f"
                return 0
            fi
            ;;
        symbol)
            if [[ -n "$arg" ]]; then
                _save_pref "PROMPT_SYMBOL" "$arg"
                print -P "%F{green}󰄲 prompt symbol set -> %B$arg%b%f"
                return 0
            fi
            ;;
        accent)
            if [[ -n "$arg" ]]; then
                _save_pref "PROMPT_ACCENT" "$arg"
                print -P "%F{green}󰄲 prompt accent set -> %B$arg%b%f"
                return 0
            fi
            ;;
        git)
            [[ -n "$arg" ]] && _save_pref "SHOW_GIT_PROMPT" "$arg" || _toggle_pref "SHOW_GIT_PROMPT"
            print -P "%F{green}󰄲 git prompt details -> %B${SHOW_GIT_PROMPT}%b%f"
            return 0
            ;;
        timer)
            [[ -n "$arg" ]] && _save_pref "SHOW_CMD_TIMER" "$arg" || _toggle_pref "SHOW_CMD_TIMER"
            print -P "%F{green}󰄲 execution timer -> %B${SHOW_CMD_TIMER}%b%f"
            return 0
            ;;
        roasts|roast)
            [[ -n "$arg" ]] && _save_pref "ENABLE_PSYCHO_ROASTS" "$arg" || _toggle_pref "ENABLE_PSYCHO_ROASTS"
            print -P "%F{green}󰄲 typo psychological roaster -> %B${ENABLE_PSYCHO_ROASTS}%b%f"
            return 0
            ;;
        greeting)
            [[ -n "$arg" ]] && _save_pref "SHOW_GREETING_ROAST" "$arg" || _toggle_pref "SHOW_GREETING_ROAST"
            print -P "%F{green}󰄲 existential greeting on open -> %B${SHOW_GREETING_ROAST}%b%f"
            return 0
            ;;
        fastfetch)
            [[ -n "$arg" ]] && _save_pref "SHOW_FASTFETCH" "$arg" || _toggle_pref "SHOW_FASTFETCH"
            print -P "%F{green}󰄲 fastfetch on open -> %B${SHOW_FASTFETCH}%b%f"
            return 0
            ;;
        reset)
            _init_prefs
            source "$PREFS_FILE"
            _reload_prompt
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
        local items=(
            "󰞷 prompt style: [${PROMPT_STYLE:-two-line}]"
            "󰊠 prompt symbol: [${PROMPT_SYMBOL:-❯}]"
            "󰏘 prompt symbol accent: [${PROMPT_ACCENT:-primary}]"
            " git details in prompt: [${SHOW_GIT_PROMPT:-true}]"
            "󰁕 execution timer in prompt: [${SHOW_CMD_TIMER:-true}]"
            "󰄛 fastfetch on open: [${SHOW_FASTFETCH:-false}]"
            "󰄛 existential greeting on open: [${SHOW_GREETING_ROAST:-false}]"
            "󰅚 psychological roaster on typo: [${ENABLE_PSYCHO_ROASTS:-true}]"
            "󰌌 keybinding mode: [${KEY_BIND_MODE:-emacs}]"
            "󰄲 view help cheatsheet"
            "󰚰 recompile zsh bytecode (.zwc speedup)"
            "󰀦 purge .zwc bytecode cache (reset)"
            "󰅚 exit settings"
        )

        local choice
        choice=$(printf "%s\n" "${items[@]}" | fzf --header="[󰄛 zsh & terminal settings - select to customize]" --reverse --height=55%)
        [[ -z "$choice" || "$choice" == *"exit settings"* ]] && break

        case "$choice" in
            *"prompt style"*)
                local s_choice
                s_choice=$(printf "%s\n" \
                    "two-line   (classic 2-line box with system, directory, and arrow)" \
                    "single-line (compact user@host in path ❯)" \
                    "minimal     (clean path ❯)" \
                    "bracket     ([user@host path] ❯)" \
                    "unhinged    (random mood kaomoji before prompt)" \
                    | fzf --header="[choose your prompt layout style]" --reverse --height=35%)
                [[ -n "$s_choice" ]] && _save_pref "PROMPT_STYLE" "${s_choice%% *}"
                ;;
            *"prompt symbol:"*)
                local sym_choice
                sym_choice=$(printf "%s\n" \
                    "❯  (default sharp arrow)" \
                    "$  (unix classic)" \
                    "󰄛  (hypr cat)" \
                    "λ  (lambda)" \
                    ">  (simple chevron)" \
                    "%  (zsh percent)" \
                    ">> (double chevron)" \
                    | fzf --header="[choose your prompt symbol character]" --reverse --height=35%)
                [[ -n "$sym_choice" ]] && _save_pref "PROMPT_SYMBOL" "${sym_choice%% *}"
                ;;
            *"prompt symbol accent"*)
                local acc_choice
                acc_choice=$(printf "%s\n" \
                    "primary    (wallpaper matugen primary accent)" \
                    "secondary  (wallpaper matugen secondary accent)" \
                    "tertiary   (wallpaper matugen tertiary accent)" \
                    "cyan       (bright cyan accent)" \
                    "green      (neon green accent)" \
                    "magenta    (lavender magenta accent)" \
                    "yellow     (golden yellow accent)" \
                    "white      (crisp white)" \
                    | fzf --header="[choose your prompt arrow color accent]" --reverse --height=40%)
                [[ -n "$acc_choice" ]] && _save_pref "PROMPT_ACCENT" "${acc_choice%% *}"
                ;;
            *"git details"*)          _toggle_pref "SHOW_GIT_PROMPT" ;;
            *"execution timer"*)      _toggle_pref "SHOW_CMD_TIMER" ;;
            *"fastfetch"*)            _toggle_pref "SHOW_FASTFETCH" ;;
            *"existential greeting"*) _toggle_pref "SHOW_GREETING_ROAST" ;;
            *"psychological roaster"*) _toggle_pref "ENABLE_PSYCHO_ROASTS" ;;
            *"keybinding mode"*)
                if [[ "$KEY_BIND_MODE" == "emacs" ]]; then
                    _save_pref "KEY_BIND_MODE" "vi"
                    bindkey -v
                else
                    _save_pref "KEY_BIND_MODE" "emacs"
                    bindkey -e
                fi
                ;;
            *"view help cheatsheet"*)
                (( $+functions[dots_help] )) && dots_help || (( $+functions[help] )) && help
                print -Pn "\n%F{244}press enter to return to settings...%f"
                read -r </dev/tty 2>/dev/null || true
                ;;
            *"recompile zsh"*)
                (( $+functions[zrecompile] )) && zrecompile 2>/dev/null || true
                print -Pn "\n%F{green}󰄲 compiled. press enter to continue...%f"
                read -r </dev/tty 2>/dev/null || true
                ;;
            *"purge .zwc"*)
                (( $+functions[zclean] )) && zclean 2>/dev/null || true
                print -Pn "\n%F{yellow}󰀦 purged. press enter to continue...%f"
                read -r </dev/tty 2>/dev/null || true
                ;;
        esac
    done

    print -P "%F{green}󰄲 zsh preferences synced -> ${PREFS_FILE}%f"
}

alias rice-settings="settings"
