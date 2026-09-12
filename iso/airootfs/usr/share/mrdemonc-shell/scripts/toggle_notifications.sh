#!/usr/bin/env bash
# Script para alternar o controlar el panel de notificaciones de Quickshell (SUPER + N)
TOGGLE_FILE="${XDG_RUNTIME_DIR:-/tmp}/quickshell_notifications.toggle"

CMD="${1:-TOGGLE}"

if [ "$CMD" == "dnd" ] || [ "$CMD" == "mute" ] || [ "$CMD" == "silenciar" ]; then
    echo "DND" > "$TOGGLE_FILE"
elif [ "$CMD" == "clear" ] || [ "$CMD" == "limpiar" ]; then
    echo "CLEAR" > "$TOGGLE_FILE"
else
    echo "TOGGLE" > "$TOGGLE_FILE"
fi
