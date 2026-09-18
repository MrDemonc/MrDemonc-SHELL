-------------------------------------------------------------
-- KEYBINDINGS DE HYPRLAND & QUICKSHELL
-- Archivo: ~/.config/hypr/keybinds.lua
-------------------------------------------------------------

local userHome    = os.getenv("HOME") or ""
local binDir      = (userHome ~= "" and (userHome .. "/.local/bin")) or "/usr/local/bin"
local terminal    = binDir .. "/shell-terminal"
local fileManager = "nautilus"
local browser     = "zen-browser"
local mainMod     = "SUPER"

-------------------------------------------------------------
-- ATAJOS PRINCIPALES
-------------------------------------------------------------

-- Terminal (SUPER + Enter)
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))

-- Navegador Web Zen Browser (SUPER + B)
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))

-- Cerrar ventana activa (SUPER + W)
hl.bind(mainMod .. " + W", hl.dsp.window.close())

-- Quickshell: Fondos de Pantalla (SUPER + SHIFT + W)
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(binDir .. "/shell-wallpaper"))

-- Quickshell: Selector de Temas (SUPER + SHIFT + T)
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd(binDir .. "/shell-theme"))

-- Quickshell: Lanzador de Aplicaciones (SUPER + Espacio)
hl.bind(mainMod .. " + space", hl.dsp.exec_cmd(binDir .. "/shell-apps"))

-- Quickshell: Guía de Atajos de Teclado y Comandos (SUPER + K)
hl.bind(mainMod .. " + K", hl.dsp.exec_cmd(binDir .. "/shell-keybinds"))

-- Quickshell: Configuración de Pantallas y Monitores (SUPER + SHIFT + S)
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(binDir .. "/shell-monitors"))

-- Quickshell: Centro y Panel de Notificaciones (SUPER + N)
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd(binDir .. "/shell-notifications"))

-- Quickshell: Modo Cafeína (SUPER + SHIFT + C)
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd(binDir .. "/shell-caffeine"))

-- Quickshell: Grabadora de Pantalla (SUPER + SHIFT + R)
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd(binDir .. "/shell-recorder"))

-- Quickshell: Cuentagotas / Selector de Color (SUPER + SHIFT + P)
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd(binDir .. "/shell-colorpicker"))

-- Quickshell: Actualización Automática del Sistema (SUPER + SHIFT + U)
hl.bind(mainMod .. " + SHIFT + U", hl.dsp.exec_cmd(binDir .. "/shell-update"))

-- Explorador de archivos (SUPER + E)
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))

-- Gestión de ventanas
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

-- Bloquear pantalla (SUPER + L) con soporte en sesión bloqueada
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd(binDir .. "/shell-lock"), { locked = true })

-- Auto-recuperación de emergencia de pantalla de bloqueo colgada (SUPER + SHIFT + Escape)
hl.bind(mainMod .. " + SHIFT + Escape", hl.dsp.exec_cmd(binDir .. "/shell-recover-lock"), { locked = true })

-- Captura de Pantalla (Tecla Impr Pant / Print)
hl.bind("Print", hl.dsp.exec_cmd(binDir .. "/shell-screenshot"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd(binDir .. "/shell-screenshot area"))
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd(binDir .. "/shell-screenshot area"))

-- Quickshell: Menú de Apagado y Gestión de Energía (SUPER + Escape)
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd(binDir .. "/shell-power"))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd(binDir .. "/shell-power"))

-------------------------------------------------------------
-- PORTAPAPELES COMPATIBLE CON WAYLAND (SUPER + C / X / V)
-------------------------------------------------------------
local function is_terminal_window(win)
    if not win or not win.class then return false end
    local c = win.class:lower()
    return c:find("kitty") ~= nil or c:find("terminal") ~= nil or c:find("foot") ~= nil or c:find("alacritty") ~= nil or c:find("wezterm") ~= nil or c:find("console") ~= nil
end

local function clipboard_action(action)
    local win = hl.get_active_window()
    local is_term = is_terminal_window(win)

    if action == "copy" then
        if is_term then
            hl.dispatch(hl.dsp.send_shortcut({ mods = "CTRL + SHIFT", key = "c" }))
        else
            hl.dispatch(hl.dsp.send_shortcut({ mods = "CTRL", key = "c" }))
        end
    elseif action == "cut" then
        if is_term then
            hl.dispatch(hl.dsp.send_shortcut({ mods = "CTRL + SHIFT", key = "c" }))
        else
            hl.dispatch(hl.dsp.send_shortcut({ mods = "CTRL", key = "x" }))
        end
    elseif action == "paste" then
        if is_term then
            hl.dispatch(hl.dsp.send_shortcut({ mods = "CTRL + SHIFT", key = "v" }))
        else
            hl.dispatch(hl.dsp.send_shortcut({ mods = "CTRL", key = "v" }))
        end
    end
end

-- 1. SUPER + C: COPIAR
hl.bind(mainMod .. " + C", function() clipboard_action("copy") end)

-- 2. SUPER + X: CORTAR
hl.bind(mainMod .. " + X", function() clipboard_action("cut") end)

-- 3. SUPER + V: PEGAR
hl.bind(mainMod .. " + V", function() clipboard_action("paste") end)

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
-- TECLAS DEDICADAS DE HARDWARE (BRILLO Y VOLUMEN CON OSD ESTILO MACOS)
-------------------------------------------------------------
-- Control de audio por teclas dedicadas del teclado
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(binDir .. "/shell-osd volume-up"),   { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(binDir .. "/shell-osd volume-down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd(binDir .. "/shell-osd volume-mute"), { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd(binDir .. "/shell-osd mic-mute"),    { locked = true })

-- Control de brillo por teclas dedicadas del teclado (laptops)
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd(binDir .. "/shell-osd brightness-up"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd(binDir .. "/shell-osd brightness-down"), { locked = true, repeating = true })

-- Control de reproducción multimedia (playerctl)
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Botón físico de encendido/apagado y suspensión (abre menú de energía de Quickshell)
hl.bind("XF86PowerOff",  hl.dsp.exec_cmd(binDir .. "/shell-power open"), { locked = true, ignore_mods = true })
hl.bind("XF86PowerDown", hl.dsp.exec_cmd(binDir .. "/shell-power open"), { locked = true, ignore_mods = true })
hl.bind("XF86Sleep",     hl.dsp.exec_cmd(binDir .. "/shell-power open"), { locked = true, ignore_mods = true })

-------------------------------------------------------------
-- GESTIÓN DE TAPA DE LAPTOP (LID SWITCH)
-------------------------------------------------------------
-- Al cerrar la tapa de la laptop con pantalla externa conectada, conmuta automáticamente a sólo pantalla externa
hl.bind("switch:on:Lid Switch",  hl.dsp.exec_cmd(binDir .. "/shell-monitors lid_close"), { locked = true })
-- Al abrir la tapa de la laptop, reactiva la pantalla y restaura el escritorio extendido
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd(binDir .. "/shell-monitors lid_open"),  { locked = true })

