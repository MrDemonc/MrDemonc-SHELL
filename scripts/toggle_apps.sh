#!/usr/bin/env bash
# Script para alternar o buscar aplicaciones con el launcher de Quickshell
TOGGLE_FILE="${XDG_RUNTIME_DIR:-/tmp}/quickshell_app_launcher.toggle"

if [ "$1" == "list" ]; then
    /home/demonc/Documents/Proyects/shell/scripts/app_launcher.py list
elif [ "$1" == "launch" ] && [ -n "$2" ]; then
    /home/demonc/Documents/Proyects/shell/scripts/app_launcher.py launch "$2" "$3"
else
    touch "$TOGGLE_FILE"
fi
