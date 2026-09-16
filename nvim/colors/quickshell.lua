-- Generado automáticamente por Quickshell Theme Manager
-- Tema activo: Street
vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end
vim.g.colors_name = "quickshell"
vim.o.termguicolors = true
vim.o.background = "dark"

local c = {
  bg = "#14171a",
  bg_surface = "#1b1f23",
  bg_hover = "#282e35",
  border = "#3a434c",
  fg = "#ece5de",
  subtext = "#b8ab9f",
  overlay = "#707a84",
  primary = "#f5af19",
  success = "#6f9479",
  warning = "#e59b1f",
  danger = "#c85a42",
  cyan = "#77a2b2",
  pink = "#b67d8f",
}

local hl = function(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

-- Fondo transparente integrado directamente con Kitty (cero desfase de bordes)
hl("Normal", { fg = c.fg, bg = "none" })
hl("NormalNC", { fg = c.subtext, bg = "none" })
hl("NormalFloat", { fg = c.fg, bg = "none" })
hl("FloatBorder", { fg = c.primary, bg = "none" })
hl("FloatTitle", { fg = c.primary, bg = "none", bold = true })
hl("CursorLine", { bg = c.bg_hover })
hl("CursorColumn", { bg = c.bg_hover })
hl("ColorColumn", { bg = c.bg_surface })
hl("LineNr", { fg = c.overlay, bg = "none" })
hl("CursorLineNr", { fg = c.primary, bg = "none", bold = true })
hl("SignColumn", { fg = c.overlay, bg = "none" })
hl("EndOfBuffer", { fg = c.border, bg = "none" })
hl("MsgArea", { fg = c.fg, bg = "none" })
hl("VertSplit", { fg = c.border, bg = "none" })
hl("WinSeparator", { fg = c.border, bg = "none" })
hl("StatusLine", { fg = c.fg, bg = c.bg_surface })
hl("StatusLineNC", { fg = c.overlay, bg = c.bg_surface })
hl("TabLine", { fg = c.overlay, bg = c.bg_surface })
hl("TabLineFill", { bg = c.bg_surface })
hl("TabLineSel", { fg = c.bg, bg = c.primary, bold = true })
hl("Pmenu", { fg = c.fg, bg = c.bg_surface })
hl("PmenuSel", { fg = c.bg, bg = c.primary, bold = true })
hl("PmenuSbar", { bg = c.bg_surface })
hl("PmenuThumb", { bg = c.overlay })
hl("Visual", { bg = c.bg_hover })
hl("VisualNOS", { bg = c.bg_hover })
hl("Search", { fg = c.bg, bg = c.warning })
hl("IncSearch", { fg = c.bg, bg = c.primary })
hl("CurSearch", { fg = c.bg, bg = c.primary, bold = true })
hl("MatchParen", { fg = c.primary, bold = true, underline = true })
hl("Directory", { fg = c.primary, bold = true })
hl("Title", { fg = c.primary, bold = true })

-- Sintaxis estándar
hl("Comment", { fg = c.overlay, italic = true })
hl("Constant", { fg = c.warning })
hl("String", { fg = c.success })
hl("Character", { fg = c.success })
hl("Number", { fg = c.warning })
hl("Boolean", { fg = c.warning, bold = true })
hl("Float", { fg = c.warning })
hl("Identifier", { fg = c.fg })
hl("Function", { fg = c.primary, bold = true })
hl("Statement", { fg = c.pink })
hl("Conditional", { fg = c.pink })
hl("Repeat", { fg = c.pink })
hl("Label", { fg = c.pink })
hl("Operator", { fg = c.cyan })
hl("Keyword", { fg = c.pink, bold = true })
hl("Exception", { fg = c.danger })
hl("PreProc", { fg = c.cyan })
hl("Include", { fg = c.cyan })
hl("Define", { fg = c.cyan })
hl("Macro", { fg = c.cyan })
hl("Type", { fg = c.cyan })
hl("StorageClass", { fg = c.cyan })
hl("Structure", { fg = c.cyan })
hl("Typedef", { fg = c.cyan })
hl("Special", { fg = c.primary })
hl("SpecialChar", { fg = c.warning })
hl("Tag", { fg = c.primary })
hl("Delimiter", { fg = c.subtext })
hl("SpecialComment", { fg = c.overlay, bold = true })
hl("Debug", { fg = c.danger })
hl("Underlined", { underline = true })
hl("Error", { fg = c.danger, bold = true })
hl("Todo", { fg = c.bg, bg = c.warning, bold = true })

-- Diagnósticos LSP
hl("DiagnosticError", { fg = c.danger })
hl("DiagnosticWarn", { fg = c.warning })
hl("DiagnosticInfo", { fg = c.cyan })
hl("DiagnosticHint", { fg = c.primary })
hl("DiagnosticUnderlineError", { undercurl = true, sp = c.danger })
hl("DiagnosticUnderlineWarn", { undercurl = true, sp = c.warning })
hl("DiagnosticUnderlineInfo", { undercurl = true, sp = c.cyan })
hl("DiagnosticUnderlineHint", { undercurl = true, sp = c.primary })

-- Git Signs
hl("GitSignsAdd", { fg = c.success, bg = "none" })
hl("GitSignsChange", { fg = c.warning, bg = "none" })
hl("GitSignsDelete", { fg = c.danger, bg = "none" })

-- Treesitter
hl("@function", { fg = c.primary, bold = true })
hl("@function.call", { fg = c.primary })
hl("@method", { fg = c.primary })
hl("@keyword", { fg = c.pink, bold = true })
hl("@keyword.function", { fg = c.pink, bold = true })
hl("@keyword.return", { fg = c.pink, bold = true })
hl("@string", { fg = c.success })
hl("@variable", { fg = c.fg })
hl("@variable.builtin", { fg = c.pink })
hl("@property", { fg = c.cyan })
hl("@type", { fg = c.cyan })
hl("@type.builtin", { fg = c.cyan })
hl("@constant", { fg = c.warning })
hl("@comment", { fg = c.overlay, italic = true })
hl("@punctuation", { fg = c.subtext })
hl("@operator", { fg = c.cyan })

-- Neo-tree / Snacks / Telescope
hl("NeoTreeNormal", { fg = c.fg, bg = "none" })
hl("NeoTreeNormalNC", { fg = c.subtext, bg = "none" })
hl("NeoTreeDirectoryIcon", { fg = c.primary })
hl("NeoTreeDirectoryName", { fg = c.fg, bold = true })
hl("NeoTreeFileName", { fg = c.subtext })
hl("NeoTreeRootName", { fg = c.primary, bold = true })
hl("NeoTreeGitAdded", { fg = c.success })
hl("NeoTreeGitModified", { fg = c.warning })
hl("NeoTreeGitDeleted", { fg = c.danger })
hl("TelescopeNormal", { fg = c.fg, bg = "none" })
hl("TelescopeBorder", { fg = c.primary, bg = "none" })
hl("TelescopePromptNormal", { fg = c.fg, bg = "none" })
hl("TelescopePromptBorder", { fg = c.primary, bg = "none" })
hl("TelescopePromptTitle", { fg = c.bg, bg = c.primary, bold = true })
hl("TelescopePreviewTitle", { fg = c.bg, bg = c.success, bold = true })
hl("TelescopeResultsTitle", { fg = c.bg, bg = c.cyan, bold = true })
hl("TelescopeSelection", { bg = c.bg_hover, bold = true })
hl("SnacksNormal", { fg = c.fg, bg = "none" })
hl("SnacksNormalNC", { fg = c.subtext, bg = "none" })
hl("SnacksDashboardHeader", { fg = c.primary, bold = true })
hl("SnacksDashboardKey", { fg = c.pink, bold = true })
hl("SnacksDashboardDesc", { fg = c.fg })
hl("SnacksDashboardIcon", { fg = c.cyan })
