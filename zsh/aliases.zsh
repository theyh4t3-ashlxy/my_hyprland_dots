# shortcuts because my fingers are lazy
alias p="paru"
alias update="paru -Syu"
alias install="paru -S"
alias remove="paru -Rns"

# purge orphaned packages safely without crying on empty lists
cleanup() {
    local orphans=($(pacman -Qtdq 2>/dev/null))
    if (( ${#orphans[@]} > 0 )); then
        paru -Rns "${orphans[@]}"
    else
        print -P "%F{green}󰄲 no orphaned packages to clean%f"
    fi
}

# text editor escape hatch
alias mc="micro"

# launch nautilus without hijacking stdout or locking directory
fm() {
    nautilus "${1:-.}" >/dev/null 2>&1 &!
}

# yazi wrapper so exiting drops me in the current folder
yz() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

# git shortcuts so i can commit crimes faster
if (( $+commands[lazygit] )); then
    alias lg="lazygit"
fi
alias gs="git status -sb"
alias gd="git diff"
alias gp="git push"
alias gc="git commit -m"
alias gca="git commit --amend"
alias ga="git add"
alias gaa="git add -A"
alias gl="git log --oneline --graph --decorate -n 15"
alias gco="git checkout"
alias gcb="git checkout -b"

# steal color hex off screen
alias color="hyprpicker -a"

# type file name to edit it directly
alias -s {qml,lua,conf,toml,json,zsh,sh,css,md,txt,yaml,yml}=${EDITOR:-micro}

# pipe magic
alias -g G='| grep -i'
alias -g L='| less'
alias -g F='| fzf'
alias -g B='| bat'

# fast jumps
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias -- -='cd -'

# directory warps
hash -d dots="$HOME/my-hyprland-dots"
hash -d hypr="$HOME/my-hyprland-dots/hypr"
hash -d qs="$HOME/my-hyprland-dots/quickshell"
hash -d wp="$HOME/.wallpapers"
hash -d conf="$HOME/.config"
