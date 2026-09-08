#!/usr/bin/env bash
# ==============================================================================
#  INSTALADOR AUTOMATIZADO: MrDemonc-SHELL + Hyprland + Quickshell
# ==============================================================================

set -e

# Colores de terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Directorio del repositorio
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_HOME="${HOME:-/home/$USER}"
BIN_DIR="$USER_HOME/.local/bin"
HYPR_CONFIG_DIR="$USER_HOME/.config/hypr"
KITTY_CONFIG_DIR="$USER_HOME/.config/kitty"
WALLPAPER_DIR="$USER_HOME/Pictures/Wallpapers"

echo -e "${CYAN}${BOLD}"
echo "=================================================================="
echo "        INSTALADOR DE QUICKSHELL + HYPRLAND (MrDemonc-SHELL)      "
echo "=================================================================="
echo -e "${NC}"
echo -e "${BLUE}[INFO]${NC} Directorio de instalación: ${BOLD}$REPO_DIR${NC}"
echo -e "${BLUE}[INFO]${NC} Usuario detectado: ${BOLD}$USER${NC} ($USER_HOME)"
echo ""

# ------------------------------------------------------------------------------
# 1. Verificación del Sistema Operativo y Gestor de Paquetes
# ------------------------------------------------------------------------------
echo -e "${YELLOW}[1/7] Verificando dependencias del sistema...${NC}"

PACKAGES=(
    pipewire
    wireplumber
    libpulse
    networkmanager
    bluez
    bluez-utils
    kitty
    dolphin
    ttf-jetbrains-mono-nerd
    xdg-utils
    python
    brightnessctl
    playerctl
)

if command -v pacman >/dev/null 2>&1; then
    echo -e "  Detectado sistema basado en Arch Linux."
    echo -e "  Instalando paquetes esenciales con pacman..."
    sudo pacman -S --needed --noconfirm "${PACKAGES[@]}" || {
        echo -e "${YELLOW}[AVISO] Algunos paquetes fallaron o requieren confirmación.${NC}"
    }

    # Verificar quickshell
    if ! command -v quickshell >/dev/null 2>&1; then
        echo -e "${YELLOW}[AVISO] 'quickshell' no está instalado en el sistema.${NC}"
        if command -v yay >/dev/null 2>&1; then
            echo -e "  Instalando quickshell desde AUR con yay..."
            yay -S --needed --noconfirm quickshell || true
        elif command -v paru >/dev/null 2>&1; then
            echo -e "  Instalando quickshell desde AUR con paru..."
            paru -S --needed --noconfirm quickshell || true
        else
            echo -e "${RED}[ERROR] No se encontró un helper de AUR (yay o paru) para instalar 'quickshell'.${NC}"
            echo -e "  Por favor instala 'quickshell' manualmente desde AUR (ej: yay -S quickshell)."
        fi
    else
        echo -e "${GREEN}[OK] quickshell ya está instalado.${NC}"
    fi
else
    echo -e "${YELLOW}[AVISO] No se detectó pacman. Asegúrate de instalar manualmente: ${PACKAGES[*]} quickshell${NC}"
fi

# ------------------------------------------------------------------------------
# 2. Creación de Directorios Necesarios
# ------------------------------------------------------------------------------
echo -e "${YELLOW}[2/7] Creando estructura de directorios del usuario...${NC}"
mkdir -p "$BIN_DIR"
mkdir -p "$HYPR_CONFIG_DIR"
mkdir -p "$KITTY_CONFIG_DIR"
mkdir -p "$USER_HOME/.config/quickshell"
mkdir -p "$USER_HOME/.local/state/omarchy/current/theme"
mkdir -p "$WALLPAPER_DIR"
echo -e "${GREEN}[OK] Directorios listos.${NC}"

