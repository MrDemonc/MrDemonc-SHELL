#!/usr/bin/env bash
# ==============================================================================
#  ARCH LINUX: Instalador Automatizado (Live ISO)
# ==============================================================================
#  Características:
#    • Instalación directa sin pantallas de bienvenida ni pausas artificiales
#    • Toda la configuración se aplica durante la instalación (0 pasos post-reinicio)
#    • Asistente de red Wi-Fi (redes visibles y OCULTAS)
#    • Selección de idioma del sistema (Locales) y distribución de teclado
#    • Configuración de Hostname y perfil de Git
#    • Cifrado automático de disco completo con LUKS2 (Argon2id)
#    • Contraseña maestra unificada (Cifrado LUKS + Root + Usuario sudo)
#    • Sistema de archivos BTRFS con subvolúmenes (@, @home, @snapshots, etc.)
#    • Gestor de arranque UEFI rápido (systemd-boot)
#    • Seamless Login directo a Hyprland en tty1 (sin gestor GDM)
#    • Shell Zsh + Oh My Zsh + Starship prompt personalizado
#    • Despliegue completo de MrDemonc-SHELL (Hyprland + Quickshell)
# ==============================================================================

set -eo pipefail

# ------------------------------------------------------------------------------
# 1. Colores y Estilos
# ------------------------------------------------------------------------------
ARCH_BLUE="\033[38;5;39m"
BLUE="\033[38;5;33m"
GREEN="\033[38;5;42m"
RED="\033[38;5;196m"
YELLOW="\033[38;5;220m"
MAGENTA="\033[38;5;177m"
WHITE="\033[38;5;255m"
GRAY="\033[38;5;242m"
DARK_GRAY="\033[38;5;238m"
BOLD="\033[1m"
DIM="\033[2m"
NC="\033[0m"

badge_ok()   { echo -e "  ${GREEN}${BOLD}✔ [OK]${NC} $1"; }
badge_info() { echo -e "  ${ARCH_BLUE}${BOLD}ℹ [INFO]${NC} $1"; }
badge_warn() { echo -e "  ${YELLOW}${BOLD}▲ [AVISO]${NC} $1"; }
badge_err()  { echo -e "  ${RED}${BOLD}✖ [ERROR]${NC} $1"; }
badge_sec()  { echo -e "  ${MAGENTA}${BOLD}🔒 [LUKS2]${NC} $1"; }
badge_fs()   { echo -e "  ${BLUE}${BOLD}💿 [BTRFS]${NC} $1"; }

draw_header() {
    local current_step="$1"

    clear
    echo -e "${ARCH_BLUE}${BOLD}  ARCH LINUX INSTALLER  ${GRAY}•  Btrfs + LUKS2 + Hyprland + MrDemonc${NC}"
    echo -e "${DARK_GRAY}  ────────────────────────────────────────────────────────────────────────────${NC}"

    # Barra de progreso (Stepper)
    local steps=("Red" "Idioma" "Teclado" "Host & Git" "Disco & LUKS" "Instalar" "Finalizar")
    local s_line="  "
    for i in "${!steps[@]}"; do
        local num=$((i + 1))
        local name="${steps[$i]}"
        if [ "$num" -eq "$current_step" ]; then
            s_line="${s_line}${ARCH_BLUE}${BOLD}◆ [${num}. ${name}]${NC} "
        elif [ "$num" -lt "$current_step" ]; then
            s_line="${s_line}${GREEN}✔ ${name}${NC} "
        else
            s_line="${s_line}${GRAY}${num}. ${name}${NC} "
        fi
        if [ "$num" -lt "${#steps[@]}" ]; then
            s_line="${s_line}${DARK_GRAY}──${NC} "
        fi
    done
    echo -e "$s_line"
    echo -e "${DARK_GRAY}  ────────────────────────────────────────────────────────────────────────────${NC}\n"
}

show_boot_splash() {
    clear
    echo -e "${ARCH_BLUE}"
    cat << "SPLASH"

                ╭────────────────────────────────────────╮
                │                                        │
                │    █████╗ ██████╗  ██████╗██╗  ██╗     │
                │   ██╔══██╗██╔══██╗██╔════╝██║  ██║     │
                │   ███████║██████╔╝██║     ███████║     │
                │   ██╔══██║██╔══██╗██║     ██╔══██║     │
                │   ██║  ██║██║  ██║╚██████╗██║  ██║     │
                │   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝     │
                │                                        │
                │              ARCH LINUX                │
                │                                        │
                │         Cargando instalador...         │
                │                                        │
                ╰────────────────────────────────────────╯

SPLASH
    echo -e "${NC}"
    echo -ne "                  ["
    for i in {1..20}; do
        echo -ne "${ARCH_BLUE}█${NC}"
        sleep 0.02
    done
    echo -e "]\n"
    sleep 0.4
}

# Ejecutar pantalla de carga visual (Splash)
show_boot_splash

# ------------------------------------------------------------------------------
# 2. Verificaciones Previas (Modo UEFI y Permisos)
# ------------------------------------------------------------------------------
if [ "$(id -u)" -ne 0 ]; then
    badge_err "Este instalador debe ejecutarse como root desde la ISO de Arch Linux."
    exit 1
