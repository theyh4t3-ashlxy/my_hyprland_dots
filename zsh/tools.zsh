# modern cli tools replacing ancient gnu relics with rust/go power

# zoxide: fuzzy directory teleportation
if (( $+commands[zoxide] )); then
    eval "$(zoxide init zsh)"
    alias cd="z"
fi

# smart cd + auto-listing
c() {
    if [[ $# -eq 0 ]]; then
        builtin cd "$HOME" && (( $+commands[eza] )) && eza --color=auto --group-directories-first --icons=auto
    elif (( $+commands[z] )); then
        z "$@" && (( $+commands[eza] )) && eza --color=auto --group-directories-first --icons=auto
    else
        builtin cd "$@" && (( $+commands[eza] )) && eza --color=auto --group-directories-first --icons=auto
    fi
}

# eza: modern ls with icons and git integration
if (( $+commands[eza] )); then
    alias ls="eza --color=auto --group-directories-first --icons=auto"
    alias la="eza -a --color=auto --group-directories-first --icons=auto"
    alias ll="eza -l --color=auto --group-directories-first --icons=auto --git"
    alias l="eza -lah --color=auto --group-directories-first --icons=auto --git"
    alias lt="eza --tree --level=2 --icons=auto"
    alias tree="eza --tree --level=3 --icons=auto"
fi

# bat: cat with syntax highlighting (never page on direct cat)
if (( $+commands[bat] )); then
    alias cat="bat --style=plain --paging=never"
    alias preview="bat --style=numbers --color=always"
    alias b="bat"
fi

# ripgrep: ultra-fast regex search
if (( $+commands[rg] )); then
    alias grep="rg --smart-case"
    alias rgi="rg -i"
fi

# fd: fast, intuitive find alternative
if (( $+commands[fd] )); then
    alias find="fd"
    alias fdd="fd -t d"
    alias fdf="fd -t f"
fi

# btop: modern resource monitor
if (( $+commands[btop] )); then
    alias top="btop"
    alias htop="btop"
fi

# wl-clipboard: wayland system clipboard shortcuts
if (( $+commands[wl-copy] )); then
    alias copy="wl-copy"
    alias paste="wl-paste"
    alias pbcopy="wl-copy"
    alias pbpaste="wl-paste"
fi

# fastfetch: system info overview
if (( $+commands[fastfetch] )); then
    alias ff="fastfetch"
    alias fetch="fastfetch"
fi

# micro: fast intuitive terminal editor
if (( $+commands[micro] )); then
    alias mc="micro"
    alias edit="micro"
fi

# yazi: terminal file manager
if (( $+commands[yazi] )); then
    alias y="yz"
    alias yazi="yz"
fi

# fzf: fuzzy finder integration & preview wiring
if (( $+commands[fzf] )); then
    eval "$(fzf --zsh 2>/dev/null || fzf --shell=zsh 2>/dev/null || true)"
    export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border=none --color=16"
    export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :50 {} 2>/dev/null || eza --tree --level=2 --icons {} 2>/dev/null || head -200 {}' --bind 'ctrl-/:toggle-preview'"
    export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --icons --color=always {} 2>/dev/null || ls {}'"
fi
