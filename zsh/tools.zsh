# --- Modern CLI Tool Overrides (tools.zsh) ---

# 1. Zoxide (Smart directory jumper, replaces 'cd' with 'z')
if (( $+commands[zoxide] )); then
    eval "$(zoxide init zsh)"
    alias cd="z"
fi

# 2. Eza (Beautiful, colorful 'ls' replacement with Nerdfont icons)
if (( $+commands[eza] )); then
    alias ls="eza --color=always --group-directories-first --icons"
    alias la="eza -a --color=always --group-directories-first --icons"
    alias ll="eza -l --color=always --group-directories-first --icons"
    alias lt="eza --tree --level=2 --icons" # Shows directory tree 2 levels deep
fi

# 3. Bat (Better 'cat' with syntax highlighting and line numbers)
if (( $+commands[bat] )); then
    alias cat="bat --style=plain"
    alias preview="bat" # Keeps full formatting/git gutters
fi
