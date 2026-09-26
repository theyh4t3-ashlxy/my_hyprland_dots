return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    lazy = false,
    opts = {
      window = {
        mappings = {
          ["j"] = "close_node",
          ["l"] = "open",
          ["i"] = function() vim.cmd("normal! gk") end,
          ["k"] = function() vim.cmd("normal! gj") end,
        },
      },
    },
  }
}
