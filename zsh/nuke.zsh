# nuke: interactive process sniper & auto-sudo terminator

nuke() {
    local target="${1:-}"

    # If specific process name or PID is passed directly
    if [[ -n "$target" && "$target" != "-i" ]]; then
        local pids=()
        if [[ "$target" =~ ^[0-9]+$ ]]; then
            pids=( "$target" )
        else
            pids=( ${(f)"$(pgrep -f "$target" 2>/dev/null || true)"} )
        fi

        if (( ${#pids[@]} == 0 )); then
            print -P "%F{yellow}󰀦 no processes found matching '$target'%f"
            return 1
        fi

        print -P "%F{red}󰅚 nuking ${#pids[@]} process(es) matching '$target'...%f"
        for p in "${pids[@]}"; do
            if kill -9 "$p" 2>/dev/null; then
                print -P "  %F{green}󰄲 terminated PID $p%f"
            else
                print -P "  %F{yellow}󰀦 permission denied for PID $p, escalating to sudo...%f"
                sudo kill -9 "$p" && print -P "  %F{green}󰄲 terminated PID $p (via sudo)%f"
            fi
        done
        return 0
    fi

    # Interactive FZF Process Sniper
    if ! (( $+commands[fzf] )); then
        print "usage: nuke <process_name | pid>"
        return 1
    fi

    local selected=$(ps -eo pid,user,%cpu,%mem,comm,args --sort=-%cpu | sed 1d | \
        fzf -m --header="[󰅚 NUKE PROCESS - TAB to multi-select, ENTER to kill]" \
            --header-first \
            --prompt="nuke ❯ " \
            --preview="echo {} | awk '{print \$6}'" \
            --preview-window=down:3:wrap \
            --reverse --height=50%)

    [[ -z "$selected" ]] && return 0

    local kill_pids=( $(echo "$selected" | awk '{print $1}') )
    if (( ${#kill_pids[@]} > 0 )); then
        print -P "%F{red}󰅚 executing lethal force on ${#kill_pids[@]} process(es)...%f"
        for p in "${kill_pids[@]}"; do
            if kill -9 "$p" 2>/dev/null; then
                print -P "  %F{green}󰄲 terminated PID $p%f"
            else
                print -P "  %F{yellow}󰀦 permission denied on PID $p, requesting sudo...%f"
                sudo kill -9 "$p" && print -P "  %F{green}󰄲 terminated PID $p (via sudo)%f"
            fi
        done
    fi
}
