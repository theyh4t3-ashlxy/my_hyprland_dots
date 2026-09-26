-- space as leader because reaching for escape is torture
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local map = vim.keymap.set

-- quick save and quit
map("n", "<leader>w", "<cmd>w<CR>", { desc = "save file" })
map("n", "<leader>q", "<cmd>q<CR>", { desc = "quit" })
map("n", "<leader>x", "<cmd>bdelete<CR>", { desc = "close buffer" })

-- clear search highlight on escape
map("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- file tree toggle
map("n", "<leader>e", "<cmd>Neotree toggle<CR>", { desc = "toggle file tree" })
map("n", "<C-n>", "<cmd>Neotree toggle<CR>", { desc = "toggle file tree" })

-- window splits
map("n", "<leader>sv", "<cmd>vsplit<CR>", { desc = "split vertically" })
map("n", "<leader>sh", "<cmd>split<CR>", { desc = "split horizontally" })
map("n", "<leader>sx", "<cmd>close<CR>", { desc = "close current split" })

-- =======================================================================
-- CORE IJKL NAVIGATION (replaces HJKL)
-- =======================================================================
-- Normal & Visual mode basic directional movement (gj/gk handle wrapped lines nicely)
map({ "n", "x" }, "i", "gk", { desc = "cursor up" })
map({ "n", "x" }, "j", "h", { desc = "cursor left" })
map({ "n", "x" }, "k", "gj", { desc = "cursor down" })
map({ "n", "x" }, "l", "l", { desc = "cursor right" })

-- =======================================================================
-- INSERT MODE (The 'H' Swap)
-- =======================================================================
-- Since 'i' is Up, 'h' becomes Insert before cursor, and 'H' inserts at start of line
map("n", "h", "i", { desc = "insert before cursor" })
map("n", "H", "I", { desc = "insert at line start" })

-- =======================================================================
-- HIGH-SPEED & BOUNDARY JUMPS (Shift + IJKL)
-- =======================================================================
map({ "n", "x" }, "I", "5gk", { desc = "jump 5 lines up" })
map({ "n", "x" }, "K", "5gj", { desc = "jump 5 lines down" })
map({ "n", "x" }, "J", "^", { desc = "jump to line start" })
map({ "n", "x" }, "L", "$", { desc = "jump to line end" })

-- Join lines moved to <leader>j (since J is now jump to line start)
map("n", "<leader>j", "J", { desc = "join lines" })

-- =======================================================================
-- WINDOW SPLIT NAVIGATION (IJKL with Alt / Ctrl-w)
-- =======================================================================
map("n", "<C-w>i", "<C-w>k", { desc = "window up" })
map("n", "<C-w>k", "<C-w>j", { desc = "window down" })
map("n", "<C-w>j", "<C-w>h", { desc = "window left" })
map("n", "<C-w>l", "<C-w>l", { desc = "window right" })

map("n", "<A-i>", "<C-w>k", { desc = "window up" })
map("n", "<A-k>", "<C-w>j", { desc = "window down" })
map("n", "<A-j>", "<C-w>h", { desc = "window left" })
map("n", "<A-l>", "<C-w>l", { desc = "window right" })

-- Visual mode: move selected lines up and down using Alt-i / Alt-k
map("x", "<A-i>", ":m '<-2<CR>gv=gv", { desc = "move selected lines up", silent = true })
map("x", "<A-k>", ":m '>+1<CR>gv=gv", { desc = "move selected lines down", silent = true })

-- keep screen centered during big jumps
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- =======================================================================
-- LEARNING & UTILITY AIDS
-- =======================================================================
map("n", "<leader>?", "<cmd>Cheatsheet<CR>", { desc = "show IJKL cheatsheet" })
map("n", "<leader>rt", "<cmd>RoastToggle<CR>", { desc = "toggle arrow roast mode" })
