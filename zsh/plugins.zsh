# auto-pull plugins so fresh installs dont give me depression
local plugin_dir="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"
mkdir -p "$plugin_dir"

load_plugin() {
    local repo="$1"
    local name="${repo:t}"
    local dir="$plugin_dir/$name"

    if [[ ! -d "$dir" ]]; then
        echo "grabbing $name..."
        git clone --depth 1 "https://github.com/$repo.git" "$dir" >/dev/null 2>&1
    fi

    if [[ -f "$dir/$name.zsh" ]]; then
        source "$dir/$name.zsh"
    elif [[ -f "$dir/$name.plugin.zsh" ]]; then
        source "$dir/$name.plugin.zsh"
    fi
}

# holy trinity of not making typing painful
load_plugin "zsh-users/zsh-autosuggestions"
load_plugin "zsh-users/zsh-syntax-highlighting"
load_plugin "zsh-users/zsh-history-substring-search"

# autosuggestions that actually blend with wallpaper
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=${MATUGEN_OUTLINE:-8}"

# up/down arrow search so i dont retype commands like an npc
if (( $+functions[history-substring-search-up] )); then
    bindkey '^[[A' history-substring-search-up
    bindkey '^[OA' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
    bindkey '^[OB' history-substring-search-down

    export HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND="fg=${MATUGEN_PRIMARY:-cyan},bold"
    export HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND="fg=${MATUGEN_ERROR:-red},bold"
fi
