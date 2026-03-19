-- HotPurpleTrafficLight colorscheme for Neovim
-- Matching btop's HotPurpleTrafficLight by Pete Allebone
--
-- Place at: ~/.config/nvim/colors/hotpurpletrafficlight.lua
-- Then activate: vim.cmd("colorscheme hotpurpletrafficlight")
-- Or in lazy.nvim, just drop it into your colors/ dir and set it.

local M = {}

local c = {
    bg          = "#000000",
    bg_light    = "#1a1a2e",
    bg_float    = "#0a0a14",
    bg_sel      = "#6666ff",
    fg          = "#d1d1e0",
    fg_dim      = "#9999ff",
    fg_bright   = "#eeeef5",
    purple      = "#9933ff", -- hi_fg / signature purple
    purple_m    = "#a64dff", -- box outlines
    blue_p      = "#6666ff", -- selected_bg
    blue_dim    = "#4d4dff", -- meter_bg / div_line
    green       = "#00ff00", -- traffic light green
    green_light = "#66d98e", -- lighter version of green
    yellow      = "#ccff66", -- graph mid
    orange      = "#ff9933", -- temp mid / warning
    red         = "#ff0000", -- traffic light red
    inactive    = "#9999ff",
    gutter      = "#33334d",
    comment     = "#7a7aad",
}