fi

if [ ! -d "/sys/firmware/efi/efivars" ]; then
    badge_err "El sistema no arrancó en modo UEFI. Por favor configura tu BIOS en modo UEFI."
    exit 1
fi

timedatectl set-ntp true 2>/dev/null || true

# ------------------------------------------------------------------------------
# PASO 1: Asistente de Conectividad a Internet (Wi-Fi, Redes Ocultas, Ethernet)
# ------------------------------------------------------------------------------
configure_network_wizard() {
    if command -v systemctl >/dev/null 2>&1; then
        systemctl start NetworkManager 2>/dev/null || true
        systemctl start iwd 2>/dev/null || true
    fi
    rfkill unblock all 2>/dev/null || true
    nmcli radio wifi on 2>/dev/null || true

    while true; do
        draw_header 1
        local net_status="${RED}● DESCONECTADO (Se requiere internet para pacstrap)${NC}"
        local is_online=false
        if ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1 || ping -c 1 -W 2 archlinux.org >/dev/null 2>&1; then
            net_status="${GREEN}● CONECTADO A INTERNET${NC}"
            is_online=true
        fi

        echo -e "${ARCH_BLUE}╭─ Paso 1/7: Conexión a Internet y Redes ──────────────────────────────────────╮${NC}"
        echo -e "│                                                                              │"
        echo -e "│  Estado de red:  $net_status"
        echo -e "│                                                                              │"
        echo -e "│  ${BOLD}Opciones de conexión disponibles:${NC}                                           │"
        echo -e "│    ${ARCH_BLUE}${BOLD}[1]${NC}  📡 Escanear y conectar a una red Wi-Fi visible                       │"
        echo -e "│    ${ARCH_BLUE}${BOLD}[2]${NC}  🔒 Conectar a red Wi-Fi ${MAGENTA}${BOLD}OCULTA${NC} (Hidden SSID)                         │"
        echo -e "│    ${ARCH_BLUE}${BOLD}[3]${NC}  🌐 Probar conexión por cable Ethernet (DHCP)                         │"
        echo -e "│    ${ARCH_BLUE}${BOLD}[4]${NC}  ⌨️   Abrir consola manual iwctl                                        │"
        echo -e "│    ${ARCH_BLUE}${BOLD}[5]${NC}  ⏩ Continuar al siguiente paso                                        │"
        echo -e "│                                                                              │"
        echo -e "${ARCH_BLUE}╰──────────────────────────────────────────────────────────────────────────────╯${NC}"

        if [ "$is_online" = true ]; then
            echo ""
            badge_ok "¡Conexión a Internet activa y verificada!"
            echo ""
            read -r -p "  ¿Avanzar al siguiente paso? [S/n] (o escribe 'r' para reconfigurar): " NET_CHOICE
            if [[ ! "$NET_CHOICE" =~ ^[nN]$ ]] && [[ ! "$NET_CHOICE" =~ ^[rR]$ ]]; then
                return 0
            fi
        fi

        read -r -p "  ❯ Selecciona una opción [1-5]: " NET_OPT

        case "$NET_OPT" in
            1)
                echo ""
                badge_info "Escaneando redes Wi-Fi cercanas..."
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
                        badge_info "Conectando a $WIFI_SSID..."
                        if [ -n "$WIFI_PASS" ]; then
                            nmcli dev wifi connect "$WIFI_SSID" password "$WIFI_PASS" || badge_err "Falló la conexión a $WIFI_SSID."
                        else
                            nmcli dev wifi connect "$WIFI_SSID" || true
                        fi
                    fi
                elif command -v iwctl >/dev/null 2>&1; then
                    WLAN_DEV=$(iwctl device list 2>/dev/null | awk '/station/ {print $2}' | head -n 1)
                    WLAN_DEV="${WLAN_DEV:-wlan0}"
                    badge_info "Escaneando con iwctl en $WLAN_DEV..."
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
                    badge_warn "El nombre SSID no puede estar vacío."
                    sleep 1
                    continue
                fi
                read -s -r -p "  Introduce la contraseña (deja vacío si es abierta): " HIDDEN_PASS
                echo ""
                badge_info "Conectando a red oculta $HIDDEN_SSID..."
                if command -v nmcli >/dev/null 2>&1; then
                    if [ -n "$HIDDEN_PASS" ]; then
                        nmcli dev wifi connect "$HIDDEN_SSID" password "$HIDDEN_PASS" hidden yes || {
                            badge_warn "Reintentando escaneo de SSID específico..."
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
                badge_info "Solicitando IP por DHCP en interfaces de red..."
                dhcpcd 2>/dev/null || true
                sleep 2
                ;;

            4)
                echo ""
                badge_info "Abriendo consola iwctl. Escribe 'exit' cuando termines."
                iwctl || true
                ;;

            5)
                return 0
                ;;
        esac
    done
}

configure_network_wizard

