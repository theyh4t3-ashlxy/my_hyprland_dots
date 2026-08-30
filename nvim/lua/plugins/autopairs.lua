-- auto-close quotes and brackets before i lose my mind
return {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {
        check_ts = true,
    },
}
