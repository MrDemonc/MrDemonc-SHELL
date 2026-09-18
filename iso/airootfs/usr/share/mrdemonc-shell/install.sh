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
echo -e "${YELLOW}[1/11] Verificando dependencias del sistema...${NC}"

PACKAGES=(
    hyprland
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
    wf-recorder
    hyprpicker
    wl-clipboard
    wtype
    kitty
    nautilus
    gvfs
    gvfs-mtp
    gvfs-gphoto2
    gvfs-afc
    gvfs-smb
    udisks2
    udiskie
    android-udev
    dosfstools
    exfatprogs
    ntfs-3g
    capitaine-cursors
    polkit-gnome
    ttf-jetbrains-mono-nerd
    zsh
    starship
    fastfetch
    chafa
    curl
    git
    python
    jq
    cups
    cups-filters
    cups-pdf
    system-config-printer
    avahi
    nss-mdns
    gutenprint
    foomatic-db-engine
    foomatic-db
    sane
    sane-airscan
    v4l-utils
    pipewire-v4l2
    gst-plugin-pipewire
    gst-plugins-good
    libcamera
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

    # Verificar zen-browser (usando yay -S zen-browser-bin)
    if ! command -v zen-browser >/dev/null 2>&1 && ! command -v zen >/dev/null 2>&1; then
        echo -e "  Instalando zen-browser-bin desde AUR con yay..."
        if command -v yay >/dev/null 2>&1; then
            yay -S --needed --noconfirm zen-browser-bin || true
        elif command -v paru >/dev/null 2>&1; then
            paru -S --needed --noconfirm zen-browser-bin || true
        else
            echo -e "${YELLOW}[AVISO] No se encontró yay o paru para instalar 'zen-browser-bin'.${NC}"
            echo -e "  Por favor instala 'zen-browser-bin' manualmente usando: yay -S zen-browser-bin"
        fi
    else
        echo -e "${GREEN}[OK] Zen Browser ya está instalado.${NC}"
    fi
else
    echo -e "${YELLOW}[AVISO] No se detectó pacman. Asegúrate de instalar manualmente: ${PACKAGES[*]} quickshell${NC}"
fi

# ------------------------------------------------------------------------------
# 2. Creación de Directorios Necesarios
# ------------------------------------------------------------------------------
echo -e "${YELLOW}[2/11] Creando estructura de directorios del usuario...${NC}"
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
echo -e "${YELLOW}[3/11] Configurando permisos de ejecución en scripts...${NC}"
chmod +x "$REPO_DIR/scripts/"*.sh 2>/dev/null || true
chmod +x "$REPO_DIR/bin/"* 2>/dev/null || true

# ------------------------------------------------------------------------------
# 4. Instalación de Utilidades CLI en ~/.local/bin
# ------------------------------------------------------------------------------
echo -e "${YELLOW}[4/11] Instalando utilidades CLI en $BIN_DIR...${NC}"

# Helper para crear wrappers portables
create_cli_wrapper() {
    local cmd_name="$1"
    local script_rel="$2"
    local full_path="$BIN_DIR/$cmd_name"

    if [ -f "$REPO_DIR/bin/$cmd_name" ]; then
        cp -f "$REPO_DIR/bin/$cmd_name" "$full_path"
    else
        cat << WRAPPER > "$full_path"
#!/usr/bin/env bash
TARGET_DIR="\${QUICKSHELL_DIR:-$REPO_DIR}"
exec "\$TARGET_DIR/$script_rel" "\$@"
WRAPPER
    fi
    chmod +x "$full_path"
    echo -e "  -> Instalado comando: ${CYAN}$cmd_name${NC}"
}

# Copiar todos los binarios nativos de bin/
if [ -d "$REPO_DIR/bin" ]; then
    cp -f "$REPO_DIR/bin/"* "$BIN_DIR/" 2>/dev/null || true
    chmod +x "$BIN_DIR"/* 2>/dev/null || true
fi

create_cli_wrapper "shell-apps" "bin/shell-apps"
create_cli_wrapper "shell-wallpaper" "bin/shell-wallpaper"
create_cli_wrapper "shell-theme" "bin/shell-theme"
create_cli_wrapper "shell-popout" "bin/shell-popout"
create_cli_wrapper "shell-bar" "bin/shell-bar"
create_cli_wrapper "shell-keybinds" "bin/shell-keybinds"
create_cli_wrapper "shell-monitors" "bin/shell-monitors"
create_cli_wrapper "clipboard-action" "bin/clipboard-action"
create_cli_wrapper "shell-image" "bin/shell-image"
create_cli_wrapper "shell-video" "bin/shell-video"
create_cli_wrapper "shell-pdf" "bin/shell-pdf"
create_cli_wrapper "shell-screenshot" "bin/shell-screenshot"
create_cli_wrapper "shell-power" "bin/shell-power"
create_cli_wrapper "shell-notifications" "bin/shell-notifications"
create_cli_wrapper "shell-caffeine" "bin/shell-caffeine"
create_cli_wrapper "shell-recorder" "bin/shell-recorder"
create_cli_wrapper "shell-colorpicker" "bin/shell-colorpicker"
create_cli_wrapper "shell-lock" "bin/shell-lock"
create_cli_wrapper "shell-osd" "bin/shell-osd"
create_cli_wrapper "shell-brightness" "bin/shell-brightness"
create_cli_wrapper "shell-volume" "bin/shell-volume"
create_cli_wrapper "shell-audio-init" "bin/shell-audio-init"
create_cli_wrapper "shell-terminal" "bin/shell-terminal"
create_cli_wrapper "shell-steam-intel" "bin/shell-steam-intel"
create_cli_wrapper "shell-supervisor" "bin/shell-supervisor"
create_cli_wrapper "shell-session-locked" "bin/shell-session-locked"
create_cli_wrapper "shell-recover-lock" "bin/shell-recover-lock"

# Instalar también en /usr/local/bin para disponibilidad global en el sistema
if command -v sudo >/dev/null 2>&1; then
    echo -e "  Registrando comandos globalmente en /usr/local/bin..."
    sudo cp -f "$REPO_DIR/bin/"* /usr/local/bin/ 2>/dev/null || true
    sudo chmod +x /usr/local/bin/shell-* /usr/local/bin/clipboard-action 2>/dev/null || true

    # Configurar permisos de hardware para brillo de laptop, audio, almacenamiento y Android MTP/ADB
    echo -e "  Configurando permisos de hardware para brillo de laptop, audio, almacenamiento y Android..."
    sudo usermod -aG video,audio,input,storage,adbusers "$CURRENT_USER" 2>/dev/null || true
    if [ ! -f /etc/udev/rules.d/90-backlight.rules ]; then
        echo 'ACTION=="add", SUBSYSTEM=="backlight", RUN+="/bin/chmod a+rw /sys/class/backlight/%k/brightness"' | sudo tee /etc/udev/rules.d/90-backlight.rules >/dev/null 2>&1 || true
        sudo udevadm control --reload-rules 2>/dev/null || true
        sudo udevadm trigger --subsystem-match=backlight 2>/dev/null || true
    fi

    # Configurar reglas de Polkit para permitir montaje de discos y particiones sin contraseña
    if [ ! -f /etc/polkit-1/rules.d/50-udisks2.rules ]; then
        sudo mkdir -p /etc/polkit-1/rules.d
        cat << 'POLKIT_EOF' | sudo tee /etc/polkit-1/rules.d/50-udisks2.rules >/dev/null 2>&1 || true
/* Permitir a usuarios en el grupo wheel montar, desmontar y desbloquear discos sin solicitar clave */
polkit.addRule(function(action, subject) {
    if ((action.id == "org.freedesktop.udisks2.filesystem-mount" ||
         action.id == "org.freedesktop.udisks2.filesystem-mount-system" ||
         action.id == "org.freedesktop.udisks2.filesystem-mount-other-seat" ||
         action.id == "org.freedesktop.udisks2.encrypted-unlock" ||
         action.id == "org.freedesktop.udisks2.encrypted-unlock-system" ||
         action.id == "org.freedesktop.udisks2.eject-media" ||
         action.id == "org.freedesktop.udisks2.power-off-drive") &&
        subject.isInGroup("wheel")) {
        return polkit.Result.YES;
    }
});
POLKIT_EOF
    fi

    sudo systemctl enable --now udisks2.service 2>/dev/null || true
    sudo udevadm control --reload-rules 2>/dev/null || true
    sudo udevadm trigger 2>/dev/null || true
fi

# Configurar perfil de audio inicial (altavoces + HDMI para portátiles)
echo -e "  Configurando perfil de audio predeterminado para tarjetas Intel/ALSA..."
mkdir -p "$USER_HOME/.local/state/wireplumber"
cat << 'WP_PROF' > "$USER_HOME/.local/state/wireplumber/default-profile"
[default-profile]
alsa_card.pci-0000_00_1f.3-platform-skl_hda_dsp_generic=HiFi (HDMI1, HDMI2, HDMI3, Mic1, Mic2, Speaker)
WP_PROF
if command -v pactl >/dev/null 2>&1; then
    for card in $(pactl list cards short 2>/dev/null | awk '{print $1}'); do
        pactl set-card-profile "$card" "HiFi (HDMI1, HDMI2, HDMI3, Mic1, Mic2, Speaker)" 2>/dev/null || true
    done
fi

# Instalar accesos directos .desktop
mkdir -p "$USER_HOME/.local/share/applications"
cp -f "$REPO_DIR/desktop/"*.desktop "$USER_HOME/.local/share/applications/" 2>/dev/null || true
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$USER_HOME/.local/share/applications" 2>/dev/null || true
fi

# Asegurar que ~/.local/bin y ~/.opencode/bin estén en el PATH del usuario
for rc_file in "$USER_HOME/.bashrc" "$USER_HOME/.zshrc"; do
    if [ -f "$rc_file" ]; then
        if ! grep -q '\.local/bin' "$rc_file"; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc_file"
            echo -e "  Añadido ~/.local/bin al PATH en $rc_file"
        fi
        if ! grep -q '\.opencode/bin' "$rc_file"; then
            echo 'export PATH="$HOME/.opencode/bin:$PATH"' >> "$rc_file"
            echo -e "  Añadido ~/.opencode/bin al PATH en $rc_file"
        fi
    fi
done

# ------------------------------------------------------------------------------
# 5. Configuración de Hyprland Modular e Hypridle
# ------------------------------------------------------------------------------
echo -e "${YELLOW}[5/11] Desplegando configuración modular de Hyprland e Hypridle...${NC}"

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
    cp -f "$REPO_DIR/hypr/hypridle.conf" "$HYPR_CONFIG_DIR/hypridle.conf" 2>/dev/null || true
    if [ -f "$REPO_DIR/hypr/monitors.lua" ]; then
        cp -f "$REPO_DIR/hypr/monitors.lua" "$HYPR_CONFIG_DIR/monitors.lua"
    fi
    rm -f "$HYPR_CONFIG_DIR/hyprlock"*.conf 2>/dev/null || true
    
    # Generar hyprland.lua con la ruta exacta del repositorio
    sed "s|userHome .. \"/Documentos/MrDemonc-SHELL\"|\"$REPO_DIR\"|g" \
        "$REPO_DIR/hypr/hyprland.lua" > "$HYPR_CONFIG_DIR/hyprland.lua"
    
    echo -e "${GREEN}[OK] Archivos de Hyprland instalados (windows.lua, keybinds.lua, hyprland.lua, hypridle.conf).${NC}"
else
    echo -e "${YELLOW}[AVISO] No se encontró carpeta hypr/ en el repo, omitiendo copia de archivos lua.${NC}"
fi

# ------------------------------------------------------------------------------
# 6. Configuración de Kitty y Sistema
# ------------------------------------------------------------------------------
echo -e "${YELLOW}[6/11] Configurando Kitty, MIME de archivos y Servicios...${NC}"

if [ -d "$REPO_DIR/kitty" ]; then
    cp -a "$REPO_DIR/kitty/." "$KITTY_CONFIG_DIR/"
    echo -e "${GREEN}[OK] Configuración y paleta de temas de Kitty aplicadas (~/.config/kitty/).${NC}"
fi

# Establecer asociaciones MIME predeterminadas (Imágenes, PDF, Videos, Navegador y Gestor de carpetas)
mkdir -p "$USER_HOME/.config"
cat << 'MIME_CONF' > "$USER_HOME/.config/mimeapps.list"
[Default Applications]
text/html=zen.desktop
x-scheme-handler/http=zen.desktop
x-scheme-handler/https=zen.desktop
x-scheme-handler/about=zen.desktop
x-scheme-handler/unknown=zen.desktop
inode/directory=org.gnome.Nautilus.desktop
application/pdf=shell-pdf.desktop
application/x-pdf=shell-pdf.desktop
application/x-bzpdf=shell-pdf.desktop
application/x-gzpdf=shell-pdf.desktop
image/bmp=shell-image.desktop
image/gif=shell-image.desktop
image/jpeg=shell-image.desktop
image/jpg=shell-image.desktop
image/pjpeg=shell-image.desktop
image/png=shell-image.desktop
image/tiff=shell-image.desktop
image/webp=shell-image.desktop
image/x-bmp=shell-image.desktop
image/x-portable-anymap=shell-image.desktop
image/x-portable-bitmap=shell-image.desktop
image/x-portable-graymap=shell-image.desktop
image/x-portable-pixmap=shell-image.desktop
image/x-xbitmap=shell-image.desktop
image/x-xpixmap=shell-image.desktop
image/svg+xml=shell-image.desktop
image/avif=shell-image.desktop
image/heic=shell-image.desktop
image/heif=shell-image.desktop
image/jxl=shell-image.desktop
video/mp4=shell-video.desktop
video/webm=shell-video.desktop
video/x-matroska=shell-video.desktop
video/quicktime=shell-video.desktop
video/x-msvideo=shell-video.desktop
video/ogg=shell-video.desktop
video/mpeg=shell-video.desktop
video/avi=shell-video.desktop
video/x-flv=shell-video.desktop
video/x-ms-wmv=shell-video.desktop
video/3gpp=shell-video.desktop
video/3gpp2=shell-video.desktop
video/mp2t=shell-video.desktop

[Added Associations]
text/html=zen.desktop;
x-scheme-handler/http=zen.desktop;
x-scheme-handler/https=zen.desktop;
x-scheme-handler/about=zen.desktop;
x-scheme-handler/unknown=zen.desktop;
inode/directory=org.gnome.Nautilus.desktop;
application/pdf=shell-pdf.desktop;
application/x-pdf=shell-pdf.desktop;
application/x-bzpdf=shell-pdf.desktop;
application/x-gzpdf=shell-pdf.desktop;
image/bmp=shell-image.desktop;
image/gif=shell-image.desktop;
image/jpeg=shell-image.desktop;
image/jpg=shell-image.desktop;
image/pjpeg=shell-image.desktop;
image/png=shell-image.desktop;
image/tiff=shell-image.desktop;
image/webp=shell-image.desktop;
image/x-bmp=shell-image.desktop;
image/x-portable-anymap=shell-image.desktop;
image/x-portable-bitmap=shell-image.desktop;
image/x-portable-graymap=shell-image.desktop;
image/x-portable-pixmap=shell-image.desktop;
image/x-xbitmap=shell-image.desktop;
image/x-xpixmap=shell-image.desktop;
image/svg+xml=shell-image.desktop;
image/avif=shell-image.desktop;
image/heic=shell-image.desktop;
image/heif=shell-image.desktop;
image/jxl=shell-image.desktop;
video/mp4=shell-video.desktop;
video/webm=shell-video.desktop;
video/x-matroska=shell-video.desktop;
video/quicktime=shell-video.desktop;
video/x-msvideo=shell-video.desktop;
video/ogg=shell-video.desktop;
video/mpeg=shell-video.desktop;
video/avi=shell-video.desktop;
video/x-flv=shell-video.desktop;
video/x-ms-wmv=shell-video.desktop;
video/3gpp=shell-video.desktop;
video/3gpp2=shell-video.desktop;
video/mp2t=shell-video.desktop;
MIME_CONF

if command -v xdg-mime >/dev/null 2>&1; then
    xdg-mime default org.gnome.Nautilus.desktop inode/directory 2>/dev/null || true
    xdg-mime default shell-image.desktop image/png image/jpeg image/jpg image/webp image/gif image/svg+xml image/avif image/bmp image/tiff image/heic image/heif image/jxl 2>/dev/null || true
    xdg-mime default shell-pdf.desktop application/pdf application/x-pdf application/x-bzpdf application/x-gzpdf 2>/dev/null || true
    xdg-mime default shell-video.desktop video/mp4 video/webm video/x-matroska video/quicktime video/x-msvideo video/ogg video/mpeg video/avi video/x-flv video/x-ms-wmv video/3gpp video/3gpp2 video/mp2t 2>/dev/null || true
fi

# Habilitar servicios de red, bluetooth e impresión
if command -v systemctl >/dev/null 2>&1; then
    sudo systemctl enable --now NetworkManager 2>/dev/null || true
    sudo systemctl enable --now bluetooth 2>/dev/null || true
    sudo systemctl enable --now cups 2>/dev/null || true
    sudo systemctl enable --now avahi-daemon 2>/dev/null || true
    # Dar prioridad exclusiva al servidor nativo de notificaciones de Quickshell
    systemctl --user stop dunst.service 2>/dev/null || true
    systemctl --user mask dunst.service 2>/dev/null || true
    # Configurar systemd-logind para que delegue la tecla de encendido y tapa a Hyprland / Quickshell
    if [ -d "/etc/systemd" ]; then
        sudo mkdir -p /etc/systemd/logind.conf.d
        sudo tee /etc/systemd/logind.conf.d/lid.conf >/dev/null << 'LOGIND_LID'
[Login]
HandlePowerKey=ignore
HandlePowerKeyLongPress=poweroff
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
LidSwitchIgnoreInhibited=no
LOGIND_LID
        sudo systemctl kill -s HUP systemd-logind 2>/dev/null || true
    fi
fi

# Añadir usuario a grupos de cámara y escáner/impresora si existe
sudo usermod -aG video,lp,scanner "$USER" 2>/dev/null || true

# ------------------------------------------------------------------------------
# 7. Configuración de Shell Zsh, Oh My Zsh y Prompt Starship
# ------------------------------------------------------------------------------
echo -e "${YELLOW}[7/11] Configurando Zsh, Oh My Zsh y Starship...${NC}"

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

# 1.1 Instalar configuración de Fastfetch con pato.gif
mkdir -p "$USER_HOME/.config/fastfetch"
if [ -d "$REPO_DIR/fastfetch" ]; then
    cp -af "$REPO_DIR/fastfetch/." "$USER_HOME/.config/fastfetch/"
    echo -e "  -> Configuración de Fastfetch y pato.gif instalados en ~/.config/fastfetch/"
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
    # Deshabilitar tema de Oh My Zsh para dar prioridad a Starship
    sed -i 's/^ZSH_THEME=".*"/ZSH_THEME=""/' "$ZSHRC"

    # Habilitar plugins si existen
    if grep -q '^plugins=' "$ZSHRC"; then
        sed -i 's/^plugins=(.*)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$ZSHRC"
    fi

    # Asegurar ~/.local/bin y ~/.opencode/bin en PATH
    if ! grep -q '\.local/bin' "$ZSHRC"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$ZSHRC"
    fi
    if ! grep -q '\.opencode/bin' "$ZSHRC"; then
        echo 'export PATH="$HOME/.opencode/bin:$PATH"' >> "$ZSHRC"
    fi

    # Activar Starship Prompt
    if ! grep -q 'starship init zsh' "$ZSHRC"; then
        echo '' >> "$ZSHRC"
        echo '# Inicialización de Starship Prompt' >> "$ZSHRC"
        echo 'export STARSHIP_CONFIG="$HOME/.config/starship.toml"' >> "$ZSHRC"
        echo 'eval "$(starship init zsh)"' >> "$ZSHRC"
    fi
    echo -e "${GREEN}[OK] ~/.zshrc configurado con Oh My Zsh y Starship.${NC}"
fi

# 5. Configurar Seamless Login en ~/.zprofile para inicio automático en tty1 con zsh
ZPROFILE="$USER_HOME/.zprofile"
if ! grep -q 'start-hyprland' "$ZPROFILE" 2>/dev/null && ! grep -q 'exec Hyprland' "$ZPROFILE" 2>/dev/null; then
    cat << 'HOOK' >> "$ZPROFILE"

# Auto-start Hyprland en tty1 (Seamless Login)
export BROWSER=zen-browser
export DEFAULT_BROWSER=zen-browser
if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    if command -v start-hyprland >/dev/null 2>&1; then
        exec start-hyprland
    else
        exec Hyprland
    fi
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
echo -e "${YELLOW}[8/11] Inicializando tema y sincronización...${NC}"

# Inicializar con Default
if [ -f "$REPO_DIR/scripts/theme_manager.py" ]; then
    python3 "$REPO_DIR/scripts/theme_manager.py" set default >/dev/null 2>&1 || true
    echo -e "${GREEN}[OK] Tema 'default' sincronizado correctamente.${NC}"
fi

# ------------------------------------------------------------------------------
# 9. Configuración de Seamless Login
# ------------------------------------------------------------------------------
echo -e "${YELLOW}[9/11] Configurando Seamless Login...${NC}"

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
if ! grep -q 'start-hyprland' "$BASH_PROFILE" 2>/dev/null && ! grep -q 'exec Hyprland' "$BASH_PROFILE" 2>/dev/null; then
    cat << 'HOOK' >> "$BASH_PROFILE"

# Auto-start Hyprland en tty1 (Seamless Login)
export BROWSER=zen-browser
export DEFAULT_BROWSER=zen-browser
if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    if command -v start-hyprland >/dev/null 2>&1; then
        exec start-hyprland
    else
        exec Hyprland
    fi
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
echo -e "${YELLOW}[10/11] Desinstalando GNOME Desktop y GDM del sistema...${NC}"

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

# ------------------------------------------------------------------------------
# 11. Herramientas de Desarrollo con IA: OpenCode & Antigravity CLI
# ------------------------------------------------------------------------------
echo -e "${YELLOW}[11/11] Instalando herramientas de IA (OpenCode & Antigravity CLI)...${NC}"

echo -e "  -> Instalando OpenCode..."
curl -fsSL https://opencode.ai/install | bash 2>/dev/null || {
    echo -e "     ${YELLOW}Aviso: Falló la descarga de OpenCode o no hay conexión a internet disponible.${NC}"
}

