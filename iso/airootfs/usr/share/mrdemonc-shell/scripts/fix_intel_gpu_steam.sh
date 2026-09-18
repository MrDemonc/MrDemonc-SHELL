#!/usr/bin/env bash
# ==============================================================================
#  MrDemonc-SHELL: Corrección de Controladores Gráficos y Vulkan para Intel & Steam
#  Reemplaza paquetes residuales de NVIDIA por los controladores nativos de Intel
# ==============================================================================

REAL_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$REAL_PATH")" && pwd)"

# 1. Obtener colores del tema activo
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
RESET="\033[0m"

clear
echo ""
echo -e "${COLOR_PRIMARY}  ╭──────────────────────────────────────────────────────────────────────────╮${RESET}"
echo -e "${COLOR_PRIMARY}  │${RESET}  ${BOLD}󰓓  CONFIGURACIÓN DE CONTROLADORES GRÁFICOS INTEL & STEAM${RESET}             ${COLOR_PRIMARY}│${RESET}"
echo -e "${COLOR_PRIMARY}  │${RESET}     ${COLOR_MUTED}Vulkan 32/64-bit · Mesa OpenGL · Aceleración Intel VA-API${RESET}           ${COLOR_PRIMARY}│${RESET}"
echo -e "${COLOR_PRIMARY}  ╰──────────────────────────────────────────────────────────────────────────╯${RESET}"
echo ""

# 2. Detección de hardware gráfico
DETECTED_GPU=$(lspci -d ::0300; lspci -d ::0302; lspci -d ::0380) 2>/dev/null || true
if [ -z "$DETECTED_GPU" ]; then
    DETECTED_GPU=$(lspci 2>/dev/null | grep -iE 'vga|3d|display' || true)
fi

echo -e "  ${COLOR_CYAN}󰢮${RESET} ${COLOR_TEXT}GPU detectada en tu equipo:${RESET}"
echo -e "     ${COLOR_PRIMARY}${BOLD}${DETECTED_GPU}${RESET}"
echo ""

# Verificar si hay librerías de NVIDIA instaladas incorrectamente
NVIDIA_PKGS=$(pacman -Q lib32-nvidia-utils nvidia-utils 2>/dev/null || true)
if [ -n "$NVIDIA_PKGS" ]; then
    echo -e "  ${COLOR_WARNING}󰀦  Se detectaron paquetes de NVIDIA instalados como dependencia de Steam:${RESET}"
    echo "$NVIDIA_PKGS" | while read -r p; do
        echo -e "     ${COLOR_MUTED}•${RESET} ${COLOR_DANGER}$p${RESET}"
    done
    echo ""
fi

# 3. Solicitar confirmación o ejecutar si se pasa --noconfirm
if [ "$1" != "--noconfirm" ] && [ "$1" != "-y" ]; then
    echo -e "  ${COLOR_PRIMARY}──────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${BOLD}${COLOR_TEXT}¿Deseas instalar los controladores Intel (32 y 64 bits) y remover los de NVIDIA?${RESET}"
    echo -e "  Presiona ${COLOR_SUCCESS}${BOLD}[S]${RESET} o ${COLOR_SUCCESS}${BOLD}[Y]${RESET} para continuar, o ${COLOR_DANGER}${BOLD}[N]${RESET} para cancelar:"
    echo -n "  > "
    read -r -n 1 -s RESPONSE
    echo ""
    case "$RESPONSE" in
        s|S|y|Y|"")
            ;;
        *)
            echo -e "  ${COLOR_DANGER}Operación cancelada por el usuario.${RESET}"
            exit 0
            ;;
    esac
fi

echo ""
echo -e "  ${COLOR_SUCCESS}󰄬 Procediendo con la configuración...${RESET}"
echo ""

# Solicitar permisos de administrador si no somos root
if [ "$EUID" -ne 0 ]; then
    if ! sudo -v; then
        echo -e "  ${COLOR_DANGER}✖ Error: Autenticación requerida para gestionar paquetes del sistema.${RESET}"
        exit 1
    fi
    SUDO_CMD="sudo"
    # Mantener token sudo vivo
    while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done 2>/dev/null &
    KEEP_SUDO_PID=$!
    trap 'kill $KEEP_SUDO_PID 2>/dev/null' EXIT
else
    SUDO_CMD=""
fi

echo -e "  ${COLOR_PRIMARY}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
echo -e "  ${COLOR_PRIMARY}║${RESET} ${BOLD}1/3. Instalando controladores nativos Vulkan y OpenGL para Intel...${RESET}     ${COLOR_PRIMARY}║${RESET}"
echo -e "  ${COLOR_PRIMARY}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
echo ""

$SUDO_CMD pacman -Sy --noconfirm --needed \
    vulkan-intel \
    lib32-vulkan-intel \
    intel-media-driver \
    mesa \
    lib32-mesa \
    vulkan-icd-loader \
    lib32-vulkan-icd-loader

echo ""
echo -e "  ${COLOR_PRIMARY}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
echo -e "  ${COLOR_PRIMARY}║${RESET} ${BOLD}2/3. Removiendo librerías de NVIDIA no requeridas...${RESET}                    ${COLOR_PRIMARY}║${RESET}"
echo -e "  ${COLOR_PRIMARY}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
echo ""

$SUDO_CMD pacman -Rdd --noconfirm lib32-nvidia-utils nvidia-utils 2>/dev/null || true
$SUDO_CMD pacman -Rns --noconfirm egl-wayland egl-gbm egl-wayland2 egl-x11 2>/dev/null || true

echo ""
echo -e "  ${COLOR_PRIMARY}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
echo -e "  ${COLOR_PRIMARY}║${RESET} ${BOLD}3/3. Verificando controladores Vulkan activos en el sistema...${RESET}          ${COLOR_PRIMARY}║${RESET}"
echo -e "  ${COLOR_PRIMARY}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
echo ""

ICD_DIR="/usr/share/vulkan/icd.d"
if [ -d "$ICD_DIR" ]; then
    echo -e "  ${COLOR_CYAN}Archivos ICD registrados:${RESET}"
    ls -l "$ICD_DIR" | tail -n +2 | while read -r line; do
        echo -e "     ${COLOR_SUCCESS}󰄬${RESET} ${COLOR_TEXT}$line${RESET}"
    done
else
    echo -e "  ${COLOR_WARNING}Aviso: No se encontró el directorio $ICD_DIR${RESET}"
fi

echo ""
echo -e "  ${COLOR_SUCCESS}╭──────────────────────────────────────────────────────────────────────────╮${RESET}"
echo -e "  ${COLOR_SUCCESS}│${RESET}  ${BOLD}󰄬  Controladores de Intel y Steam configurados exitosamente${RESET}             ${COLOR_SUCCESS}│${RESET}"
echo -e "  ${COLOR_SUCCESS}│${RESET}     ${COLOR_MUTED}Steam ahora utilizará vulkan-intel (ANV) a 32 y 64 bits.${RESET}            ${COLOR_SUCCESS}│${RESET}"
echo -e "  ${COLOR_SUCCESS}╰──────────────────────────────────────────────────────────────────────────╯${RESET}"
echo ""
