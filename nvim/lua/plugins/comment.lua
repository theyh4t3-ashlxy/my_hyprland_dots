-- gcc to comment line, gc in visual mode
return {
    "numToStr/Comment.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {},
}