# ------------------------------------------------------------------------------
# PASO 2: Selección de Idioma del Sistema (Locales)
# ------------------------------------------------------------------------------
draw_header 2
echo -e "${ARCH_BLUE}╭─ Paso 2/7: Idioma del Sistema (Locales) ─────────────────────────────────────╮${NC}"
echo -e "│                                                                              │"
echo -e "│  Selecciona el idioma principal de tu sistema Arch Linux:                    │"
echo -e "│                                                                              │"
echo -e "│    ${ARCH_BLUE}${BOLD}[1]${NC}  🇪🇸  Español (España)         [es_ES.UTF-8]  (Predeterminado)        │"
echo -e "│    ${ARCH_BLUE}${BOLD}[2]${NC}  🇲🇽  Español (Latinoamérica)  [es_MX.UTF-8]                          │"
echo -e "│    ${ARCH_BLUE}${BOLD}[3]${NC}  🇵🇪  Español (Perú)           [es_PE.UTF-8]                          │"
echo -e "│    ${ARCH_BLUE}${BOLD}[4]${NC}  🇦🇷  Español (Argentina)      [es_AR.UTF-8]                          │"
echo -e "│    ${ARCH_BLUE}${BOLD}[5]${NC}  🇨🇱  Español (Chile)          [es_CL.UTF-8]                          │"
echo -e "│    ${ARCH_BLUE}${BOLD}[6]${NC}  🇨🇴  Español (Colombia)       [es_CO.UTF-8]                          │"
echo -e "│    ${ARCH_BLUE}${BOLD}[7]${NC}  🇺🇸  English (United States)  [en_US.UTF-8]                          │"
echo -e "│                                                                              │"
echo -e "${ARCH_BLUE}╰──────────────────────────────────────────────────────────────────────────────╯${NC}"
echo ""
read -r -p "  ❯ Selecciona una opción [1-7] (Enter para Español España): " LANG_OPT

case "$LANG_OPT" in
    2) SYS_LOCALE="es_MX.UTF-8" ;;
    3) SYS_LOCALE="es_PE.UTF-8" ;;
    4) SYS_LOCALE="es_AR.UTF-8" ;;
    5) SYS_LOCALE="es_CL.UTF-8" ;;
    6) SYS_LOCALE="es_CO.UTF-8" ;;
    7) SYS_LOCALE="en_US.UTF-8" ;;
    *) SYS_LOCALE="es_ES.UTF-8" ;;
esac
badge_ok "Idioma configurado: ${BOLD}$SYS_LOCALE${NC}"
sleep 1

# ------------------------------------------------------------------------------
# PASO 3: Distribución de Teclado (Consola y Hyprland)
# ------------------------------------------------------------------------------
draw_header 3
echo -e "${ARCH_BLUE}╭─ Paso 3/7: Distribución de Teclado ──────────────────────────────────────────╮${NC}"
echo -e "│                                                                              │"
echo -e "│  Configura el mapa de teclas para la consola tty y para Hyprland:            │"
echo -e "│                                                                              │"
echo -e "│    ${ARCH_BLUE}${BOLD}[1]${NC}  ⌨️   Latinoamericano (la-latin1 / latam)  (Predeterminado)            │"
echo -e "│    ${ARCH_BLUE}${BOLD}[2]${NC}  🇪🇸  Español España (es)                                              │"
echo -e "│    ${ARCH_BLUE}${BOLD}[3]${NC}  🇺🇸  Inglés / US (us)                                                 │"
echo -e "│                                                                              │"
echo -e "${ARCH_BLUE}╰──────────────────────────────────────────────────────────────────────────────╯${NC}"
echo ""
read -r -p "  ❯ Selecciona una opción [1-3] (Enter para Latinoamericano): " KB_OPT

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
badge_ok "Teclado activo: ${BOLD}$KEYMAP${NC} (Hyprland: ${BOLD}$HYPR_KB${NC})"
sleep 1

# ------------------------------------------------------------------------------
# PASO 4: Identidad del Equipo y Git
# ------------------------------------------------------------------------------
draw_header 4
echo -e "${ARCH_BLUE}╭─ Paso 4/7: Identidad del Equipo y Perfil Git ────────────────────────────────╮${NC}"
echo -e "│                                                                              │"
echo -e "│  Asigna el nombre de tu máquina (Hostname) y tu perfil global de Git:        │"
echo -e "│                                                                              │"
echo -e "${ARCH_BLUE}╰──────────────────────────────────────────────────────────────────────────────╯${NC}"
echo ""
read -r -p "  ❯ Nombre del equipo / Hostname [archlinux]: " SYS_HOSTNAME
SYS_HOSTNAME="${SYS_HOSTNAME:-archlinux}"

echo ""
read -r -p "  ❯ Nombre de usuario para Git (ej: MrDemonc): " GIT_USER_NAME
read -r -p "  ❯ Correo de usuario para Git (ej: usuario@correo.com): " GIT_USER_EMAIL
badge_ok "Identidad: Hostname=${BOLD}$SYS_HOSTNAME${NC}, Git=${BOLD}${GIT_USER_NAME:-N/A}${NC}"
sleep 1

