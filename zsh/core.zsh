# --- Zsh Options ---
setopt AUTO_CD              # Just type a directory name to cd into it
setopt INTERACTIVE_COMMENTS # Allow comments starting with '#' in the command line
setopt NO_BEEP              # Turn off that annoying terminal bell
setopt GLOB_COMPLETE        # Show autocompletes for globs
setopt MENU_COMPLETE        # Auto-select the first option in the completion menu

# --- History Configuration ---
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000

setopt HIST_IGNORE_ALL_DUPS # Don't record duplicate commands
setopt HIST_REDUCE_BLANKS   # Remove superfluous blanks before recording
setopt SHARE_HISTORY        # Share command history instantly across all open tabs
setopt HIST_VERIFY          # Show history command before executing (like !!)

# --- completion engine with colored category headers ---
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
zstyle ':completion:*' rehash true

# group completion results by category with colored headers
zstyle ':completion:*:*:*:*:descriptions' format '%F{cyan}󰅂 %d%f'
zstyle ':completion:*:messages' format '%F{yellow}󰅂 %d%f'
zstyle ':completion:*:warnings' format '%F{red}󰅂 no matches found: %d%f'
zstyle ':completion:*:corrections' format '%F{green}󰅂 %d (errors: %e)%f'
zstyle ':completion:*' group-name ''

# colorize completion entries using ls colors
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# case-insensitive + partial word + substring matching
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|='

# enable interactive selection menu with arrow keys & vim motion
zstyle ':completion:*' menu select
zmodload zsh/complist
bindkey -M menuselect 'h' backward-char
bindkey -M menuselect 'k' up-line-or-history
bindkey -M menuselect 'l' forward-char
bindkey -M menuselect 'j' down-line-or-history
bindkey -M menuselect '^[[Z' reverse-menu-complete

# process list formatting for kill
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,%cpu,%mem,command -w"
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'

# Initialize completion system (checks cache to avoid slowing down shell startup)
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.m-1) ]]; then
    compinit -C
else
    compinit
fi

# --- Keyboard Bindings (Emacs style with modern terminal fixes) ---
bindkey -e

# Fix standard keys (Home, End, Delete, Backspace)
bindkey '^[[H'  beginning-of-line      # Home
bindkey '^[[F'  end-of-line            # End
bindkey '^[[3~' delete-char            # Delete
bindkey '^?'    backward-delete-char   # Backspace

# Word skipping with Ctrl + Left / Right
bindkey '^[[1;5D' backward-word        # Ctrl+Left
bindkey '^[[1;5C' forward-word         # Ctrl+Right

# Command-line editing in $EDITOR with 'Ctrl + X, Ctrl + E'
autoload -z edit-command-line
zle -N edit-command-line
bindkey "^X^E" edit-command-line
