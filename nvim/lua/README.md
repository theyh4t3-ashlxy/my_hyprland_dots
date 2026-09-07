# nvim/lua

the central nervous system of neovim.

lua tables and closures all the way down. no global vimscript variables polluting memory.

## subdirectories
- `config/`: editor options, keymaps, autocommands, and wallpaper color integration hooks.
- `plugins/`: modular lazy plugin specs (telescope, treesitter, lsp-zero, cmp, bufferline, lualine, etc) where each tool is given its own declarative isolated config table.
