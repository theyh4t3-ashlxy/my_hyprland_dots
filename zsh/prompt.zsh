# prompt.zsh
# A small terminal creature with questionable professionalism.
#
# Settings (set before sourcing, or change interactively):
#   PROMPT_STYLE=unhinged
#     unhinged | two-line | single-line | minimal | bracket
#     gremlin | kaomoji-speech | cyberpunk | capsule
#   KAOMOJI_SET=reactive       # reactive | cats | cute | rage | ascii
#   PROMPT_ACCENT=primary     # primary | secondary | tertiary
#                             # cyan | green | magenta | yellow | white
#   PROMPT_SYMBOL='❯'
#   SHOW_GIT_PROMPT=true
#   SHOW_CMD_TIMER=true
#   SHOW_PROMPT_BANTER=true
#
# Git: + staged, ~ unstaged, ? untracked entries, ! conflicts
#      ↑ ahead, ↓ behind
#
# Nerd Font recommended for icons.
# Git status is synchronous; disable it for very large repositories.

autoload -Uz add-zsh-hook
zmodload -F zsh/stat b:zstat 2>/dev/null

setopt PROMPT_SUBST PROMPT_PERCENT
unsetopt PROMPT_BANG

# Remove hooks from the previous version when sourcing in a live shell.
add-zsh-hook -d preexec _cmd_timer_start 2>/dev/null
add-zsh-hook -d precmd _prompt_precmd 2>/dev/null
add-zsh-hook -d preexec _gp_preexec 2>/dev/null
add-zsh-hook -d precmd _gp_precmd 2>/dev/null

typeset -gi _GP_EXIT=0 _GP_RAN=0 _GP_ELAPSED=0
typeset -gi _GP_DIRTY=0 _GP_CONFLICT=0 _GP_REFRESH=0
typeset -g _GP_START="" _GP_STAMP="" _GP_MOOD_KEY=""
typeset -g _GP_FACE="" _GP_BANTER=""
typeset -g _GP_LEFT="" _GP_RIGHT="" _GP_GIT=""

# Keep assembled text in parameters instead of inserting arbitrary data
# directly into the prompt's shell-substitution source.
PROMPT='${_GP_LEFT}'
RPROMPT='${_GP_RIGHT}'

_gp_literal() {
    REPLY="${1//[[:cntrl:]]/}"
    REPLY="${REPLY//\%/%%}"
}

_gp_colors() {
    typeset -g _GP_OUT="%F{${MATUGEN_OUTLINE:-#a08d86}}"
    typeset -g _GP_PRI="%F{${MATUGEN_PRIMARY:-#ffb59a}}"
    typeset -g _GP_SEC="%F{${MATUGEN_SECONDARY:-#e7beaf}}"
    typeset -g _GP_TER="%F{${MATUGEN_TERTIARY:-#d5c68e}}"
    typeset -g _GP_ERR="%F{${MATUGEN_ERROR:-#ffb4ab}}"
    typeset -g _GP_RST="%f"
    typeset -g _GP_ACC="$_GP_PRI"

    case "${PROMPT_ACCENT:-primary}" in
        secondary) _GP_ACC="$_GP_SEC" ;;
        tertiary)  _GP_ACC="$_GP_TER" ;;
        cyan)      _GP_ACC='%F{117}' ;;
        green)     _GP_ACC='%F{120}' ;;
        magenta)   _GP_ACC='%F{141}' ;;
        yellow)    _GP_ACC='%F{221}' ;;
        white)     _GP_ACC='%F{white}' ;;
    esac
}

_gp_matugen() {
    local file="${ZDOTDIR:-$HOME/.config/zsh}/matugen.zsh"
    local stamp=loaded
    local -A info

    [[ -f "$file" ]] || return 0

    if (( $+builtins[zstat] )); then
        if zstat -H info "$file" 2>/dev/null; then
            stamp="${info[mtime]}:${info[size]}:${info[ino]}"
        fi
    fi

    if [[ "$stamp" != "$_GP_STAMP" ]] || (( _GP_REFRESH )); then
        # This is executable configuration: only source a trusted file.
        if source "$file" 2>/dev/null; then
            _GP_STAMP="$stamp"
        fi
    fi

    _GP_REFRESH=0
    return 0
}

