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

# fuzzy interactive package install
in() {
    if (( $+commands[paru] )); then
        local pkgs
        pkgs=$(paru -Slq | fzf --multi --preview 'paru -Si {1}' --preview-window=right:60%:wrap --header="[󰏤 install package]")
        [[ -n "$pkgs" ]] && echo "$pkgs" | xargs -ro paru -S
    fi
}
alias fin="in"

# fuzzy interactive package remove
un() {
    if (( $+commands[paru] )); then
        local pkgs
        pkgs=$(paru -Qq | fzf --multi --preview 'paru -Qi {1}' --preview-window=right:60%:wrap --header="[󰀦 remove package]")
        [[ -n "$pkgs" ]] && echo "$pkgs" | xargs -ro paru -Rns
    fi
}
alias fun="un"

# fuzzy edit file
fe() {
    local file
    file=$(fzf --preview 'bat --style=numbers --color=always --line-range :100 {} 2>/dev/null || head -n 100 {}' --header="[󰈙 open file]")
    [[ -n "$file" ]] && ${EDITOR:-micro} "$file"
}
