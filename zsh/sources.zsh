# Define the config directory path (fallback to ~/.config/zsh if ZDOTDIR isn't set)
local zdir="${ZDOTDIR:-$HOME/.config/zsh}"

# 1. Base Shell Setup
[[ -f "$zdir/core.zsh" ]]    && source "$zdir/core.zsh"
[[ -f "$zdir/plugins.zsh" ]] && source "$zdir/plugins.zsh"
[[ -f "$zdir/exports.zsh" ]] && source "$zdir/exports.zsh"

# 2. Aliases, Modern Tools, & Functions
[[ -f "$zdir/aliases.zsh" ]]   && source "$zdir/aliases.zsh"   # Old aliases
[[ -f "$zdir/tools.zsh" ]]     && source "$zdir/tools.zsh"     # Modern overrides
[[ -f "$zdir/functions.zsh" ]] && source "$zdir/functions.zsh" # Custom functions
[[ -f "$zdir/git.zsh" ]]       && source "$zdir/git.zsh"

# 3. Environment & Local Configurations
[[ -f "$zdir/hyprland.zsh" ]] && source "$zdir/hyprland.zsh"
[[ -f "$zdir/but.zsh" ]]      && source "$zdir/but.zsh"
[[ -f "$zdir/matugen.zsh" ]]  && source "$zdir/matugen.zsh"
[[ -f "$zdir/local.zsh" ]]    && source "$zdir/local.zsh"

# 4. Prompt Theme (Load right before fastfetch)
[[ -f "$zdir/prompt.zsh" ]]   && source "$zdir/prompt.zsh"

# Fastfetch (using fast Zsh-native command check to prevent forks)
if (( $+commands[fastfetch] )); then
    fastfetch
else
    echo "fastfetch not found. how will anyone know you use arch?"
fi
