#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ $# -gt 0 ]; then
    exec python3 "$SCRIPT_DIR/monitor_manager.py" "$@"
fi

STATE="${XDG_RUNTIME_DIR:-/tmp}/quickshell_monitors.toggle"
touch "$STATE"

