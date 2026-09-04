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
        local hour=12
        if (( $+EPOCHSECONDS )); then
            hour=$(strftime "%-H" "$EPOCHSECONDS" 2>/dev/null || echo 12)
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
        )

        if (( hour >= 0 && hour < 5 )); then
            greetings+=(
                "it is ${hour}am. you just opened a new terminal. you are actively running away from tomorrow."
                "new shell at ${hour}am. you aren't grinding, you are dissociating under blue light."
            )
        fi

        local greet="${greetings[$(( RANDOM % ${#greetings[@]} + 1 ))]}"
        print -P "%F{38;5;141}󰄛%f %F{244}${greet}%f\n"
    fi
fi