# ------------------------------------------------------------------------------
# PASO 5: Almacenamiento, Cifrado LUKS2 Automático y Contraseña Maestra
# ------------------------------------------------------------------------------
draw_header 5
echo -e "${ARCH_BLUE}╭─ Paso 5/7: Almacenamiento, BTRFS y Contraseña Maestra ───────────────────────╮${NC}"
echo -e "│                                                                              │"
echo -e "│  ${MAGENTA}${BOLD}🔒 Cifrado de Disco:${NC}  Automático con LUKS2 (Argon2id)                      │"
echo -e "│  ${BLUE}${BOLD}💿 Sistema de Archivos:${NC} BTRFS con subvolúmenes (@, @home, @snapshots)     │"
echo -e "│                                                                              │"
echo -e "│  ${BOLD}Discos de almacenamiento detectados:${NC}                                       │"
echo -e "${ARCH_BLUE}╰──────────────────────────────────────────────────────────────────────────────╯${NC}"
echo ""
lsblk -d -p -n -l -o NAME,SIZE,MODEL,TYPE | grep -E "disk" || lsblk
echo ""
read -r -p "  ❯ Introduce el disco objetivo (ej: /dev/sda o /dev/nvme0n1): " TARGET_DISK

if [ ! -b "$TARGET_DISK" ]; then
    badge_err "El dispositivo '$TARGET_DISK' no es un disco válido."
    exit 1
fi

echo ""
echo -e "  ${RED}${BOLD}¡ADVERTENCIA! Todos los datos en $TARGET_DISK serán eliminados permanentemente.${NC}"
read -r -p "  Escribe 'SI' (en mayúsculas) para confirmar el formateo: " CONFIRM_DISCO
if [ "$CONFIRM_DISCO" != "SI" ]; then
    badge_warn "Instalación cancelada por el usuario."
    exit 0
fi

echo ""
echo -e "${ARCH_BLUE}╭─ Contraseña Maestra Unificada ───────────────────────────────────────────────╮${NC}"
echo -e "│                                                                              │"
echo -e "│  La ${BOLD}Contraseña Maestra${NC} que definas se aplicará automáticamente a:             │"
echo -e "│    1. 🔒 Desbloqueo del disco cifrado al encender la PC                      │"
echo -e "│    2. 🔑 Superusuario root                                                   │"
echo -e "│    3. 👤 Tu cuenta de usuario personal y comandos sudo                       │"
echo -e "│                                                                              │"
echo -e "${ARCH_BLUE}╰──────────────────────────────────────────────────────────────────────────────╯${NC}"
echo ""
read -r -p "  ❯ Nombre de tu usuario personal [demonc]: " SYS_USER
SYS_USER="${SYS_USER:-demonc}"

while true; do
    read -s -r -p "  ❯ Introduce la Contraseña Maestra: " P1
    echo ""
    read -s -r -p "  ❯ Confirma la Contraseña Maestra: " P2
    echo ""
    if [ -n "$P1" ] && [ "$P1" == "$P2" ]; then
        MASTER_PASS="$P1"
        break
    else
        badge_err "Las contraseñas no coinciden o están vacías. Inténtalo de nuevo."
    fi
done
badge_ok "Clave Maestra configurada para Cifrado LUKS, Root y $SYS_USER."

echo ""
read -r -p "  ❯ Zona horaria [America/Lima]: " SYS_TIMEZONE
SYS_TIMEZONE="${SYS_TIMEZONE:-America/Lima}"

# ------------------------------------------------------------------------------
# PASO 6: Despliegue Automatizado del Sistema (100% Configurado, 0 pasos post-reinicio)
# ------------------------------------------------------------------------------
draw_header 6
echo -e "${ARCH_BLUE}╭─ Paso 6/7: Despliegue Automatizado del Sistema ──────────────────────────────╮${NC}"
echo -e "│                                                                              │"
echo -e "│  [1/6]  ● Particionando disco y preparando contenedor cifrado LUKS2...       │"
echo -e "│  [2/6]  ○ Creando subvolúmenes BTRFS (@, @home, @snapshots, etc.)           │"
echo -e "│  [3/6]  ○ Instalando sistema base, Hyprland y Quickshell con pacstrap        │"
echo -e "│  [4/6]  ○ Configurando Chroot, systemd-boot y Seamless Login                 │"
echo -e "│  [5/6]  ○ Desplegando MrDemonc-SHELL, módulos de Hyprland y atajos           │"
echo -e "│  [6/6]  ○ Configurando Zsh, Oh My Zsh, Starship y permisos finales           │"
echo -e "│                                                                              │"
echo -e "${ARCH_BLUE}╰──────────────────────────────────────────────────────────────────────────────╯${NC}"
echo ""

# Desmontar puntos de montaje previos si existen
swapoff -a 2>/dev/null || true
umount -R /mnt 2>/dev/null || true
cryptsetup close cryptroot 2>/dev/null || true

# Limpieza total de tablas de particiones
badge_info "Limpiando firmas previas en $TARGET_DISK..."
sgdisk --zap-all "$TARGET_DISK" >/dev/null 2>&1 || true
wipefs -a "$TARGET_DISK" >/dev/null 2>&1 || true
partprobe "$TARGET_DISK" 2>/dev/null || true
sleep 1

