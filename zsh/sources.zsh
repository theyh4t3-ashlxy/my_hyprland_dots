# locating where my sanity is stored
local zdir="${ZDOTDIR:-$HOME/.config/zsh}"

# load user preferences
[[ -f "$zdir/user_prefs.conf" ]] && source "$zdir/user_prefs.conf"

# base shell wiring
[[ -f "$zdir/core.zsh" ]]     && source "$zdir/core.zsh"
[[ -f "$zdir/plugins.zsh" ]]  && source "$zdir/plugins.zsh"
[[ -f "$zdir/exports.zsh" ]]  && source "$zdir/exports.zsh"

# modern overrides and shortcuts
[[ -f "$zdir/aliases.zsh" ]]   && source "$zdir/aliases.zsh"
[[ -f "$zdir/tools.zsh" ]]     && source "$zdir/tools.zsh"
[[ -f "$zdir/functions.zsh" ]] && source "$zdir/functions.zsh"
[[ -f "$zdir/roast.zsh" ]]     && source "$zdir/roast.zsh"
[[ -f "$zdir/quicknav.zsh" ]]  && source "$zdir/quicknav.zsh"
[[ -f "$zdir/dev.zsh" ]]       && source "$zdir/dev.zsh"
[[ -f "$zdir/wp.zsh" ]]        && source "$zdir/wp.zsh"
[[ -f "$zdir/nuke.zsh" ]]      && source "$zdir/nuke.zsh"
[[ -f "$zdir/dnd.zsh" ]]       && source "$zdir/dnd.zsh"
[[ -f "$zdir/settings.zsh" ]]  && source "$zdir/settings.zsh"
[[ -f "$zdir/git.zsh" ]]       && source "$zdir/git.zsh"

# wallpaper hooks and local overrides
[[ -f "$zdir/hyprland.zsh" ]]  && source "$zdir/hyprland.zsh"
[[ -f "$zdir/matugen.zsh" ]]   && source "$zdir/matugen.zsh"
[[ -f "$zdir/local.zsh" ]]     && source "$zdir/local.zsh"

# the actual prompt
[[ -f "$zdir/prompt.zsh" ]]    && source "$zdir/prompt.zsh"

# terminal greeting experience (customizable via `settings`)
if [[ -o interactive && -t 0 && -t 1 ]]; then
    if [[ "${SHOW_FASTFETCH:-true}" == "true" ]] && (( $+commands[fastfetch] )); then
        fastfetch
    fi

    if [[ "${SHOW_GREETING_ROAST:-true}" == "true" ]]; then
        local greetings=(
            "remember: every minute spent ricing is a minute not debugging production."
            "your desktop is at 100% aesthetic capacity. now do something useful."
            "welcome back. the terminal missed you, but your sleep schedule did not."
            "ready to compile some questionable code."
            "system running at peak velocity. zero excuses remaining."
        )
        local greet="${greetings[$(( RANDOM % ${#greetings[@]} + 1 ))]}"
        print -P "%F{38;5;141m󰄛%f %F{244}${greet}%f"
    fi
fi
