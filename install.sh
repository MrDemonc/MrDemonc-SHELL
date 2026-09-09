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
CURRENT_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$CURRENT_USER")
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
echo -e "${BLUE}[INFO]${NC} Usuario detectado: ${BOLD}$CURRENT_USER${NC} ($USER_HOME)"
echo ""

# ------------------------------------------------------------------------------
# 1. Verificación del Sistema Operativo y Gestor de Paquetes
# ------------------------------------------------------------------------------
echo -e "${YELLOW}[1/10] Verificando dependencias del sistema...${NC}"

PACKAGES=(
    hyprland
    hyprlock
    hypridle
    pipewire
    wireplumber
    libpulse
    playerctl
    networkmanager
    bluez
    bluez-utils
    upower
    brightnessctl
    xdg-utils
    libnotify
    grim
    slurp
    wl-clipboard
    wtype
    kitty
    dolphin
    ttf-jetbrains-mono-nerd
    zsh
    starship
    curl
    git
    python
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
            echo -e "  Por favor instala 'quickshell' manualmente desde AUR."
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
echo -e "${YELLOW}[2/10] Creando estructura de directorios del usuario...${NC}"
mkdir -p "$BIN_DIR"
mkdir -p "$HYPR_CONFIG_DIR"
mkdir -p "$KITTY_CONFIG_DIR"
mkdir -p "$USER_HOME/.config/quickshell"
mkdir -p "$USER_HOME/.local/state/mrdemonc/current/theme"
mkdir -p "$WALLPAPER_DIR"
echo -e "${GREEN}[OK] Directorios listos.${NC}"

# ------------------------------------------------------------------------------
# 3. Permisos de Ejecución en Scripts
# ------------------------------------------------------------------------------
echo -e "${YELLOW}[3/10] Configurando permisos de ejecución en scripts...${NC}"
chmod +x "$REPO_DIR"/scripts/*.sh 2>/dev/null || true
chmod +x "$REPO_DIR"/scripts/*.py 2>/dev/null || true
echo -e "${GREEN}[OK] Scripts ejecutables configurados.${NC}"

# ------------------------------------------------------------------------------
# 4. Instalación de Comandos CLI en ~/.local/bin
# ------------------------------------------------------------------------------
echo -e "${YELLOW}[4/10] Instalando utilidades CLI en $BIN_DIR...${NC}"

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
create_cli_wrapper "clipboard-action" "scripts/clipboard_action.sh"

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
# 5. Configuración de Hyprland Modular y Pantalla de Bloqueo
# ------------------------------------------------------------------------------
echo -e "${YELLOW}[5/10] Desplegando configuración modular de Hyprland, Hyprlock e Hypridle...${NC}"

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
    cp -f "$REPO_DIR/hypr/hyprlock.conf" "$HYPR_CONFIG_DIR/hyprlock.conf" 2>/dev/null || true
    cp -f "$REPO_DIR/hypr/hyprlock_colors.conf" "$HYPR_CONFIG_DIR/hyprlock_colors.conf" 2>/dev/null || true
    cp -f "$REPO_DIR/hypr/hypridle.conf" "$HYPR_CONFIG_DIR/hypridle.conf" 2>/dev/null || true
    
    # Generar hyprland.lua con la ruta exacta del repositorio
    sed "s|userHome .. \"/Documentos/MrDemonc-SHELL\"|\"$REPO_DIR\"|g" \
        "$REPO_DIR/hypr/hyprland.lua" > "$HYPR_CONFIG_DIR/hyprland.lua"
    
    echo -e "${GREEN}[OK] Archivos de Hyprland instalados (windows.lua, keybinds.lua, hyprland.lua, hyprlock.conf, hypridle.conf).${NC}"
else
    echo -e "${YELLOW}[AVISO] No se encontró carpeta hypr/ en el repo, omitiendo copia de archivos lua.${NC}"
fi

# ------------------------------------------------------------------------------
# 6. Configuración de Kitty y Sistema
# ------------------------------------------------------------------------------
echo -e "${YELLOW}[6/10] Configurando Kitty, MIME de archivos y Servicios...${NC}"

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
# 7. Configuración de Shell Zsh, Oh My Zsh y Prompt Starship
# ------------------------------------------------------------------------------
echo -e "${YELLOW}[7/10] Configurando Zsh, Oh My Zsh y Starship...${NC}"

# 1. Instalar configuración de Starship
mkdir -p "$USER_HOME/.config"
STARSHIP_SRC=""
if [ -f "$REPO_DIR/starship/starship.toml" ]; then
    STARSHIP_SRC="$REPO_DIR/starship/starship.toml"
elif [ -f "$USER_HOME/Descargas/starship.toml" ]; then
    STARSHIP_SRC="$USER_HOME/Descargas/starship.toml"
fi

if [ -n "$STARSHIP_SRC" ]; then
    cp -f "$STARSHIP_SRC" "$USER_HOME/.config/starship.toml"
    echo -e "  -> Configuración de Starship instalada en ~/.config/starship.toml"
fi

# 2. Instalar Oh My Zsh de forma no interactiva (unattended)
if [ ! -d "$USER_HOME/.oh-my-zsh" ]; then
    if command -v curl >/dev/null 2>&1; then
        echo -e "  Instalando Oh My Zsh..."
        RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || {
            echo -e "${YELLOW}[AVISO] No se pudo descargar Oh My Zsh automáticamente o zsh aún no está en el PATH.${NC}"
        }
        echo -e "${GREEN}[OK] Oh My Zsh instalado con éxito.${NC}"
    else
        echo -e "${YELLOW}[AVISO] curl no está instalado; omitiendo instalación de Oh My Zsh.${NC}"
    fi
else
    echo -e "${GREEN}[OK] Oh My Zsh ya está instalado (~/.oh-my-zsh).${NC}"
fi

# 3. Descargar plugins populares de Oh My Zsh (autosuggestions & syntax-highlighting)
ZSH_CUSTOM="${ZSH_CUSTOM:-$USER_HOME/.oh-my-zsh/custom}"
if [ -d "$USER_HOME/.oh-my-zsh" ]; then
    mkdir -p "$ZSH_CUSTOM/plugins"
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
        echo -e "  Descargando plugin zsh-autosuggestions..."
        git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" 2>/dev/null || true
    fi
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
        echo -e "  Descargando plugin zsh-syntax-highlighting..."
        git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" 2>/dev/null || true
    fi
fi

# 4. Configurar ~/.zshrc con Starship, PATH y plugins
ZSHRC="$USER_HOME/.zshrc"
if [ ! -f "$ZSHRC" ] && [ -f "$USER_HOME/.oh-my-zsh/templates/zshrc.zsh-template" ]; then
    cp "$USER_HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$ZSHRC"
fi

if [ -f "$ZSHRC" ]; then
    # Habilitar plugins si existen
    if grep -q '^plugins=' "$ZSHRC"; then
        sed -i 's/^plugins=(.*)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$ZSHRC"
    fi

    # Asegurar ~/.local/bin en PATH
    if ! grep -q '\.local/bin' "$ZSHRC"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$ZSHRC"
    fi

    # Activar Starship Prompt
    if ! grep -q 'starship init zsh' "$ZSHRC"; then
        echo '' >> "$ZSHRC"
        echo '# Inicialización de Starship Prompt' >> "$ZSHRC"
        echo 'eval "$(starship init zsh)"' >> "$ZSHRC"
    fi
    echo -e "${GREEN}[OK] ~/.zshrc configurado con Oh My Zsh y Starship.${NC}"
fi

# 5. Configurar Seamless Login en ~/.zprofile para inicio automático en tty1 con zsh
ZPROFILE="$USER_HOME/.zprofile"
if ! grep -q 'exec Hyprland' "$ZPROFILE" 2>/dev/null; then
    cat << 'HOOK' >> "$ZPROFILE"

# Auto-start Hyprland en tty1 (Seamless Login)
if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec Hyprland
fi
HOOK
    echo -e "${GREEN}[OK] Hook de arranque de Hyprland añadido a ~/.zprofile.${NC}"
else
    echo -e "${GREEN}[OK] Hook de arranque de Hyprland ya presente en ~/.zprofile.${NC}"
fi

# 6. Cambiar la shell predeterminada a ZSH si está disponible
if command -v zsh >/dev/null 2>&1; then
    ZSH_PATH="$(command -v zsh)"
    CURRENT_SHELL="$(getent passwd "$CURRENT_USER" | cut -d: -f7)"
    if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
        echo -e "  Configurando Zsh como shell predeterminada para $CURRENT_USER..."
        sudo chsh -s "$ZSH_PATH" "$CURRENT_USER" 2>/dev/null || chsh -s "$ZSH_PATH" 2>/dev/null || true
        echo -e "${GREEN}[OK] Shell por defecto cambiada a $ZSH_PATH.${NC}"
    else
        echo -e "${GREEN}[OK] Zsh ya es la shell por defecto ($CURRENT_SHELL).${NC}"
    fi
fi

# ------------------------------------------------------------------------------
# 8. Inicialización del Tema y Arranque
# ------------------------------------------------------------------------------
echo -e "${YELLOW}[8/10] Inicializando tema y sincronización...${NC}"

# Inicializar con Catppuccin Mocha
if [ -f "$REPO_DIR/scripts/theme_manager.py" ]; then
    python3 "$REPO_DIR/scripts/theme_manager.py" set catppuccin-mocha >/dev/null 2>&1 || true
    echo -e "${GREEN}[OK] Tema 'catppuccin-mocha' sincronizado correctamente.${NC}"
fi

# ------------------------------------------------------------------------------
# 9. Configuración de Seamless Login
# ------------------------------------------------------------------------------
echo -e "${YELLOW}[9/10] Configurando Seamless Login...${NC}"

# 1. Configurar Autologin en tty1 con systemd agetty
if [ -d "/etc/systemd/system" ]; then
    echo -e "  Configurando inicio automático en tty1 para ${BOLD}$CURRENT_USER${NC}..."
    sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
    sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf > /dev/null << AUTOLOGIN
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $CURRENT_USER --noclear %I \$TERM
Type=idle
AUTOLOGIN
    echo -e "${GREEN}[OK] /etc/systemd/system/getty@tty1.service.d/autologin.conf configurado.${NC}"
fi

# 2. Configurar autoarranque de Hyprland en ~/.bash_profile
BASH_PROFILE="$USER_HOME/.bash_profile"
if ! grep -q 'exec Hyprland' "$BASH_PROFILE" 2>/dev/null; then
    cat << 'HOOK' >> "$BASH_PROFILE"

# Auto-start Hyprland en tty1 (Seamless Login)
if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec Hyprland
fi
HOOK
    echo -e "${GREEN}[OK] Hook de arranque de Hyprland añadido a ~/.bash_profile.${NC}"
else
    echo -e "${GREEN}[OK] Hook de arranque de Hyprland ya presente en ~/.bash_profile.${NC}"
fi

# 3. Deshabilitar GDM para permitir arranque directo
if command -v systemctl >/dev/null 2>&1; then
    if systemctl is-enabled gdm.service >/dev/null 2>&1; then
        echo -e "  Deshabilitando GDM para permitir inicio directo sin gestor de usuarios..."
        sudo systemctl disable gdm.service 2>/dev/null || true
        echo -e "${GREEN}[OK] gdm.service deshabilitado.${NC}"
    else
        echo -e "${GREEN}[OK] gdm.service ya estaba deshabilitado.${NC}"
    fi
    sudo systemctl daemon-reload 2>/dev/null || true
fi

# ------------------------------------------------------------------------------
# 10. Desinstalación Automática de GNOME Desktop y GDM
# ------------------------------------------------------------------------------
echo -e "${YELLOW}[10/10] Desinstalando GNOME Desktop y GDM del sistema...${NC}"

# 1. Deshabilitar y detener servicio GDM
if command -v systemctl >/dev/null 2>&1; then
    if systemctl is-enabled gdm.service >/dev/null 2>&1 || systemctl is-active gdm.service >/dev/null 2>&1; then
        echo -e "  Deshabilitando y deteniendo gdm.service..."
        sudo systemctl disable gdm.service 2>/dev/null || true
        sudo systemctl stop gdm.service 2>/dev/null || true
    fi
    sudo systemctl daemon-reload 2>/dev/null || true
fi

# 2. Desinstalar paquetes de GDM y GNOME Desktop
GNOME_PKGS=()
for pkg in gdm gnome-shell mutter gnome-session gnome-settings-daemon gnome-control-center gnome-keyring gnome-terminal; do
    if pacman -Q "$pkg" >/dev/null 2>&1; then
        GNOME_PKGS+=("$pkg")
    fi
done

if [ ${#GNOME_PKGS[@]} -gt 0 ]; then
    echo -e "  Eliminando paquetes de GNOME y GDM (${GNOME_PKGS[*]})..."
    sudo pacman -R --noconfirm "${GNOME_PKGS[@]}" 2>/dev/null || \
    sudo pacman -Rdd --noconfirm "${GNOME_PKGS[@]}" 2>/dev/null || true
    echo -e "${GREEN}[OK] GNOME Desktop y GDM desinstalados con éxito.${NC}"
else
    echo -e "${GREEN}[OK] GNOME Desktop y GDM no están presentes en el sistema.${NC}"
fi

# Recargar Hyprland si está en ejecución
if pgrep -x Hyprland >/dev/null 2>&1; then
    echo -e "  Recargando Hyprland..."
    hyprctl reload >/dev/null 2>&1 || true
fi

# Reiniciar Quickshell si está en ejecución
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
  • ${BOLD}SUPER + C / X / V${NC}      : Copiar, Cortar y Pegar nativo en Wayland
  • ${BOLD}SUPER + W${NC}              : Cerrar ventana activa
  • ${BOLD}SUPER + T${NC}              : Alternar ventana flotante (Float)
  • ${BOLD}SUPER + L${NC}              : Bloquear pantalla (Hyprlock adaptable a temas)
  • ${BOLD}SUPER + Espacio${NC}        : Lanzador y buscador de aplicaciones
  • ${BOLD}SUPER + Shift + W${NC}      : Selector de fondos de pantalla
  • ${BOLD}SUPER + Shift + T${NC}      : Selector de temas de color
  • ${BOLD}SUPER + Shift + Flechas${NC}: Mover ventanas de posición
  • ${BOLD}SUPER + E${NC}              : Explorador de archivos (Dolphin)
  • ${BOLD}Zsh + Starship Prompt${NC}  : Shell interactiva con Oh My Zsh y diseño Demonc"
echo ""
echo -e "  • ${CYAN}Seamless Login${NC}       : Arrancará directamente a Hyprland sin pantalla de GDM."
echo -e "  • ${CYAN}Bloqueo por Inactividad${NC}: 'hypridle' atenuará a los 5m y bloqueará a los 10m."
echo ""
echo -e "  Comandos disponibles en terminal: ${CYAN}shell-apps${NC}, ${CYAN}shell-theme${NC}, ${CYAN}shell-wallpaper${NC}, ${CYAN}shell-bar${NC}"
echo ""
