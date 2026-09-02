# nyae: [n]o, [y]es, [a]bort, [e]dit confirmation & action framework
# because accidentally wiping your disk is a skill issue you can avoid

nyae() {
    local cmd="${*:-}"
    
    if [[ -z "$cmd" ]]; then
        print -P "%F{magenta}󰄛 nyae%f - [n]o, [y]es, [a]bort, [e]dit prompt guard"
        print -P "  usage: %F{cyan}nyae <command to execute>%f"
        print -P "  example: %F{yellow}nyae git push origin main --force%f"
        print -P "  example: %F{yellow}nyae rm -rf ./target_dir%f"
        return 0
    fi

    local prompt_color="\e[38;5;141m"
    local reset="\e[0m"
    local yellow="\e[38;5;221m"
    local red="\e[38;5;203m"
    local green="\e[38;5;120m"
    local cyan="\e[38;5;117m"
    local bold="\e[1m"
    local dim="\e[38;5;244m"

    print -P "${prompt_color}󰄛 nyae guard:${reset} ${bold}${cmd}${reset}"
    print -Pn "  ${dim}[${reset}${green}${bold}y${reset}${dim}]es  [${reset}${yellow}${bold}n${reset}${dim}]o  [${reset}${red}${bold}a${reset}${dim}]bort  [${reset}${cyan}${bold}e${reset}${dim}]dit ${reset}${prompt_color}❯${reset} "

    local key
    read -k 1 key
    print ""

    case "$key" in
        y|Y|$'\n'|$'\r')
            print -P "  ${green}󰄲 executing...${reset}"
            eval "$cmd"
            return $?
            ;;
        n|N)
            print -P "  ${yellow}󰀦 skipped.${reset}"
            return 0
            ;;
        a|A|$'\e'|q|Q)
            print -P "  ${red}󰅚 aborted by user.${reset}"
            return 1
            ;;
        e|E)
            local tmp_edit="$(mktemp -t "nyae-edit.XXXXXX")"
            print -r -- "$cmd" > "$tmp_edit"
            ${EDITOR:-micro} "$tmp_edit"
            local edited_cmd="$(<"$tmp_edit")"
            rm -f "$tmp_edit"
            
            if [[ -n "$edited_cmd" && "$edited_cmd" != "$cmd" ]]; then
                print -P "  ${cyan}󰁕 updated command:${reset} ${bold}${edited_cmd}${reset}"
                nyae "$edited_cmd"
                return $?
            else
                print -P "  ${yellow}󰀦 no changes made, executing original...${reset}"
                eval "$cmd"
                return $?
            fi
            ;;
        *)
            print -P "  ${red}󰅚 invalid choice '${key}', aborting.${reset}"
            return 1
            ;;
    esac
}

# quick safety wrappers
safe-rm() {
    nyae "rm -rf $*"
}

safe-push() {
    nyae "git push $*"
}