# Partición 1: EFI (ESP) de 1024MB
badge_info "Creando particiones GPT (ESP 1GB + Linux LUKS)..."
sgdisk -n 1:0:+1024M -t 1:ef00 -c 1:"EFI System Partition" "$TARGET_DISK"
# Partición 2: Cifrada Linux (Resto del disco)
sgdisk -n 2:0:0 -t 2:8300 -c 2:"Linux LUKS Btrfs" "$TARGET_DISK"

partprobe "$TARGET_DISK" 2>/dev/null || true
sleep 1

if [[ "$TARGET_DISK" =~ [0-9]$ ]]; then
    PART_EFI="${TARGET_DISK}p1"
    PART_ROOT="${TARGET_DISK}p2"
else
    PART_EFI="${TARGET_DISK}1"
    PART_ROOT="${TARGET_DISK}2"
fi

badge_info "Formateando partición EFI en $PART_EFI (FAT32)..."
mkfs.fat -F 32 -n EFI "$PART_EFI" >/dev/null

badge_sec "Cifrando partición $PART_ROOT con LUKS2 (Argon2id)..."
echo -n "$MASTER_PASS" | cryptsetup luksFormat --type luks2 --pbkdf argon2id --batch-mode "$PART_ROOT" -
badge_sec "Desbloqueando contenedor cryptroot..."
echo -n "$MASTER_PASS" | cryptsetup open "$PART_ROOT" cryptroot -

ROOT_DEV="/dev/mapper/cryptroot"

# Subvolúmenes Btrfs
badge_fs "Formateando contenedor en BTRFS..."
mkfs.btrfs -f -L ARCHROOT "$ROOT_DEV" >/dev/null

mount "$ROOT_DEV" /mnt
badge_fs "Creando subvolúmenes: @, @home, @snapshots, @var_log, @pkg..."
btrfs subvolume create /mnt/@ >/dev/null
btrfs subvolume create /mnt/@home >/dev/null
btrfs subvolume create /mnt/@snapshots >/dev/null
btrfs subvolume create /mnt/@var_log >/dev/null
btrfs subvolume create /mnt/@pkg >/dev/null
umount /mnt

BTRFS_MOUNT_OPTS="noatime,compress=zstd,space_cache=v2"
mount -o "$BTRFS_MOUNT_OPTS,subvol=@" "$ROOT_DEV" /mnt
mkdir -p /mnt/{home,.snapshots,var/log,var/cache/pacman/pkg,boot}
mount -o "$BTRFS_MOUNT_OPTS,subvol=@home" "$ROOT_DEV" /mnt/home
mount -o "$BTRFS_MOUNT_OPTS,subvol=@snapshots" "$ROOT_DEV" /mnt/.snapshots
mount -o "$BTRFS_MOUNT_OPTS,subvol=@var_log" "$ROOT_DEV" /mnt/var/log
mount -o "$BTRFS_MOUNT_OPTS,subvol=@pkg" "$ROOT_DEV" /mnt/var/cache/pacman/pkg
mount "$PART_EFI" /mnt/boot

badge_ok "Sistema de archivos BTRFS y subvolúmenes montados."

# Detección de microcódigo CPU
UCODE_PKG=""
if grep -q "AuthenticAMD" /proc/cpuinfo; then
    UCODE_PKG="amd-ucode"
    badge_info "CPU AMD detectado (instalando $UCODE_PKG)..."
elif grep -q "GenuineIntel" /proc/cpuinfo; then
    UCODE_PKG="intel-ucode"
    badge_info "CPU Intel detectado (instalando $UCODE_PKG)..."
fi

# Lista completa de paquetes (Incluye entorno Hyprland, Quickshell y utilidades)
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
    zsh-autosuggestions
    zsh-syntax-highlighting
    starship
    curl
    wget
    nano
    neovim
    hyprland
    hyprlock
    hypridle
    quickshell
    kitty
    dolphin
    ttf-jetbrains-mono-nerd
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
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

echo ""
badge_info "Instalando sistema base, Hyprland y Quickshell con pacstrap..."
pacstrap -K /mnt "${BASE_PACKAGES[@]}"

badge_info "Generando /etc/fstab..."
genfstab -U /mnt >> /mnt/etc/fstab
badge_ok "Sistema base y fstab listos."

# Configuración del Sistema en Chroot
ROOT_UUID=$(blkid -s UUID -o value "$PART_ROOT")
BOOT_ENTRY_OPTIONS="cryptdevice=UUID=$ROOT_UUID:cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rw quiet splash"
MKINITCPIO_HOOKS="base udev autodetect modconf kms keyboard keymap consolefont block encrypt btrfs filesystems fsck"

UCODE_LINE=""
if [ -n "$UCODE_PKG" ]; then
    UCODE_LINE="initrd  /$UCODE_PKG.img"
fi

badge_info "Configurando sistema interno en chroot..."
cat << CHROOT_SCRIPT > /mnt/tmp/setup_chroot.sh
#!/usr/bin/env bash
set -e

# Zona horaria y reloj
ln -sf /usr/share/zoneinfo/$SYS_TIMEZONE /etc/localtime
hwclock --systohc

