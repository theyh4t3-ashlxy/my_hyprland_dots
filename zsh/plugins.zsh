# plugin graveyard location
typeset -g _PLUGIN_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"

# only fork mkdir if the directory actually doesn't exist
[[ -d "$_PLUGIN_DIR" ]] || mkdir -p "$_PLUGIN_DIR"

_load_plugin() {
    local repo="$1"
    local name="${repo:t}"
    local dir="$_PLUGIN_DIR/$name"

    # snatch from git if missing
    if [[ ! -d "$dir" ]]; then
        print -P "%F{cyan}󰄛 grabbing plugin:%f %F{green}$name%f..."
        git clone --depth 1 "https://github.com/$repo.git" "$dir" >/dev/null 2>&1
    fi

    # find entrypoint
    local target=""
    [[ -f "$dir/$name.plugin.zsh" ]] && target="$dir/$name.plugin.zsh"
    [[ -f "$dir/$name.zsh" ]]        && target="$dir/$name.zsh"

    if [[ -n "$target" ]]; then
        # byte-compile so the shell doesn't crawl like a snail
        if [[ ! -f "$target.zwc" || "$target" -nt "$target.zwc" ]]; then
            zcompile "$target" 2>/dev/null
        fi
        source "$target"
    fi
}

# the holy trinity in strict load order so syntax highlighting doesn't combust
_load_plugin "zsh-users/zsh-autosuggestions"
_load_plugin "zsh-users/zsh-syntax-highlighting"
_load_plugin "zsh-users/zsh-history-substring-search"

# autosuggestion ghost colors
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=${MATUGEN_OUTLINE:-8}"

# arrow keys for digging up your past mistakes
if (( $+functions[history-substring-search-up] )); then
    bindkey '^[[A' history-substring-search-up
    bindkey '^[OA' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
    bindkey '^[OB' history-substring-search-down

    export HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND="fg=${MATUGEN_PRIMARY:-cyan},bold"
    export HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND="fg=${MATUGEN_ERROR:-red},bold"
fi

# nuke the loader from memory
unfunction _load_plugin