local function hi(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
end

function M.setup()
    vim.cmd("hi clear")
    if vim.fn.exists("syntax_on") == 1 then
        vim.cmd("syntax reset")
    end
    vim.o.termguicolors = true
    vim.g.colors_name = "hotpurpletrafficlight"

    -- ── Editor ──────────────────────────────────────────────────
    hi("Normal", { fg = c.fg, bg = c.bg })
    hi("NormalFloat", { fg = c.fg, bg = c.bg_light })
    hi("FloatBorder", { fg = c.purple_m, bg = c.bg_light })
    hi("Cursor", { fg = c.bg, bg = c.purple })
    hi("CursorLine", { bg = c.bg_light })
    hi("CursorColumn", { bg = c.bg_light })
    hi("ColorColumn", { bg = c.bg_light })
    hi("LineNr", { fg = c.gutter })
    hi("CursorLineNr", { fg = c.purple, bold = true })
    hi("SignColumn", { fg = c.gutter, bg = c.bg })
    hi("VertSplit", { fg = c.blue_dim })
    hi("WinSeparator", { fg = c.blue_dim })
    hi("StatusLine", { fg = c.fg, bg = c.bg_light })
    hi("StatusLineNC", { fg = c.inactive, bg = c.bg })
    hi("TabLine", { fg = c.inactive, bg = c.bg })
    hi("TabLineFill", { bg = c.bg })
    hi("TabLineSel", { fg = c.fg, bg = c.bg_sel, bold = true })
    hi("WinBar", { fg = c.fg, bg = c.bg })
    hi("WinBarNC", { fg = c.inactive, bg = c.bg })
    hi("Folded", { fg = c.comment, bg = c.bg_light })
    hi("FoldColumn", { fg = c.gutter })
    hi("NonText", { fg = c.gutter })
    hi("SpecialKey", { fg = c.blue_dim })
    hi("Visual", { bg = c.bg_sel })
    hi("VisualNOS", { bg = c.bg_sel })
    hi("Search", { fg = c.bg, bg = c.orange, bold = true })
    hi("IncSearch", { fg = c.bg, bg = c.green, bold = true })
    hi("CurSearch", { fg = c.bg, bg = c.green, bold = true })
    hi("MatchParen", { fg = c.orange, bold = true, underline = true })
    hi("Pmenu", { fg = c.fg, bg = c.bg_light })
    hi("PmenuSel", { fg = c.fg, bg = c.bg_sel })
    hi("PmenuSbar", { bg = c.gutter })
    hi("PmenuThumb", { bg = c.purple })
    hi("Directory", { fg = c.purple })
    hi("Title", { fg = c.purple, bold = true })
    hi("ErrorMsg", { fg = c.red, bold = true })
    hi("WarningMsg", { fg = c.orange, bold = true })
    hi("MoreMsg", { fg = c.green })
    hi("Question", { fg = c.green })
    hi("ModeMsg", { fg = c.purple, bold = true })
    hi("Conceal", { fg = c.comment })
    hi("Whitespace", { fg = c.gutter })

    -- ── Diff ────────────────────────────────────────────────────
    hi("DiffAdd", { fg = c.green, bg = "#002200" })
    hi("DiffChange", { fg = c.orange, bg = "#332200" })
    hi("DiffDelete", { fg = c.red, bg = "#220000" })
    hi("DiffText", { fg = c.fg, bg = "#333300", bold = true })

    -- ── Syntax ──────────────────────────────────────────────────
    hi("Comment", { fg = c.comment, italic = true })
    hi("Constant", { fg = c.orange })
    hi("String", { fg = c.green_light })
    hi("Character", { fg = c.green_light })
    hi("Number", { fg = c.orange })
    hi("Boolean", { fg = c.orange })
    hi("Float", { fg = c.orange })
    hi("Identifier", { fg = c.fg })
    hi("Function", { fg = c.purple, bold = true })
    hi("Statement", { fg = c.purple_m })
    hi("Conditional", { fg = c.purple_m })
    hi("Repeat", { fg = c.purple_m })
    hi("Label", { fg = c.blue_p })
    hi("Operator", { fg = c.fg_dim })
    hi("Keyword", { fg = c.purple, italic = true })
    hi("Exception", { fg = c.red })
    hi("PreProc", { fg = c.blue_p })
    hi("Include", { fg = c.blue_p })
    hi("Define", { fg = c.blue_p })
    hi("Macro", { fg = c.blue_p })
    hi("Type", { fg = c.yellow })
    hi("StorageClass", { fg = c.purple_m })
    hi("Structure", { fg = c.yellow })
    hi("Typedef", { fg = c.yellow })
    hi("Special", { fg = c.orange })
    hi("SpecialChar", { fg = c.orange })
    hi("Tag", { fg = c.purple })
    hi("Delimiter", { fg = c.fg_dim })
    hi("SpecialComment", { fg = c.purple, italic = true })
    hi("Debug", { fg = c.red })
    hi("Underlined", { underline = true })
    hi("Error", { fg = c.red, bold = true })
    hi("Todo", { fg = c.bg, bg = c.orange, bold = true })

    -- ── Treesitter ──────────────────────────────────────────────
    hi("@variable", { fg = c.fg })
    hi("@variable.builtin", { fg = c.orange, italic = true })
    hi("@variable.parameter", { fg = c.fg_dim })
    hi("@constant", { fg = c.orange })
    hi("@constant.builtin", { fg = c.orange, bold = true })
    hi("@module", { fg = c.blue_p })
    hi("@string", { fg = c.green_light })
    hi("@string.escape", { fg = c.yellow })
    hi("@string.regexp", { fg = c.yellow })
    hi("@character", { fg = c.green_light })
    hi("@number", { fg = c.orange })
    hi("@boolean", { fg = c.orange })
    hi("@float", { fg = c.orange })
    hi("@function", { fg = c.purple, bold = true })
    hi("@function.builtin", { fg = c.purple_m })
    hi("@function.call", { fg = c.purple })
    hi("@function.method", { fg = c.purple })
    hi("@function.method.call", { fg = c.purple })
    hi("@constructor", { fg = c.yellow })
    hi("@keyword", { fg = c.purple, italic = true })
    hi("@keyword.function", { fg = c.purple_m, italic = true })
    hi("@keyword.return", { fg = c.purple_m })
    hi("@keyword.operator", { fg = c.fg_dim })
    hi("@operator", { fg = c.fg_dim })
    hi("@punctuation", { fg = c.fg_dim })
    hi("@punctuation.bracket", { fg = c.fg_dim })
    hi("@punctuation.delimiter", { fg = c.fg_dim })
    hi("@punctuation.special", { fg = c.purple })
    hi("@type", { fg = c.yellow })
    hi("@type.builtin", { fg = c.yellow, italic = true })
    hi("@property", { fg = c.fg })
    hi("@attribute", { fg = c.blue_p })
    hi("@tag", { fg = c.purple })
    hi("@tag.attribute", { fg = c.yellow })
    hi("@tag.delimiter", { fg = c.fg_dim })
    hi("@comment", { fg = c.comment, italic = true })

    -- ── LSP hover / signature / popups ────────────────────────
    hi("NormalFloat", { fg = c.fg, bg = c.bg_float })
    hi("FloatBorder", { fg = c.purple_m, bg = c.bg_float })
    hi("FloatTitle", { fg = c.purple, bg = c.bg_float, bold = true })
    hi("LspInfoBorder", { fg = c.purple_m, bg = c.bg_float })

    -- ── Diagnostics ─────────────────────────────────────────────
    hi("DiagnosticError", { fg = c.red })
    hi("DiagnosticWarn", { fg = c.orange })
    hi("DiagnosticInfo", { fg = c.blue_p })
    hi("DiagnosticHint", { fg = c.inactive })
    hi("DiagnosticUnderlineError", { sp = c.red, undercurl = true })
    hi("DiagnosticUnderlineWarn", { sp = c.orange, undercurl = true })
    hi("DiagnosticUnderlineInfo", { sp = c.blue_p, undercurl = true })
    hi("DiagnosticUnderlineHint", { sp = c.inactive, undercurl = true })

    -- ── Git signs ───────────────────────────────────────────────
    hi("GitSignsAdd", { fg = c.green })
    hi("GitSignsChange", { fg = c.orange })
    hi("GitSignsDelete", { fg = c.red })

    -- ── Telescope ───────────────────────────────────────────────
    hi("TelescopeBorder", { fg = c.purple_m })
    hi("TelescopePromptBorder", { fg = c.purple })
    hi("TelescopeResultsBorder", { fg = c.blue_dim })
    hi("TelescopePreviewBorder", { fg = c.blue_dim })
    hi("TelescopePromptPrefix", { fg = c.purple })
    hi("TelescopeMatching", { fg = c.orange, bold = true })
    hi("TelescopeSelection", { bg = c.bg_sel })

    -- ── Indent Blankline ────────────────────────────────────────
    hi("IblIndent", { fg = c.gutter })
    hi("IblScope", { fg = c.purple })
    hi("IndentBlanklineChar", { fg = c.gutter })
    hi("IndentBlanklineContextChar", { fg = c.purple })

    -- ── Lazy / Mason / Which-key ────────────────────────────────
    hi("LazyH1", { fg = c.bg, bg = c.purple, bold = true })
    hi("LazyButton", { fg = c.fg, bg = c.bg_light })
    hi("LazyButtonActive", { fg = c.bg, bg = c.blue_p })
    hi("WhichKey", { fg = c.purple })
    hi("WhichKeyGroup", { fg = c.blue_p })
    hi("WhichKeyDesc", { fg = c.fg })
    hi("WhichKeySeparator", { fg = c.comment })

    -- ── Render-markdown ───────────────────────────────────────
    hi("RenderMarkdownCode", { bg = c.bg_light })
    hi("RenderMarkdownCodeInline", { fg = c.purple, bg = c.bg_light })
    hi("RenderMarkdownH1Bg", { fg = c.purple, bg = c.bg_light, bold = true })
    hi("RenderMarkdownH2Bg", { fg = c.purple_m, bg = c.bg_light, bold = true })
    hi("RenderMarkdownH3Bg", { fg = c.blue_p, bg = c.bg_light, bold = true })
    hi("RenderMarkdownH4Bg", { fg = c.yellow, bg = c.bg_light })
    hi("RenderMarkdownH5Bg", { fg = c.orange, bg = c.bg_light })
    hi("RenderMarkdownH6Bg", { fg = c.inactive, bg = c.bg_light })
    -- ── Lualine (expose palette for lualine theme) ──────────────
    -- See the separate lualine theme file below.
end

-- Auto-setup when the colorscheme is loaded
M.setup()

-- Expose palette for lualine integration
M.colors = c

return M
