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
    
    # grounded developer humiliation
    local roasts=(
        "command '$cmd' not found. you typed that with astonishing confidence for someone guessing syntax."
        "'$cmd' is not recognized. your switches sounded crisp and loud, but the exit code is still 127."
        "zsh: cannot find '$cmd'. no matter how rounded your window corners are, the binary still has to exist."
        "failed to execute '$cmd'. another command typed solely to look busy when someone walks past your room."
        "error: '$cmd' does not exist. you spent four hours on a blur shader just to typo a basic utility."
        "zsh: command '$cmd' not found. your fingers slipped off the home row and you hit enter anyway."
        "'$cmd' is undefined. you have six custom alias files and still managed to invent a nonexistent command."
        "command '$cmd' failed. maybe try reading the man page instead of treating the shell like a slot machine."
        "zsh: '$cmd' was not found. even tab completion refused to participate in whatever that was."
        "'$cmd' does not exist in any PATH. much like your actual documentation."
        "command '$cmd' not found. you optimize milliseconds off shell startup just to sit here staring at stdout."
        "'$cmd' is undefined. you use a tiling window manager so you can fail commands in four equal quadrants."
        "zsh: cannot find '$cmd'. closing this terminal tab won't un-embarrass that typo."
        "failed to execute '$cmd'. your dotfiles repo has 400 commits and your actual project has an empty readme."
        "error: '$cmd' does not exist. you remapped capslock to escape and still couldn't exit this failure cleanly."
        "zsh: command '$cmd' missing. you're entering commands via pure muscle memory and zero cognitive oversight."
        "'$cmd' not found. the script you promised yourself you'd write three months ago is still a todo comment."
        "zsh: '$cmd' is not in PATH. you configured catppuccin mocha across twelve configs just to misspell 'cat'."
        "command '$cmd' failed. you mashed backspace three times and still managed to hit the wrong key."
        "'$cmd' does not exist. you have 40 tabs of arch wiki open and none of them taught you how to spell '$cmd'."
        "command '$cmd' not found. you're running on cold brew, dry eyes, and raw syntax denial."
        "'$cmd' is undefined. you're debugging your prompt theme while your actual project fails to build."
        "zsh: cannot find '$cmd'. this isn't flow state, you're just typing fast into an empty buffer."
        "failed to execute '$cmd'. you have eight nerd font glyph packs installed and zero working binaries for this."
        "error: '$cmd' does not exist. you could have checked '--help' or used tab completion, but you chose violence."
        "zsh: '$cmd' missing. your shell history is just an archive of desperate typos and 'cd ..'."
        "'$cmd' not found. you're typing at 110 wpm straight into a brick wall."
        "zsh: '$cmd' is not in PATH. you spent forty minutes picking a mono font to read error messages in italic."
        "command '$cmd' failed. your keyboard has lubed switches but your commands are completely unhinged."
        "'$cmd' does not exist. you hit up arrow 35 times hoping past-you ran something useful instead of this."
        "zsh: '$cmd' unresolvable. pipe that to /dev/null and pretend it never happened."
        "error: '$cmd' not found. you ran this command entirely on vibes and the shell rejected the vibes."
        "command '$cmd' not found. you wrote a custom command-not-found script instead of finishing your real work."
        "'$cmd' is not recognized. the terminal is currently 12-0 against your typing accuracy."
        "zsh: cannot find '$cmd'. you alias 'ls' to 'eza' and 'cat' to 'bat' and still can't find files."
        "error: '$cmd' missing. the cursor is blinking at you like it wants an explanation."
        "command '$cmd' failed. did you mean to run an actual command, or did your sleeve brush the enter key?"
        "zsh: '$cmd' undefined. you spend more time fixing indentation than actually running code."
        "failed to execute '$cmd'. you just hit ctrl+c after running a nonexistent binary out of pure panic."
        "'$cmd' not found. your neck is bent at a 90-degree angle and your shell is returning 127."
        "zsh: command '$cmd' failed. you are one typo away from aliasing your mistakes to real commands."
        "command '$cmd' missing. you configured custom prompt icons just to fail in full rgb."
        "error: '$cmd' does not exist. you're fighting zsh and zsh hasn't even broken a sweat."
        "zsh: '$cmd' not found. your dopamine receptors are fried. take your hands off the keyboard for five seconds."
        "command '$cmd' failed. you're piping random flags into a tool you haven't touched since last october."
        "'$cmd' is undefined. your git status has 22 unstaged changes and you're over here inventing shell syntax."
        "zsh: command '$cmd' not found. maybe if you buy a heavier keycap set you'll hit the right letter."
        "'$cmd' does not exist. you migrated from bash to zsh just to make typos with slightly better completion."
        "error: '$cmd' unresolvable. you're two misfires away from running 'chmod 777' on your home directory."
        "failed to execute '$cmd'. you have three terminal splits open and not a single one has a clean exit code."
    )

    # late night fatigue modifiers
    if (( hour >= 0 && hour < 5 )); then
        roasts+=(
            "command '$cmd' not found. it's ${hour}am. your eyes are burning and you're mistyping three-letter words."
            "'$cmd' missing. it's ${hour}am. tomorrow's alarm is four hours away and you're arguing with a prompt."
            "zsh: '$cmd' not found. you've reread this same line three times without processing a single character."
            "command '$cmd' failed at ${hour}am. your monitor is the only light in the room and you're missing keys."
            "'$cmd' does not exist. close the lid. the bug isn't going to fix itself while your brain is offline."
            "zsh: '$cmd' not found at ${hour}am. you aren't in the zone, your motor control is just dropping to zero."
        )
    fi

    # consecutive failure escalation
    if (( _EXISTENTIAL_FAILS >= 3 )); then
        roasts+=(
            "command '$cmd' failed. that's ${_EXISTENTIAL_FAILS} typos in a row. your hands aren't even on the home row."
            "'$cmd' not found. ${_EXISTENTIAL_FAILS} consecutive misses. step away from the keyboard and drink some water."
            "zsh: '$cmd' missing. ${_EXISTENTIAL_FAILS} failed commands in 30 seconds. you're just button-mashing now."
            "error: '$cmd' not found. streak of ${_EXISTENTIAL_FAILS}. clear the buffer, sit up straight, try again."
            "command '$cmd' failed. ${_EXISTENTIAL_FAILS} errors back to back. your backspace key is doing all the work."
        )
    fi
    
    if [[ "${ENABLE_PSYCHO_ROASTS:-true}" == "true" ]]; then
        local random_roast="${roasts[$(( RANDOM % ${#roasts[@]} + 1 ))]}"
        print -P "\n%F{red}󰅚%f %F{244}${random_roast}%f"
    else
        print -P "\n%F{red}󰅚%f %F{244}command not found: %F{white}${cmd}%f"
    fi
    
    # package lookup
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

    if (( $+commands[pkgfile] )); then
        pkg=$(pkgfile -b -q "$cmd" 2>/dev/null | head -n 1)
    elif (( $+commands[pacman] )); then
        pkg=$(pacman -Fq "usr/bin/$cmd" 2>/dev/null | head -n 1)
    fi

    if [[ -n "$pkg" ]]; then
        print -P "  %F{cyan}󰄛 copium:%f you can download more distraction via %F{green}%B${pkg}%b%f (run: %F{magenta}${helper} ${pkg}%f)\n"
    else
        print ""
    fi
    
    _IN_CNF=0
    return 127
}

