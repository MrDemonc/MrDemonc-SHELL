#!/usr/bin/env bash
# Gestor y controlador de Grabación de Pantalla para Quickshell / Hyprland

# Asegurar WAYLAND_DISPLAY si no está exportado en subshell
if [ -z "$WAYLAND_DISPLAY" ]; then
    for s in /run/user/$(id -u)/wayland-*; do
        if [ -S "$s" ]; then
            export WAYLAND_DISPLAY="$(basename "$s")"
            break
        fi
    done
fi

RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"
PID_FILE="${RUNTIME_DIR}/quickshell_recorder.pid"
FILE_STORE="${RUNTIME_DIR}/quickshell_recorder.file"
STATE_FILE="${RUNTIME_DIR}/quickshell_recorder.state"
AUDIO_PIDS="${RUNTIME_DIR}/quickshell_recorder_audio.pids"
TOGGLE_FILE="${RUNTIME_DIR}/quickshell_recorder.toggle"
LOG_FILE="${RUNTIME_DIR}/quickshell_recorder.log"

is_recording() {
    if [ -f "$PID_FILE" ]; then
        local pid
        pid=$(cat "$PID_FILE" 2>/dev/null)
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            return 0
        fi
    fi
    return 1
}

cleanup_audio() {
    if [ -f "$AUDIO_PIDS" ]; then
        local mix_mod l1 l2
        read -r mix_mod l1 l2 < "$AUDIO_PIDS" 2>/dev/null || true
        [ -n "$l1" ] && kill -9 "$l1" 2>/dev/null || true
        [ -n "$l2" ] && kill -9 "$l2" 2>/dev/null || true
        [ -n "$mix_mod" ] && pactl unload-module "$mix_mod" 2>/dev/null || true
        rm -f "$AUDIO_PIDS"
    fi
}

start_recording() {
    if is_recording; then
        echo "Ya se está grabando."
        return 0
    fi

    local mode="${1:-screen}"
    local sys_audio="${2:-0}"
    local mic_audio="${3:-0}"

    if ! command -v wf-recorder >/dev/null 2>&1; then
        echo "ERROR: wf-recorder no disponible" >&2
        return 1
    fi

    local base_videos
    if command -v xdg-user-dir >/dev/null 2>&1; then
        base_videos="$(xdg-user-dir VIDEOS 2>/dev/null)"
    fi
    if [ -z "$base_videos" ] || [ ! -d "$base_videos" ]; then
        if [ -d "$HOME/Vídeos" ]; then
            base_videos="$HOME/Vídeos"
        elif [ -d "$HOME/Videos" ]; then
            base_videos="$HOME/Videos"
        else
            base_videos="${XDG_VIDEOS_DIR:-$HOME/Vídeos}"
        fi
    fi
    local videos_dir="$base_videos/screenrecoder"
    mkdir -p "$videos_dir"

    local filename="Grabacion_$(date +'%Y-%m-%d_%H-%M-%S').mp4"
    local output_file="$videos_dir/$filename"

    local geom_args=()
    if [ "$mode" = "area" ]; then
        if ! command -v slurp >/dev/null 2>&1; then
            echo "ERROR: slurp no disponible" >&2
            return 1
        fi
        local geom
        geom=$(slurp -b "#00000055" -c "#ef4444" -w 2 2>/dev/null)
        if [ -z "$geom" ]; then
            echo "Selección cancelada por el usuario."
            return 0
        fi
        geom_args=("-g" "$geom")
    fi

    # Configuración de audio
    local audio_args=()
    cleanup_audio

    if [ "$sys_audio" = "1" ] && [ "$mic_audio" = "1" ]; then
        # Mezcla virtual PipeWire de audio del sistema + micrófono
        local default_sink default_source mix_module l1 l2
        default_sink=$(pactl get-default-sink 2>/dev/null)
        default_source=$(pactl get-default-source 2>/dev/null)

        if [ -n "$default_sink" ] && [ -n "$default_source" ] && command -v pw-loopback >/dev/null 2>&1; then
            mix_module=$(pactl load-module module-null-sink sink_name=rec_mix sink_properties=device.description=Recording_Mix 2>/dev/null)
            pw-loopback -m '[FL FR]' --capture="$default_sink.monitor" --playback="rec_mix" >/dev/null 2>&1 &
            l1=$!
            pw-loopback -m '[FL FR]' --capture="$default_source" --playback="rec_mix" >/dev/null 2>&1 &
            l2=$!
            echo "$mix_module $l1 $l2" > "$AUDIO_PIDS"
            sleep 0.2
            audio_args=("-a" "rec_mix.monitor")
        elif [ -n "$default_sink" ]; then
            audio_args=("-a" "$default_sink.monitor")
        fi
    elif [ "$sys_audio" = "1" ]; then
        local default_sink
        default_sink=$(pactl get-default-sink 2>/dev/null)
        if [ -n "$default_sink" ]; then
            audio_args=("-a" "$default_sink.monitor")
        fi
    elif [ "$mic_audio" = "1" ]; then
        local default_source
        default_source=$(pactl get-default-source 2>/dev/null)
        if [ -n "$default_source" ]; then
            audio_args=("-a" "$default_source")
        fi
    fi

    # Iniciar grabación en segundo plano con wf-recorder
    wf-recorder "${geom_args[@]}" "${audio_args[@]}" -f "$output_file" -c libx264 -p preset=veryfast -p crf=23 >"$LOG_FILE" 2>&1 &
    local rec_pid=$!

    echo "$rec_pid" > "$PID_FILE"
    echo "$output_file" > "$FILE_STORE"
    echo "START $output_file" > "$STATE_FILE"
    rm -f "${RUNTIME_DIR}/quickshell_recorder.stop"
    touch "${RUNTIME_DIR}/quickshell_recorder.start"

    echo "Grabando en $output_file (PID: $rec_pid)"
}

