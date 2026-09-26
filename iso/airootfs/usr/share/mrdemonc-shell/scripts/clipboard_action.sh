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
                wtype -s 10 -m logo -M ctrl -M shift -k c -m shift -m ctrl
            else
                wtype -s 10 -m logo -M ctrl -k c -m ctrl
            fi
            ;;
        cut)
            if [ "$IS_TERMINAL" = true ]; then
                wtype -s 10 -m logo -M ctrl -M shift -k c -m shift -m ctrl
            else
                wtype -s 10 -m logo -M ctrl -k x -m ctrl
            fi
            ;;
        paste)
            if [ "$IS_TERMINAL" = true ]; then
                wtype -s 10 -m logo -M ctrl -M shift -k v -m shift -m ctrl
            else
                wtype -s 10 -m logo -M ctrl -k v -m ctrl
            fi
            ;;
    esac
else
    # 2. Fallback usando el dispatcher estándar sendshortcut de Hyprland
    case "$ACTION" in
        copy)
            if [ "$IS_TERMINAL" = true ]; then
                hyprctl dispatch sendshortcut "CTRL SHIFT, c, activewindow" >/dev/null 2>&1
            else
                hyprctl dispatch sendshortcut "CTRL, c, activewindow" >/dev/null 2>&1
            fi
            ;;
        cut)
            if [ "$IS_TERMINAL" = true ]; then
                hyprctl dispatch sendshortcut "CTRL SHIFT, c, activewindow" >/dev/null 2>&1
            else
                hyprctl dispatch sendshortcut "CTRL, x, activewindow" >/dev/null 2>&1
            fi
            ;;
        paste)
            if [ "$IS_TERMINAL" = true ]; then
                hyprctl dispatch sendshortcut "CTRL SHIFT, v, activewindow" >/dev/null 2>&1
            else
                hyprctl dispatch sendshortcut "CTRL, v, activewindow" >/dev/null 2>&1
            fi
            ;;
    esac
fi
