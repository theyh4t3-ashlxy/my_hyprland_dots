# modern tools that replaced ancient gnu relics
if (( $+commands[zoxide] )); then
    eval "$(zoxide init zsh)"
    alias cd="z" # teleports me across the filesystem before my brain finishes loading
fi

if (( $+commands[eza] )); then
    alias ls="eza --color=auto --group-directories-first --icons=auto" # icons on tty, raw text on pipe
    alias la="eza -a --color=auto --group-directories-first --icons=auto"
    alias ll="eza -l --color=auto --group-directories-first --icons=auto"
    alias lt="eza --tree --level=2 --icons=auto"
fi

if (( $+commands[bat] )); then
    alias cat="bat --style=plain" # cat with syntax highlighting so i can actually read
    alias preview="bat"
fi

if (( $+commands[fzf] )); then
    eval "$(fzf --zsh 2>/dev/null || fzf --shell=zsh 2>/dev/null || true)"
    export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :50 {} 2>/dev/null || eza --tree --level=2 --icons {} 2>/dev/null || head -200 {}' --bind 'ctrl-/:toggle-preview'"
    export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --icons --color=always {} 2>/dev/null || ls {}'"
fi