stop_recording() {
    rm -f "${RUNTIME_DIR}/quickshell_recorder.start"
    touch "${RUNTIME_DIR}/quickshell_recorder.stop"

    if ! is_recording; then
        echo "No hay ninguna grabación en curso."
        cleanup_audio
        rm -f "$PID_FILE"
        echo "STOP" > "$STATE_FILE"
        return 0
    fi

    local pid
    pid=$(cat "$PID_FILE" 2>/dev/null)
    local output_file
    output_file=$(cat "$FILE_STORE" 2>/dev/null)

    # Detener con SIGINT para que libx264 escriba los encabezados MP4 adecuadamente
    kill -INT "$pid" 2>/dev/null || true

    local count=0
    while kill -0 "$pid" 2>/dev/null && [ "$count" -lt 40 ]; do
        sleep 0.1
        count=$((count + 1))
    done

    if kill -0 "$pid" 2>/dev/null; then
        kill -TERM "$pid" 2>/dev/null || kill -9 "$pid" 2>/dev/null || true
    fi

    cleanup_audio
    rm -f "$PID_FILE" "$FILE_STORE"
    echo "STOP $output_file" > "$STATE_FILE"

    if [ -f "$output_file" ]; then
        notify-send "Grabación guardada" "Vídeo guardado con éxito:\n$output_file" -i "video-x-generic" -u normal -t 5000 2>/dev/null
    else
        notify-send "Grabación detenida" "La grabación ha finalizado." -i "media-record" -u low -t 3000 2>/dev/null
    fi
    echo "Grabación finalizada: $output_file"
}

case "$1" in
    start)
        start_recording "$2" "$3" "$4"
        ;;
    stop)
        stop_recording
        ;;
    toggle)
        if is_recording; then
            stop_recording
        else
            touch "$TOGGLE_FILE"
        fi
        ;;
    status)
        if is_recording; then
            echo "RECORDING"
        else
            echo "IDLE"
        fi
        ;;
    *)
        if is_recording; then
            stop_recording
        else
            touch "$TOGGLE_FILE"
        fi
        ;;
esac
