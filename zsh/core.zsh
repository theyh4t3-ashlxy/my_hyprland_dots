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

# --- Fast Autocomplete & Menu Selection ---
# Cache completions for a massive speedup
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"

# Enable interactive selection menu with arrow keys
zstyle ':completion:*' menu select

# Case-insensitive autocomplete (typing 'g' matches 'Git', etc.)
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|='

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
