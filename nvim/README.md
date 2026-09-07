# nvim

neovim configured cleanly in lua because vimscript belongs in a museum of ancient curses.

exit with `:qa!` or pull the power cord out of the wall. there is no middle ground.

powered by `lazy.nvim`. snappy startup times, zero plugin bloat, intelligent lsp auto-completion, treesitter parsing, and synchronized dynamically with matugen so your editor colors match whatever wallpaper is currently gracing your display.

## directory map
- `init.lua`: the bootstrap script. downloads `lazy.nvim` if missing and initializes the lua module tree.
- `lazy-lock.json`: deterministic lockfile pinning plugin commits so an upstream breaking change doesn't murder your workflow while you are in the zone.
- `lua/`: the entire modular configuration containing your keymaps, options, and plugin specifications.