# Locales e Idioma
sed -i "s/#$SYS_LOCALE UTF-8/$SYS_LOCALE UTF-8/" /etc/locale.gen
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen 2>/dev/null || true
locale-gen
echo "LANG=$SYS_LOCALE" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

# Hostname y Red
echo "$SYS_HOSTNAME" > /etc/hostname
cat << HOSTS > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   $SYS_HOSTNAME.localdomain $SYS_HOSTNAME
HOSTS

# Contraseña Maestra para Root y Usuario
echo "root:$MASTER_PASS" | chpasswd
useradd -m -g users -G wheel,video,audio,storage,optical,network -s /usr/bin/zsh "$SYS_USER"
echo "$SYS_USER:$MASTER_PASS" | chpasswd

# Sudoers
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel
chmod 440 /etc/sudoers.d/wheel

# Configurar Git del usuario
if [ -n "$GIT_USER_NAME" ]; then
    su - "$SYS_USER" -c "git config --global user.name '$GIT_USER_NAME'"
fi
if [ -n "$GIT_USER_EMAIL" ]; then
    su - "$SYS_USER" -c "git config --global user.email '$GIT_USER_EMAIL'"
fi
su - "$SYS_USER" -c "git config --global init.defaultBranch main" 2>/dev/null || true

# mkinitcpio para LUKS y BTRFS
sed -i "s/^HOOKS=(.*)/HOOKS=($MKINITCPIO_HOOKS)/" /etc/mkinitcpio.conf
mkinitcpio -P

# systemd-boot (UEFI)
bootctl install

cat << LOADER > /boot/loader/loader.conf
default arch.conf
timeout 3
console-mode max
editor no
LOADER

cat << ENTRY > /boot/loader/entries/arch.conf
title   ARCH Linux (Btrfs + LUKS)
linux   /vmlinuz-linux
$UCODE_LINE
initrd  /initramfs-linux.img
options $BOOT_ENTRY_OPTIONS
ENTRY

# Habilitar servicios requeridos
systemctl enable NetworkManager.service
systemctl enable bluetooth.service 2>/dev/null || true

# Seamless Login directo en tty1
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat << AUTOLOGIN > /etc/systemd/system/getty@tty1.service.d/autologin.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $SYS_USER --noclear %I \\$TERM
Type=idle
AUTOLOGIN

# Hook de autoarranque a Hyprland
for prof in /home/$SYS_USER/.zprofile /home/$SYS_USER/.bash_profile; do
    cat << 'HOOK' >> "\\$prof"

# Auto-start Hyprland en tty1 (Seamless Login)
if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec Hyprland
fi
HOOK
    chown $SYS_USER:users "\\$prof"
done
CHROOT_SCRIPT

chmod +x /mnt/tmp/setup_chroot.sh
arch-chroot /mnt /tmp/setup_chroot.sh
rm -f /mnt/tmp/setup_chroot.sh
badge_ok "Configuración de chroot, bootloader y usuarios finalizada."

# ------------------------------------------------------------------------------
# Despliegue de MrDemonc-SHELL y Entorno Completo (100% Preconfigurado)
# ------------------------------------------------------------------------------
badge_info "Desplegando entorno gráfico MrDemonc-SHELL, módulos y configuraciones..."

USER_HOME="/mnt/home/$SYS_USER"
DOCS_DIR="$USER_HOME/Documentos"
DEST_REPO="$DOCS_DIR/MrDemonc-SHELL"
mkdir -p "$DOCS_DIR"

# 1. Copiar repositorio local desde la ISO o clonar si es necesario
if [ -d "/usr/share/mrdemonc-shell" ]; then
    badge_info "Copiando MrDemonc-SHELL desde el medio de instalación..."
    cp -a /usr/share/mrdemonc-shell "$DEST_REPO"
elif [ -d "/home/demonc-test/Documentos/MrDemonc-SHELL" ]; then
    cp -a "/home/demonc-test/Documentos/MrDemonc-SHELL" "$DEST_REPO"
else
    badge_info "Clonando repositorio oficial MrDemonc-SHELL..."
    git clone https://github.com/MrDemonc/MrDemonc-SHELL.git "$DEST_REPO" || true
fi