preexec() {
    _EXISTENTIAL_FAILS=0
}

greeting_roast() {
    zmodload -i zsh/datetime 2>/dev/null
    local hour=12 dow="Thu"
    if (( $+EPOCHSECONDS )); then
        hour=$(strftime "%-H" "$EPOCHSECONDS" 2>/dev/null || echo 12)
        dow=$(strftime "%a" "$EPOCHSECONDS" 2>/dev/null || echo "Thu")
    fi

    local greetings=(
        "new tab opened. you're going to run 'ls', clear the screen, and wonder what you were doing."
        "another terminal tab allocated to sit idle while you check your phone."
        "welcome back. your window borders have liquid corner radii and your code still doesn't run."
        "opened another buffer. you have three terminal windows hidden behind your browser right now."
        "welcome back. your dotfiles have twelve commits today and your actual project has none."
        "nice font choice. your syntax errors look very aesthetic in italic ligatures."
        "you opened this window with a specific plan and completely forgot it during the 4ms shell startup."
        "welcome back. your posture is shaped like a desk lamp. sit up."
        "another shell running. you bought a high refresh rate monitor just to watch monospace text scroll past."
        "welcome back. you spent two hours tweaking bar padding to avoid writing one function."
        "ready to run. you're going to hit up arrow fourteen times instead of using fzf."
        "welcome. your git log is four commits of 'wip' followed by 'revert everything please work'."
        "new terminal. your ram usage is 85% and most of it is electron wrappers."
        "welcome back. typing 'clear' every thirty seconds is not a personality trait."
        "welcome back. you migrated your config to a new tool just to import the exact same problems."
        "ready. you configured three icon packs just to fail commands in aesthetic material glyphs."
        "welcome back. your coffee is cold and you're about to run 'gti status' by mistake."
        "new shell. you could be testing your code, but instead we're looking at fastfetch output."
        "welcome back. you're one broken config syntax error away from an unexpected reinstall."
        "terminal ready. you have 18 unstaged changes you're planning to 'git stash' and never look at again."
    )

    if (( hour >= 0 && hour < 5 )); then
        greetings+=(
            "it's ${hour}am. you aren't debugging, you're just staring at a glowing rectangle in a dark room."
            "new shell at ${hour}am. your eyes are bloodshot and your sleep schedule is completely wrecked."
            "it is ${hour}am. go to sleep. the bug will still be there in the morning."
        )
    elif (( hour >= 13 && hour <= 16 )); then
        greetings+=(
            "afternoon slump. you're staring blankly at the prompt hoping the code writes itself."
            "it is ${hour}:00. on your third lukewarm coffee pretending it's fixing your lack of sleep."
        )
    fi

    if [[ "$dow" == "Fri" ]] && (( hour >= 18 )); then
        greetings+=(
            "it's Friday night. you're spending it testing zsh command-not-found handlers."
            "Friday night shell opened. peak introversion confirmed."
        )
    elif [[ "$dow" == "Sun" ]] && (( hour >= 20 )); then
        greetings+=(
            "Sunday night panic. tomorrow morning is coming whether this builds or not."
            "Sunday evening dotfile tweaks to delay thinking about Monday morning."
        )
    fi

    local greet="${greetings[$(( RANDOM % ${#greetings[@]} + 1 ))]}"
    print -P "%F{141}󰄛%f %F{244}${greet}%f\n"
}

roast() {
    local pool=(
        "your window borders have liquid corner radii, but your code is still jagged and broken."
        "you spent 45 minutes finding the perfect blur shader just to typo 'ls'."
        "your posture is currently shaped like a boiled shrimp. sit up straight."
        "you've spent more time benchmarking shell startup than writing actual software this week."
        "you configured three icon packs so you can fail commands in aesthetic glyphs."
        "you are one careless 'rm -rf' away from absolute panic."
        "your dopamine receptors are fried. take your hands off the mechanical keyboard."
        "you alias 'ls' to 'eza' and 'cat' to 'bat' and still can't find your files."
        "you're entering commands with the cognitive function of a sleepy toddler."
        "your git history looks like a crime scene and your commit messages are cries for help."
        "you hit up arrow 40 times to find a command you ran five minutes ago."
        "you wrote 400 lines of zsh roasts to insult yourself instead of finishing your project."
    )
    local r="${pool[$(( RANDOM % ${#pool[@]} + 1 ))]}"
    print -P "%F{red}󰅚%f %F{244}${r}%f"
}
