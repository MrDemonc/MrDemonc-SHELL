#!/usr/bin/env bash
# ==============================================================================
#  MrDemonc-SHELL: Script de Actualización Automática del Sistema
#  Sincronizado dinámicamente con los colores y estilo del tema activo
# ==============================================================================

REAL_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$REAL_PATH")" && pwd)"

# 1. Obtener colores del tema activo desde theme_manager.py
eval "$(python3 -c "
import json, subprocess, os
try:
    tm = os.path.join('${SCRIPT_DIR}', 'theme_manager.py')
    if not os.path.isfile(tm):
        tm = '/usr/share/mrdemonc-shell/scripts/theme_manager.py'
    data = json.loads(subprocess.check_output(['python3', tm]).decode())
    def to_rgb(hex_code):
        h = hex_code.lstrip('#')
        return f'{int(h[0:2], 16)};{int(h[2:4], 16)};{int(h[4:6], 16)}'
    print(f'THEME_NAME=\"{data.get(\"name\", \"Default\")}\"')
    print(f'COLOR_PRIMARY=\"\\033[38;2;{to_rgb(data.get(\"primary\", \"#88c0d0\"))}m\"')
    print(f'COLOR_CYAN=\"\\033[38;2;{to_rgb(data.get(\"cyan\", \"#81a1c1\"))}m\"')
    print(f'COLOR_TEXT=\"\\033[38;2;{to_rgb(data.get(\"text\", \"#eceff4\"))}m\"')
    print(f'COLOR_SUBTEXT=\"\\033[38;2;{to_rgb(data.get(\"subtext\", \"#d8dee9\"))}m\"')
    print(f'COLOR_SUCCESS=\"\\033[38;2;{to_rgb(data.get(\"success\", \"#a3be8c\"))}m\"')
    print(f'COLOR_WARNING=\"\\033[38;2;{to_rgb(data.get(\"warning\", \"#ebcb8b\"))}m\"')
    print(f'COLOR_DANGER=\"\\033[38;2;{to_rgb(data.get(\"danger\", \"#bf616a\"))}m\"')
    print(f'COLOR_MUTED=\"\\033[38;2;{to_rgb(data.get(\"overlay\", \"#7b889b\"))}m\"')
except Exception:
    print('THEME_NAME=\"Default\"')
    print('COLOR_PRIMARY=\"\\033[1;36m\"')
    print('COLOR_CYAN=\"\\033[36m\"')
    print('COLOR_TEXT=\"\\033[37m\"')
    print('COLOR_SUBTEXT=\"\\033[90m\"')
    print('COLOR_SUCCESS=\"\\033[1;32m\"')
    print('COLOR_WARNING=\"\\033[1;33m\"')
    print('COLOR_DANGER=\"\\033[1;31m\"')
    print('COLOR_MUTED=\"\\033[90m\"')
")"

BOLD="\033[1m"
DIM="\033[2m"
RESET="\033[0m"

clear
echo ""
echo -e "${COLOR_PRIMARY}  ╭──────────────────────────────────────────────────────────────────────────╮${RESET}"
echo -e "${COLOR_PRIMARY}  │${RESET}  ${BOLD}󰚰  ACTUALIZACIÓN AUTOMÁTICA DEL SISTEMA${RESET} · ${COLOR_CYAN}MrDemonc-SHELL${RESET}               ${COLOR_PRIMARY}│${RESET}"
echo -e "${COLOR_PRIMARY}  │${RESET}     ${COLOR_MUTED}Arch Linux · Pacman, AUR (yay) & Flatpak${RESET}                           ${COLOR_PRIMARY}│${RESET}"
echo -e "${COLOR_PRIMARY}  │${RESET}     ${COLOR_SUBTEXT}Tema activo:${RESET} ${COLOR_PRIMARY}${THEME_NAME}${RESET}                                               ${COLOR_PRIMARY}│${RESET}"
echo -e "${COLOR_PRIMARY}  ╰──────────────────────────────────────────────────────────────────────────╯${RESET}"
echo ""

# 2. Comprobar paquetes pendientes de actualizar
echo -e "  ${COLOR_CYAN}󰇚${RESET} ${COLOR_TEXT}Comprobando paquetes desactualizados en los repositorios...${RESET}"

PACMAN_UPDATES=0
if command -v checkupdates >/dev/null 2>&1; then
    PACMAN_UPDATES=$(checkupdates 2>/dev/null | wc -l)
fi

YAY_UPDATES=0
if command -v yay >/dev/null 2>&1; then
    YAY_UPDATES=$(yay -Qua 2>/dev/null | wc -l)
fi

TOTAL_UPDATES=$((PACMAN_UPDATES + YAY_UPDATES))

