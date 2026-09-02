# micro because vim trapped me for 4 hours once
export EDITOR="micro"
export VISUAL="micro"
export PAGER="less"
export LANG="en_US.UTF-8"

# less that doesnt leave ghost text all over my screen
export LESS="-R -F -X -i"

# stop dumping garbage in my home folder challenge (impossible)
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# where the binaries live
typeset -U path
path=(
    "$HOME/.local/bin"
    "$HOME/bin"
    /usr/local/bin
    /usr/bin
    /bin
    /usr/sbin
    /sbin
    $path
)
export PATH
