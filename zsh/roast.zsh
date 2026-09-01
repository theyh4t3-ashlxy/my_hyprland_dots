# psychological & existential command not found handler
# questioning your life choices one typo at a time

command_not_found_handler() {
    local cmd="$1"
    
    local roasts=(
        "command '$cmd' not found. just like the purpose of opening this terminal at 2am."
        "'$cmd' is not recognized. you have been sitting in this exact chair for hours accomplishing nothing."
        "zsh: cannot find '$cmd'. no matter how much you rice this desktop, the void inside remains unconfigured."
        "failed to execute '$cmd'. another action with zero tangible outcome in your life."
        "error: '$cmd' does not exist. much like your work-life balance."
        "zsh: command '$cmd' not found. was this keystroke truly your own, or just muscle memory distracting you from your deadlines?"
        "'$cmd' is undefined. you are customizing dotfiles for an audience that will never see them."
        "command '$cmd' failed. a subtle reminder of every opportunity you hesitated on."
        "zsh: '$cmd' was not found. even the shell is growing tired of watching you type aimlessly."
        "'$cmd' does not exist in any PATH. much like the direction you are currently heading."
    )
    
    local random_roast="${roasts[$(( RANDOM % ${#roasts[@]} + 1 ))]}"
    print -P "%F{red}󰅚%f %F{244}${random_roast}%f"
    
    # Check if command exists in Arch repos
    if (( $+commands[pacman] )); then
        local pkg=$(pacman -Fq "$cmd" 2>/dev/null | head -n 1)
        if [[ -n "$pkg" ]]; then
            print -P "  %F{cyan}󰄛 reality check:%f '$cmd' might exist in package %F{green}%B${pkg}%b%f (run: %F{magenta}paru -S ${pkg}%f)"
        fi
    fi
    
    return 127
}
