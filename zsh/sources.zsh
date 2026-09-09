# master dotfiles wiring
local zdir="${ZDOTDIR:-$HOME/.config/zsh}"

# preferences & path exports must load first
[[ -f "$zdir/user_prefs.conf" ]] && source "$zdir/user_prefs.conf"
[[ -f "$zdir/exports.zsh" ]]     && source "$zdir/exports.zsh"

# modular components in optimized dependency order
local -a _mods=(
    core matugen plugins aliases tools functions
    quicknav dev wp nuke dnd roast settings help local prompt
)

local mod f
for mod in "${_mods[@]}"; do
    f="$zdir/$mod.zsh"
    [[ -f "$f" ]] && source "$f"
done
unset _mods mod f

# interactive terminal greeting
if [[ -o interactive && -t 0 && -t 1 ]]; then
    if [[ "${SHOW_FASTFETCH:-false}" == "true" ]] && (( $+commands[fastfetch] )); then
        fastfetch
    fi

    if [[ "${SHOW_GREETING_ROAST:-false}" == "true" ]]; then
        (( $+functions[greeting_roast] )) && greeting_roast
    fi
fi
