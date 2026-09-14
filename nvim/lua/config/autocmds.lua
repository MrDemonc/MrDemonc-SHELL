-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

-- 1. Transparencia total de fondo para eliminar cualquier borde o desfase con Kitty
local function apply_transparency()
  local groups = {
    "Normal",
    "NormalNC",
    "NormalFloat",
    "FloatBorder",
    "FloatTitle",
    "SignColumn",
    "LineNr",
    "CursorLineNr",
    "FoldColumn",
    "Folded",
    "EndOfBuffer",
    "NeoTreeNormal",
    "NeoTreeNormalNC",
    "NeoTreeEndOfBuffer",
    "SnacksNormal",
    "SnacksNormalNC",
    "WhichKeyNormal",
    "TelescopeNormal",
    "TelescopeBorder",
    "TelescopePromptNormal",
    "TelescopePromptBorder",
  }
  for _, g in ipairs(groups) do
    pcall(vim.api.nvim_set_hl, 0, g, { bg = "none", ctermbg = "none" })
  end
end

vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter", "BufEnter" }, {
  callback = apply_transparency,
})

-- 2. Recargar automáticamente el colorscheme cuando Quickshell Theme Manager actualice quickshell.lua
local colors_file = vim.fn.stdpath("config") .. "/colors/quickshell.lua"
local watcher = (vim.uv or vim.loop).new_fs_event()
if watcher then
  watcher:start(colors_file, {}, vim.schedule_wrap(function(err, fname, events)
    if not err then
      pcall(vim.cmd, "colorscheme quickshell")
      apply_transparency()
    end
  end))
end
