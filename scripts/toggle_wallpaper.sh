#!/usr/bin/env bash
# Script para abrir o alternar el selector de wallpapers de Quickshell
TOGGLE_FILE="${XDG_RUNTIME_DIR:-/tmp}/quickshell_wallpaper_picker.toggle"

if [ "$1" == "list" ]; then
    /home/demonc/Documents/Proyects/shell/scripts/wallpaper_manager.py list
elif [ "$1" == "get" ]; then
    /home/demonc/Documents/Proyects/shell/scripts/wallpaper_manager.py get
elif [ "$1" == "set" ] && [ -n "$2" ]; then
    /home/demonc/Documents/Proyects/shell/scripts/wallpaper_manager.py set "$2"
elif [ "$1" == "folder" ] || [ "$1" == "open" ]; then
    /home/demonc/Documents/Proyects/shell/scripts/wallpaper_manager.py open_dir
else
    touch "$TOGGLE_FILE"
fi
