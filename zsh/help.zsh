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
        "help / cheatsheet        | display this cheat sheet"
        "c <dir> / up [n]         | smart cd with auto-ls / jump up n levels"
        "ls / l / la              | eza compact grid (l is identical to ls, la = all)"
        "ll / lla                 | table view with git (ll = visible, lla = all)"
        "rlah / Rlah / lt / tree  | recursive long listing / tree views"
        "ld / lf / lk / lm        | filter dirs/files or sort by size/modtime"
        "take <dir|url>           | smart mkdir & cd, or git clone & cd"
        "mkfile <path>            | create file & missing parent directories"
        "d                        | directory stack history (jump with cd -1)"
        "cat <file> / preview     | bat syntax highlighted / numbered view"
        "fif <query> / fe         | fuzzy grep inside files / fuzzy open file"
        "fdd / fdf / fdh          | fd fast search (directories/files/hidden)"
        "rgi / rgh / rgw / rgf    | ripgrep (ignore-case, hidden, word, files)"
        "dus / df / free          | sorted dir sizes / disk usage / memory"
        "mc / edit                | micro editor"
        "yz / yazi                | terminal file manager with cwd sync on exit"
        "zrecompile / zclean      | compile / clean .zwc bytecode caches"
        "reload / sz              | restart shell / re-source zsh config"
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
        "gd (diff)                | gds (diff staged) | glog (pretty graph)"
        "gco (checkout)           | gcb (new branch)  | gsw / gswc (switch)"
        "gpl (pull --rebase)      | gst / gstp (stash)  | grh / grs (reset/restore)"
        "GAP:"
        "HEADER:󰅂 pipe shortcuts & global aliases"
        "G / L / F / B            | pipe to: grep -i | less | fzf | bat"
        "H / T / W / C            | pipe to: head | tail | wc -l | wl-copy"
        "N / E                    | redirect: >/dev/null 2>&1 | 2>&1"
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
        elif [[ "$cmd" == "gs "* || "$cmd" == "gc "* || "$cmd" == "gd "* || "$cmd" == "gco "* || "$cmd" == "gpl "* ]]; then
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
