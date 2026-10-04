autoload -U add-zsh-hook
zmodload -F zsh/stat b:zstat 2>/dev/null
setopt PROMPT_SUBST

set_prompt_colors() {
    M_OUT="%F{${MATUGEN_OUTLINE:-#a08d86}}"
    M_PRI="%F{${MATUGEN_PRIMARY:-#ffb59a}}"
    M_SEC="%F{${MATUGEN_SECONDARY:-#e7beaf}}"
    M_TER="%F{${MATUGEN_TERTIARY:-#d5c68e}}"
    M_ERR="%F{${MATUGEN_ERROR:-#ffb4ab}}"
    M_RST="%f"

    local sym_color="${M_PRI}"
    case "${PROMPT_ACCENT:-primary}" in
        secondary) sym_color="${M_SEC}" ;;
        tertiary)  sym_color="${M_TER}" ;;
        cyan)      sym_color="%F{117}" ;;
        green)     sym_color="%F{120}" ;;
        magenta)   sym_color="%F{141}" ;;
        yellow)    sym_color="%F{221}" ;;
        white)     sym_color="%F{white}" ;;
        *)         sym_color="${M_PRI}" ;;
    esac
    M_SYM_COLOR="$sym_color"
}

_check_matugen_refresh() {
    local matugen_file="${ZDOTDIR:-$HOME/.config/zsh}/matugen.zsh"
    [[ -f "$matugen_file" ]] || return

    local mtime
    if (( $+builtins[zstat] )); then
        local -A st
        zstat -H st "$matugen_file" 2>/dev/null
        mtime="${st[mtime]}"
    fi

    if [[ -n "$mtime" ]]; then
        if [[ "$mtime" != "$_LAST_MATUGEN_MTIME" ]]; then
            _LAST_MATUGEN_MTIME="$mtime"
            source "$matugen_file" 2>/dev/null || true
            set_prompt_colors
        fi
    elif [[ -z "$_LAST_MATUGEN_MTIME" ]]; then
        _LAST_MATUGEN_MTIME=1
        source "$matugen_file" 2>/dev/null || true
        set_prompt_colors
    fi
}

TRAPUSR2() {
    local matugen_file="${ZDOTDIR:-$HOME/.config/zsh}/matugen.zsh"
    if [[ -f "$matugen_file" ]]; then
        source "$matugen_file" 2>/dev/null || true
        if (( $+builtins[zstat] )); then
            local -A st
            zstat -H st "$matugen_file" 2>/dev/null
            _LAST_MATUGEN_MTIME="${st[mtime]}"
        fi
    fi
    set_prompt_colors
    build_prompt
    zle && zle reset-prompt
}

