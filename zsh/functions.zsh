# interactive fuzzy helpers & quick utilities

take() {
    if [[ -z "$1" ]]; then
        print -P "%F{yellow}󰀦 take what? path missing%f"
        return 1
    fi
    mkdir -p "$1" && cd "$1"
}
alias mkcd="take"

reload-qs() {
    { qs kill; qs -d; } > /dev/null 2>&1
    print -P "%F{green}󰄲 quickshell daemon reloaded :3%f"
}
alias restart-qs="reload-qs"

# fuzzy find inside files with ripgrep and bat preview
fif() {
    if ! (( $+commands[rg] )) || ! (( $+commands[fzf] )); then
        print -P "%F{red}󰅚 rg or fzf missing%f"
        return 1
    fi
    local file_line
    file_line=$(rg --color=always --line-number --no-heading --smart-case "${*:-}" 2>/dev/null |
        fzf --ansi \
            --delimiter : \
            --preview 'bat --style=numbers --color=always {1} --highlight-line {2}' \
            --preview-window 'right,60%,border-left,+{2}+3/3,~3')
    if [[ -n "$file_line" ]]; then
        local file="${file_line%%:*}"
        local rest="${file_line#*:}"
        local line="${rest%%:*}"
        ${EDITOR:-micro} "+${line}" "$file"
    fi
}

# fkill aliases directly to the process sniper in nuke.zsh
alias fkill="nuke"

# ephemeral nix-shell environment
try() {
    if [[ -z "$1" ]]; then
        print -P "%F{yellow}󰀦 usage: try <package ...>%f"
        return 1
    fi
    print -P "%F{cyan}󰄛 entering ephemeral nix environment for: %F{green}$*%f"
    nix-shell -p "$@"
}
alias in="try"
alias fin="try"

# package removal reminder for declarative system
un() {
    print -P "%F{yellow}󰀦 NixOS packages are declarative! Remove the package from ~nix/configuration.nix and run 'rebuild'.%f"
}
alias fun="un"

# fuzzy edit file
fe() {
    local file
    file=$(fzf --preview 'bat --style=numbers --color=always --line-range :100 {} 2>/dev/null || head -n 100 {}' --header="[󰈙 open file]")
    [[ -n "$file" ]] && ${EDITOR:-micro} "$file"
}

# list nixos system generations
gens() {
    print -P "%F{cyan}󰋊 [nixos system generations]%f"
    nixos-rebuild list-generations
}
alias generations="gens"
alias snaps="gens"


