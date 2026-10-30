-------------------------------------------------------------
-- DISEÑO Y APARIENCIA DE VENTANAS (HYPRLAND)
-- Archivo: ~/.config/hypr/windows.lua
-------------------------------------------------------------

-- Cargar colores del tema activo (generado por theme_manager.py)
local themeColors = {
    active_border    = "rgba(7aa2f7ee)",
    secondary_border = "rgba(7dcfffee)",
    inactive_border  = "rgba(3b4261aa)",
}

pcall(function()
    local loaded = require("theme_colors")
    if type(loaded) == "table" then
        if loaded.active_border then themeColors.active_border = loaded.active_border end
        if loaded.secondary_border then themeColors.secondary_border = loaded.secondary_border end
        if loaded.inactive_border then themeColors.inactive_border = loaded.inactive_border end
    end
end)

-- Cargar configuración del efecto Wobble / Compiz (Hyprland 0.57+)
local wobbleConfig = {
    enabled   = true,
    mesh      = 12,
    stiffness = 180.0,
    damping   = 11.0,
    mass      = 1.0,
    intensity = 0.25,
}

pcall(function()
    local loaded = require("wobble_config")
    if type(loaded) == "table" then
        if loaded.enabled ~= nil then wobbleConfig.enabled = loaded.enabled end
        if loaded.mesh then wobbleConfig.mesh = loaded.mesh end
        if loaded.stiffness then wobbleConfig.stiffness = loaded.stiffness end
        if loaded.damping then wobbleConfig.damping = loaded.damping end
        if loaded.mass then wobbleConfig.mass = loaded.mass end
        if loaded.intensity then wobbleConfig.intensity = loaded.intensity end
    end
end)

hl.config({
    general = {
        -- Menor espacio y padding entre ventanas y bordes de pantalla
        gaps_in  = 3,
        gaps_out = 6,

        -- Grosor del borde de ventana
        border_size = 2,

        -- Colores dinámicos adaptados al tema
        col = {
            active_border   = { 
                colors = { themeColors.active_border, themeColors.secondary_border }, 
                angle = 45 
            },
            inactive_border = themeColors.inactive_border,
        },

        -- Permitir redimensionar arrastrando en bordes
        resize_on_border = true,

        -- Dwindle layout para gestión automática de mosaico
        layout = "dwindle",
    },

    decoration = {
        -- Esquinas rectas (0 radio)
        rounding       = 0,
        rounding_power = 1,

        -- Opacidad y transparencia sutil y legible para ventanas (efecto glass)
        active_opacity   = 0.92,
        inactive_opacity = 0.85,

        -- Sombras sutiles y elegantes
        shadow = {
            enabled      = true,
            range        = 8,
            render_power = 3,
            color        = 0xaa101014,
        },

        -- Desenfoque (blur) de fondo con suavizado y soporte para opacidad de ventanas
        blur = {
            enabled           = true,
            size              = 6,
            passes            = 3,
            vibrancy          = 0.2,
            ignore_opacity    = true,
            new_optimizations = true,
        },

        -- Efecto Ventanas Gelatinosas (Wobble / Compiz) - Hyprland 0.57+
        wobble = {
            enabled   = wobbleConfig.enabled,
            mesh      = wobbleConfig.mesh,
            stiffness = wobbleConfig.stiffness,
            damping   = wobbleConfig.damping,
            mass      = wobbleConfig.mass,
            intensity = wobbleConfig.intensity,
        },
    },
})
