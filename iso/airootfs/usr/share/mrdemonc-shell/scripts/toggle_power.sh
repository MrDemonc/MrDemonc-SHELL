#!/usr/bin/env bash
# Entrega única; el botón físico usa OPEN, los atajos usan TOGGLE.
RUNTIME_DIR="${XDG_RUNTIME_DIR:?Se requiere una sesión de usuario}"
STATE="$RUNTIME_DIR/quickshell_power.toggle"
FIFO="$RUNTIME_DIR/quickshell_power.fifo"
case "${1:-toggle}" in
    open) MESSAGE=OPEN ;;
    toggle) MESSAGE=TOGGLE ;;
    *) exit 2 ;;
esac
if [ -p "$FIFO" ] && timeout 0.3 bash -c 'printf "%s\n" "$1" > "$2"' _ "$MESSAGE" "$FIFO"; then
    exit 0
fi
printf '%s\n' "$MESSAGE" > "$STATE"
