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

MODS="CTRL"
KEY="c"

case "$ACTION" in
    copy)
        if [ "$IS_TERMINAL" = true ]; then
            MODS="CTRL + SHIFT"
        fi
        KEY="c"
        ;;
    cut)
        if [ "$IS_TERMINAL" = true ]; then
            MODS="CTRL + SHIFT"
            KEY="c"
        else
            KEY="x"
        fi
        ;;
    paste)
        if [ "$IS_TERMINAL" = true ]; then
            MODS="CTRL + SHIFT"
        fi
        KEY="v"
        ;;
esac

# 1. Enviar atajo directamente a través del dispatcher de Hyprland Lua (instantáneo, confiable y nativo)
if hyprctl eval "hl.dispatch(hl.dsp.send_shortcut({ mods = \"$MODS\", key = \"$KEY\" }))" >/dev/null 2>&1; then
    exit 0
fi

# 2. Fallback con wtype si no se puede comunicar con Hyprland
if command -v wtype >/dev/null 2>&1; then
    if [ "$MODS" = "CTRL + SHIFT" ]; then
        wtype -M ctrl -M shift -k "$KEY" -m shift -m ctrl
    else
        wtype -M ctrl -k "$KEY" -m ctrl
    fi
fi

