-- interactive / fast cheatsheet popup for learning Neovim with IJKL
local M = {}

local content = {
    "  ╔════════════════════════════════════════════════════════════════════════╗",
    "  ║                     ASHLEY'S NEOVIM IJKL CHEATSHEET                    ║",
    "  ╚════════════════════════════════════════════════════════════════════════╝",
    "",
    "  [ NAVIGATION (Inverted-T / WASD Style) ]",
    "      i            : Move Up",
    "    j   l          : Move Left / Move Right",
    "      k            : Move Down",
    "",
    "  [ HIGH-SPEED JUMPS (Shift + IJKL) ]",
    "      I            : Jump 5 lines UP",
    "      K            : Jump 5 lines DOWN",
    "      J            : Jump to START of line (^)",
    "      L            : Jump to END of line ($)",
    "",
    "  [ INSERT MODE (The 'H' Swap) ]",
    "      h            : Enter Insert mode (before cursor)",
    "      H            : Enter Insert mode at start of line",
    "      a / A        : Append after cursor / Append at end of line",
    "      o / O        : Open new line below / above and insert",
    "      Esc          : Return to Normal mode",
    "",
    "  [ THE BIG 4 VIM VERBS ]",
    "      d<motion>    : Delete / Cut  (e.g. 'dw' delete word, 'dj' delete left)",
    "      c<motion>    : Change & Insert (e.g. 'cw' change word)",
    "      y<motion>    : Yank / Copy   (e.g. 'yy' copy line)",
    "      p / P        : Paste after / before cursor",
    "      u / <C-r>    : Undo / Redo",
    "",
    "  [ TEXT OBJECTS (Inner / Around Magic) ]",
    "      ciw          : Change Inside Word",
    "      di\"          : Delete Inside Quotes",
    "      yi(          : Yank Inside Parentheses",
    "      da{          : Delete Around Braces (including {})",
    "",
    "  [ SPLITS & WINDOWS ]",
    "      <leader>sv / sh : Split vertically / horizontally",
    "      <leader>sx      : Close current split",
    "      <A-i> / <A-k>   : Jump to window Above / Below",
    "      <A-j> / <A-l>   : Jump to window Left / Right",
    "",
    "  [ SIDEBAR & UTILITIES ]",
    "      <leader>e    : Toggle Neo-tree file sidebar",
    "                     Inside Neo-tree: 'i'/'k' = up/down, 'j' = collapse, 'l' = open",
    "      <leader>j    : Join current line with line below",
    "      gh           : Show LSP hover documentation",
    "      <leader>rt   : Toggle Roast Mode on/off",
    "      <leader>?    : Toggle this cheatsheet",
    "",
    "  [ Press 'q' or '<Esc>' to close this cheatsheet ]",
}

function M.open()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
    vim.bo[buf].modifiable = false
    vim.bo[buf].filetype = "markdown"

    local width = math.min(84, vim.o.columns - 4)
    local height = math.min(#content + 2, vim.o.lines - 4)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
        title = " 󰞋 Neovim IJKL Guide ",
        title_pos = "center",
    })

    -- quick close bindings
    local close = function()
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
        end
    end

    vim.keymap.set("n", "q", close, { buffer = buf, nowait = true, silent = true })
    vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true, silent = true })
end

vim.api.nvim_create_user_command("Cheatsheet", M.open, { desc = "Show Neovim IJKL cheatsheet" })

return M
