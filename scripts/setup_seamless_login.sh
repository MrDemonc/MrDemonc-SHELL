#!/usr/bin/env bash
# ==============================================================================
#  MrDemonc-SHELL: Configuración de Seamless Login (Estilo Omarchy) y Lock Screen
# ==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

CURRENT_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$CURRENT_USER")

echo -e "${CYAN}${BOLD}"
echo "=================================================================="
echo "    MrDemonc-SHELL: SEAMLESS LOGIN & HYPRLOCK LOCKSCREEN SETUP   "
echo "=================================================================="
echo -e "${NC}"
echo -e "${BLUE}[INFO]${NC} Configurando para el usuario: ${BOLD}$CURRENT_USER${NC}"
echo ""

# 1. Asegurar que hyprlock y hypridle estén instalados
echo -e "${YELLOW}[1/5] Verificando e instalando hyprlock y hypridle...${NC}"
if ! command -v hyprlock >/dev/null 2>&1 || ! command -v hypridle >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm hyprlock hypridle
    echo -e "${GREEN}[OK] hyprlock y hypridle instalados.${NC}"
else
    echo -e "${GREEN}[OK] hyprlock y hypridle ya están instalados.${NC}"
fi

# 2. Desplegar configuraciones de hyprlock y hypridle
echo -e "${YELLOW}[2/5] Desplegando archivos de configuración de Hyprlock y Hypridle...${NC}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$USER_HOME/.config/hypr"
cp -f "$REPO_DIR/hypr/hyprlock.conf" "$USER_HOME/.config/hypr/hyprlock.conf"
cp -f "$REPO_DIR/hypr/hypridle.conf" "$USER_HOME/.config/hypr/hypridle.conf"
cp -f "$REPO_DIR/hypr/hyprlock_colors.conf" "$USER_HOME/.config/hypr/hyprlock_colors.conf" 2>/dev/null || true
chown -R "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/.config/hypr"
echo -e "${GREEN}[OK] Configuraciones desplegadas en $USER_HOME/.config/hypr/${NC}"

# 3. Configurar Autologin en tty1 con systemd (Seamless Login estilo Omarchy)
echo -e "${YELLOW}[3/5] Configurando Autologin en tty1 (systemd agetty drop-in)...${NC}"
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf > /dev/null << AUTOLOGIN
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $CURRENT_USER --noclear %I \$TERM
Type=idle
AUTOLOGIN
echo -e "${GREEN}[OK] /etc/systemd/system/getty@tty1.service.d/autologin.conf creado.${NC}"

# 4. Configurar autoarranque de Hyprland en ~/.bash_profile
echo -e "${YELLOW}[4/5] Verificando autoarranque de Hyprland en ~/.bash_profile...${NC}"
BASH_PROFILE="$USER_HOME/.bash_profile"
if ! grep -q 'exec Hyprland' "$BASH_PROFILE" 2>/dev/null; then
    cat << 'HOOK' >> "$BASH_PROFILE"

# Auto-start Hyprland en tty1 (Seamless Login estilo Omarchy)
if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec Hyprland
fi
HOOK
    echo -e "${GREEN}[OK] Hook añadido a $BASH_PROFILE.${NC}"
else
    echo -e "${GREEN}[OK] Hook de Hyprland ya activo en $BASH_PROFILE.${NC}"
fi

# 5. Deshabilitar GDM (GNOME Display Manager)
echo -e "${YELLOW}[5/5] Deshabilitando GDM...${NC}"
if systemctl is-enabled gdm.service >/dev/null 2>&1; then
    sudo systemctl disable gdm.service
    echo -e "${GREEN}[OK] gdm.service deshabilitado.${NC}"
else
    echo -e "${GREEN}[OK] gdm.service ya estaba deshabilitado.${NC}"
fi

sudo systemctl daemon-reload

echo ""
echo -e "${GREEN}${BOLD}¡SEAMLESS LOGIN CONFIGURADO CON ÉXITO!${NC}"
echo "------------------------------------------------------------------"
echo "Al encender la máquina virtual o reiniciar:"
echo "1. El sistema arrancará e iniciará sesión automáticamente en tty1"
echo "   con tu usuario (${BOLD}$CURRENT_USER${NC}) sin mostrar GDM."
echo "2. Hyprland y MrDemonc-SHELL se abrirán directamente."
echo "3. Tu pantalla se bloqueará con Hyprlock (estilo Omarchy) usando:"
echo "   - Atajo de teclado: ${BOLD}SUPER + L${NC}"
echo "   - Inactividad automática: ${BOLD}hypridle${NC} (a los 10 minutos)"
echo "------------------------------------------------------------------"
echo ""
echo -e "${CYAN}Opcional: Si deseas desinstalar GDM y GNOME Desktop completamente:${NC}"
echo "  sudo pacman -Rns gdm gnome-shell gnome-session gnome-settings-daemon"
echo "------------------------------------------------------------------"
