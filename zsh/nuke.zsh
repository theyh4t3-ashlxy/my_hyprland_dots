# nuke: interactive process sniper & auto-sudo terminator

nuke() {
    local target="${1:-}"
    local pids=()

    # resolve target pids
    if [[ -n "$target" && "$target" != "-i" ]]; then
        if [[ "$target" =~ ^[0-9]+$ ]]; then
            pids=( "$target" )
        else
            # strip empty lines so array length is accurate
            pids=( ${(f)"$(pgrep -f -- "$target" 2>/dev/null)"} )
            pids=( ${pids:#} )
        fi

        if (( ${#pids[@]} == 0 )); then
            print -P "%F{yellow}󰀦 no processes found matching '$target'%f"
            return 1
        fi
    else
        if ! (( $+commands[fzf] )); then
            print "usage: nuke <process_name | pid>"
            return 1
        fi

        local selected
        selected=$(ps -eo pid,user,%cpu,%mem,comm,args --sort=-%cpu | sed 1d | \
            fzf -m --header="[󰅚 nuke process - tab to multi-select, enter to kill]" \
                --header-first \
                --prompt="nuke ❯ " \
                --preview="ps -u -p {1} 2>/dev/null || echo {6..}" \
                --preview-window=down:4:wrap \
                --reverse --height=50%)

        [[ -z "$selected" ]] && return 0

        pids=( ${(f)"$(print -r -- "$selected" | awk '{print $1}')"} )
        pids=( ${pids:#} )
    fi

    (( ${#pids[@]} == 0 )) && return 0

    print -P "%F{red}󰅚 targeting ${#pids[@]} process(es)...%f"

    local need_sudo=()
    for p in "${pids[@]}"; do
        # check if process actually exists before trying to kill it
        if ! kill -0 "$p" 2>/dev/null; then
            print -P "  %F{yellow}󰀦 pid $p no longer exists%f"
            continue
        fi

        if kill -9 "$p" 2>/dev/null; then
            print -P "  %F{green}󰄲 terminated pid $p%f"
        else
            need_sudo+=( "$p" )
        fi
    done

    # batch sudo execution instead of prompting inside a loop
    if (( ${#need_sudo[@]} > 0 )); then
        print -P "  %F{yellow}󰀦 permission denied for ${#need_sudo[@]} pid(s), escalating to sudo...%f"
        if sudo kill -9 "${need_sudo[@]}" 2>/dev/null; then
            for p in "${need_sudo[@]}"; do
                print -P "  %F{green}󰄲 terminated pid $p (via sudo)%f"
            done
        else
            print -P "  %F{red}󰅚 failed to terminate pid(s): ${need_sudo[*]}%f"
            return 1
        fi
    fi
}
