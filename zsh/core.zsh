# making zsh stop acting like it was born in 1989
setopt AUTO_CD              # typing cd every 3 seconds is for cavemen
setopt AUTO_PUSHD           # push directories to stack on cd (cd -1, cd -2, dirs -v)
setopt PUSHD_IGNORE_DUPS    # don't push duplicates to directory stack
setopt PUSHD_SILENT         # don't print directory stack after every pushd
setopt PUSHD_TO_HOME        # pushd with no args goes home
setopt INTERACTIVE_COMMENTS # paste broken snippets with # without terminal screaming
setopt NO_BEEP              # if my pc beeps at me one more time im throwing it out the window
setopt GLOB_COMPLETE        # auto-expand globs
setopt EXTENDED_GLOB        # supercharged globs (#q, ^, ~, etc)
setopt COMPLETE_IN_WORD     # tab complete from anywhere inside word
setopt ALWAYS_TO_END        # move cursor to end of word on completion
setopt MULTIOS              # pipe to multiple outputs simultaneously
setopt RM_STAR_WAIT         # 10s safety delay if executing 'rm *' or 'rm path/*'

# remembering the 50000 mistakes ive made in terminal
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000

setopt HIST_IGNORE_ALL_DUPS   # stop recording the 40 times i spammed ls in 2 seconds
setopt HIST_IGNORE_SPACE      # leading space hides secrets/tokens from history
setopt HIST_SAVE_NO_DUPS      # omit older duplicates when writing history
setopt HIST_FIND_NO_DUPS      # do not display duplicates when searching
setopt HIST_REDUCE_BLANKS     # trim useless whitespace before saving
setopt SHARE_HISTORY          # telepathically sync my bad decisions across tabs
setopt HIST_VERIFY            # show history command before executing
setopt HIST_EXPIRE_DUPS_FIRST # trim oldest duplicates first when history is full
setopt EXTENDED_HISTORY       # record timestamps and execution duration in history

# completion drip so i dont have to memorize flags
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
zstyle ':completion:*' rehash true

# category headers styled with matugen accents
zstyle ':completion:*:*:*:*:descriptions' format '%F{cyan}󰅂 %d%f'
zstyle ':completion:*:messages' format '%F{yellow}󰅂 %d%f'
zstyle ':completion:*:warnings' format '%F{red}󰅂 no matches found: %d%f'
zstyle ':completion:*:corrections' format '%F{green}󰅂 %d (errors: %e)%f'
zstyle ':completion:*' group-name ''

# colorize completion entries using ls colors
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# case-insensitive + typo correction so i dont cry when typing fast
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|='

# ijkl because hjkl is an actual war crime
zstyle ':completion:*' menu select
zmodload zsh/complist
bindkey -M menuselect 'i' up-line-or-history
bindkey -M menuselect 'k' down-line-or-history
bindkey -M menuselect 'j' backward-char
bindkey -M menuselect 'l' forward-char
bindkey -M menuselect '^[[Z' reverse-menu-complete

# process list formatting so kill is interactive
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,%cpu,%mem,command -w"
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'

# lightning fast compdump caching & background bytecode compilation
autoload -Uz compinit
local zcomp="${ZDOTDIR:-$HOME}/.zcompdump"
if [[ -n ${zcomp}(#qN.mh-24) ]]; then
    compinit -C -d "$zcomp"
else
    compinit -d "$zcomp"
    touch "$zcomp"
    { zcompile -R "$zcomp" } >/dev/null 2>&1 &!
fi

# compile all zsh configs and plugins to .zwc bytecode on demand
zrecompile() {
    local zdir="${ZDOTDIR:-$HOME/.config/zsh}"
    local pdir="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"
    local count=0
    for f in "$zdir"/*.zsh(N); do
        zcompile -R "$f" 2>/dev/null && (( count++ ))
    done
    for f in "$pdir"/*/*.zsh(N) "$pdir"/*/*/*.zsh(N); do
        [[ "$f" == *"test-data"* || "$f" == *"/tests/"* ]] && continue
        zcompile -R "$f" 2>/dev/null && (( count++ ))
    done
    [[ -f "$HOME/.zcompdump" ]] && zcompile -R "$HOME/.zcompdump" 2>/dev/null
    print -P "%F{green}󰄲 compiled ${count} scripts into fresh .zwc bytecode%f"
}

# wipe all .zwc bytecode caches if anything gets cursed
zclean() {
    local zdir="${ZDOTDIR:-$HOME/.config/zsh}"
    local pdir="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"
    rm -f "$zdir"/*.zwc(N) "$pdir"/**/*.zwc(N) "$HOME"/.zcompdump*.zwc(N)
    print -P "%F{yellow}󰀦 purged all .zwc bytecode caches%f"
}

alias zwc="zrecompile"
alias unzwc="zclean"
alias recompile="zrecompile"

# keys that actually work when i press them
bindkey -e

bindkey '^[[H'  beginning-of-line      # home
bindkey '^[[F'  end-of-line            # end
bindkey '^[[3~' delete-char            # delete
bindkey '^?'    backward-delete-char   # backspace

# subword movement: stop at path and flag delimiters (/, _, -, .) instead of whole words
autoload -U select-word-style && select-word-style bash

# ctrl + left/right to skip words at lightspeed
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word

# magic url escaping (auto-escape ?, &, = when pasting urls without quotes)
autoload -Uz bracketed-paste-magic && zle -N bracketed-paste bracketed-paste-magic
autoload -Uz url-quote-magic && zle -N self-insert url-quote-magic

# emergency ctrl+x ctrl+e escape hatch into micro
autoload -z edit-command-line
zle -N edit-command-line
bindkey "^X^E" edit-command-line

