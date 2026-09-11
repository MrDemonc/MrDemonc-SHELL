#!/usr/bin/env bash
# ==============================================================================
# Herramienta de Captura de Pantalla para MrDemonc-SHELL
# ==============================================================================

MODE="${1:-picker}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Buscar si ya existe una instancia abierta del selector
EXISTING_PIDS=$(pgrep -f "[q]uickshell.*shell-screenshot" || true)

# Si se llama al selector interactivo y ya está abierto -> toggle (cerrar y salir)
if [ "$MODE" = "picker" ] || [ "$MODE" = "gui" ]; then
    if [ -n "$EXISTING_PIDS" ]; then
        kill -9 $EXISTING_PIDS 2>/dev/null || true
        exit 0
    fi
    SEARCH_DIRS=(
        "$SCRIPT_DIR/../viewers/shell-screenshot"
        "$HOME/Documentos/MrDemonc-SHELL/viewers/shell-screenshot"
        "/usr/share/mrdemonc-shell/viewers/shell-screenshot"
    )
    for d in "${SEARCH_DIRS[@]}"; do
        if [ -f "$d/shell.qml" ]; then
            exec quickshell -p "$d"
        fi
    done
    MODE="area"
fi

# Si se va a tomar una captura directa y el selector está visible, cerrarlo primero
if [ -n "$EXISTING_PIDS" ]; then
    kill -9 $EXISTING_PIDS 2>/dev/null || true
    sleep 0.1
fi

# Directorio de guardado: carpeta Screenshots en la carpeta de Imágenes
PICTURES_DIR="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Imágenes")"
[ ! -d "$PICTURES_DIR" ] && PICTURES_DIR="$HOME/Pictures"
SCREENSHOT_DIR="$PICTURES_DIR/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

# Mantener sincronizada la carpeta en ~/Pictures/Screenshots si corresponde
if [ "$PICTURES_DIR" = "$HOME/Imágenes" ] && [ -d "$HOME/Pictures" ] && [ ! -e "$HOME/Pictures/Screenshots" ]; then
    ln -sf "$SCREENSHOT_DIR" "$HOME/Pictures/Screenshots" 2>/dev/null || true
fi

# Nombre de archivo con fecha y hora
TIMESTAMP=$(date +'%Y-%m-%d_%H-%M-%S')
FILENAME="Screenshot_${TIMESTAMP}.png"
FILEPATH="$SCREENSHOT_DIR/$FILENAME"

# Pausa breve para que cualquier menú u overlay se desvanezca antes de capturar
sleep 0.15

case "$MODE" in
    full|fullscreen)
        grim "$FILEPATH"
        ;;
    area|selection)
        GEOM=$(slurp -b "#1a1d24aa" -c "#88c0d0" -s "#88c0d022" -w 2 2>/dev/null)
        if [ -z "$GEOM" ]; then
            exit 0
        fi
        grim -g "$GEOM" "$FILEPATH"
        ;;
    *)
        grim "$FILEPATH"
        ;;
esac

if [ -f "$FILEPATH" ]; then
    # Copiar al portapapeles del sistema como imagen PNG
    wl-copy --type image/png < "$FILEPATH" 2>/dev/null || true
    # Notificación de escritorio con miniatura
    notify-send -a "Captura de Pantalla" -i "$FILEPATH" "Captura guardada" "Guardada en Screenshots/$FILENAME\nCopiada al portapapeles." -t 4000 2>/dev/null || true
fi
