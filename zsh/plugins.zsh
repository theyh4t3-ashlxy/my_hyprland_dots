# --- Zsh Plugin Loader (Lightweight & Self-Installing) ---

local plugin_dir="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"
mkdir -p "$plugin_dir"

# Helper function to dynamically clone and load GitHub plugins
load_plugin() {
    local repo="$1"
    local name="${repo:t}"
    local dir="$plugin_dir/$name"

    # Shallow clone if the directory doesn't exist
    if [[ ! -d "$dir" ]]; then
        echo "Cloning Zsh plugin: $name..."
        git clone --depth 1 "https://github.com/$repo.git" "$dir" >/dev/null 2>&1
    fi

    # Source the entrypoint file
    if [[ -f "$dir/$name.zsh" ]]; then
        source "$dir/$name.zsh"
    elif [[ -f "$dir/$name.plugin.zsh" ]]; then
        source "$dir/$name.plugin.zsh"
    fi
}

# --- Core Plugins ---
load_plugin "zsh-users/zsh-autosuggestions"
load_plugin "zsh-users/zsh-syntax-highlighting"
load_plugin "zsh-users/zsh-history-substring-search"


# --- Plugin Configurations ---

# 1. Autosuggestions Styling (Integrates with Matugen)
# Uses your Matugen outline color, falling back to basic terminal gray (8)
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=${MATUGEN_OUTLINE:-8}"

# 2. History Substring Search (Bind Up/Down arrows to search history)
# This lets you type "git" and press Up to search only commands starting with "git"
if (( $+functions[history-substring-search-up] )); then
    bindkey '^[[A' history-substring-search-up
    bindkey '^[OA' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
    bindkey '^[OB' history-substring-search-down

    # Styles matching substrings in your search
    export HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND="fg=${MATUGEN_PRIMARY:-cyan},bold"
    export HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND="fg=${MATUGEN_ERROR:-red},bold"
fi
