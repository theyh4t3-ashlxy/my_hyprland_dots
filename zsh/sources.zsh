# master dotfiles wiring
local zdir="${ZDOTDIR:-$HOME/.config/zsh}"

# preferences & path exports must load first
[[ -f "$zdir/user_prefs.conf" ]] && source "$zdir/user_prefs.conf"
[[ -f "$zdir/exports.zsh" ]]     && source "$zdir/exports.zsh"

# modular components in optimized dependency order
local -a _mods=(
    core matugen plugins aliases tools functions
    quicknav dev wp nuke dnd roast settings local prompt
)

local mod f
for mod in "${_mods[@]}"; do
    f="$zdir/$mod.zsh"
    if [[ -f "$f" ]]; then
        source "$f"
        # compile bytecode in background so next launch is instant
        if [[ ! -f "$f.zwc" || "$f" -nt "$f.zwc" ]]; then
            { zcompile -R "$f" } >/dev/null 2>&1 &!
        fi
    fi
done
unset _mods mod f

# existential greeting ritual
if [[ -o interactive && -t 0 && -t 1 ]]; then
    if [[ "${SHOW_FASTFETCH:-true}" == "true" ]] && (( $+commands[fastfetch] )); then
        fastfetch
    fi

    if [[ "${SHOW_GREETING_ROAST:-true}" == "true" ]]; then
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
    fi
fi
