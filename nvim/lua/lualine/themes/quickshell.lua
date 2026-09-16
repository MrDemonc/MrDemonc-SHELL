-- Generado automáticamente por Quickshell Theme Manager
local colors = {
  bg = "#14171a",
  bg_surface = "#1b1f23",
  bg_hover = "#282e35",
  fg = "#ece5de",
  primary = "#f5af19",
  success = "#6f9479",
  warning = "#e59b1f",
  danger = "#c85a42",
  pink = "#b67d8f",
  cyan = "#77a2b2",
  overlay = "#707a84",
}

return {
  normal = {
    a = { fg = colors.bg, bg = colors.primary, gui = "bold" },
    b = { fg = colors.fg, bg = colors.bg_surface },
    c = { fg = colors.overlay, bg = "none" },
  },
  insert = {
    a = { fg = colors.bg, bg = colors.success, gui = "bold" },
    b = { fg = colors.fg, bg = colors.bg_surface },
    c = { fg = colors.overlay, bg = "none" },
  },
  visual = {
    a = { fg = colors.bg, bg = colors.pink, gui = "bold" },
    b = { fg = colors.fg, bg = colors.bg_surface },
    c = { fg = colors.overlay, bg = "none" },
  },
  replace = {
    a = { fg = colors.bg, bg = colors.danger, gui = "bold" },
    b = { fg = colors.fg, bg = colors.bg_surface },
    c = { fg = colors.overlay, bg = "none" },
  },
  command = {
    a = { fg = colors.bg, bg = colors.warning, gui = "bold" },
    b = { fg = colors.fg, bg = colors.bg_surface },
    c = { fg = colors.overlay, bg = "none" },
  },
  inactive = {
    a = { fg = colors.overlay, bg = "none", gui = "bold" },
    b = { fg = colors.overlay, bg = "none" },
    c = { fg = colors.overlay, bg = "none" },
  },
}
