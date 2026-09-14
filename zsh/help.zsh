# cheatsheet: dots, shell shortcuts, and desktop controls
# warning: reading this will not make your rice look like unixporn

dots_help() {
    # 8-bit colors because truecolor in a tty is pure vanity
    local c_pri="%F{141}" c_sec="%F{117}" c_ter="%F{221}"
    local c_cmd="%F{120}" c_dim="%F{244}" c_rst="%f"

    print -P "${c_pri}󰄛 hyprland + quickshell + zsh cheat sheet${c_rst}"
    print -P "${c_dim}dont panic. here is everything wired into this rice.${c_rst}\n"

    # data table because hardcoded spacebar art is for barbarians
    local -a entries=(
        "HEADER:󰞷 zsh & terminal"
        "settings / rice-settings | customize prompt style, accent color & roasts"
        "help / dots-help         | display this cheat sheet"
        "c <dir>                  | smart cd with automatic eza listing"
        "ll / la / tree           | eza file listings with git status & icons"
        "cat <file>               | bat with syntax highlighting and line numbers"
        "find <query>             | fd fast search"
        "grep <pattern>           | ripgrep file search"
        "yz / yazi                | terminal file manager with cwd sync on exit"
        "mc <file>                | micro editor for when vim refuses to let you leave"
        "zrecompile / zclean      | compile / clean .zwc bytecode caches"
        "GAP:"
        "HEADER:󰏘 wallpaper & matugen"
        "wp random [category]     | roll random wallpaper + matugen color refresh"
        "wp select                | interactive wallpaper chooser via fzf"
        "wp fetch <query>         | download live wallpaper loop from giphy"
        "wp color <hex>           | set custom hex color scheme"
        "wp scan                  | rescan ~/.wallpapers directory"
        "color                    | hyprpicker screen hex color dropper"
        "dnd toggle               | toggle do not disturb (silence toasts)"
        "GAP:"
        "HEADER:󰄲 quickshell & session"
        "qs -d                    | launch quickshell background daemon"
        "quickshell kill          | murder running quickshell instance"
        "quickshell log -t 30     | tail live quickshell logs before it crashes"
        "nuke                     | interactive process sniper & auto-sudo guillotine"
        "GAP:"
        "HEADER: git shortcuts"
        "gs (status -sb)          | ga (add)          | gaa (add all)"
        "gc (commit -m)           | gp (push)         | gl (log graph)"
        "gd (diff)                | gco (checkout)    | gcb (checkout -b)"
        "GAP:"
        "HEADER:󰌌 hyprland hotkeys (binds.lua)"
        "Win + T                  | open kitty terminal (uwsm)"
        "Win + Q                  | close active window"
        "Win + F                  | toggle fullscreen"
        "Win + Space              | toggle floating window"
        "Win + Shift + Space      | toggle float and pin window"
        "Win + I / J / K / L      | focus window (the wrist-sparing layout)"
        "Win + Shift + IJKL       | move window (same layout, more adrenaline)"
        "Win + 1..9, 0            | switch to workspace 1..10"
        "Win + Alt + W            | roll random wallpaper on the fly"
        "Win + End                | lock screen (quickshell / hyprlock)"
        "Win + Shift + End        | exit session (graceful uwsm stop)"
        "Print                    | quickshell screenshot tool"
    )

    local line cmd desc
    for line in "${entries[@]}"; do
        if [[ "$line" == "GAP:" ]]; then
            print ""
            continue
        fi

        if [[ "$line" == HEADER:* ]]; then
            # section headers for humans with decaying dopamine receptors
            print -P "${c_sec}${line#HEADER:}${c_rst}"
            continue
        fi

        # split on pipe delimiter
        cmd="${line%% | *}"
        desc="${line#* | }"

        # ${(r:24:)cmd} is native zsh string padding
        # because printf choked on prompt colors like a toddler on a battery
        if [[ "$cmd" == "Win "* ]]; then
            print -P "  ${c_ter}${(r:24:)cmd}${c_rst} ${c_dim}${desc}${c_rst}"
        elif [[ "$cmd" == "gs "* || "$cmd" == "gc "* || "$cmd" == "gd "* ]]; then
            # multi-column layout for git commands to avoid three feet of empty whitespace
            local col1="${cmd}"
            local col2="${desc%% | *}"
            local col3="${desc#* | }"
            print -P "  ${c_cmd}${(r:24:)col1}${c_rst} ${c_cmd}${(r:20:)col2}${c_rst} ${c_cmd}${col3}${c_rst}"
        else
            print -P "  ${c_cmd}${(r:24:)cmd}${c_rst} ${c_dim}${desc}${c_rst}"
        fi
    done

    # reminder that tweaking configs is not the same as getting work done
    print -P "\n${c_dim}type 'settings' to tweak your prompt and shell vibe.${c_rst}"
}

alias dots-help="dots_help"
alias cheatsheet="dots_help"
alias help="dots_help"