set_prompt_git() {
    MY_GIT=""
    [[ "${SHOW_GIT_PROMPT:-true}" != "true" ]] && return
    (( $+commands[git] )) || return

    # single git call for branch + worktree, 0 forks if outside repo
    local raw_status
    raw_status=$(git status --porcelain=v1 -b -unormal --ignore-submodules=dirty 2>/dev/null) || return
    [[ -z "$raw_status" ]] && return

    local -a lines
    lines=("${(f)raw_status}")

    local branch_line="${lines[1]#\#\# }"
    local branch
    if [[ "$branch_line" == (HEAD \(no branch\)|no branch|\(no branch\))* ]]; then
        branch=$(git rev-parse --short HEAD 2>/dev/null || print -r "detached")
    elif [[ "$branch_line" == (Initial commit on |No commits yet on )* ]]; then
        branch="${branch_line##* }"
    else
        branch="${${branch_line%%\.\.\.*}%% *}"
    fi

    # escape % so weird branch names dont mangle prompt formatting
    branch="${branch//\%/%%}"

    local staged=0 unstaged=0 untracked=0
    untracked=${#${(M)lines:#\?\?*}}
    staged=${#${(M)lines:#[MADRC]*}}
    unstaged=${#${(M)lines:#?[MADRC]*}}

    MY_GIT_DIRTY=""
    if (( staged > 0 || unstaged > 0 || untracked > 0 )); then
        MY_GIT_DIRTY="1"
    fi

    local details=""
    (( staged > 0 ))   && details+="${M_TER}+${staged}${M_RST}"
    (( unstaged > 0 )) && details+="${M_SEC}*${unstaged}${M_RST}"
    (( untracked > 0 )) && details+="${M_ERR}?${untracked}${M_RST}"

    if [[ -n "$details" ]]; then
        MY_GIT=" ${M_OUT}(${M_RST}${M_PRI} ${branch}${M_RST} ${details}${M_OUT})${M_RST}"
    else
        MY_GIT=" ${M_OUT}(${M_RST}${M_TER} ${branch}${M_RST}${M_OUT})${M_RST}"
    fi
}

set_prompt_venv() {
    if [[ -n "$VIRTUAL_ENV" ]]; then
        local venv="${VIRTUAL_ENV:t}"
        MY_VENV=" ${M_OUT}[󰌠 ${M_RST}${M_SEC}${venv//\%/%%}${M_RST}${M_OUT}]${M_RST}"
    elif [[ -n "$CONDA_DEFAULT_ENV" ]]; then
        MY_VENV=" ${M_OUT}[󱔎 ${M_RST}${M_SEC}${CONDA_DEFAULT_ENV//\%/%%}${M_RST}${M_OUT}]${M_RST}"
    else
        MY_VENV=""
    fi
}

set_prompt_qol() {
    if [[ ! -w . ]]; then
        MY_RO=" ${M_ERR}${M_RST}"
    else
        MY_RO=""
    fi

    MY_EXTRA_QOL=""
    if [[ -n "$SSH_CONNECTION" || -n "$SSH_CLIENT" ]]; then
        MY_EXTRA_QOL+=" ${M_TER}[ssh]${M_RST}"
    fi
    if [[ $SHLVL -gt 1 && -z "$TMUX" && "$TERM_PROGRAM" != "vscode" ]]; then
        MY_EXTRA_QOL+=" ${M_OUT}[lvl:${SHLVL}]${M_RST}"
    fi
}

_cmd_timer_start() {
    _CMD_START_TIME=$SECONDS
}
add-zsh-hook preexec _cmd_timer_start

_cmd_timer_stop() {
    _LAST_CMD_SLOW=""
    if [[ "${SHOW_CMD_TIMER:-true}" != "true" ]]; then
        MY_ELAPSED=""
        unset _CMD_START_TIME
        return
    fi
    if [[ -n "$_CMD_START_TIME" ]]; then
        # integer cast prevents float SECONDS from spitting ugly decimals
        local -i elapsed=$(( SECONDS - _CMD_START_TIME ))
        unset _CMD_START_TIME
        if (( elapsed >= 5 )); then
            _LAST_CMD_SLOW="1"
        fi
        if (( elapsed >= 1 )); then
            local -i mins=$(( elapsed / 60 ))
            local -i secs=$(( elapsed % 60 ))
            if (( mins > 0 )); then
                MY_ELAPSED="${M_SEC}${mins}m${secs}s${M_RST} "
            else
                MY_ELAPSED="${M_SEC}${secs}s${M_RST} "
            fi
            return
        fi
    fi
    MY_ELAPSED=""
}

set_prompt_kaomoji() {
    local exit_code="${1:-0}"
    local mood_set="${KAOMOJI_SET:-reactive}"
    local -a moods

    case "$mood_set" in
        cats)
            moods=('ᓚᘏᗢ' '(=^･ω･^=)' '(=^･ｪ･^=)' '(^・x・^)' '(ﾐㅇ ༝ ㅇﾐ)' '(=①ω①=)' '󰄛')
            ;;
        rage)
            moods=('(╯°□°)╯彡┻━┻' '(ノಠ益ಠ)ノ' '(°ㅂ°╬)' '(ง'"'"'-'"'"')ง' '(╬ಠ益ಠ)' '💀' '(ノ°Д°)ノ')
            ;;
        cute)
            moods=('(◕‿◕✿)' '(✿◠‿◠)' '(｡♥‿♥｡)' '( ˶•̀֊•́˶)' '( •̀ ω •́ )✧' '( ˘▽˘)っ♨' '(✿◡‿◡)')
            ;;
        reactive|*)
            if (( exit_code != 0 )); then
                moods=(
                    '(╯°□°)╯彡┻━┻'
                    '(ノಠ益ಠ)ノ'
                    '(;´༎ຶД༎ຶ`)'
                    '(╥﹏╥)'
                    '(x_x)'
                    '(°ㅂ°╬)'
                    '( ;-_-)ノ'
                    '💀'
                    '(ノ°Д°)ノ'
                    '(ಥ_ಥ)'
                )
            elif [[ -n "$_LAST_CMD_SLOW" ]]; then
                moods=(
                    '(－_－) zzZ'
                    '(눈_눈)'
                    '( ˘-˘)'
                    '( ×_×)'
                    '(疲れた...)'
                )
            elif [[ -n "$MY_GIT_DIRTY" ]]; then
                moods=(
                    '(・_・;)'
                    '(¬_¬ )'
                    '(⊙_⊙;)'
                    '(;¬_¬)'
                    '(・ω・;)'
                )
            else
                moods=(
                    '(◕‿◕✿)'
                    '( ˶•̀֊•́˶)'
                    'ᓚᘏᗢ'
                    '( •̀ ω •́ )✧'
                    '(⌐■_■)'
                    '( ˘▽˘)っ♨'
                    '(ง'"'"'-'"'"')ง'
                    '(✿◡‿◡)'
                    '(｡♥‿♥｡)'
                    '󰄛'
                )
            fi
            ;;
    esac

    KAOMOJI_MOOD="${moods[$(( RANDOM % ${#moods[@]} + 1 ))]}"
}

