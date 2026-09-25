# nixos system rebuild & package management
alias rebuild="sudo nixos-rebuild switch"
alias test-build="sudo nixos-rebuild test"
alias boot-build="sudo nixos-rebuild boot"
alias nsearch="nix search nixpkgs"
alias nshell="nix-shell -p"
alias nrun="nix run nixpkgs#"
alias nix-gens="nixos-rebuild list-generations"

# purge old generations and dead nix store paths
cleanup() {
    print -P "%F{cyan}󰄛 purging user generations & store garbage...%f"
    nix-collect-garbage -d
    if (( $+commands[sudo] )); then
        print -P "%F{cyan}󰄛 purging system-wide nix generations & store garbage...%f"
        sudo nix-collect-garbage -d
    fi
    print -P "%F{green}󰄲 nix store cleanup complete%f"
}


# text editor escape hatch
alias mc="micro"

# launch GUI file manager without hijacking stdout or locking directory
fm() {
    if (( $+commands[dolphin] )); then
        dolphin "${1:-.}" >/dev/null 2>&1 &!
    elif (( $+commands[nautilus] )); then
        nautilus "${1:-.}" >/dev/null 2>&1 &!
    else
        yz "${1:-.}"
    fi
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
hash -d dots="$HOME/.local/share/dotfiles"
hash -d hypr="$HOME/.local/share/dotfiles/hypr"
hash -d qs="$HOME/.local/share/dotfiles/quickshell"
hash -d nix="/etc/nixos"
hash -d wp="$HOME/.wallpapers"
hash -d conf="$HOME/.config"

# nmtui with dark aesthetic palette
alias nmtui="NEWT_COLORS=\"\$NEWT_COLORS\" command nmtui"

# it looks like i need agy as a run
alias agy="nix run github:jacopone/antigravity-nix"

# ok so i want mixtapes to work
export XDG_DATA_DIRS="$HOME/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:$XDG_DATA_DIRS"
