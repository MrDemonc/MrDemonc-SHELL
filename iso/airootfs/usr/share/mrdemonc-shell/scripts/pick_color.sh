#!/usr/bin/env bash
# Selector de color interactivo para Quickshell / Hyprland

RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"
DATA_FILE="${RUNTIME_DIR}/quickshell_colorpicker.data"

COLOR=""

# 1. Intentar con hyprpicker si está instalado
if command -v hyprpicker >/dev/null 2>&1; then
    COLOR=$(hyprpicker -f hex 2>/dev/null)
else
    # 2. Fallback sin dependencias adicionales usando grim + slurp + python
    if command -v grim >/dev/null 2>&1 && command -v slurp >/dev/null 2>&1; then
        POINT=$(slurp -p -b "#00000044" -c "#60a5fa" 2>/dev/null)
        if [ -n "$POINT" ]; then
            COLOR=$(grim -g "$POINT" -t ppm - 2>/dev/null | python3 -c '
import sys
data = sys.stdin.buffer.read()
if len(data) >= 3:
    p = data[-3:]
    print(f"#{p[0]:02x}{p[1]:02x}{p[2]:02x}")
' 2>/dev/null)
        fi
    fi
fi

# Si el usuario canceló (Esc) o no se seleccionó color
if [ -z "$COLOR" ]; then
    exit 0
fi

# Formatear a mayúsculas limpio
COLOR=$(echo "$COLOR" | tr '[:lower:]' '[:upper:]' | tr -d ' \r\n')

# Asegurar que empieza con '#'
if [[ "$COLOR" != \#* ]]; then
    COLOR="#$COLOR"
fi

# Copiar al portapapeles directamente
if command -v wl-copy >/dev/null 2>&1; then
    echo -n "$COLOR" | wl-copy
fi

# Notificar al backend de Quickshell
echo "$COLOR" > "$DATA_FILE"

