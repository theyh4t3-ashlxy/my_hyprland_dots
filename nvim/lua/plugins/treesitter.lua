return {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    lazy = false,
    build = ":TSUpdate",
    config = function()
        local ok, configs = pcall(require, "nvim-treesitter.configs")
        if not ok then
            return
        end
        configs.setup({
            highlight = { enable = true },
            indent = { enable = true },
            ensure_installed = {
                "lua",
                "python",
                "javascript",
                "typescript",
                "markdown",
                "markdown_inline",
                "bash",
                "css",
                "json",
                "toml",
            },
            auto_install = true,
        })
    end,
}