_gp_git() {
    _GP_GIT=""
    _GP_DIRTY=0
    _GP_CONFLICT=0

    [[ "${SHOW_GIT_PROMPT:-true}" == true ]] || return 0
    (( $+commands[git] )) || return 0

    local raw line xy branch="" oid="" tracking REPLY
    local -i staged=0 unstaged=0 untracked=0 conflicts=0
    local -a counts details

    raw=$(command git --no-optional-locks status \
        --porcelain=v2 --branch --untracked-files=normal \
        --ignore-submodules=dirty 2>/dev/null) || return 0

    for line in "${(@f)raw}"; do
        case "$line" in
            '# branch.head '*) branch="${line#\# branch.head }" ;;
            '# branch.oid '*)  oid="${line#\# branch.oid }" ;;
            '# branch.ab '*)
                tracking="${line#\# branch.ab }"
                counts=(${=tracking})
                ;;
            '1 '*|'2 '*)
                xy="${line[3,4]}"
                [[ "${xy[1]}" != '.' ]] && (( ++staged ))
                [[ "${xy[2]}" != '.' ]] && (( ++unstaged ))
                ;;
            'u '*) (( ++conflicts )) ;;
            '? '*) (( ++untracked )) ;;
        esac
    done

    [[ -n "$branch" ]] || return 0
    [[ "$branch" == '(detached)' ]] && branch="@${oid[1,8]}"

    _prompt_unused_placeholder=  # Removed below; no external helpers needed.
    _gp_literal "$branch"
    branch="$REPLY"

    (( staged ))    && details+=("${_GP_TER}+${staged}%f")
    (( unstaged ))  && details+=("${_GP_SEC}~${unstaged}%f")
    (( untracked )) && details+=("${_GP_OUT}?${untracked}%f")
    (( conflicts )) && details+=("${_GP_ERR}!${conflicts}%f")

    if (( ${#counts} == 2 )); then
        [[ "${counts[1]}" != '+0' ]] &&
            details+=("${_GP_PRI}↑${counts[1]#+}%f")
        [[ "${counts[2]}" != '-0' ]] &&
            details+=("${_GP_SEC}↓${counts[2]#-}%f")
    fi

    (( staged + unstaged + untracked + conflicts )) && _GP_DIRTY=1
    (( conflicts )) && _GP_CONFLICT=1

    local color="$_GP_TER"
    (( _GP_DIRTY )) && color="$_GP_PRI"
    (( _GP_CONFLICT )) && color="$_GP_ERR"

    _GP_GIT=" ${_GP_OUT}(${color} ${branch}%f"
    (( ${#details} )) && _GP_GIT+=" ${(j: :)details}"
    _GP_GIT+="${_GP_OUT})%f"
    return 0
}

_gp_preexec() {
    _GP_START="$SECONDS"
    _GP_RAN=1
    return 0
}

_gp_mood() {
    local state=happy key
    local -a faces words

    if (( EUID == 0 )); then
        state=root
    elif (( _GP_EXIT == 130 )); then
        state=cancelled
    elif (( _GP_EXIT != 0 )); then
        state=error
    elif (( _GP_CONFLICT )); then
        state=conflict
    elif (( _GP_ELAPSED >= 5 )); then
        state=slow
    elif (( _GP_DIRTY )); then
        state=dirty
    fi

    key="${KAOMOJI_SET:-reactive}:${state}"
    if [[ "$key" == "$_GP_MOOD_KEY" && -n "$_GP_FACE" ]] &&
       (( ! _GP_RAN )); then
        return 0
    fi
    _GP_MOOD_KEY="$key"

    case "$state" in
        root)
            faces=('(ಠ_ಠ)' '(눈_눈)')
            words=('files do not have plot armor' 'god mode. mortal judgment.')
            ;;
        cancelled)
            faces=('(￣▽￣)ゞ' '( ._.)')
            words=('tactical retreat' 'we saw nothing' 'actually never mind')
            ;;
        error)
            faces=('(╯°□°)╯彡┻━┻' '(ಥ_ಥ)' '(╥﹏╥)' '(ノಠ益ಠ)ノ')
            words=('that was character development' 'computer says no'
                   'the plot thickens' 'well shit')
            ;;
        conflict)
            faces=('(ง •̀_•́)ง' '(⊙_⊙;)' '(ಠ益ಠ)')
            words=('git chose violence' 'pick a timeline'
                   'both sides brought receipts')
            ;;
        slow)
            faces=('(－_－) zzZ' '(눈_눈)' '(∪｡∪)｡｡｡')
            words=('i grew a beard' 'finally' 'a geological event')
            ;;
        dirty)
            faces=('(・_・;)' '(¬_¬ )' '(；・∀・)')
            words=('little crimes, uncommitted' 'the worktree has lore'
                   'nothing to see here')
            ;;
        *)
            faces=('(◕‿◕✿)' 'ᓚᘏᗢ' '(⌐■_■)' '( ˘▽˘)っ♨')
            words=('professionally unserious' 'it works. suspicious.'
                   'certified terminal creature' 'tiny wins count')
            ;;
    esac

    case "${KAOMOJI_SET:-reactive}" in
        cats)
            faces=('ᓚᘏᗢ' '(=^･ω･^=)' '(=①ω①=)' '(^・x・^)')
            ;;
        cute)
            faces=('(◕‿◕✿)' '(✿◠‿◠)' '(｡♥‿♥｡)' '(✿◡‿◡)')
            ;;
        rage)
            faces=('(╯°□°)╯彡┻━┻' '(ノಠ益ಠ)ノ' '(╬ಠ益ಠ)')
            ;;
        ascii)
            case "$state" in
                error|conflict) faces=('(>_<)' '(x_x)' 'D:') ;;
                slow)          faces=('(-_-) zzz' '(-.-)') ;;
                dirty)         faces=('(o_o;)' '(^_^;)') ;;
                root)          faces=('(-_-)') ;;
                cancelled)     faces=('(._.)') ;;
                *)             faces=('(^_^)' '(=^.^=)' '(^o^)') ;;
            esac
            ;;
    esac

    _GP_FACE="${faces[RANDOM % ${#faces} + 1]}"
    _GP_BANTER="${words[RANDOM % ${#words} + 1]}"
    return 0
}

