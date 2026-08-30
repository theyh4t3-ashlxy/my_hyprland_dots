# --- Everyday Shortcuts (aliases.zsh) ---

# 1. Fast Arch System Maintenance
alias p="paru"
alias update="paru -Syu"
alias install="paru -S"
alias remove="paru -Rns"
alias cleanup="paru -Rns \$(paru -Qtdq)" # Instantly purge orphaned packages

# 2. Micro Editor Shortcut
alias mc="micro"

# 3. GUI Nautilus Shortcut (Opens Nautilus in the current folder)
alias fm="nautilus . >/dev/null 2>&1 &"

# 4. Yazi CLI File Manager with auto-cd wrapper
yz() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

# 5. Git & Github Shortcuts (featuring Lazygit)
if (( $+commands[lazygit] )); then
    alias lg="lazygit"
fi
alias gs="git status"
alias gd="git diff"
alias gp="git push"
alias gc="git commit -m"
alias ga="git add"

# 6. Rice Utilities
alias color="hyprpicker -a" # Grabs hex color from screen and copies to clipboard

# 7. Suffix Aliases (typing a file name opens directly in editor)
alias -s {qml,lua,conf,toml,json,zsh,sh,css,md,txt,yaml,yml}=${EDITOR:-micro}

# 8. Global Pipe Aliases (e.g. pacman -Q G hypr)
alias -g G='| grep -i'
alias -g L='| less'
alias -g F='| fzf'
alias -g B='| bat'

# 9. Fast Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias -- -='cd -'

# 10. Named Directory Bookmarks (~dots, ~hypr, ~qs, ~wp)
hash -d dots="$HOME/my-hyprland-dots"
hash -d hypr="$HOME/my-hyprland-dots/hypr"
hash -d qs="$HOME/my-hyprland-dots/quickshell"
hash -d wp="$HOME/.wallpapers"
