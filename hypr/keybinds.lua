-------------------------------------------------------------
-- KEYBINDINGS DE HYPRLAND & QUICKSHELL
-- Archivo: ~/.config/hypr/keybinds.lua
-------------------------------------------------------------

local userHome    = os.getenv("HOME") or "/home/demonc-test"
local binDir      = userHome .. "/.local/bin"
local terminal    = "kitty"
local fileManager = "dolphin"
local mainMod     = "SUPER"

-------------------------------------------------------------
-- ATAJOS PRINCIPALES
-------------------------------------------------------------

-- Terminal (SUPER + Enter)
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))

-- Cerrar ventana activa (SUPER + W)
hl.bind(mainMod .. " + W", hl.dsp.window.close())

-- Quickshell: Fondos de Pantalla (SUPER + SHIFT + W)
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(binDir .. "/shell-wallpaper"))

-- Quickshell: Selector de Temas (SUPER + SHIFT + T)
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd(binDir .. "/shell-theme"))

-- Quickshell: Lanzador de Aplicaciones (SUPER + Espacio)
hl.bind(mainMod .. " + space", hl.dsp.exec_cmd(binDir .. "/shell-apps"))

-- Explorador de archivos (SUPER + E)
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))

-- Gestión de ventanas
hl.bind(mainMod .. " + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

-- Bloquear pantalla (SUPER + L)
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("command -v hyprlock >/dev/null 2>&1 && hyprlock || notify-send 'MrDemonc-SHELL' 'hyprlock no está instalado. Ejecuta: sudo pacman -S hyprlock' -u normal -t 4000"))

-- Apagado / Salir
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))

-------------------------------------------------------------
-- NAVEGACIÓN Y ESPACIOS DE TRABAJO (WORKSPACES)
-------------------------------------------------------------

-- Mover foco entre ventanas con flechas (SUPER + flechas)
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Mover ventanas de posición con SUPER + SHIFT + flechas
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))

-- Cambiar de workspace con SUPER + [1-9, 0]
-- Mover ventana a workspace con SUPER + SHIFT + [1-9, 0]
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Espacio especial (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Desplazarse por workspaces con rueda del ratón
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Mover / Redimensionar ventanas con ratón + SUPER
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-------------------------------------------------------------
-- TECLAS MULTIMEDIA Y BRILLO
-------------------------------------------------------------
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Control de reproducción multimedia (playerctl)
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
