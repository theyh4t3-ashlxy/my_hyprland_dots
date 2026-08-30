# --- prompt layout & visual style ---

autoload -U add-zsh-hook
setopt PROMPT_SUBST

# Dynamically set clean color escape codes before every command line render
set_prompt_colors() {
    M_OUT="%F{${MATUGEN_OUTLINE:-#a08d86}}"
    M_PRI="%F{${MATUGEN_PRIMARY:-#ffb59a}}"
    M_SEC="%F{${MATUGEN_SECONDARY:-#e7beaf}}"
    M_TER="%F{${MATUGEN_TERTIARY:-#d5c68e}}"
    M_ERR="%F{${MATUGEN_ERROR:-#ffb4ab}}"
    M_RST="%f"
}
add-zsh-hook precmd set_prompt_colors

# Subshell-free git tracker (branch + staged/unstaged/untracked indicators)
git_status_detailed() {
    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
    [[ -z "$branch" ]] && return

    local raw_status
    raw_status=$(git status --porcelain=v1 2>/dev/null)

    if [[ -z "$raw_status" ]]; then
        echo " ${M_OUT}(${M_RST}${M_TER}${branch}${M_RST}${M_OUT})${M_RST}"
        return
    fi

    local staged=0 unstaged=0 untracked=0
    untracked=${#${(M)${(f)raw_status}:#\?\?*}}
    staged=${#${(M)${(f)raw_status}:#[MADRC] *}}
    unstaged=${#${(M)${(f)raw_status}:#?[MADRC]*}}

    local details=""
    (( staged > 0 ))   && details+="${M_TER}+${staged}${M_RST}"
    (( unstaged > 0 )) && details+="${M_SEC}*${unstaged}${M_RST}"
    (( untracked > 0 )) && details+="${M_ERR}?${untracked}${M_RST}"

    echo " ${M_OUT}(${M_RST}${M_PRI}${branch}${M_RST} ${details}${M_OUT})${M_RST}"
}

set_prompt_git() { 
    MY_GIT=$(git_status_detailed) 
}
add-zsh-hook precmd set_prompt_git

# Python virtual environment detector
get_venv() {
    if [[ -n "$VIRTUAL_ENV" ]]; then
        local venv_name="${VIRTUAL_ENV:t}"
        echo " ${M_OUT}[py:${M_RST}${M_SEC}${venv_name}${M_RST}${M_OUT}]${M_RST}"
    fi
}

set_prompt_venv() { 
    MY_VENV=$(get_venv) 
}
add-zsh-hook precmd set_prompt_venv 2>/dev/null || true

# Read-only directory & SSH/subshell indicator badges
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
add-zsh-hook precmd set_prompt_qol

# Execution duration timer for commands taking >= 1s
_cmd_timer_start() {
    _CMD_START_TIME=$SECONDS
}
add-zsh-hook preexec _cmd_timer_start

_cmd_timer_stop() {
    if [[ -n "$_CMD_START_TIME" ]]; then
        local elapsed=$(( SECONDS - _CMD_START_TIME ))
        unset _CMD_START_TIME
        if (( elapsed >= 1 )); then
            local mins=$(( elapsed / 60 ))
            local secs=$(( elapsed % 60 ))
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
add-zsh-hook precmd _cmd_timer_stop

# Default prompt arrow color fallback
: ${PROMPT_ARROW:="${M_PRI}❯${M_RST}"}

# Main prompt layout (cleanly interpolates pre-rendered colors)
PROMPT=$'\n${M_OUT}╭─[${M_RST} ${M_PRI}%n${M_RST}${M_OUT}@${M_RST}${M_SEC}%m${M_RST} ${M_OUT}in${M_RST} ${M_TER}%~${M_RST}${MY_RO}%(1j. ${M_SEC}⚙ %j${M_RST}.)${M_OUT} ]${M_RST}${MY_GIT}${MY_VENV}${MY_EXTRA_QOL}\n${M_OUT}╰─${M_RST}${PROMPT_ARROW} '

# Right prompt (shows command failure exit code + execution duration + time)
RPROMPT="%(?..${M_ERR}✘ %?${M_RST} )\${MY_ELAPSED}${M_OUT}%T${M_RST}"

# Root prompt mode (angry red accent)
if [[ $UID -eq 0 ]]; then
    PROMPT=$'\n${M_OUT}╭─[${M_RST} ${M_ERR}%n@%m${M_RST} ${M_OUT}in${M_RST} %F{yellow}%~%f${MY_RO}%(1j. ${M_ERR}⚙ %j${M_RST}.)${M_OUT} ]${M_RST}${MY_GIT}${MY_VENV}${MY_EXTRA_QOL}\n${M_OUT}╰─${M_RST}${M_ERR}❯${M_RST} '
    RPROMPT="%(?..${M_ERR}✘ %?${M_RST} )${M_ERR}don't nuke root${M_RST} \${MY_ELAPSED}${M_OUT}%T${M_RST}"
fi
