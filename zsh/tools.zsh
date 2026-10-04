# modern cli tools replacing ancient gnu relics with rust/go power

# zoxide: jumping between directories like a caffeinated goblin
if (( $+commands[zoxide] )); then
    eval "$(zoxide init zsh)"
    alias cd="z"
fi

# cd and immediately vomit directory contents
c() {
    if [[ $# -eq 0 ]]; then
        builtin cd "$HOME" && ls
    elif (( $+commands[z] )); then
        z "$@" && ls
    else
        builtin cd "$@" && ls
    fi
}

# automatic ls on cd because typing two letters was draining your life force
_auto_ls_chpwd() {
    if [[ "${AUTO_LS:-false}" == "true" && -o interactive ]]; then
        ls
    fi
}
autoload -Uz add-zsh-hook
add-zsh-hook chpwd _auto_ls_chpwd

# eza: rust propaganda dressed up as a directory listing
if (( $+commands[eza] )); then
    # base command: icons and colors to mask the existential dread
    alias ls="eza --color=auto --group-directories-first --icons=auto"

    # the sane hierarchy: l is actually ls, no surprise autopsies
    alias l="ls"                             # one keystroke shortcut, identical to ls
    alias la="ls -a"                         # compact grid including dotfile shame
    alias ll="ls -lh --git"                  # table view with sizes and git, visible files only
    alias lla="ls -lah --git"                # full table autopsy including dotfiles
    alias lal="ls -lah --git"                # reverse fat-finger alias for lla
    alias lr="ls -R"                         # dump entire filesystem onto screen by accident
    alias lR="ls -R"                         # capital R for when caps lock gets angry
    alias rlah="ls -Rlah --git"              # the unholy all-in-one recursive incantation
    alias Rlah="ls -Rlah --git"              # exact case because shift key discipline is dead
    alias lt="ls --tree --level=2"           # fake tree view
    alias lt3="ls --tree --level=3"          # deeper fake tree view
    alias tree="ls --tree --level=3"         # pretending we installed the actual tree package

    # surgical filters for when scrolling is too much physical labor
    alias ld="ls -D"                         # directories only, hide the broken scripts
    alias lf="ls -f"                         # files only, ignore the folder structure
    alias l.="ls -d .*(N)"                   # expose the dotfiles hiding in plain sight

    # sorting so you can see which bloated node_modules or log is eating your disk
    alias lk="ls -lah --sort=size --git"     # show me the fattest files first
    alias lm="ls -lah --sort=modified --git" # what did i break most recently
    alias lc="ls -lah --sort=changed --git"  # status change surveillance
    alias lx="ls -lah --sort=extension --git" # group by file extension like a civilized creature
else
    # ancient gnu coreutils for when you're trapped in an alpine container
    alias ls="command ls --color=auto --group-directories-first"
    alias l="ls"
    alias la="ls -A"
    alias ll="ls -lh"
    alias lla="ls -lah"
    alias lal="ls -lah"
    alias lr="ls -R"
    alias lR="ls -R"
    alias rlah="ls -lahR"
    alias Rlah="ls -lahR"
    alias lt="ls -lhtr"
    alias ld="ls -d */"
    alias l.="ls -d .*(N)"
    alias lk="ls -lahS"
    alias lm="ls -laht"
    alias lx="ls -lahX"
fi

# bat: cat with training wheels and syntax highlights
if (( $+commands[bat] )); then
    alias cat="bat --style=plain --paging=never"
    alias preview="bat --style=numbers --color=always"
    alias b="bat"
    alias batp="bat --paging=always"
else
    alias preview="less -N"
fi

# ripgrep: searching codebases at relativistic speeds
if (( $+commands[rg] )); then
    alias rgs="rg --smart-case"
    alias rgi="rg -i"
    alias rgh="rg --hidden"
    alias rgw="rg -w"
    alias rgf="rg --files"
    alias rgl="rg -l"
    alias rgc="rg --count"
fi
alias grep="command grep --color=auto"
alias egrep="command grep -E --color=auto"
alias fgrep="command grep -F --color=auto"

# fd: find for people who can't remember gnu syntax
if (( $+commands[fd] )); then
    alias fdd="fd -t d"
    alias fdf="fd -t f"
    alias fdh="fd -H"
    alias fde="fd -e"
fi

# checking how much storage you wasted on abandoned repos
alias df="df -h"
alias du="du -h"
alias dus="du -sh * 2>/dev/null | sort -h"
alias free="free -h"

# stalking rogue processes before executing them
alias psg="ps aux | grep -v grep | grep -i"

# resource monitor so you can watch quickshell burn cpu cycles
if (( $+commands[btop] )); then
    alias top="btop"
    alias htop="btop"
fi

# wayland clipboard sync
if (( $+commands[wl-copy] )); then
    alias copy="wl-copy"
    alias paste="wl-paste"
    alias pbcopy="wl-copy"
    alias pbpaste="wl-paste"
fi

# system stats flex on empty terminal
if (( $+commands[fastfetch] )); then
    alias ff="fastfetch"
    alias fetch="fastfetch"
fi

# editor for the terminal hostage situation
if (( $+commands[micro] )); then
    alias mc="micro"
    alias edit="micro"
fi

# yazi: ranger but rust and speed
if (( $+commands[yazi] )); then
    alias y="yz"
    alias yazi="yz"
fi

# fzf: fuzzy finder wired with duct tape and hope
if (( $+commands[fzf] )); then
    eval "$(fzf --zsh 2>/dev/null || fzf --shell=zsh 2>/dev/null || true)"
    if [[ "$FZF_DEFAULT_OPTS" != *"--layout="* ]]; then
        export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border=none --inline-info ${FZF_DEFAULT_OPTS:-}"
    fi
    export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :50 {} 2>/dev/null || eza --tree --level=2 --icons {} 2>/dev/null || head -200 {}' --bind 'ctrl-/:toggle-preview'"
    export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --icons --color=always {} 2>/dev/null || ls {}'"
fi
