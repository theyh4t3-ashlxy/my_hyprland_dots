# --- System Editor & Defaults ---
export EDITOR="micro"
export VISUAL="micro"
export PAGER="less"
export LANG="en_US.UTF-8"

# --- Cleaner less/PAGER behavior ---
# -R: Colors, -F: Exit if one screen, -X: Keep screen contents, -i: Case-insensitive search
export LESS="-R -F -X -i"

# --- XDG Base Directory Specification (keeps your home directory clean) ---
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# --- PATH Adjustments ---
# Construct PATH safely, checking if directories exist before adding them
typeset -U path # Keep only unique paths
path=(
    "$HOME/.local/bin"
    "$HOME/bin"
    /usr/local/bin
    $path
)
export PATH