# ------------------------------------------------------------------------------
# 3. Permisos de Ejecución en Scripts
# ------------------------------------------------------------------------------
echo -e "${YELLOW}[3/7] Configurando permisos de ejecución en scripts...${NC}"
chmod +x "$REPO_DIR"/scripts/*.sh 2>/dev/null || true
chmod +x "$REPO_DIR"/scripts/*.py 2>/dev/null || true
echo -e "${GREEN}[OK] Scripts ejecutables configurados.${NC}"

# ------------------------------------------------------------------------------
# 4. Instalación de Comandos CLI en ~/.local/bin
# ------------------------------------------------------------------------------
echo -e "${YELLOW}[4/7] Instalando utilidades CLI en $BIN_DIR...${NC}"

# Helper para crear wrappers portables
create_cli_wrapper() {
    local cmd_name="$1"
    local script_rel="$2"
    local full_path="$BIN_DIR/$cmd_name"

    cat << WRAPPER > "$full_path"
#!/usr/bin/env bash
TARGET_DIR="\${QUICKSHELL_DIR:-$REPO_DIR}"
exec "\$TARGET_DIR/$script_rel" "\$@"
WRAPPER
    chmod +x "$full_path"
    echo -e "  -> Instalado comando: ${CYAN}$cmd_name${NC}"
}

create_cli_wrapper "shell-apps" "scripts/toggle_apps.sh"
create_cli_wrapper "shell-wallpaper" "scripts/toggle_wallpaper.sh"

# Wrapper para shell-theme con soporte CLI ('set', 'list') y GUI
cat << WRAPPER > "$BIN_DIR/shell-theme"
#!/usr/bin/env bash
TARGET_DIR="\${QUICKSHELL_DIR:-$REPO_DIR}"
if [ "\$1" == "set" ] || [ "\$1" == "list" ]; then
    exec python3 "\$TARGET_DIR/scripts/theme_manager.py" "\$@"
else
    exec "\$TARGET_DIR/scripts/toggle_theme_picker.sh" "\$@"
fi
WRAPPER
chmod +x "$BIN_DIR/shell-theme"
echo -e "  -> Instalado comando: ${CYAN}shell-theme${NC}"

# Wrapper para shell-popout
cat << WRAPPER > "$BIN_DIR/shell-popout"
#!/usr/bin/env bash
TARGET="\${1:-audio}"
STATE="\${XDG_RUNTIME_DIR:-/tmp}/quickshell_popout.toggle"
echo "\$TARGET" > "\$STATE"
WRAPPER
chmod +x "$BIN_DIR/shell-popout"
echo -e "  -> Instalado comando: ${CYAN}shell-popout${NC}"

# Wrapper para shell-bar (cambiar posición de la barra: top, bottom, left, right)
cat << WRAPPER > "$BIN_DIR/shell-bar"
#!/usr/bin/env bash
TARGET_DIR="\${QUICKSHELL_DIR:-$REPO_DIR}"
if [ "\$1" == "pos" ] || [ "\$1" == "position" ]; then
    shift
    exec python3 "\$TARGET_DIR/scripts/manage_order.py" save_position "\$@"
elif [ "\$1" == "get-pos" ]; then
    exec python3 "\$TARGET_DIR/scripts/manage_order.py" get_position
else
    exec python3 "\$TARGET_DIR/scripts/manage_order.py" "\$@"
fi
WRAPPER
chmod +x "$BIN_DIR/shell-bar"
echo -e "  -> Instalado comando: ${CYAN}shell-bar${NC}"

# Asegurar que ~/.local/bin esté en el PATH del usuario
for rc_file in "$USER_HOME/.bashrc" "$USER_HOME/.zshrc"; do
    if [ -f "$rc_file" ]; then
        if ! grep -q '\.local/bin' "$rc_file"; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc_file"
            echo -e "  Añadido ~/.local/bin al PATH en $rc_file"
        fi
    fi
done

# ------------------------------------------------------------------------------
# 5. Configuración de Hyprland Modular
# ------------------------------------------------------------------------------
echo -e "${YELLOW}[5/7] Desplegando configuración modular de Hyprland...${NC}"

# Respaldar configuración previa si no se ha respaldado
if [ -f "$HYPR_CONFIG_DIR/hyprland.lua" ] && [ ! -f "$HYPR_CONFIG_DIR/hyprland.lua.bak" ]; then
    cp "$HYPR_CONFIG_DIR/hyprland.lua" "$HYPR_CONFIG_DIR/hyprland.lua.bak"
    echo -e "  Respaldo creado en $HYPR_CONFIG_DIR/hyprland.lua.bak"
fi

# Copiar módulos de Hyprland
if [ -d "$REPO_DIR/hypr" ]; then
    cp -f "$REPO_DIR/hypr/windows.lua" "$HYPR_CONFIG_DIR/windows.lua"
    cp -f "$REPO_DIR/hypr/keybinds.lua" "$HYPR_CONFIG_DIR/keybinds.lua"
    cp -f "$REPO_DIR/hypr/theme_colors.lua" "$HYPR_CONFIG_DIR/theme_colors.lua" 2>/dev/null || true
    
    # Generar hyprland.lua con la ruta exacta del repositorio
    sed "s|userHome .. \"/Documentos/MrDemonc-SHELL\"|\"$REPO_DIR\"|g" \
        "$REPO_DIR/hypr/hyprland.lua" > "$HYPR_CONFIG_DIR/hyprland.lua"
    
    echo -e "${GREEN}[OK] Archivos de Hyprland instalados (windows.lua, keybinds.lua, hyprland.lua).${NC}"
else
    echo -e "${YELLOW}[AVISO] No se encontró carpeta hypr/ en el repo, omitiendo copia de archivos lua.${NC}"
fi

# ------------------------------------------------------------------------------
# 6. Configuración de Kitty y Sistema
# ------------------------------------------------------------------------------
echo -e "${YELLOW}[6/7] Configurando Kitty, MIME de archivos y Servicios...${NC}"

if [ -f "$REPO_DIR/kitty/kitty.conf" ]; then
    cp -f "$REPO_DIR/kitty/kitty.conf" "$KITTY_CONFIG_DIR/kitty.conf"
    echo -e "${GREEN}[OK] Configuración de Kitty aplicada (~/.config/kitty/kitty.conf).${NC}"
fi

# Establecer Dolphin como explorador de carpetas por defecto
if command -v xdg-mime >/dev/null 2>&1; then
    xdg-mime default org.kde.dolphin.desktop inode/directory 2>/dev/null || true
fi

# Habilitar servicios de red y bluetooth
if command -v systemctl >/dev/null 2>&1; then
    sudo systemctl enable --now NetworkManager 2>/dev/null || true
    sudo systemctl enable --now bluetooth 2>/dev/null || true
fi

# ------------------------------------------------------------------------------
# 7. Inicialización del Tema y Arranque
# ------------------------------------------------------------------------------
echo -e "${YELLOW}[7/7] Inicializando tema y sincronización...${NC}"

# Inicializar con Tokyo Night
if [ -f "$REPO_DIR/scripts/theme_manager.py" ]; then
    python3 "$REPO_DIR/scripts/theme_manager.py" set tokyo-night >/dev/null 2>&1 || true
    echo -e "${GREEN}[OK] Tema 'tokyo-night' sincronizado correctamente.${NC}"
fi

# Recargar Hyprland si está en ejecución
if pgrep -x Hyprland >/dev/null 2>&1; then
    echo -e "  Recargando Hyprland..."
    hyprctl reload >/dev/null 2>&1 || true
fi

# Reiniciar Quickshell si está en ejecución o preguntar
if pgrep -x quickshell >/dev/null 2>&1; then
    echo -e "  Reiniciando instancia activa de Quickshell..."
    killall -9 quickshell 2>/dev/null || true
    sleep 1
    if pgrep -x Hyprland >/dev/null 2>&1; then
        hyprctl eval "hl.exec_cmd('quickshell -p $REPO_DIR')" >/dev/null 2>&1 || true
    else
        nohup quickshell -p "$REPO_DIR" >/dev/null 2>&1 &
    fi
fi

echo ""
echo -e "${GREEN}${BOLD}==================================================================${NC}"
echo -e "${GREEN}${BOLD}             ¡INSTALACIÓN COMPLETADA CON ÉXITO!                   ${NC}"
echo -e "${GREEN}${BOLD}==================================================================${NC}"
echo ""
echo -e "  • ${BOLD}SUPER + Enter${NC}          : Abrir terminal Kitty (transparencia 93%)
  • ${BOLD}SUPER + W${NC}              : Cerrar ventana activa
  • ${BOLD}SUPER + T${NC}              : Alternar ventana flotante (Float)
  • ${BOLD}SUPER + Espacio${NC}        : Lanzador y buscador de aplicaciones
  • ${BOLD}SUPER + Shift + W${NC}      : Selector de fondos de pantalla
  • ${BOLD}SUPER + Shift + T${NC}      : Selector de temas de color
  • ${BOLD}SUPER + Shift + Flechas${NC}: Mover ventanas de posición
  • ${BOLD}SUPER + E${NC}              : Explorador de archivos (Dolphin)"
echo ""
echo -e "  Comandos disponibles en cualquier terminal: ${CYAN}shell-apps${NC}, ${CYAN}shell-theme${NC}, ${CYAN}shell-wallpaper${NC}, ${CYAN}shell-popout${NC}"
echo ""
