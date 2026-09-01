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

# smart archive extractor
extract() {
    if [[ -z "$1" ]]; then
        print "usage: extract <archive_file>"
        return 1
    fi
    if [[ ! -f "$1" ]]; then
        print -P "%F{red}󰅚 file not found:%f $1"
        return 1
    fi
    case "$1" in
        *.tar.bz2)   tar xjf "$1"     ;;
        *.tar.gz)    tar xzf "$1"     ;;
        *.tar.xz)    tar xJf "$1"     ;;
        *.tar.zst)   tar --zstd -xf "$1" ;;
        *.bz2)       bunzip2 "$1"     ;;
        *.rar)       unrar x "$1"     ;;
        *.gz)        gunzip "$1"      ;;
        *.tar)       tar xf "$1"      ;;
        *.tbz2)      tar xjf "$1"     ;;
        *.tgz)       tar xzf "$1"     ;;
        *.zip)       unzip "$1"       ;;
        *.Z)         uncompress "$1"  ;;
        *.7z)        7z x "$1"        ;;
        *.deb)       ar x "$1"        ;;
        *.pkg)       tar xf "$1"      ;;
        *)           print -P "%F{red}󰅚 unknown archive format:%f $1" ;;
    esac
}

# copy working directory path to clipboard
cpwd() {
    if (( $+commands[wl-copy] )); then
        print -n "$PWD" | wl-copy
        print -P "%F{green}󰄲 copied working directory:%f %F{cyan}${PWD}%f"
    else
        echo "$PWD"
    fi
}

# copy file content to clipboard
cpfile() {
    if [[ -z "$1" || ! -f "$1" ]]; then
        print "usage: cpfile <file_path>"
        return 1
    fi
    if (( $+commands[wl-copy] )); then
        wl-copy < "$1"
        print -P "%F{green}󰄲 copied file content:%f %F{cyan}${1}%f"
    fi
}

# quick local network info
myip() {
    print -P "%F{magenta}󰄛 network info:%f"
    local local_ip=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}')
    print -P "  local ip:  %F{cyan}${local_ip:-unknown}%f"
    if (( $+commands[curl] )); then
        local pub_ip=$(curl -s --max-time 2 https://icanhazip.com 2>/dev/null)
        print -P "  public ip: %F{yellow}${pub_ip:-offline}%f"
    fi
}

# quick local http server
serve() {
    local port="${1:-8000}"
    print -P "%F{green}󰄲 starting local http server at http://localhost:${port}%f"
    python3 -m http.server "$port"
}

# make directory and enter it
mkcd() {
    mkdir -p "$1" && cd "$1"
}
