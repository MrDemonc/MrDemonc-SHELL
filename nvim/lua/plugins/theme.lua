return {
  -- Configurar el colorscheme predeterminado de LazyVim
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "quickshell",
    },
  },

  -- Adaptar Lualine al tema activo con transparencia
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.options = opts.options or {}
      opts.options.theme = "quickshell"
    end,
  },

  -- Configuración de Tokyonight en caso de seleccionarse manualmente (con transparencia activa)
  {
    "folke/tokyonight.nvim",
    opts = {
      transparent = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
    },
  },

  -- Configuración de Catppuccin si se llega a usar
  {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = {
      transparent_background = true,
    },
  },
}
