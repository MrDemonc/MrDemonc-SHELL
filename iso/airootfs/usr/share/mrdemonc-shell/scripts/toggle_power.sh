#!/usr/bin/env bash
# Alterna la visibilidad del menú de apagado/energía de Quickshell (SUPER + ESC / Botón Power)
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"
STATE="${RUNTIME_DIR}/quickshell_power.toggle"
FIFO="${RUNTIME_DIR}/quickshell_power.fifo"

touch "$STATE"
if [ -p "$FIFO" ]; then
    timeout 0.3 bash -c "echo 'TOGGLE' > '$FIFO'" 2>/dev/null || true
fi
