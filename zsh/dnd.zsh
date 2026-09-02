# dnd: do not disturb mode controller

dnd() {
    local arg="${1:-toggle}"
    local conf_file="$HOME/.config/quickshell/settings.conf"
    [[ ! -f "$conf_file" ]] && touch "$conf_file"

    local current_dnd="false"
    if grep -q "^dnd=true" "$conf_file" 2>/dev/null; then
        current_dnd="true"
    fi

    case "$arg" in
        on|enable|1)
            if grep -q "^dnd=" "$conf_file"; then
                sed -i "s|^dnd=.*|dnd=true|" "$conf_file"
            else
                echo "dnd=true" >> "$conf_file"
            fi
            print -P "%F{magenta}󰂛 dnd enabled%f - %F{dim}notification toasts silenced%f"
            ;;
        off|disable|0)
            if grep -q "^dnd=" "$conf_file"; then
                sed -i "s|^dnd=.*|dnd=false|" "$conf_file"
            else
                echo "dnd=false" >> "$conf_file"
            fi
            print -P "%F{green}󰂚 dnd disabled%f - %F{dim}notification toasts active%f"
            ;;
        status)
            if [[ "$current_dnd" == "true" ]]; then
                print -P "%F{magenta}󰂛 dnd is active%f (%F{dim}toasts muted%f)"
            else
                print -P "%F{green}󰂚 dnd is inactive%f (%F{dim}toasts unmuted%f)"
            fi
            ;;
        toggle|*)
            if [[ "$current_dnd" == "true" ]]; then
                dnd off
            else
                dnd on
            fi
            ;;
    esac
}