echo ""
if [ "$TOTAL_UPDATES" -gt 0 ]; then
    echo -e "  ${COLOR_WARNING}󰏔  Se encontraron ${BOLD}${TOTAL_UPDATES}${RESET}${COLOR_WARNING} actualizaciones disponibles:${RESET}"
    echo -e "     ${COLOR_MUTED}•${RESET} ${COLOR_TEXT}Repositorios oficiales (Pacman):${RESET} ${COLOR_PRIMARY}${PACMAN_UPDATES}${RESET} paquetes"
    if command -v yay >/dev/null 2>&1; then
        echo -e "     ${COLOR_MUTED}•${RESET} ${COLOR_TEXT}Repositorio de usuarios (AUR/yay):${RESET} ${COLOR_CYAN}${YAY_UPDATES}${RESET} paquetes"
    fi
else
    echo -e "  ${COLOR_SUCCESS}󰄬  El sistema se encuentra al día${RESET} ${COLOR_MUTED}(puedes sincronizar para forzar comprobación).${RESET}"
fi
echo ""

# 3. Preguntar al usuario confirmación interactiva
echo -e "  ${COLOR_PRIMARY}──────────────────────────────────────────────────────────────────────────${RESET}"
echo -e "  ${BOLD}${COLOR_TEXT}¿Deseas proceder con la actualización del sistema?${RESET}"
echo -e "  Presiona ${COLOR_SUCCESS}${BOLD}[S]${RESET} o ${COLOR_SUCCESS}${BOLD}[Y]${RESET} para continuar, o ${COLOR_DANGER}${BOLD}[N]${RESET} para cancelar:"
echo -n "  > "

read -r -n 1 -s RESPONSE
echo ""

case "$RESPONSE" in
    s|S|y|Y|"")
        echo ""
        echo -e "  ${COLOR_SUCCESS}󰄬 Confirmado.${RESET} ${COLOR_TEXT}Solicitando permisos de administrador...${RESET}"
        echo ""
        
        # Validar contraseña sudo con feedback
        if ! sudo -v; then
            echo -e "  ${COLOR_DANGER}✖ Error: Autenticación fallida o cancelada.${RESET}"
            sleep 2
            exit 1
        fi
        
        # Mantener credenciales vivas durante la descarga
        while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done 2>/dev/null &
        SUDO_PID=$!
        trap 'kill $SUDO_PID 2>/dev/null' EXIT

        echo ""
        echo -e "  ${COLOR_PRIMARY}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
        echo -e "  ${COLOR_PRIMARY}║${RESET} ${BOLD}1/3. Actualizando repositorios oficiales con Pacman...${RESET}                 ${COLOR_PRIMARY}║${RESET}"
        echo -e "  ${COLOR_PRIMARY}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
        echo ""
        sudo pacman -Syu --noconfirm || {
            echo -e "  ${COLOR_WARNING}Aviso: Pacman terminó con código no cero o fue interrumpido.${RESET}"
        }

        # Actualizar AUR si yay está disponible
        if command -v yay >/dev/null 2>&1; then
            echo ""
            echo -e "  ${COLOR_CYAN}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
            echo -e "  ${COLOR_CYAN}║${RESET} ${BOLD}2/3. Actualizando paquetes de AUR con Yay...${RESET}                           ${COLOR_CYAN}║${RESET}"
            echo -e "  ${COLOR_CYAN}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
            echo ""
            yay -Sua --noconfirm || {
                echo -e "  ${COLOR_WARNING}Aviso: Yay finalizó con avisos o sin cambios pendientes.${RESET}"
            }
        else
            echo ""
            echo -e "  ${COLOR_MUTED}[2/3] Yay no está instalado en el sistema. Omitiendo AUR.${RESET}"
        fi

        # Actualizar Flatpaks si está disponible
        if command -v flatpak >/dev/null 2>&1; then
            echo ""
            echo -e "  ${COLOR_PRIMARY}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
            echo -e "  ${COLOR_PRIMARY}║${RESET} ${BOLD}3/3. Comprobando actualizaciones de Flatpak...${RESET}                         ${COLOR_PRIMARY}║${RESET}"
            echo -e "  ${COLOR_PRIMARY}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
            echo ""
            flatpak update -y 2>/dev/null || true
        fi

        echo ""
        echo -e "  ${COLOR_PRIMARY}──────────────────────────────────────────────────────────────────────────${RESET}"
        echo -e "  ${COLOR_SUCCESS}${BOLD}✔ ¡Actualización del sistema completada con éxito!${RESET}"
        echo ""

        # Notificación de escritorio
        if command -v notify-send >/dev/null 2>&1; then
            notify-send -a "Actualización del Sistema" "Sistema Actualizado" "Todos los paquetes de pacman y yay se actualizaron con éxito." -i system-software-update 2>/dev/null || true
        fi

        echo -e "  ${COLOR_SUBTEXT}Presiona cualquier tecla para cerrar esta ventana...${RESET}"
        read -r -n 1 -s
        exit 0
        ;;
    n|N|q|Q|$'\e')
        echo ""
        echo -e "  ${COLOR_DANGER}✖ Actualización cancelada por el usuario.${RESET}"
        echo ""
        sleep 0.8
        exit 0
        ;;
    *)
        echo ""
        echo -e "  ${COLOR_MUTED}Opción no reconocida. Cancelando.${RESET}"
        sleep 0.8
        exit 0
        ;;
esac
