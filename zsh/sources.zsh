# locating where my sanity is stored
local zdir="${ZDOTDIR:-$HOME/.config/zsh}"

# base shell wiring
[[ -f "$zdir/core.zsh" ]]    && source "$zdir/core.zsh"
[[ -f "$zdir/plugins.zsh" ]] && source "$zdir/plugins.zsh"
[[ -f "$zdir/exports.zsh" ]] && source "$zdir/exports.zsh"

# modern overrides and shortcuts
[[ -f "$zdir/aliases.zsh" ]]   && source "$zdir/aliases.zsh"
[[ -f "$zdir/tools.zsh" ]]     && source "$zdir/tools.zsh"
[[ -f "$zdir/functions.zsh" ]] && source "$zdir/functions.zsh"
[[ -f "$zdir/git.zsh" ]]       && source "$zdir/git.zsh"

# wallpaper hooks and local overrides
[[ -f "$zdir/hyprland.zsh" ]] && source "$zdir/hyprland.zsh"
[[ -f "$zdir/but.zsh" ]]      && source "$zdir/but.zsh"
[[ -f "$zdir/matugen.zsh" ]]  && source "$zdir/matugen.zsh"
[[ -f "$zdir/local.zsh" ]]    && source "$zdir/local.zsh"

# the actual prompt
[[ -f "$zdir/prompt.zsh" ]]   && source "$zdir/prompt.zsh"

if (( $+commands[fastfetch] )); then
    fastfetch
else
    echo "fastfetch not found. how will anyone know you use arch?"
fi
