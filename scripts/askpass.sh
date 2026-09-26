#!/usr/bin/env bash
# Helper de autenticación gráfica (SUDO_ASKPASS) para MrDemonc-SHELL

if command -v zenity >/dev/null 2>&1; then
    zenity --password --title="MrDemonc-SHELL: Autenticación" 2>/dev/null
elif command -v systemd-ask-password >/dev/null 2>&1; then
    systemd-ask-password "MrDemonc-SHELL: Contraseña sudo:"
elif [ -n "$SSH_ASKPASS" ] && command -v "$SSH_ASKPASS" >/dev/null 2>&1; then
    "$SSH_ASKPASS" "Contraseña:"
fi
