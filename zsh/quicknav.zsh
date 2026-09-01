# quicknav: teleport across folders and bookmarks at lightspeed

MARKPATH="${XDG_DATA_HOME:-$HOME/.local/share}/quicknav/marks"
mkdir -p "$MARKPATH"

mark() {
    local name="${1:-$(basename "$PWD")}"
    ln -sfn "$PWD" "$MARKPATH/$name"
    print -P "%F{green}󰄲 marked:%f %F{magenta}${name}%f -> %F{dim}${PWD}%f"
}

unmark() {
    local name="${1:-}"
    if [[ -z "$name" ]]; then
        print "usage: unmark <bookmark_name>"
        return 1
    fi
    if [[ -L "$MARKPATH/$name" || -e "$MARKPATH/$name" ]]; then
        rm -f "$MARKPATH/$name"
        print -P "%F{yellow}󰀦 unmarked:%f %F{magenta}${name}%f"
    else
        print -P "%F{red}󰅚 bookmark not found:%f ${name}"
    fi
}

marks() {
    print -P "%F{magenta}󰄛 bookmarks:%f"
    for l in "$MARKPATH"/*(N); do
        local name="$(basename "$l")"
        local target="$(readlink "$l")"
        print -P "  %F{cyan}${name}%f -> %F{dim}${target}%f"
    done
}

jump() {
    local name="${1:-}"
    if [[ -z "$name" ]]; then
        if (( $+commands[fzf] )); then
            local sel=$(for l in "$MARKPATH"/*(N); do basename "$l"; done | fzf --header="[jump to bookmark]" --preview="readlink $MARKPATH/{}")
            [[ -n "$sel" ]] && cd "$MARKPATH/$sel"
        else
            marks
        fi
        return 0
    fi

    if [[ -d "$MARKPATH/$name" ]]; then
        cd "$MARKPATH/$name"
    else
        print -P "%F{red}󰅚 bookmark '${name}' does not exist.%f"
        return 1
    fi
}
