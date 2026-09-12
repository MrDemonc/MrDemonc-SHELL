#!/usr/bin/env bash
# ==============================================================================
#  MrDemonc-SHELL: Controlador de Volumen y Brillo con OSD estilo macOS
# ==============================================================================

ACTION="${1:-help}"
VALUE="${2:-5%}"

FIFO_PATH="${XDG_RUNTIME_DIR:-/tmp}/quickshell_osd.fifo"
STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/quickshell_virtual_brightness"

# --- Funciones de Audio ---
get_volume() {
    local vol=50 muted="false"
    if command -v wpctl >/dev/null 2>&1; then
        local raw
        raw=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || true)
        if [[ -n "$raw" ]]; then
            if [[ "$raw" =~ \[MUTED\] ]]; then
                muted="true"
            fi
            local v
            v=$(echo "$raw" | grep -Po '[0-9]+\.[0-9]+' | head -n 1)
            if [ -n "$v" ]; then
                vol=$(awk -v v="$v" 'BEGIN { printf "%d", (v * 100) + 0.5 }')
            fi
        fi
    elif command -v pactl >/dev/null 2>&1; then
        local pvol
        pvol=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -Po '\d+%' | head -n 1 | tr -d '%')
        [ -n "$pvol" ] && vol=$pvol
        if pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | grep -q "yes"; then
            muted="true"
        fi
    fi
    [ "$vol" -gt 150 ] && vol=150
    echo "$vol:$muted"
}

get_mic() {
    local vol=100 muted="false"
    if command -v wpctl >/dev/null 2>&1; then
        local raw
        raw=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null || true)
        if [[ -n "$raw" ]]; then
            if [[ "$raw" =~ \[MUTED\] ]]; then
                muted="true"
            fi
            local v
            v=$(echo "$raw" | grep -Po '[0-9]+\.[0-9]+' | head -n 1)
            if [ -n "$v" ]; then
                vol=$(awk -v v="$v" 'BEGIN { printf "%d", (v * 100) + 0.5 }')
            fi
        fi
    elif command -v pactl >/dev/null 2>&1; then
        if pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null | grep -q "yes"; then
            muted="true"
        fi
    fi
    echo "$vol:$muted"
}

# --- Funciones de Brillo de Laptop / Pantalla ---
get_brightness() {
    local b=""
    if command -v brightnessctl >/dev/null 2>&1; then
        # 1. Intentar backlight primero (pantallas integradas de laptop)
        b=$(brightnessctl -c backlight -m 2>/dev/null | head -n 1 | cut -d',' -f4 | tr -d '%')
    fi

    # 2. Fallback virtual si no hay control de hardware de backlight (ej: VM o monitor de sobremesa)
    if [ -z "$b" ]; then
        if [ -f "$STATE_FILE" ]; then
            b=$(cat "$STATE_FILE" 2>/dev/null)
        fi
        [ -z "$b" ] && b=75
    fi
    echo "$b"
}

send_osd() {
    local payload="$1"
    # Escribir en FIFO de Quickshell sin bloquear si no hay lector activo
    if [ -p "$FIFO_PATH" ]; then
        python3 -c "
import os, sys
fifo = sys.argv[1]
msg = sys.argv[2] + '\n'
try:
    fd = os.open(fifo, os.O_WRONLY | os.O_NONBLOCK)
    os.write(fd, msg.encode('utf-8'))
    os.close(fd)
except Exception:
    pass
" "$FIFO_PATH" "$payload" 2>/dev/null || true
    fi

    # Guardar último estado para sincronización
    local state_log="${XDG_RUNTIME_DIR:-/tmp}/quickshell_osd.last"
    echo "$payload" > "$state_log" 2>/dev/null || true
}

