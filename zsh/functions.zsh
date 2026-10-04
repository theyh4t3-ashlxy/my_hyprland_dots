# interactive fuzzy helpers & quick utilities

# cd into a folder or pull down someone else's unmaintained code
take() {
    if [[ -z "$1" ]]; then
        print -P "%F{yellow}󰀦 take what? path or git url missing%f"
        return 1
    fi
    # git clone and dive straight into the wreckage
    if [[ "$1" =~ ^(https://|git@|ssh://).*(\.git)?$ ]] || [[ "$1" =~ ^github\.com/ ]]; then
        local repo="$1"
        git clone "$repo" || return 1
        local dir="${repo:t}"
        dir="${dir%.git}"
        builtin cd "$dir"
    else
        mkdir -p "$1" && cd "$1"
    fi
}
alias mkcd="take"

# touch with parent directory scaffolding so bash stops whining
mkfile() {
    if [[ -z "$1" ]]; then
        print -P "%F{yellow}󰀦 usage: mkfile <path/to/file>%f"
        return 1
    fi
    mkdir -p -- "${1:h}" && touch -- "$1" && print -P "%F{green}󰄲 created:%f $1"
}

# climb out of nested directory hell
up() {
    local count="${1:-1}"
    if ! [[ "$count" =~ ^[0-9]+$ ]]; then
        print -P "%F{red}󰅚 usage: up [number_of_levels]%f"
        return 1
    fi
    local path=""
    for (( i=0; i<count; i++ )); do
        path="../$path"
    done
    cd "$path"
}

# audit the crime scene that is your PATH variable
path() {
    print -P "%F{magenta}󰄛 system PATH ($#path entries):%f"
    local idx=1
    for p in "${path[@]}"; do
        if [[ -d "$p" ]]; then
            print -P "  %F{dim}[$idx]%f %F{cyan}${p}%f"
        else
            print -P "  %F{dim}[$idx]%f %F{red}${p}%f %F{dim}(missing)%f"
        fi
        (( idx++ ))
    done
}

# quick math in terminal because opening a gui calc app is defeat
_calc() {
    if [[ -z "$1" ]]; then
        print -P "%F{yellow}󰀦 usage: calc <math_expression>%f"
        return 1
    fi
    zmodload -i zsh/mathfunc 2>/dev/null
    print -P "%F{green}󰄲 %f$(( $* ))"
}
alias calc="noglob _calc"

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
