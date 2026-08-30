local function apply_matugen_theme()
    local ok, c = pcall(require, "config.colors")
    if not ok or type(c) ~= "table" then
        -- fallback palette if matugen hasn't generated colors.lua yet
        c = {
            bg = "#14140c",
            fg = "#e5e3d6",
            primary = "#c9cb78",
            on_primary = "#313300",
            secondary = "#c9c8a5",
            on_secondary = "#313219",
            tertiary = "#a3d0be",
            error = "#ffb4ab",
            outline = "#939182",
            outline_variant = "#48473a",
            surface_container = "#202018",
            surface_container_high = "#2b2a22",
        }
    end

    local hl = function(group, opts)
        vim.api.nvim_set_hl(0, group, opts)
    end

    -- editor basics (transparent background so wallpaper shines through)
    hl("Normal", { fg = c.fg, bg = "none" })
    hl("NormalNC", { fg = c.fg, bg = "none" })
    hl("NormalFloat", { fg = c.fg, bg = "none" })
    hl("FloatBorder", { fg = c.primary, bg = "none" })
    hl("EndOfBuffer", { fg = c.outline_variant, bg = "none" })
    hl("CursorLine", { bg = c.surface_container })
    hl("CursorLineNr", { fg = c.primary, bold = true })
    hl("LineNr", { fg = c.outline })
    hl("SignColumn", { bg = "none" })
    hl("ColorColumn", { bg = c.surface_container })
    hl("VertSplit", { fg = c.outline_variant, bg = "none" })
    hl("WinSeparator", { fg = c.outline_variant, bg = "none" })
    hl("StatusLine", { fg = c.fg, bg = c.surface_container })
    hl("StatusLineNC", { fg = c.outline, bg = "none" })

    -- syntax highlighting
    hl("Comment", { fg = c.outline, italic = true })
    hl("Constant", { fg = c.tertiary })
    hl("String", { fg = c.tertiary })
    hl("Character", { fg = c.tertiary })
    hl("Number", { fg = c.tertiary })
    hl("Boolean", { fg = c.tertiary, bold = true })
    hl("Float", { fg = c.tertiary })
    hl("Identifier", { fg = c.fg })
    hl("Function", { fg = c.primary, bold = true })
    hl("Statement", { fg = c.secondary, bold = true })
    hl("Conditional", { fg = c.secondary, bold = true })
    hl("Repeat", { fg = c.secondary, bold = true })
    hl("Label", { fg = c.secondary })
    hl("Operator", { fg = c.outline })
    hl("Keyword", { fg = c.secondary, bold = true })
    hl("Exception", { fg = c.error })
    hl("PreProc", { fg = c.primary })
    hl("Type", { fg = c.primary })
    hl("Structure", { fg = c.primary })
    hl("Special", { fg = c.secondary })
    hl("Underlined", { underline = true })
    hl("Error", { fg = c.error, bold = true })
    hl("Todo", { fg = c.primary, bold = true })

    -- search & selection
    hl("Search", { fg = c.on_primary, bg = c.primary })
    hl("IncSearch", { fg = c.on_primary, bg = c.primary })
    hl("Visual", { bg = c.surface_container_high })
    hl("MatchParen", { fg = c.primary, underline = true, bold = true })

    -- popup completion menu
    hl("Pmenu", { fg = c.fg, bg = c.surface_container })
    hl("PmenuSel", { fg = c.on_primary, bg = c.primary, bold = true })
    hl("PmenuSbar", { bg = c.surface_container_high })
    hl("PmenuThumb", { bg = c.primary })

    -- diagnostics
    hl("DiagnosticError", { fg = c.error })
    hl("DiagnosticWarn", { fg = c.secondary })
    hl("DiagnosticInfo", { fg = c.primary })
    hl("DiagnosticHint", { fg = c.tertiary })
    hl("DiagnosticUnderlineError", { undercurl = true, sp = c.error })
    hl("DiagnosticUnderlineWarn", { undercurl = true, sp = c.secondary })

    -- tree-sitter highlights
    hl("@variable", { fg = c.fg })
    hl("@variable.builtin", { fg = c.secondary, italic = true })
    hl("@function", { fg = c.primary, bold = true })
    hl("@function.builtin", { fg = c.primary })
    hl("@keyword", { fg = c.secondary, bold = true })
    hl("@string", { fg = c.tertiary })
    hl("@type", { fg = c.primary })
    hl("@comment", { fg = c.outline, italic = true })
    hl("@property", { fg = c.fg })

    -- telescope
    hl("TelescopeBorder", { fg = c.primary, bg = "none" })
    hl("TelescopePromptBorder", { fg = c.secondary, bg = "none" })
    hl("TelescopeResultsBorder", { fg = c.primary, bg = "none" })
    hl("TelescopePreviewBorder", { fg = c.outline, bg = "none" })
    hl("TelescopeTitle", { fg = c.on_primary, bg = c.primary, bold = true })
    hl("TelescopePromptPrefix", { fg = c.primary })
    hl("TelescopeSelection", { bg = c.surface_container_high })

    -- neo-tree
    hl("NeoTreeNormal", { fg = c.fg, bg = "none" })
    hl("NeoTreeNormalNC", { fg = c.fg, bg = "none" })
    hl("NeoTreeEndOfBuffer", { fg = c.outline_variant, bg = "none" })
    hl("NeoTreeDirectoryIcon", { fg = c.primary })
    hl("NeoTreeDirectoryName", { fg = c.primary, bold = true })
    hl("NeoTreeFileName", { fg = c.fg })
    hl("NeoTreeRootName", { fg = c.primary, bold = true })
    hl("NeoTreeGitModified", { fg = c.secondary })
    hl("NeoTreeGitUntracked", { fg = c.tertiary })
end

local function get_lualine_theme()
    local ok, c = pcall(require, "config.colors")
    if not ok or type(c) ~= "table" then
        return "auto"
    end
    return {
        normal = {
            a = { fg = c.on_primary, bg = c.primary, gui = "bold" },
            b = { fg = c.fg, bg = c.surface_container },
            c = { fg = c.outline, bg = "none" },
        },
        insert = {
            a = { fg = c.on_tertiary, bg = c.tertiary, gui = "bold" },
            b = { fg = c.fg, bg = c.surface_container },
            c = { fg = c.outline, bg = "none" },
        },
        visual = {
            a = { fg = c.on_secondary, bg = c.secondary, gui = "bold" },
            b = { fg = c.fg, bg = c.surface_container },
            c = { fg = c.outline, bg = "none" },
        },
        replace = {
            a = { fg = c.on_error, bg = c.error, gui = "bold" },
            b = { fg = c.fg, bg = c.surface_container },
            c = { fg = c.outline, bg = "none" },
        },
        command = {
            a = { fg = c.on_primary, bg = c.secondary, gui = "bold" },
            b = { fg = c.fg, bg = c.surface_container },
            c = { fg = c.outline, bg = "none" },
        },
        inactive = {
            a = { fg = c.outline, bg = "none" },
            b = { fg = c.outline, bg = "none" },
            c = { fg = c.outline, bg = "none" },
        },
    }
end

return {
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = function()
            apply_matugen_theme()
            return {
                options = {
                    theme = get_lualine_theme(),
                    component_separators = { left = "", right = "" },
                    section_separators = { left = "", right = "" },
                    globalstatus = true,
                },
            }
        end,
    },
}
