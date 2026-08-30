-- popup cheat sheet when pressing space so i don't have to memorize 9000 keybinds
return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
        vim.o.timeout = true
        vim.o.timeoutlen = 300
    end,
    opts = {
        icons = {
            mappings = false,
        },
    },
}
