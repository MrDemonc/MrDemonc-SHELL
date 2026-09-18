#!/usr/bin/env bash
STATE="${XDG_RUNTIME_DIR:-/tmp}/quickshell_control_center.toggle"
if [ -n "$1" ]; then
    echo "TAB:$1" > "$STATE"
    echo "TAB:$1" > "/tmp/quickshell_control_center.toggle" 2>/dev/null || true
else
    echo "TOGGLE" > "$STATE"
    echo "TOGGLE" > "/tmp/quickshell_control_center.toggle" 2>/dev/null || true
fi
