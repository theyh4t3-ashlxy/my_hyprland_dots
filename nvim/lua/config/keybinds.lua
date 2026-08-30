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

-- ijkl window navigation (ctrl / alt)
map("n", "<C-i>", "<C-w>k", { desc = "window up" })
map("n", "<C-k>", "<C-w>j", { desc = "window down" })
map("n", "<C-j>", "<C-w>h", { desc = "window left" })
map("n", "<C-l>", "<C-w>l", { desc = "window right" })

map("n", "<A-i>", "<C-w>k", { desc = "window up" })
map("n", "<A-k>", "<C-w>j", { desc = "window down" })
map("n", "<A-j>", "<C-w>h", { desc = "window left" })
map("n", "<A-l>", "<C-w>l", { desc = "window right" })

-- move lines up and down in visual mode
map("v", "K", ":m '>+1<CR>gv=gv", { desc = "move selected lines down" })
map("v", "I", ":m '<-2<CR>gv=gv", { desc = "move selected lines up" })

-- keep screen centered during big jumps
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")
