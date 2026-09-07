#!/usr/bin/env bash
SOCKET_PATH="${XDG_RUNTIME_DIR:-/tmp}/quickshell_theme_picker.fifo"

# Enviar comando a la shell mediante archivo de estado o toggle
STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/quickshell_theme_picker.toggle"

if [ -f "$STATE_FILE" ]; then
    rm -f "$STATE_FILE"
else
    touch "$STATE_FILE"
fi