# Permisos ejecutables a scripts
chmod +x "$DEST_REPO"/scripts/*.sh 2>/dev/null || true
chmod +x "$DEST_REPO"/scripts/*.py 2>/dev/null || true

# 2. Configurar directorios del usuario
mkdir -p "$USER_HOME/.config/hypr"
mkdir -p "$USER_HOME/.config/kitty"
mkdir -p "$USER_HOME/.config/quickshell"
mkdir -p "$USER_HOME/.local/bin"
mkdir -p "$USER_HOME/Pictures/Wallpapers"

# 3. Desplegar módulos de Hyprland
if [ -d "$DEST_REPO/hypr" ]; then
    cp -f "$DEST_REPO/hypr/windows.lua" "$USER_HOME/.config/hypr/windows.lua"
    cp -f "$DEST_REPO/hypr/keybinds.lua" "$USER_HOME/.config/hypr/keybinds.lua"
    cp -f "$DEST_REPO/hypr/theme_colors.lua" "$USER_HOME/.config/hypr/theme_colors.lua" 2>/dev/null || true
    cp -f "$DEST_REPO/hypr/hyprlock.conf" "$USER_HOME/.config/hypr/hyprlock.conf" 2>/dev/null || true
    cp -f "$DEST_REPO/hypr/hyprlock_colors.conf" "$USER_HOME/.config/hypr/hyprlock_colors.conf" 2>/dev/null || true
    cp -f "$DEST_REPO/hypr/hypridle.conf" "$USER_HOME/.config/hypr/hypridle.conf" 2>/dev/null || true

    # Inyectar teclado seleccionado y ruta absoluta del usuario en hyprland.lua
    sed "s|userHome .. \"/Documentos/MrDemonc-SHELL\"|\"/home/$SYS_USER/Documentos/MrDemonc-SHELL\"|g" \
        "$DEST_REPO/hypr/hyprland.lua" > "$USER_HOME/.config/hypr/hyprland.lua"
    sed -i "s/kb_layout  = \".*\"/kb_layout  = \"$HYPR_KB\"/g" "$USER_HOME/.config/hypr/hyprland.lua"
    badge_ok "Configuración modular de Hyprland desplegada (~/.config/hypr)."
fi

# 4. Desplegar utilidades CLI en ~/.local/bin
cat << WRAP_APPS > "$USER_HOME/.local/bin/shell-apps"
#!/usr/bin/env bash
exec /home/$SYS_USER/Documentos/MrDemonc-SHELL/scripts/toggle_apps.sh "\\$@"
WRAP_APPS

cat << WRAP_WALL > "$USER_HOME/.local/bin/shell-wallpaper"
#!/usr/bin/env bash
exec /home/$SYS_USER/Documentos/MrDemonc-SHELL/scripts/toggle_wallpaper.sh "\\$@"
WRAP_WALL

cat << WRAP_CLIP > "$USER_HOME/.local/bin/clipboard-action"
#!/usr/bin/env bash
exec /home/$SYS_USER/Documentos/MrDemonc-SHELL/scripts/clipboard_action.sh "\\$@"
WRAP_CLIP

cat << WRAP_THEME > "$USER_HOME/.local/bin/shell-theme"
#!/usr/bin/env bash
TARGET_DIR="/home/$SYS_USER/Documentos/MrDemonc-SHELL"
if [ "\\$1" == "set" ] || [ "\\$1" == "list" ]; then
    exec python3 "\\$TARGET_DIR/scripts/theme_manager.py" "\\$@"
else
    exec "\\$TARGET_DIR/scripts/toggle_theme_picker.sh" "\\$@"
fi
WRAP_THEME

cat << WRAP_POPOUT > "$USER_HOME/.local/bin/shell-popout"
#!/usr/bin/env bash
TARGET="\${1:-audio}"
STATE="\${XDG_RUNTIME_DIR:-/tmp}/quickshell_popout.toggle"
echo "\\$TARGET" > "\\$STATE"
WRAP_POPOUT

cat << WRAP_BAR > "$USER_HOME/.local/bin/shell-bar"
#!/usr/bin/env bash
TARGET_DIR="/home/$SYS_USER/Documentos/MrDemonc-SHELL"
if [ "\\$1" == "pos" ] || [ "\\$1" == "position" ]; then
    shift
    exec python3 "\\$TARGET_DIR/scripts/manage_order.py" save_position "\\$@"
elif [ "\\$1" == "get-pos" ]; then
    exec python3 "\\$TARGET_DIR/scripts/manage_order.py" get_position
else
    exec python3 "\\$TARGET_DIR/scripts/manage_order.py" "\\$@"
fi
WRAP_BAR

chmod +x "$USER_HOME/.local/bin"/* 2>/dev/null || true
badge_ok "Comandos de terminal instalados en ~/.local/bin."

# 5. Configurar Kitty con Zsh y fuente JetBrainsMono
if [ -f "$DEST_REPO/kitty/kitty.conf" ]; then
    cp -f "$DEST_REPO/kitty/kitty.conf" "$USER_HOME/.config/kitty/kitty.conf"
    badge_ok "Configuración de terminal Kitty desplegada."
fi

# 6. Desplegar Starship Prompt
if [ -f "$DEST_REPO/starship/starship.toml" ]; then
    cp -f "$DEST_REPO/starship/starship.toml" "$USER_HOME/.config/starship.toml"
    badge_ok "Tema de Starship desplegado (~/.config/starship.toml)."
fi

# 7. Desplegar Oh My Zsh y plugins (Totalmente autónomo)
badge_info "Configurando entorno Zsh con Oh My Zsh y plugins..."
if [ ! -d "$USER_HOME/.oh-my-zsh" ]; then
    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$USER_HOME/.oh-my-zsh" 2>/dev/null || true
fi

# Copiar plugins de zsh instalados a nivel de sistema si existen
mkdir -p "$USER_HOME/.oh-my-zsh/custom/plugins"
if [ -d "/mnt/usr/share/zsh/plugins/zsh-autosuggestions" ]; then
    cp -r /mnt/usr/share/zsh/plugins/zsh-autosuggestions "$USER_HOME/.oh-my-zsh/custom/plugins/" 2>/dev/null || true
fi
if [ -d "/mnt/usr/share/zsh/plugins/zsh-syntax-highlighting" ]; then
    cp -r /mnt/usr/share/zsh/plugins/zsh-syntax-highlighting "$USER_HOME/.oh-my-zsh/custom/plugins/" 2>/dev/null || true
fi

# Configurar ~/.zshrc completo
cat << ZSHRC > "$USER_HOME/.zshrc"
# ==============================================================================
#  MrDemonc-SHELL: Zsh Configuration
# ==============================================================================
export ZSH="\$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

# Plugins
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

if [ -f "\$ZSH/oh-my-zsh.sh" ]; then
    source "\$ZSH/oh-my-zsh.sh"
fi

# Cargar plugins nativos del sistema si no están en Oh My Zsh
[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Starship Prompt
eval "\\$(starship init zsh)"

# Variables de entorno
export PATH="\$HOME/.local/bin:\$PATH"
export SHELL="/usr/bin/zsh"
export BROWSER="dolphin"

# Alias útiles
alias ls="ls --color=auto"
alias ll="ls -la"
alias grep="grep --color=auto"
ZSHRC

badge_ok "Configuración de shell Zsh terminada (~/.zshrc)."

# 8. Asignar propiedad completa al usuario
chown -R "$SYS_USER:users" "$USER_HOME"

# Desmontar sistemas de archivos
badge_info "Desmontando sistemas de archivos de forma limpia..."
umount -R /mnt 2>/dev/null || true
cryptsetup close cryptroot 2>/dev/null || true

# ------------------------------------------------------------------------------
# PASO 7: Finalización y Resumen del Sistema
# ------------------------------------------------------------------------------
draw_header 7
echo -e "${GREEN}${BOLD}╭──────────────────────────────────────────────────────────────────────────────╮"
echo -e "│                                                                              │"
echo -e "│   █████╗ ██████╗  ██████╗██╗  ██╗    ¡INSTALACIÓN COMPLETADA CON ÉXITO!      │"
echo -e "│  ██╔══██╗██╔══██╗██╔════╝██║  ██║    EL SISTEMA ESTÁ 100% CONFIGURADO        │"
echo -e "│  ███████║██████╔╝██║     ███████║    ───────────────────────────────────     │"
echo -e "│  ██╔══██║██╔══██╗██║     ██╔══██║    Al encender el equipo no requerirás     │"
echo -e "│  ██║  ██║██║  ██║╚██████╗██║  ██║    realizar ningún paso adicional.         │"
echo -e "│  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝                                            │"
echo -e "│                                                                              │"
echo -e "╰──────────────────────────────────────────────────────────────────────────────╯${NC}"
echo ""
echo -e "${ARCH_BLUE}╭─ Resumen del Sistema Instalado ──────────────────────────────────────────────╮${NC}"
echo -e "│                                                                              │"
echo -e "│  • ${BOLD}Disco:${NC}             ${WHITE}$TARGET_DISK${NC}"
echo -e "│  • ${BOLD}Sistema Archivos:${NC}  ${BLUE}BTRFS (@, @home, @snapshots, @var_log, @pkg)${NC}"
echo -e "│  • ${BOLD}Cifrado:${NC}           ${MAGENTA}LUKS2 (Argon2id) Automático${NC}"
echo -e "│  • ${BOLD}Clave Maestra:${NC}     Unificada (Desbloqueo de arranque + Root + sudo)"
echo -e "│  • ${BOLD}Arranque:${NC}          systemd-boot (UEFI) con Seamless Login a Hyprland"
echo -e "│  • ${BOLD}Idioma & Teclado:${NC}  $SYS_LOCALE / $KEYMAP (Hyprland: $HYPR_KB)"
echo -e "│  • ${BOLD}Equipo (Hostname):${NC} $SYS_HOSTNAME"
if [ -n "$GIT_USER_NAME" ]; then
echo -e "│  • ${BOLD}Git Configurado:${NC}   $GIT_USER_NAME <$GIT_USER_EMAIL>"
fi
echo -e "│  • ${BOLD}Entorno Gráfico:${NC}   Hyprland + Quickshell (MrDemonc-SHELL desplegado)"
echo -e "│  • ${BOLD}Shell & Prompt:${NC}    Zsh + Oh My Zsh + Starship Prompt (Demonc)"
echo -e "│  • ${BOLD}Usuario Creado:${NC}    ${ARCH_BLUE}$SYS_USER${NC}"
echo -e "│                                                                              │"
echo -e "${ARCH_BLUE}╰──────────────────────────────────────────────────────────────────────────────╯${NC}"
echo ""
echo -e "  ${BOLD}Pasos para iniciar tu nuevo sistema:${NC}"
echo -e "    1. Retira la memoria USB de tu computadora."
echo -e "    2. Ejecuta el comando: ${GREEN}${BOLD}reboot${NC}"
echo -e "    3. Al encender, introduce tu Contraseña Maestra y entrarás directo a Hyprland."
echo ""
