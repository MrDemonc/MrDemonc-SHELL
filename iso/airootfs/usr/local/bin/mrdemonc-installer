#!/usr/bin/env bash
# ==============================================================================
#  MrDemonc-SHELL: Instalador Automatizado desde Arch Linux ISO (Live USB)
# ==============================================================================
#  Características:
#    • Asistente interactivo de red Wi-Fi (redes visibles y OCULTAS)
#    • Selección interactiva de idioma del sistema y distribución de teclado
#    • Configuración de usuario Git y Hostname
#    • Cifrado automático de disco completo con LUKS2 (Argon2id)
#    • Contraseña maestra unificada (Cifrado LUKS + Root + Usuario sudo)
#    • Sistema de archivos BTRFS con subvolúmenes optimizados (@, @home, etc.)
#    • Gestor de arranque UEFI rápido (systemd-boot)
#    • Seamless Login directo a Hyprland (sin gestor de sesiones GDM)
#    • Shell Zsh + Oh My Zsh + Starship prompt personalizado
#    • Entorno de escritorio MrDemonc-SHELL (Hyprland + Quickshell)
# ==============================================================================

set -eo pipefail

# Colores de terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

clear
echo -e "${CYAN}${BOLD}"
cat << 'BANNER'
  __  __       _____                                    _____ _    _ ______ _      _      
 |  \/  |     |  __ \                                  / ____| |  | |  ____| |    | |     
 | \  / |_ __ | |  | | ___ _ __ ___   ___  _ __   ___ | (___ | |__| | |__  | |    | |     
 | |\/| | '__|| |  | |/ _ \ '_ ` _ \ / _ \| '_ \ / __| \___ \|  __  |  __| | |    | |     
 | |  | | |   | |__| |  __/ | | | | | (_) | | | | (__  ____) | |  | | |____| |____| |____ 
 |_|  |_|_|   |_____/ \___|_| |_| |_|\___/|_| |_|\___||_____/|_|  |_|______|______|______|
BANNER
echo "========================================================================"
echo "    ¡BIENVENIDO AL INSTALADOR AUTOMATIZADO DE ARCH LINUX + MrDemonc!    "
echo "========================================================================"
echo -e "${NC}"
echo -e "  Este asistente configurará tu conexión Wi-Fi, tu disco con BTRFS cifrado"
echo -e "  automáticamente con LUKS2, y desplegará el sistema completo con Seamless"
echo -e "  Login a Hyprland, Zsh y el prompt Starship."
echo ""

# ------------------------------------------------------------------------------
# 1. Verificaciones del Entorno de Ejecución (Live ISO)
# ------------------------------------------------------------------------------
echo -e "${YELLOW}[1/9] Verificando modo de arranque UEFI...${NC}"

# Verificar permisos de root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}[ERROR] Este instalador debe ejecutarse como root desde la ISO de Arch Linux.${NC}"
    exit 1
fi

# Verificar modo UEFI
if [ ! -d "/sys/firmware/efi/efivars" ]; then
    echo -e "${RED}[ERROR] El sistema no arrancó en modo UEFI. Por favor configura tu BIOS en modo UEFI.${NC}"
    exit 1
else
    echo -e "  ${GREEN}[OK]${NC} Modo UEFI verificado correctamente."
fi

# Sincronizar reloj del sistema
timedatectl set-ntp true 2>/dev/null || true

# ------------------------------------------------------------------------------
# 2. Asistente de Conectividad a Internet (Wi-Fi, Redes Ocultas, Ethernet)
# ------------------------------------------------------------------------------
echo ""
echo -e "${YELLOW}[2/9] Configuración de Red e Internet...${NC}"

configure_network_wizard() {
    # Iniciar NetworkManager e iwd si están disponibles
    if command -v systemctl >/dev/null 2>&1; then
        systemctl start NetworkManager 2>/dev/null || true
        systemctl start iwd 2>/dev/null || true
    fi
    rfkill unblock all 2>/dev/null || true
    nmcli radio wifi on 2>/dev/null || true

    while true; do
        echo ""
        echo -e "  Comprobando estado de conexión a Internet..."
        if ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1 || ping -c 1 -W 2 archlinux.org >/dev/null 2>&1; then
            echo -e "  ${GREEN}${BOLD}[OK] ¡Conexión a Internet activa y funcionando!${NC}"
            echo ""
            read -r -p "  ¿Continuar con la instalación? [S/n] (o escribe 'r' para configurar otra red): " NET_CHOICE
            if [[ "$NET_CHOICE" =~ ^[nN]$ ]] || [[ "$NET_CHOICE" =~ ^[rR]$ ]]; then
                : # Muestra el menú de redes
            else
                return 0
            fi
        else
            echo -e "  ${RED}[AVISO] No se detecta acceso a Internet actualmente.${NC}"
        fi

        echo ""
        echo -e "  ${CYAN}${BOLD}Opciones de Conexión a Internet:${NC}"
        echo -e "    ${BOLD}1)${NC} 📡 Escanear y conectar a una red Wi-Fi visible"
        echo -e "    ${BOLD}2)${NC} 🔒 Conectar a una red Wi-Fi ${MAGENTA}${BOLD}OCULTA${NC} (Hidden SSID)"
        echo -e "    ${BOLD}3)${NC} 🌐 Probar conexión por cable Ethernet (DHCP)"
        echo -e "    ${BOLD}4)${NC} ⌨️  Abrir consola manual Wi-Fi ('iwctl')"
        echo -e "    ${BOLD}5)${NC} ⏩ Continuar de todas formas (Modo offline / Manual)"
        echo ""
        read -r -p "  Elige una opción [1-5]: " NET_OPT

        case "$NET_OPT" in
            1)
                echo ""
                echo -e "  ${BLUE}[INFO]${NC} Escaneando redes Wi-Fi cercanas..."
                if command -v nmcli >/dev/null 2>&1; then
                    nmcli dev wifi rescan 2>/dev/null || true
                    sleep 1
                    echo ""
                    nmcli --colors yes -f IN-USE,SSID,SIGNAL,BARS,SECURITY device wifi list 2>/dev/null || true
                    echo ""
                    read -r -p "  Introduce el nombre (SSID) de tu red Wi-Fi: " WIFI_SSID
                    if [ -n "$WIFI_SSID" ]; then
                        read -s -r -p "  Introduce la contraseña de '$WIFI_SSID': " WIFI_PASS
                        echo ""
                        echo -e "  Conectando a ${BOLD}$WIFI_SSID${NC}..."
                        if [ -n "$WIFI_PASS" ]; then
                            nmcli dev wifi connect "$WIFI_SSID" password "$WIFI_PASS" || {
                                echo -e "  ${RED}[ERROR] Falló la conexión a $WIFI_SSID. Revisa la contraseña.${NC}"
                            }
                        else
                            nmcli dev wifi connect "$WIFI_SSID" || true
                        fi
                    fi
                elif command -v iwctl >/dev/null 2>&1; then
                    WLAN_DEV=$(iwctl device list 2>/dev/null | awk '/station/ {print $2}' | head -n 1)
                    WLAN_DEV="${WLAN_DEV:-wlan0}"
                    echo -e "  Escaneando con iwctl en $WLAN_DEV..."
                    iwctl station "$WLAN_DEV" scan 2>/dev/null || true
                    sleep 1
                    iwctl station "$WLAN_DEV" get-networks 2>/dev/null || true
                    echo ""
                    read -r -p "  Introduce el nombre (SSID) de la red: " WIFI_SSID
                    if [ -n "$WIFI_SSID" ]; then
                        iwctl station "$WLAN_DEV" connect "$WIFI_SSID" || true
                    fi
                fi
                sleep 2
                ;;

            2)
                echo ""
                echo -e "  ${MAGENTA}${BOLD}=== CONECTAR A RED WI-FI OCULTA ===${NC}"
                read -r -p "  Introduce el nombre exacto de la red oculta (SSID): " HIDDEN_SSID
                if [ -z "$HIDDEN_SSID" ]; then
                    echo -e "  ${RED}El nombre SSID no puede estar vacío.${NC}"
                    continue
                fi
                read -s -r -p "  Introduce la contraseña (deja vacío si es abierta): " HIDDEN_PASS
                echo ""

                echo -e "  Conectando a red oculta ${BOLD}$HIDDEN_SSID${NC}..."
                if command -v nmcli >/dev/null 2>&1; then
                    if [ -n "$HIDDEN_PASS" ]; then
                        nmcli dev wifi connect "$HIDDEN_SSID" password "$HIDDEN_PASS" hidden yes || {
                            echo -e "  ${YELLOW}Solicitando escaneo de SSID específico y reintentando...${NC}"
                            nmcli dev wifi rescan ssid "$HIDDEN_SSID" 2>/dev/null || true
                            sleep 1
                            nmcli dev wifi connect "$HIDDEN_SSID" password "$HIDDEN_PASS" hidden yes || true
                        }
                    else
                        nmcli dev wifi connect "$HIDDEN_SSID" hidden yes || true
                    fi
                elif command -v iwctl >/dev/null 2>&1; then
                    WLAN_DEV=$(iwctl device list 2>/dev/null | awk '/station/ {print $2}' | head -n 1)
                    WLAN_DEV="${WLAN_DEV:-wlan0}"
                    if [ -n "$HIDDEN_PASS" ]; then
                        iwctl --passphrase "$HIDDEN_PASS" station "$WLAN_DEV" connect-hidden "$HIDDEN_SSID" || true
                    else
                        iwctl station "$WLAN_DEV" connect-hidden "$HIDDEN_SSID" || true
                    fi
                fi
                sleep 2
                ;;

            3)
                echo -e "  Solicitando IP por DHCP en interfaces de red..."
                dhcpcd 2>/dev/null || true
                sleep 2
                ;;

            4)
                echo ""
                echo -e "  ${CYAN}Abriendo consola 'iwctl'. Cuando termines, escribe 'exit' para volver.${NC}"
                iwctl || true
                ;;

            5)
                echo -e "  ${YELLOW}Continuando sin verificar conexión...${NC}"
                return 0
                ;;
        esac
    done
}

configure_network_wizard

# ------------------------------------------------------------------------------
# 3. Parámetros de Instalación, Idioma, Teclado, Git y Usuario
# ------------------------------------------------------------------------------
echo ""
echo -e "${YELLOW}[3/9] Parámetros del Sistema, Idioma, Teclado y Usuario...${NC}"

# A. Selección de Idioma del Sistema (Locale)
echo ""
echo -e "  ${CYAN}${BOLD}Selecciona el Idioma del Sistema:${NC}"
echo -e "    1) Español (España)          [es_ES.UTF-8] (Predeterminado)"
echo -e "    2) Español (Latinoamérica)   [es_MX.UTF-8]"
echo -e "    3) Español (Perú)            [es_PE.UTF-8]"
echo -e "    4) Español (Argentina)       [es_AR.UTF-8]"
echo -e "    5) Español (Chile)           [es_CL.UTF-8]"
echo -e "    6) Español (Colombia)        [es_CO.UTF-8]"
echo -e "    7) English (United States)   [en_US.UTF-8]"
read -r -p "  Selecciona una opción [1-7] (Enter para Español España): " LANG_OPT

case "$LANG_OPT" in
    2) SYS_LOCALE="es_MX.UTF-8" ;;
    3) SYS_LOCALE="es_PE.UTF-8" ;;
    4) SYS_LOCALE="es_AR.UTF-8" ;;
    5) SYS_LOCALE="es_CL.UTF-8" ;;
    6) SYS_LOCALE="es_CO.UTF-8" ;;
    7) SYS_LOCALE="en_US.UTF-8" ;;
    *) SYS_LOCALE="es_ES.UTF-8" ;;
esac
echo -e "  ${GREEN}[OK]${NC} Idioma configurado: ${BOLD}$SYS_LOCALE${NC}"

# B. Distribución de teclado en consola y Hyprland
echo ""
echo -e "  ${CYAN}${BOLD}Selecciona la Distribución de Teclado:${NC}"
echo -e "    1) Latinoamericano (la-latin1 / latam) [Predeterminado]"
echo -e "    2) Español España (es)"
echo -e "    3) Inglés / US (us)"
read -r -p "  Selecciona una opción [1-3] (Enter para Latinoamericano): " KB_OPT

case "$KB_OPT" in
    2)
        KEYMAP="es"
        HYPR_KB="es"
        ;;
    3)
        KEYMAP="us"
        HYPR_KB="us"
        ;;
    *)
        KEYMAP="la-latin1"
        HYPR_KB="latam"
        ;;
esac
loadkeys "$KEYMAP" 2>/dev/null || true
echo -e "  ${GREEN}[OK]${NC} Teclado activo: ${BOLD}$KEYMAP${NC} (Hyprland: ${BOLD}$HYPR_KB${NC})"

# C. Nombre del equipo (Hostname)
echo ""
read -r -p "  Nombre del equipo / Hostname [archlinux]: " SYS_HOSTNAME
SYS_HOSTNAME="${SYS_HOSTNAME:-archlinux}"

# D. Configuración de Usuario Git
echo ""
echo -e "  ${CYAN}${BOLD}Configuración de Git:${NC}"
read -r -p "  Nombre de usuario para Git (ej: MrDemonc): " GIT_USER_NAME
read -r -p "  Correo electrónico para Git (ej: mrdemonlich@gmail.com): " GIT_USER_EMAIL

# E. Selección del disco de almacenamiento
echo ""
echo -e "${CYAN}${BOLD}Discos de almacenamiento detectados:${NC}"
lsblk -d -p -n -l -o NAME,SIZE,MODEL,TYPE | grep -E "disk" || lsblk
echo ""
read -r -p "  Introduce el disco objetivo (ej: /dev/sda o /dev/nvme0n1): " TARGET_DISK

if [ ! -b "$TARGET_DISK" ]; then
    echo -e "${RED}[ERROR] El dispositivo '$TARGET_DISK' no es un disco válido.${NC}"
    exit 1
fi

echo -e "${RED}${BOLD}"
echo "  ¡ADVERTENCIA CRÍTICA! Todos los datos en $TARGET_DISK serán eliminados permanentemente."
echo -e "${NC}"
read -r -p "  Escribe 'SI' (en mayúsculas) para confirmar el formateo: " CONFIRM_DISCO
if [ "$CONFIRM_DISCO" != "SI" ]; then
    echo -e "${YELLOW}[CANCELADO] Instalación abortada por el usuario.${NC}"
    exit 0
fi

# F. Usuario y Clave Maestra (Unificada para LUKS + Root + Usuario)
echo ""
echo -e "${MAGENTA}${BOLD}========================================================================${NC}"
echo -e "${MAGENTA}${BOLD}         CONFIGURACIÓN DE USUARIO Y CLAVE MAESTRA UNIFICADA             ${NC}"
echo -e "${MAGENTA}${BOLD}========================================================================${NC}"
echo -e "  El disco se cifrará automáticamente con ${BOLD}LUKS2 (Argon2id)${NC} estilo Omarchy."
echo -e "  La ${BOLD}Contraseña Maestra${NC} que definas se aplicará automáticamente a:"
echo -e "    1. 🔒 Desbloqueo del disco cifrado al encender la PC"
echo -e "    2. 🔑 Superusuario root"
echo -e "    3. 👤 Tu usuario personal y comandos sudo"
echo ""
read -r -p "  Nombre de tu usuario [demonc]: " SYS_USER
SYS_USER="${SYS_USER:-demonc}"

while true; do
    read -s -r -p "  Introduce la Contraseña Maestra: " P1
    echo ""
    read -s -r -p "  Confirma la Contraseña Maestra: " P2
    echo ""
    if [ -n "$P1" ] && [ "$P1" == "$P2" ]; then
        MASTER_PASS="$P1"
        break
    else
        echo -e "  ${RED}Las contraseñas no coinciden o están vacías. Inténtalo de nuevo.${NC}"
    fi
done
echo -e "  ${GREEN}[OK]${NC} Clave Maestra configurada para Cifrado LUKS, Root y $SYS_USER."

# G. Zona horaria
echo ""
read -r -p "  Zona horaria (ej: America/Lima, America/Santiago, America/Mexico_City) [America/Lima]: " SYS_TIMEZONE
SYS_TIMEZONE="${SYS_TIMEZONE:-America/Lima}"

# ------------------------------------------------------------------------------
# 4. Particionado y Cifrado Automático con LUKS2
# ------------------------------------------------------------------------------
echo ""
echo -e "${YELLOW}[4/9] Particionando y cifrando disco ($TARGET_DISK)...${NC}"

# Desmontar puntos de montaje previos si existen
swapoff -a 2>/dev/null || true
umount -R /mnt 2>/dev/null || true
cryptsetup close cryptroot 2>/dev/null || true

# Limpieza total de tablas de particiones
sgdisk --zap-all "$TARGET_DISK" >/dev/null 2>&1 || true
wipefs -a "$TARGET_DISK" >/dev/null 2>&1 || true
partprobe "$TARGET_DISK" 2>/dev/null || true
sleep 1

# Partición 1: EFI System Partition (ESP) de 1024MB
sgdisk -n 1:0:+1024M -t 1:ef00 -c 1:"EFI System Partition" "$TARGET_DISK"
# Partición 2: Partición Cifrada Linux (Resto del disco)
sgdisk -n 2:0:0 -t 2:8300 -c 2:"Linux LUKS Btrfs" "$TARGET_DISK"

partprobe "$TARGET_DISK" 2>/dev/null || true
sleep 1

# Determinar nombres de particiones (ej: sda1 vs nvme0n1p1)
if [[ "$TARGET_DISK" =~ [0-9]$ ]]; then
    PART_EFI="${TARGET_DISK}p1"
    PART_ROOT="${TARGET_DISK}p2"
else
    PART_EFI="${TARGET_DISK}1"
    PART_ROOT="${TARGET_DISK}2"
fi

echo -e "  Partición EFI : ${BOLD}$PART_EFI${NC}"
echo -e "  Partición Root: ${BOLD}$PART_ROOT${NC}"

# Formatear partición EFI (FAT32)
echo -e "  Formateando partición EFI..."
mkfs.fat -F 32 -n EFI "$PART_EFI" >/dev/null

# Cifrado automático con LUKS2 y derivación Argon2id
echo -e "  Creando contenedor cifrado LUKS2 (Argon2id)..."
echo -n "$MASTER_PASS" | cryptsetup luksFormat --type luks2 --pbkdf argon2id --batch-mode "$PART_ROOT" -
echo -e "  Desbloqueando contenedor cifrado..."
echo -n "$MASTER_PASS" | cryptsetup open "$PART_ROOT" cryptroot -

ROOT_DEV="/dev/mapper/cryptroot"

# ------------------------------------------------------------------------------
# 5. Formateo y Estructura de Subvolúmenes BTRFS
# ------------------------------------------------------------------------------
echo ""
echo -e "${YELLOW}[5/9] Creando sistema de archivos BTRFS y subvolúmenes...${NC}"

# Formatear contenedor con Btrfs
mkfs.btrfs -f -L ARCHROOT "$ROOT_DEV" >/dev/null

# Montar temporalmente para crear los subvolúmenes recomendados
mount "$ROOT_DEV" /mnt
btrfs subvolume create /mnt/@ >/dev/null
btrfs subvolume create /mnt/@home >/dev/null
btrfs subvolume create /mnt/@snapshots >/dev/null
btrfs subvolume create /mnt/@var_log >/dev/null
btrfs subvolume create /mnt/@pkg >/dev/null
umount /mnt

# Montar subvolúmenes con optimizaciones BTRFS (zstd, noatime, space_cache)
BTRFS_MOUNT_OPTS="noatime,compress=zstd,space_cache=v2"

mount -o "$BTRFS_MOUNT_OPTS,subvol=@" "$ROOT_DEV" /mnt
mkdir -p /mnt/{home,.snapshots,var/log,var/cache/pacman/pkg,boot}

mount -o "$BTRFS_MOUNT_OPTS,subvol=@home" "$ROOT_DEV" /mnt/home
mount -o "$BTRFS_MOUNT_OPTS,subvol=@snapshots" "$ROOT_DEV" /mnt/.snapshots
mount -o "$BTRFS_MOUNT_OPTS,subvol=@var_log" "$ROOT_DEV" /mnt/var/log
mount -o "$BTRFS_MOUNT_OPTS,subvol=@pkg" "$ROOT_DEV" /mnt/var/cache/pacman/pkg

# Montar partición EFI en /boot
mount "$PART_EFI" /mnt/boot

echo -e "  ${GREEN}[OK]${NC} Estructura BTRFS (@, @home, @snapshots, @var_log, @pkg) montada exitosamente."

# ------------------------------------------------------------------------------
# 6. Instalación del Sistema Base con pacstrap
# ------------------------------------------------------------------------------
echo ""
echo -e "${YELLOW}[6/9] Instalando paquetes base de Arch Linux (pacstrap)...${NC}"

# Detectar microcódigo de CPU
UCODE_PKG=""
if grep -q "AuthenticAMD" /proc/cpuinfo; then
    UCODE_PKG="amd-ucode"
    echo -e "  Detectado procesador AMD (instalando $UCODE_PKG)..."
elif grep -q "GenuineIntel" /proc/cpuinfo; then
    UCODE_PKG="intel-ucode"
    echo -e "  Detectado procesador Intel (instalando $UCODE_PKG)..."
fi

BASE_PACKAGES=(
    base
    base-devel
    linux
    linux-firmware
    linux-headers
    btrfs-progs
    cryptsetup
    networkmanager
    sudo
    git
    zsh
    starship
    curl
    wget
    nano
    neovim
    kitty
    dolphin
    ttf-jetbrains-mono-nerd
    pipewire
    wireplumber
    libpulse
    playerctl
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
    python
    dosfstools
    efibootmgr
    e2fsprogs
)

if [ -n "$UCODE_PKG" ]; then
    BASE_PACKAGES+=("$UCODE_PKG")
fi

pacstrap -K /mnt "${BASE_PACKAGES[@]}"

# Generar archivo fstab con UUIDs
echo -e "  Generando /etc/fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

echo -e "  ${GREEN}[OK]${NC} Sistema base y fstab listos."

# ------------------------------------------------------------------------------
# 7. Configuración del Sistema en Chroot
# ------------------------------------------------------------------------------
echo ""
echo -e "${YELLOW}[7/9] Configurando idioma, teclado, usuarios, Git, mkinitcpio y bootloader...${NC}"

# Obtener UUID de la partición física cifrada root
ROOT_UUID=$(blkid -s UUID -o value "$PART_ROOT")

# Opciones de arranque para systemd-boot con BTRFS y LUKS
BOOT_ENTRY_OPTIONS="cryptdevice=UUID=$ROOT_UUID:cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rw quiet splash"
MKINITCPIO_HOOKS="base udev autodetect modconf kms keyboard keymap consolefont block encrypt btrfs filesystems fsck"

UCODE_LINE=""
if [ -n "$UCODE_PKG" ]; then
    UCODE_LINE="initrd  /$UCODE_PKG.img"
fi

cat << CHROOT_SCRIPT > /mnt/tmp/setup_chroot.sh
#!/usr/bin/env bash
set -e

# Zona horaria y reloj
ln -sf /usr/share/zoneinfo/$SYS_TIMEZONE /etc/localtime
hwclock --systohc

# Idioma y locales seleccionados
sed -i "s/#$SYS_LOCALE UTF-8/$SYS_LOCALE UTF-8/" /etc/locale.gen
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen 2>/dev/null || true
locale-gen
echo "LANG=$SYS_LOCALE" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

# Nombre de equipo y hosts
echo "$SYS_HOSTNAME" > /etc/hostname
cat << HOSTS > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   $SYS_HOSTNAME.localdomain $SYS_HOSTNAME
HOSTS

# Contraseña de Root (Clave Maestra)
echo "root:$MASTER_PASS" | chpasswd

# Crear usuario principal con shell Zsh y Clave Maestra
useradd -m -g users -G wheel,video,audio,storage,optical,network -s /usr/bin/zsh "$SYS_USER"
echo "$SYS_USER:$MASTER_PASS" | chpasswd

# Permitir a wheel usar sudo
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel
chmod 440 /etc/sudoers.d/wheel

# Concesión temporal NOPASSWD para scripts de instalación
echo "$SYS_USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/installer_nopasswd
chmod 440 /etc/sudoers.d/installer_nopasswd

# Configurar Git para el usuario
if [ -n "$GIT_USER_NAME" ]; then
    su - "$SYS_USER" -c "git config --global user.name '$GIT_USER_NAME'"
fi
if [ -n "$GIT_USER_EMAIL" ]; then
    su - "$SYS_USER" -c "git config --global user.email '$GIT_USER_EMAIL'"
fi
su - "$SYS_USER" -c "git config --global init.defaultBranch main" 2>/dev/null || true

# Configurar mkinitcpio para LUKS y BTRFS
sed -i "s/^HOOKS=(.*)/HOOKS=($MKINITCPIO_HOOKS)/" /etc/mkinitcpio.conf
mkinitcpio -P

# Instalar y configurar systemd-boot (UEFI)
bootctl install

cat << LOADER > /boot/loader/loader.conf
default arch.conf
timeout 3
console-mode max
editor no
LOADER

cat << ENTRY > /boot/loader/entries/arch.conf
title   MrDemonc-SHELL (Arch Linux Btrfs)
linux   /vmlinuz-linux
$UCODE_LINE
initrd  /initramfs-linux.img
options $BOOT_ENTRY_OPTIONS
ENTRY

# Habilitar servicios esenciales
systemctl enable NetworkManager.service
systemctl enable bluetooth.service 2>/dev/null || true

# Configurar Seamless Login directo en tty1
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat << AUTOLOGIN > /etc/systemd/system/getty@tty1.service.d/autologin.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $SYS_USER --noclear %I \$TERM
Type=idle
AUTOLOGIN

# Añadir hook de autostart a ~/.zprofile y ~/.bash_profile del usuario
for prof in /home/$SYS_USER/.zprofile /home/$SYS_USER/.bash_profile; do
    cat << 'HOOK' >> "\$prof"

# Auto-start Hyprland en tty1 (Seamless Login estilo Omarchy)
if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec Hyprland
fi
HOOK
    chown $SYS_USER:users "\$prof"
done

CHROOT_SCRIPT

chmod +x /mnt/tmp/setup_chroot.sh
arch-chroot /mnt /tmp/setup_chroot.sh
rm -f /mnt/tmp/setup_chroot.sh

echo -e "  ${GREEN}[OK]${NC} Configuración chroot terminada."

# ------------------------------------------------------------------------------
# 8. Despliegue de MrDemonc-SHELL y Paquetes AUR
# ------------------------------------------------------------------------------
echo ""
echo -e "${YELLOW}[8/9] Desplegando repositorio MrDemonc-SHELL y entorno Hyprland...${NC}"

cat << USER_SETUP > /mnt/tmp/setup_user.sh
#!/usr/bin/env bash
set -e
USER_HOME="/home/$SYS_USER"
DOCS_DIR="\$USER_HOME/Documentos"
mkdir -p "\$DOCS_DIR"

# 1. Clonar el repositorio de MrDemonc-SHELL
echo "Clonando MrDemonc-SHELL..."
if [ ! -d "\$DOCS_DIR/MrDemonc-SHELL" ]; then
    git clone https://github.com/MrDemonc/MrDemonc-SHELL.git "\$DOCS_DIR/MrDemonc-SHELL"
fi
cd "\$DOCS_DIR/MrDemonc-SHELL"

# 2. Configurar distribución de teclado elegida en hyprland.lua
if [ -f "hypr/hyprland.lua" ]; then
    sed -i "s/kb_layout  = \".*\"/kb_layout  = \"$HYPR_KB\"/g" hypr/hyprland.lua
fi

# 3. Instalar paru-bin para compilar/instalar paquetes AUR
echo "Instalando helper de AUR (paru-bin)..."
mkdir -p /tmp/paru-build
git clone https://aur.archlinux.org/paru-bin.git /tmp/paru-build
(cd /tmp/paru-build && makepkg -si --noconfirm)
rm -rf /tmp/paru-build

# 4. Instalar quickshell y dependencias de Hyprland desde AUR
echo "Instalando quickshell..."
paru -S --needed --noconfirm quickshell hyprlock hypridle

# 5. Ejecutar el instalador automatizado del entorno
echo "Ejecutando instalación modular de MrDemonc-SHELL..."
chmod +x install.sh
./install.sh

# 6. Limpieza de sudo temporal
sudo rm -f /etc/sudoers.d/installer_nopasswd

USER_SETUP

chmod +x /mnt/tmp/setup_user.sh
# Ejecutar como el usuario normal usando 'su' dentro del chroot
arch-chroot /mnt su - "$SYS_USER" -c "/tmp/setup_user.sh" || {
    echo -e "${YELLOW}[AVISO] La compilación en chroot requirió omitir algunos pasos de entorno gráfico.${NC}"
}
rm -f /mnt/tmp/setup_user.sh

# Asegurar eliminación del sudoers temporal en caso de fallo
rm -f /mnt/etc/sudoers.d/installer_nopasswd 2>/dev/null || true

# ------------------------------------------------------------------------------
# 9. Desmontaje y Finalización
# ------------------------------------------------------------------------------
echo ""
echo -e "${YELLOW}[9/9] Desmontando sistemas de archivos y finalizando...${NC}"

umount -R /mnt 2>/dev/null || true
cryptsetup close cryptroot 2>/dev/null || true

echo ""
echo -e "${GREEN}${BOLD}========================================================================"
echo "         ¡INSTALACIÓN DE MrDemonc-SHELL COMPLETADA CON ÉXITO!           "
echo "========================================================================"
echo -e "${NC}"
echo -e "  • ${BOLD}Disco:${NC}             Instalado en ${BOLD}$TARGET_DISK${NC}"
echo -e "  • ${BOLD}Sistema Archivos:${NC}  ${CYAN}BTRFS con subvolúmenes (@, @home, @snapshots)${NC}"
echo -e "  • ${BOLD}Seguridad:${NC}         Cifrado de disco completo con ${MAGENTA}LUKS2 (Argon2id)${NC}"
echo -e "  • ${BOLD}Clave Maestra:${NC}     Unificada (Desbloqueo de disco + Root + $SYS_USER)"
echo -e "  • ${BOLD}Arranque:${NC}          systemd-boot (UEFI) con Seamless Login a Hyprland"
echo -e "  • ${BOLD}Idioma & Teclado:${NC}  $SYS_LOCALE / $KEYMAP (Hyprland: $HYPR_KB)"
echo -e "  • ${BOLD}Equipo (Hostname):${NC} $SYS_HOSTNAME"
if [ -n "$GIT_USER_NAME" ]; then
echo -e "  • ${BOLD}Git Configurado:${NC}   $GIT_USER_NAME <$GIT_USER_EMAIL>"
fi
echo -e "  • ${BOLD}Shell:${NC}             Zsh con Oh My Zsh y Starship prompt (${BOLD}Demonc${NC})"
echo -e "  • ${BOLD}Usuario:${NC}           ${CYAN}$SYS_USER${NC}"
echo ""
echo -e "  ${BOLD}Pasos para iniciar tu nuevo sistema:${NC}"
echo -e "    1. Retira el medio de instalación USB."
echo -e "    2. Ejecuta el comando: ${GREEN}${BOLD}reboot${NC}"
echo ""
