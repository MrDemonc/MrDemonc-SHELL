-- Generado automáticamente por Quickshell Theme Manager
local colors = {
  bg = "#1a1d24",
  bg_surface = "#14161d",
  bg_hover = "#282d38",
  fg = "#eceff4",
  primary = "#88c0d0",
  success = "#a3be8c",
  warning = "#ebcb8b",
  danger = "#bf616a",
  pink = "#b48ead",
  cyan = "#81a1c1",
  overlay = "#7b889b",
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