case "$ACTION" in
    volume-up|vol-up|volume-raise)
        STEP="${2:-5%}"
        if command -v wpctl >/dev/null 2>&1; then
            wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ "$STEP+"
        elif command -v pactl >/dev/null 2>&1; then
            pactl set-sink-volume @DEFAULT_SINK@ "+$STEP"
        fi
        IFS=':' read -r v m <<< "$(get_volume)"
        send_osd "{\"type\":\"volume\",\"value\":$v,\"muted\":$m}"
        echo "Volumen: $v% (Mute: $m)"
        ;;

    volume-down|vol-down|volume-lower)
        STEP="${2:-5%}"
        if command -v wpctl >/dev/null 2>&1; then
            wpctl set-volume @DEFAULT_AUDIO_SINK@ "$STEP-"
        elif command -v pactl >/dev/null 2>&1; then
            pactl set-sink-volume @DEFAULT_SINK@ "-$STEP"
        fi
        IFS=':' read -r v m <<< "$(get_volume)"
        send_osd "{\"type\":\"volume\",\"value\":$v,\"muted\":$m}"
        echo "Volumen: $v% (Mute: $m)"
        ;;

    volume-mute|vol-mute|mute)
        if command -v wpctl >/dev/null 2>&1; then
            wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        elif command -v pactl >/dev/null 2>&1; then
            pactl set-sink-mute @DEFAULT_SINK@ toggle
        fi
        IFS=':' read -r v m <<< "$(get_volume)"
        send_osd "{\"type\":\"volume\",\"value\":$v,\"muted\":$m}"
        echo "Volumen: $v% (Mute: $m)"
        ;;

    volume-set)
        TARGET="${2:-50}"
        TARGET="${TARGET//%/}"
        if command -v wpctl >/dev/null 2>&1; then
            local dec
            dec=$(awk -v t="$TARGET" 'BEGIN { printf "%.2f", t / 100.0 }')
            wpctl set-volume @DEFAULT_AUDIO_SINK@ "$dec"
        elif command -v pactl >/dev/null 2>&1; then
            pactl set-sink-volume @DEFAULT_SINK@ "${TARGET}%"
        fi
        IFS=':' read -r v m <<< "$(get_volume)"
        send_osd "{\"type\":\"volume\",\"value\":$v,\"muted\":$m}"
        echo "Volumen: $v% (Mute: $m)"
        ;;

    mic-mute)
        if command -v wpctl >/dev/null 2>&1; then
            wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
        elif command -v pactl >/dev/null 2>&1; then
            pactl set-source-mute @DEFAULT_SOURCE@ toggle
        fi
        IFS=':' read -r v m <<< "$(get_mic)"
        send_osd "{\"type\":\"mic\",\"value\":$v,\"muted\":$m}"
        echo "Micrófono: $v% (Mute: $m)"
        ;;

    brightness-up|bright-up)
        STEP="${2:-5%}"
        CHANGED=false
        if command -v brightnessctl >/dev/null 2>&1; then
            if brightnessctl -c backlight set "$STEP+" >/dev/null 2>&1; then
                CHANGED=true
            fi
        fi
        if [ "$CHANGED" = false ]; then
            cur=$(get_brightness)
            cur=$((cur + 5))
            [ "$cur" -gt 100 ] && cur=100
            echo "$cur" > "$STATE_FILE"
        fi
        b=$(get_brightness)
        send_osd "{\"type\":\"brightness\",\"value\":$b,\"muted\":false}"
        echo "Brillo: $b%"
        ;;

    brightness-down|bright-down)
        STEP="${2:-5%}"
        CHANGED=false
        if command -v brightnessctl >/dev/null 2>&1; then
            # -n2 asegura que no baje de 2% para evitar dejar la pantalla en negro absoluto
            if brightnessctl -c backlight -n2 set "$STEP-" >/dev/null 2>&1; then
                CHANGED=true
            fi
        fi
        if [ "$CHANGED" = false ]; then
            cur=$(get_brightness)
            cur=$((cur - 5))
            [ "$cur" -lt 5 ] && cur=5
            echo "$cur" > "$STATE_FILE"
        fi
        b=$(get_brightness)
        send_osd "{\"type\":\"brightness\",\"value\":$b,\"muted\":false}"
        echo "Brillo: $b%"
        ;;

    brightness-set)
        TARGET="${2:-70}"
        TARGET="${TARGET//%/}"
        CHANGED=false
        if command -v brightnessctl >/dev/null 2>&1; then
            if brightnessctl -c backlight set "${TARGET}%" >/dev/null 2>&1; then
                CHANGED=true
            fi
        fi
        if [ "$CHANGED" = false ]; then
            [ "$TARGET" -lt 2 ] && TARGET=2
            [ "$TARGET" -gt 100 ] && TARGET=100
            echo "$TARGET" > "$STATE_FILE"
        fi
        b=$(get_brightness)
        send_osd "{\"type\":\"brightness\",\"value\":$b,\"muted\":false}"
        echo "Brillo: $b%"
        ;;

    get-volume)
        get_volume
        ;;

    get-brightness)
        get_brightness
        ;;

    *)
        echo "Uso: $0 [volume-up|volume-down|volume-mute|volume-set <N>|mic-mute|brightness-up|brightness-down|brightness-set <N>|get-volume|get-brightness]"
        exit 1
        ;;
esac
