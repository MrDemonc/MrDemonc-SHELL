#!/usr/bin/env bash
TARGET="${1:-audio}"
STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/quickshell_popout.toggle"
echo "$TARGET" > "$STATE_FILE"