echo -e "  -> Instalando Antigravity CLI..."
curl -fsSL https://antigravity.google/cli/install.sh | bash 2>/dev/null || {
    echo -e "     ${YELLOW}Aviso: Falló la descarga de Antigravity CLI o no hay conexión a internet disponible.${NC}"
}

# Crear enlace simbólico antigravity -> agy para soporte de ambos comandos
if [ -f "$USER_HOME/.local/bin/agy" ]; then
    ln -sf "$USER_HOME/.local/bin/agy" "$USER_HOME/.local/bin/antigravity" 2>/dev/null || true
    echo -e "  -> Enlace creado: ${CYAN}antigravity -> agy${NC}"
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
    systemctl --user stop quickshell.service 2>/dev/null || true
    pkill -f "quickshell_.*\.toggle" 2>/dev/null || true
    pkill -f "quickshell_.*\.set" 2>/dev/null || true
    sleep 1
    systemd-run --user --unit=quickshell --slice=app.slice quickshell -p "$REPO_DIR" 2>/dev/null || {
        nohup quickshell -p "$REPO_DIR" >/dev/null 2>&1 &
    }
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
  • ${BOLD}SUPER + Esc / M${NC}          : Menú de apagado, reinicio, suspensión y sesión
  • ${BOLD}SUPER + N${NC}              : Centro y panel lateral de notificaciones (historial, silenciar, copiar)
  • ${BOLD}SUPER + Shift + W${NC}      : Selector de fondos de pantalla
  • ${BOLD}SUPER + Shift + T${NC}      : Selector de temas de color
  • ${BOLD}SUPER + Shift + Flechas${NC}: Mover ventanas de posición
  • ${BOLD}SUPER + E${NC}              : Explorador de archivos (Dolphin)
  • ${BOLD}Zsh + Starship Prompt${NC}  : Shell interactiva con Oh My Zsh y diseño Demonc"
echo ""
echo -e "  • ${CYAN}Seamless Login${NC}       : Arrancará directamente a Hyprland sin pantalla de GDM."
echo -e "  • ${CYAN}Bloqueo por Inactividad${NC}: 'hypridle' atenuará a los 5m y bloqueará a los 10m."
echo -e "  • ${CYAN}Herramientas IA Dev${NC}    : 'opencode' y 'antigravity' (agy) listas para usar."
echo ""
echo -e "  Comandos disponibles en terminal: ${CYAN}shell-apps${NC}, ${CYAN}shell-theme${NC}, ${CYAN}shell-wallpaper${NC}, ${CYAN}shell-bar${NC}, ${CYAN}shell-power${NC}, ${CYAN}shell-notifications${NC}, ${CYAN}opencode${NC}, ${CYAN}antigravity${NC}"
echo ""
