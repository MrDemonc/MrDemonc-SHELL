#!/usr/bin/env bash
STATE="${XDG_RUNTIME_DIR:-/tmp}/quickshell_control_center.toggle"
TMP_STATE="/tmp/quickshell_control_center.toggle"

if [ -n "$1" ]; then
    CMD="TAB:$1"
else
    CMD="TOGGLE"
fi

# Intentar escribir en STATE; si falla, escribir en TMP_STATE (nunca en ambos a la vez)
echo "$CMD" > "$STATE" 2>/dev/null || echo "$CMD" > "$TMP_STATE" 2>/dev/null || true

