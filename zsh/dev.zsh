# developer superpowers & workflow enhancers

# instant scratchpad editor
scratch() {
    local sdir="${XDG_DATA_HOME:-$HOME/.local/share}/quickshell/scratch"
    mkdir -p "$sdir"
    local sfile="$sdir/scratch_$(date +%Y%m%d_%H%M%S).md"
    ${EDITOR:-micro} "$sfile"
    [[ ! -s "$sfile" ]] && rm -f "$sfile"
}

# show listening network ports and their PIDs
ports() {
    if (( $+commands[ss] )); then
        ss -tulwnp | grep -v "127.0.0.53"
    elif (( $+commands[lsof] )); then
        lsof -i -P -n | grep LISTEN
    else
        echo "neither ss nor lsof found"
    fi
}

# top resource hogs
topcpu() {
    ps aux --sort=-%cpu | head -n 11 | awk '{printf "%-8s %-6s %-6s %-6s %s\n", $1, $2, $3, $4, $11}'
}

topmem() {
    ps aux --sort=-%mem | head -n 11 | awk '{printf "%-8s %-6s %-6s %-6s %s\n", $1, $2, $3, $4, $11}'
}

# soft undo the last git commit
undo() {
    print -P "%F{yellow}󰀦 undoing last commit (keeping working tree intact)...%f"
    git reset --soft HEAD~1
}

# screen color picker with hex copy
pick() {
    if (( $+commands[hyprpicker] )); then
        local hex=$(hyprpicker -a)
        if [[ -n "$hex" ]]; then
            print -P "%F{green}󰄲 copied hex:%f %F{magenta}${hex}%f"
        fi
    else
        echo "hyprpicker not installed"
    fi
}
