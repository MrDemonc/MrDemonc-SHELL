#!/usr/bin/env bash
# ==============================================================================
#  MrDemonc-SHELL: Acciones de Portapapeles en Wayland (Copiar, Cortar, Pegar)
# ==============================================================================
ACTION="${1:-copy}"

# Obtener clase de la ventana actualmente enfocada en Hyprland
ACTIVE_CLASS=$(hyprctl activewindow -j 2>/dev/null | grep -Po '"class":\s*"\K[^"]*' | tr '[:upper:]' '[:lower:]')

case "$ACTIVE_CLASS" in
    *kitty*|*alacritty*|*foot*|*terminal*|*wezterm*|*console*)
        IS_TERMINAL=true
        ;;
    *)
        IS_TERMINAL=false
        ;;
esac

# 1. Si wtype está instalado, usar virtual keyboard de Wayland
if command -v wtype >/dev/null 2>&1; then
    case "$ACTION" in
        copy)
            if [ "$IS_TERMINAL" = true ]; then
                wtype -M ctrl -M shift c -m shift -m ctrl
            else
                wtype -M ctrl c -m ctrl
            fi
            ;;
        cut)
            if [ "$IS_TERMINAL" = true ]; then
                wtype -M ctrl -M shift c -m shift -m ctrl
            else
                wtype -M ctrl x -m ctrl
            fi
            ;;
        paste)
            if [ "$IS_TERMINAL" = true ]; then
                wtype -M ctrl -M shift v -m shift -m ctrl
            else
                wtype -M ctrl v -m ctrl
            fi
            ;;
    esac
else
    # 2. Fallback nativo usando el dispatcher de Hyprland
    case "$ACTION" in
        copy)
            if [ "$IS_TERMINAL" = true ]; then
                hyprctl dispatch 'hl.dsp.send_shortcut({ mods = "CTRL + SHIFT", key = "c" })' >/dev/null 2>&1
            else
                hyprctl dispatch 'hl.dsp.send_shortcut({ mods = "CTRL", key = "c" })' >/dev/null 2>&1
            fi
            ;;
        cut)
            if [ "$IS_TERMINAL" = true ]; then
                hyprctl dispatch 'hl.dsp.send_shortcut({ mods = "CTRL + SHIFT", key = "c" })' >/dev/null 2>&1
            else
                hyprctl dispatch 'hl.dsp.send_shortcut({ mods = "CTRL", key = "x" })' >/dev/null 2>&1
            fi
            ;;
        paste)
            if [ "$IS_TERMINAL" = true ]; then
                hyprctl dispatch 'hl.dsp.send_shortcut({ mods = "CTRL + SHIFT", key = "v" })' >/dev/null 2>&1
            else
                hyprctl dispatch 'hl.dsp.send_shortcut({ mods = "CTRL", key = "v" })' >/dev/null 2>&1
            fi
            ;;
    esac
fi
