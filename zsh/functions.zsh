# interactive fuzzy helpers & quick utilities

take() {
    if [[ -z "$1" ]]; then
        echo "take what, thoughex?"
        return 1
    fi
    mkdir -p "$1" && cd "$1"
}

reload-qs() {
    { qs kill; qs -d; } > /dev/null 2>&1
    echo "quickshell daemon reloaded :3"
}
restart-qs() { reload-qs; }

# fuzzy find inside files with ripgrep and bat preview
fif() {
    if ! (( $+commands[rg] )) || ! (( $+commands[fzf] )); then
        echo "rg or fzf missing"
        return 1
    fi
    local file_line
    file_line=$(rg --color=always --line-number --no-heading --smart-case "${*:-}" 2>/dev/null |
        fzf --ansi             --delimiter :             --preview 'bat --style=numbers --color=always {1} --highlight-line {2}'             --preview-window 'right,60%,border-left,+{2}+3/3,~3')
    if [[ -n "$file_line" ]]; then
        local file="${file_line%%:*}"
        local rest="${file_line#*:}"
        local line="${rest%%:*}"
        ${EDITOR:-micro} "+${line}" "$file"
    fi
}

# fuzzy kill process
fkill() {
    local pid
    pid=$(ps -ef | sed 1d | fzf -m --header="[󰅚 kill process]" | awk '{print $2}')
    if [[ -n "$pid" ]]; then
        echo "$pid" | xargs kill -${1:-9}
    fi
}

# fuzzy interactive package install
in() {
    if (( $+commands[paru] )); then
        local pkgs
        pkgs=$(paru -Slq | fzf --multi --preview 'paru -Si {1}' --preview-window=right:60%:wrap --header="[󰏤 install package]")
        [[ -n "$pkgs" ]] && echo "$pkgs" | xargs -ro paru -S
    fi
}

# fuzzy interactive package remove
un() {
    if (( $+commands[paru] )); then
        local pkgs
        pkgs=$(paru -Qq | fzf --multi --preview 'paru -Qi {1}' --preview-window=right:60%:wrap --header="[󰀦 remove package]")
        [[ -n "$pkgs" ]] && echo "$pkgs" | xargs -ro paru -Rns
    fi
}

# fuzzy edit file
fe() {
    local file
    file=$(fzf --preview 'bat --style=numbers --color=always --line-range :100 {} 2>/dev/null || head -n 100 {}' --header="[󰈙 open file]")
    [[ -n "$file" ]] && ${EDITOR:-micro} "$file"
}