_gp_build() {
    local out="$_GP_OUT" pri="$_GP_PRI" sec="$_GP_SEC"
    local ter="$_GP_TER" err="$_GP_ERR" acc="$_GP_ACC"
    local REPLY symbol face identity dir extras="" venv=""
    local elapsed="" style="${PROMPT_STYLE:-unhinged}"

    (( _GP_EXIT != 0 || EUID == 0 )) && acc="$err"

    _gp_literal "${PROMPT_SYMBOL:-❯}"
    symbol="${acc}${REPLY}%f"

    _gp_literal "$_GP_FACE"
    face="${acc}${REPLY}%f"

    identity="${pri}%n${out}@${sec}%m%f"
    dir="${ter}%~%f"

    [[ -w . ]] || extras+=" ${err}%f"
    extras+=' %(1j.%F{yellow}⚙ %j%f.)'

    if [[ -n "${SSH_CONNECTION-}${SSH_CLIENT-}" ]]; then
        extras+=" ${ter}[ssh]%f"
    fi

    if (( SHLVL > 1 )) &&
       [[ -z "${TMUX-}" && "${TERM_PROGRAM-}" != vscode ]]; then
        extras+=" ${out}[lvl:${SHLVL}]%f"
    fi

    if [[ -n "${VIRTUAL_ENV-}" ]]; then
        _gp_literal "${VIRTUAL_ENV:t}"
        venv=" ${out}[${sec}󰌠 ${REPLY}${out}]%f"
    elif [[ -n "${CONDA_DEFAULT_ENV-}" ]]; then
        _gp_literal "$CONDA_DEFAULT_ENV"
        venv=" ${out}[${sec}󱔎 ${REPLY}${out}]%f"
    fi

    if (( EUID == 0 )); then
        identity="${err}󰀦 %n@%m [root]%f"
    fi

    local context="${_GP_GIT}${venv}${extras}"

    case "$style" in
        single-line)
            _GP_LEFT="${face} ${identity} ${out}in ${dir}${context} ${symbol} "
            ;;
        minimal)
            _GP_LEFT="${face} ${dir}${context} ${symbol} "
            ;;
        bracket)
            _GP_LEFT="${out}[${identity} ${dir}${out}]%f ${face}${context} ${symbol} "
            ;;
        gremlin)
            _GP_LEFT=$'\n'"${identity} ${out}in ${dir}${context}"
            _GP_LEFT+=$'\n'"${face} "
            ;;
        kaomoji-speech)
            _GP_LEFT=$'\n'"${face} ${out}「${dir}${out}」%f ${identity}${context}"
            _GP_LEFT+=$'\n'"${out}╰─%f ${symbol} "
            ;;
        cyberpunk)
            _GP_LEFT=$'\n'"${out}┌──[ ${identity} ${out}:: ${dir} ${out}]%f ${face}${context}"
            _GP_LEFT+=$'\n'"${out}└──╼%f ${symbol} "
            ;;
        capsule)
            _GP_LEFT=$'\n'"${out}${identity}${out} ${dir}${out}%f ${face}${context}"
            _GP_LEFT+=$'\n'" ${symbol} "
            ;;
        two-line)
            _GP_LEFT=$'\n'"${out}╭─[ ${identity} ${out}in ${dir} ${out}]%f ${face}${context}"
            _GP_LEFT+=$'\n'"${out}╰─%f ${symbol} "
            ;;
        unhinged|*)
            _GP_LEFT=$'\n'"${out}╭── ${face} ${identity} ${out}in ${dir}${context}"
            _GP_LEFT+=$'\n'"${out}╰───%f${symbol} "
            ;;
    esac

    _GP_RIGHT=""

    (( _GP_EXIT != 0 )) &&
        _GP_RIGHT+="${err}✘ ${_GP_EXIT}%f "

    if [[ "${SHOW_PROMPT_BANTER:-true}" == true ]] &&
       (( ${COLUMNS:-80} >= 110 )); then
        _gp_literal "$_GP_BANTER"
        _GP_RIGHT+="${out}${REPLY}%f "
    fi

    if [[ "${SHOW_CMD_TIMER:-true}" == true ]] &&
       (( _GP_ELAPSED >= 1 )); then
        local -i hours=$(( _GP_ELAPSED / 3600 ))
        local -i mins=$(( _GP_ELAPSED / 60 % 60 ))
        local -i secs=$(( _GP_ELAPSED % 60 ))

        (( hours )) && elapsed+="${hours}h"
        (( hours || mins )) && elapsed+="${mins}m"
        elapsed+="${secs}s"
        _GP_RIGHT+="${sec}${elapsed}%f "
    fi

    _GP_RIGHT+="${out}%T%f"
    return 0
}

_gp_precmd() {
    local -i last_exit=$?

    if (( _GP_RAN )); then
        _GP_EXIT=$last_exit
        _GP_ELAPSED=0

        if [[ -n "$_GP_START" ]]; then
            (( _GP_ELAPSED = SECONDS - _GP_START ))
            (( _GP_ELAPSED < 0 )) && _GP_ELAPSED=0
        fi

        _GP_START=""
    fi

    _gp_matugen
    _gp_colors
    _gp_git
    _gp_mood
    _gp_build

    _GP_RAN=0
    return 0
}

TRAPUSR2() {
    # Defer the refresh to precmd so a signal cannot partially overwrite
    # prompt state while another refresh or command is running.
    _GP_REFRESH=1
    return 0
}

add-zsh-hook preexec _gp_preexec
add-zsh-hook precmd _gp_precmd

_gp_precmd