build_prompt() {
    local p_style="${PROMPT_STYLE:-two-line}"
    local sym_c="%(?.${M_SYM_COLOR}.${M_ERR})"

    if [[ $UID -eq 0 ]]; then
        PROMPT=$'\n${M_OUT}╭─[${M_RST} ${M_ERR}󰀦 %n@%m${M_RST} ${M_OUT}in${M_RST} %F{yellow}󰝰 %~%f${MY_RO}%(1j. ${M_ERR}⚙ %j${M_RST}.)${M_OUT} ]${M_RST}${MY_GIT}${MY_VENV}${MY_EXTRA_QOL}\n${M_OUT}╰─${M_RST} ${M_ERR}${PROMPT_SYMBOL:-❯}${M_RST} '
        RPROMPT='%(?..${M_ERR}✘ %?${M_RST} )${M_ERR}don'\''t nuke root${M_RST} ${MY_ELAPSED}${M_OUT}%T${M_RST}'
        return
    fi

    case "$p_style" in
        single-line)
            PROMPT=$'${M_PRI}%n${M_OUT}@${M_SEC}%m ${M_OUT}in ${M_TER}%~${M_RST}${MY_RO}%(1j. ${M_SEC}⚙ %j${M_RST}.)${MY_GIT}${MY_VENV}${MY_EXTRA_QOL} ${sym_c}${PROMPT_SYMBOL:-❯}${M_RST} '
            ;;
        minimal)
            PROMPT=$'${M_TER}%~${M_RST}${MY_RO}${MY_GIT} ${sym_c}${PROMPT_SYMBOL:-❯}${M_RST} '
            ;;
        bracket)
            PROMPT=$'${M_OUT}[${M_PRI}%n${M_OUT}@${M_SEC}%m ${M_TER}%~${M_OUT}]${M_RST}${MY_RO}${MY_GIT}${MY_VENV} ${sym_c}${PROMPT_SYMBOL:-❯}${M_RST} '
            ;;
        gremlin)
            # the prompt symbol itself is the reactive kaomoji (flips table on failure)
            PROMPT=$'\n${M_TER}󰝰 %~${M_RST}${MY_GIT}${MY_VENV}${MY_EXTRA_QOL}\n${sym_c}${KAOMOJI_MOOD}${M_RST} '
            ;;
        kaomoji-speech)
            # kaomoji holding your current path in japanese quote brackets
            PROMPT=$'\n${sym_c}${KAOMOJI_MOOD}${M_RST} ${M_OUT}「${M_TER}%~${M_OUT}」${M_RST}${MY_GIT}${MY_VENV}${MY_EXTRA_QOL}\n${M_OUT}╰─${M_RST}${sym_c}${PROMPT_SYMBOL:-❯}${M_RST} '
            ;;
        cyberpunk)
            # glitch / sci-fi coordinates with angular brackets
            PROMPT=$'\n${M_OUT}┌──[ ${M_ERR}⚡${M_PRI}%n@%m ${M_OUT}:: ${M_TER}󰝰 %~${M_RST}${MY_RO} ]${MY_GIT}${MY_VENV}\n${M_OUT}└──╼ ${sym_c}▲${M_RST} '
            ;;
        capsule)
            # modern rounded nerd font pill capsules
            PROMPT=$'\n ${M_OUT}${M_PRI} %n@%m${M_OUT} ${M_TER}󰝰 %~${M_OUT}${MY_GIT}${MY_VENV}\n ${sym_c}${PROMPT_SYMBOL:-❯}${M_RST} '
            ;;
        unhinged)
            # reactive kaomoji mood engine in an expressive curved layout
            PROMPT=$'\n${M_OUT}╭── ${sym_c}${KAOMOJI_MOOD}${M_RST} ${M_PRI}%n${M_OUT}@${M_SEC}%m ${M_OUT}in ${M_TER}%~${M_RST}${MY_RO}%(1j. ${M_SEC}⚙ %j${M_RST}.)${MY_GIT}${MY_VENV}${MY_EXTRA_QOL}\n${M_OUT}╰───${sym_c}${PROMPT_SYMBOL:-❯}${M_RST} '
            ;;
        two-line|*)
            PROMPT=$'\n${M_OUT}╭─[${M_RST} ${M_PRI} %n${M_RST} ${M_OUT}at${M_RST} ${M_SEC}󰌢 %m${M_RST} ${M_OUT}in${M_RST} ${M_TER}󰝰 %~${M_RST}${MY_RO}%(1j. ${M_SEC}⚙ %j${M_RST}.)${M_OUT} ]${M_RST}${MY_GIT}${MY_VENV}${MY_EXTRA_QOL}\n${M_OUT}╰─${M_RST} ${sym_c}${PROMPT_SYMBOL:-❯}${M_RST} '
            ;;
    esac

    RPROMPT='%(?..${M_ERR}✘ %?${M_RST} )${MY_ELAPSED}${M_OUT}%T${M_RST}'
}

_prompt_precmd() {
    local last_status=$?
    _cmd_timer_stop
    _check_matugen_refresh
    set_prompt_colors
    set_prompt_git
    set_prompt_venv
    set_prompt_qol
    set_prompt_kaomoji "$last_status"
    build_prompt
}
add-zsh-hook precmd _prompt_precmd

_prompt_precmd