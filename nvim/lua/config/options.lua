-- so neovim feels like a proper modern editor
local opt = vim.opt

-- line numbers
opt.number = true
opt.relativenumber = true
opt.cursorline = true

-- tabs and indentation
opt.shiftwidth = 4
opt.tabstop = 4
opt.expandtab = true
opt.smartindent = true

-- sync clipboard with wayland (wl-copy / wl-paste)
opt.clipboard = "unnamedplus"

-- persistent undo so closing nvim doesnt destroy my history
opt.undofile = true

-- search settings
opt.ignorecase = true
opt.smartcase = true

-- terminal colors & styling
opt.termguicolors = true
opt.signcolumn = "yes"
opt.scrolloff = 8

-- snappy response times
opt.updatetime = 50
opt.timeoutlen = 300

-- mouse support because clicking things is valid
opt.mouse = "a"
