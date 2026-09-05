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
        "command '$cmd' not found. you typed that with astonishing confidence for someone who has no idea what they're doing."
        "'$cmd' is not recognized. your mechanical keyboard sounded loud and productive, but the result is literally nothing."
        "zsh: cannot find '$cmd\. maybe try reading the documentation instead of treating the prompt like a slot machine."
        "error: '$cmd' missing. you have 6 different font glyph packs configured and zero functional commands."
        "command '$cmd' failed. was that an actual command or did your cat walk across the homerow?"
        "zsh: '$cmd' undefined. your shell is silently judging you and honestly so is the rest of the kernel."
        "failed to execute '$cmd\. you just mashed backspace like that was gonna un-embarrass you."
        "'$cmd' not found. you're running on caffeine, adrenaline, and pure denial."
        "zsh: command '$cmd' failed. you have 8 custom alias files and still managed to mistype that."
        "command '$cmd' missing. even tab-completion threw its hands up and refused to participate in this."
        "error: '$cmd' does not exist. you're fighting the terminal and the terminal is currently 10-0 against you."
        "zsh: '$cmd' not found. your dopamine receptors are fried. take your hands off the keyboard."
        "command '$cmd' failed. this is what happens when you code entirely via vibes and no documentation."
        "'$cmd' is undefined. you're debugging your terminal while your real life problems compile in the background."
        "zsh: command '$cmd' not found. your shell history is just a chronicle of someone desperately guessing syntax."
        "'$cmd' does not exist. you spent 45 minutes finding the perfect blur shader just to typo 'ls'."
        "error: '$cmd' unresolvable. closing this terminal tab won't undo what you just did."
        "failed to execute '$cmd\. you're typing at 120 wpm directly into a brick wall."
        "zsh: '$cmd' missing. maybe if you buy another mechanical keyboard with slightly heavier switches this command will work."
        "command '$cmd' not found. you could have checked '--help', but you chose violence instead."
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
            "command '$cmd' failed at ${hour}am. you're entering commands with the cognitive function of a sleepy toddler."
            "'$cmd' does not exist. close the laptop. the terminal will survive without you until morning."
        )
    fi

    # consecutive failure escalation
    if (( _EXISTENTIAL_FAILS >= 3 )); then
        roasts+=(
            "command '$cmd' failed. that's ${_EXISTENTIAL_FAILS} typos in a row. your hands are shaking and your brain is fried. walk away."
            "'$cmd' not found. ${_EXISTENTIAL_FAILS} consecutive failures. you're rage-typing into an unfeeling terminal emulator."
            "zsh: '$cmd' missing. you are losing motor control. drink some fucking water."
            "error: '$cmd' not found. ${_EXISTENTIAL_FAILS} misfires back-to-back. the keyboard isn't broken, you are just spiraling."
            "zsh: '${cmd}' failed. streak of ${_EXISTENTIAL_FAILS} errors. you are basically playing dark souls in a terminal right now."
            "command '$cmd' not found. ${_EXISTENTIAL_FAILS} typos in a row. your ancestors survived ice ages for you to miss the enter key."
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

# existential greeting ritual moved from sources.zsh with fresh flavor
greeting_roast() {
    zmodload -i zsh/datetime 2>/dev/null
    local hour=12 dow="Thu"
    if (( $+EPOCHSECONDS )); then
        hour=$(strftime "%-H" "$EPOCHSECONDS" 2>/dev/null || echo 12)
        dow=$(strftime "%a" "$EPOCHSECONDS" 2>/dev/null || echo "Thu")
    fi

    local greetings=(
        "welcome back. whatever you opened this window to do, you'll be doomscrolling in under three minutes."
        "session spawned. the facade of productivity begins now."
        "another terminal allocated. another 4 hours of staring at pixels pretending you're solving fundamental problems."
        "back again? the world moved forward while you were tuning your opacity settings."
        "session initialized. you have 14 abandoned side projects and zero shipped products."
        "your window manager is perfectly tiled, but your actual life is completely fragmented."
        "welcome back. your posture is atrocious, your eyes are dry, and nobody is checking your commit history."
        "spawning shell. you use vim keybindings to avoid moving your hands toward anything that matters."
        "another buffer opened between you and the terrifying silence of your own thoughts."
        "welcome. you have automated everything except finding peace of mind."
        "fresh shell allocated. you are going to type 'ls', clear the screen, and wonder why you feel empty."
        "the dopamine spike from this blur effect and font choice will wear off in approximately 12 seconds."
        "welcome back. you've been optimizing your environment for 4 years to prepare for work you still haven't started."
        "session alive. your childhood heroes were changing the world at your age, but hey, nice prompt icon."
        "the machine is ready. your executive function, however, is nowhere to be found."
        "session spawned. you bought a high refresh rate monitor just to watch monospace text scroll."
        "welcome back. you have 17 terminal tabs open and not a single one has an uncommitted file that actually works."
        "allocated shell. somewhere out there, people are having conversations not mediated by stdout."
        "welcome. you spent 3 hours writing a shell script to automate a task that takes 4 seconds."
        "new session. your coffee is cold, your neck is strained, and your terminal theme is immaculate."
        "spawning buffer. you are one broken config line away from re-installing arch for the 9th time."
        "welcome back. you could be touching grass, but instead you are touching mechanical linear switches."
        "session online. another day of confusing hyperfocus with emotional stability."
        "welcome. your git history looks like a crime scene and your commit messages are cries for help."
        "fresh shell. you opened this window with intense purpose and immediately forgot what it was."
        "welcome back. your dotfiles have more commits than your actual degree."
        "session initialized. the void between who you want to be and who you are is currently filled by quickshell blur."
        "welcome back. your ram usage is at 82%% and most of it is electron apps you swore you'd rewrite in rust."
        "spawning shell. you have 200 tabs open in your browser and 4 terminal splits all running fzf on nothing."
        "welcome back. you've spent more time benchmarking shell startup than talking to real human beings this week."
        "terminal spawned. your inner child is watching you right now, wondering why you're arguing with a package manager."
        "welcome. your commit messages are 'wip', 'fix', 'pls work', and 'final final real this time'."
        "session online. you could be solving real problems, but today we tune container padding by 2 pixels."
        "welcome back. your spine is shaped like a boiled shrimp. sit up straight."
        "session spawned. you use tiling window managers because you can't tile your own life."
        "welcome back. your todo list has dust on it, but hey, nice hyprpicker hex value."
        "spawning shell. you recompiled your bytecode just to shave 3ms off an existential crisis."
        "welcome back. you are one 'rm -rf' away from absolute serenity."
        "session ready. you've perfected your prompt layout so everyone knows how efficiently you procrastinate."
        "welcome back. you and gemini vibecoded 400 lines of quickshell qml just to look at the same 3 widgets."
        "session online. your bar studio has liquid concave scoops, but your life is still jagged and unfilleted."
        "welcome back. you migrated from wallpaper.sh to wallpaper.py just to feel something."
        "new shell spawned. pure black is finally pitch black, unlike your sleep schedule."
        "welcome back. typing 'wp' every 45 seconds is not a personality trait."
        "allocated terminal. you've rewritten this prompt 12 times today instead of finishing your work."
        "session alive. you configured 3 icon font packs so you can fail commands in aesthetic material glyphs."
        "welcome. you're using uwsm because the wiki told you not to. absolute rebel."
        "terminal spawned. your lua config has 70 lines and 65 of them are you arguing with hyprland keybindings."
    )

    if (( hour >= 0 && hour < 5 )); then
        greetings+=(
            "it is ${hour}am. you just opened a new terminal. you are actively running away from tomorrow."
            "new shell at ${hour}am. you aren't grinding, you are dissociating under blue light."
            "it is ${hour}am. you aren't an engineer right now, you are a cryptid staring into a luminescent rectangle."
            "terminal opened at ${hour}am. the sleep debt you're accumulating will collect interest tomorrow morning."
            "it is ${hour}am. go to bed. the bugs will still be here waiting for you in the morning."
        )
    elif (( hour >= 13 && hour <= 16 )); then
        greetings+=(
            "afternoon slump detected. your eyelids weigh 40 pounds and you're staring blankly at stdout."
            "it is ${hour}:00. you are on your third coffee pretending it's fixing your lack of sleep."
            "afternoon session. you are 10 minutes away from taking a 3-hour 'nap'."
        )
    fi

    if [[ "$dow" == "Fri" && hour -ge 18 ]]; then
        greetings+=(
            "it is Friday night. normal people are out having fun. you are ricing your zsh configuration."
            "Friday night shell spawned. this is peak introversion and we both know it."
        )
    elif [[ "$dow" == "Sun" && hour -ge 20 ]]; then
        greetings+=(
            "Sunday night panic creeping in. tomorrow morning is coming whether this code compiles or not."
            "Sunday evening. preparing dotfiles for another week of doing the bare minimum."
        )
    fi

    local greet="${greetings[$(( RANDOM % ${#greetings[@]} + 1 ))]}"
    print -P "%F{38;5;141}󰄛%f %F{244}${greet}%f\n"
}

# on-demand existential reality check
roast() {
    local pool=(
        "your bar studio has liquid concave scoops, but your life is still jagged and unfilleted."
        "you and gemini vibecoded 400 lines of quickshell qml just to stare at the same 3 widgets."
        "pure black is finally #000000 pitch black, unlike your sleep schedule."
        "you use tiling window managers because you can't tile your own life."
        "typing 'wp' every 45 seconds is not a personality trait."
        "your spine is currently shaped like a boiled shrimp. sit up straight."
        "you've spent more time benchmarking shell startup than talking to real human beings this week."
        "you configured 3 icon packs so you can fail commands in aesthetic material glyphs."
        "you are one 'rm -rf' away from absolute serenity."
        "your dopamine receptors are fried. take your hands off the keyboard."
        "you spent 45 minutes finding the perfect blur shader just to typo 'ls'."
        "you're entering commands with the cognitive function of a sleepy toddler."
    )
    local r="${pool[$(( RANDOM % ${#pool[@]} + 1 ))]}"
    print -P "%F{red}󰅚%f %F{244}${r}%f"
}
