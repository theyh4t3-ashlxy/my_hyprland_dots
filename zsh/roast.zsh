# keeping score of your mental decline across sessions
zmodload -i zsh/datetime 2>/dev/null

typeset -g _EXISTENTIAL_FAILS=0
typeset -g _IN_CNF=0

command_not_found_handler() {
    local cmd="$1"
    
    # prevent infinite recursion if helper commands misfire
    if (( _IN_CNF > 0 )); then
        return 127
    fi
    _IN_CNF=1
    
    (( _EXISTENTIAL_FAILS++ ))
    
    local hour=12
    if (( $+EPOCHSECONDS )); then
        hour=$(strftime "%-H" "$EPOCHSECONDS" 2>/dev/null || echo 12)
    fi
    
    # the grand existential trauma vault
    local roasts=(
        "command '$cmd' not found. just like the purpose of opening this terminal at 2am."
        "'$cmd' is not recognized. you have been sitting in this exact chair for hours accomplishing nothing."
        "zsh: cannot find '$cmd\. no matter how much you rice this desktop, the void inside remains unconfigured."
        "failed to execute '$cmd\. another action with zero tangible outcome in your life."
        "error: '$cmd' does not exist. much like your work-life balance."
        "zsh: command '$cmd' not found. was this keystroke truly your own, or just muscle memory distracting you from your deadlines?"
        "'$cmd' is undefined. you are customizing dotfiles for an audience that will never see them."
        "command '$cmd' failed. a subtle reminder of every opportunity you hesitated on."
        "zsh: '$cmd' was not found. even the shell is growing tired of watching you type aimlessly."
        "'$cmd' does not exist in any PATH. much like the direction you are currently heading."
        "command '$cmd' not found. you optimize milliseconds off your shell startup time while leaking entire years of your youth."
        "'$cmd' is undefined. you use a cli because deterministic errors feel safer than unpredictable human relationships."
        "zsh: cannot find '$cmd\. closing this terminal won't fix the quiet panic waiting for you when the screen goes dark."
        "failed to execute '$cmd\. you're rearranging config files just to feel a fleeting sense of control over an uncontrollable life."
        "error: '$cmd' does not exist. somewhere along the way you swapped genuine human warmth for keyboard switches and called it a hobby."
        "zsh: command '$cmd' missing. you stare into this buffer hoping syntax errors distract you from how fast your 20s are evaporating."
        "'$cmd' not found. the dopamine you promised yourself three hours ago is not in this directory."
        "zsh: '$cmd' is not in PATH. you've automated everything except dealing with the person you become when you're left alone with your thoughts."
        "command '$cmd' failed. your peers are out building lives and you are here mistyping keystrokes to an empty room."
        "'$cmd' does not exist. it's crazy how much energy you spend escaping the people who genuinely used to check in on you."
        "command '$cmd' not found. your 10-year-old self thought you'd be doing something profound by now, not misspelling commands in the dark."
        "'$cmd' is undefined. you have 40+ browser tabs open of articles you will never read, hoarding knowledge you will never apply."
        "zsh: cannot find '$cmd\. this isn't flow state. this is just dissociation with a mechanical keyboard."
        "failed to execute '$cmd\. how many messages from real people are sitting unread while you pretend you're 'too locked in' right now?"
        "error: '$cmd' does not exist. you fixate on keyboard shortcuts because confronting your actual life trajectory requires too much energy."
        "zsh: '$cmd' missing. you're one minor inconvenience away from an unrecoverable mental breakdown and we both know it."
        "'$cmd' not found. nobody is grading you on this. nobody is watching. you are exhausting yourself for a ghost."
        "zsh: '$cmd' is not in PATH. you keep checking the terminal because checking your bank account requires emotional stability you don't have."
        "command '$cmd' failed. another micro-failure in an unbroken streak of projects you started, hyperfixated on, and abandoned."
        "'$cmd' does not exist. your posture is actively decaying your spine while you debug things that won't matter in six months."
        "zsh: '$cmd' unresolvable. you optimize your workflow to save 3 seconds, then spend 4 hours doomscrolling in bed anyway."
        "error: '$cmd' not found. you hide behind technical perfectionism because if you never finish anything, you can never be judged."
    )

    # 3am sanity check modifiers
    if (( hour >= 0 && hour < 5 )); then
        roasts+=(
            "command '$cmd' not found. it's ${hour}am. you aren't being productive, you're just too afraid of your own thoughts to go to sleep."
            "'$cmd' missing. tomorrow is going to hurt, and you're actively choosing to make it worse right now."
            "zsh: '$cmd' not found. the sun will rise in a few hours and you have nothing to show for tonight except blue-light eye strain."
            "command '$cmd' not found. it's ${hour}am. nobody is watching. nobody is impressed. go the fuck to sleep."
            "'$cmd' missing. this late night productivity is just insomnia disguised as ambition."
            "zsh: '$cmd' not found. typing into the dark won't make tomorrow hurt any less."
        )
    fi

    # consecutive failure escalation
    if (( _EXISTENTIAL_FAILS >= 3 )); then
        roasts+=(
            "command '$cmd' failed. that's ${_EXISTENTIAL_FAILS} typos in a row. your hands are shaking and your brain is fried. walk away."
            "'$cmd' not found. ${_EXISTENTIAL_FAILS} consecutive failures. you're rage-typing into an unfeeling terminal emulator."
            "zsh: '$cmd' missing. you are losing motor control. drink some fucking water."
            "error: '$cmd' not found. ${_EXISTENTIAL_FAILS} misfires back-to-back. the keyboard isn't broken, you are just spiraling."
        )
    fi
    
    # picking the specific knife to twist
    if [[ "${ENABLE_PSYCHO_ROASTS:-true}" == "true" ]]; then
        local random_roast="${roasts[$(( RANDOM % ${#roasts[@]} + 1 ))]}"
        print -P "\n%F{red}󰅚%f %F{244}${random_roast}%f"
    else
        print -P "\n%F{red}󰅚%f %F{244}command not found: %F{white}${cmd}%f"
    fi
    
    # figure out how to feed your binary hoarding addiction
    local pkg=""
    local helper="sudo pacman -S"
    
    if (( $+commands[paru] )); then
        helper="paru -S"
    elif (( $+commands[yay] )); then
        helper="yay -S"
    elif (( $+commands[pacman] )); then
        helper="sudo pacman -S"
    elif (( $+commands[dnf] )); then
        helper="sudo dnf install"
    elif (( $+commands[apt] )); then
        helper="sudo apt install"
    fi

    # dig through the repos safely without subshell failure
    if (( $+commands[pkgfile] )); then
        pkg=$(pkgfile -b -v "$cmd" 2>/dev/null | head -n 1 | awk '{print $1}')
    elif (( $+commands[pacman] )); then
        pkg=$(pacman -Fq "bin/$cmd" 2>/dev/null | head -n 1)
    fi

    if [[ -n "$pkg" ]]; then
        print -P "  %F{cyan}󰄛 copium:%f you can download more distraction via %F{green}%B${pkg}%b%f (run: %F{magenta}${helper} ${pkg}%f)
"
    else
        print ""
    fi
    
    _IN_CNF=0
    return 127
}

# wipes your failure streak clean when you actually manage to type a valid command
preexec() {
    _EXISTENTIAL_FAILS=0
}
