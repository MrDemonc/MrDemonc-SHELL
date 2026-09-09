#!/usr/bin/env bash
# ==============================================================================
#  MrDemonc-SHELL: Compilador de Imagen ISO Live Bootable (mkarchiso)
# ==============================================================================
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ISO_DIR="$REPO_DIR/iso"
WORK_DIR="/var/tmp/archiso-mrdemonc-work"
OUT_DIR="$REPO_DIR/out"

# Colores
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}"
echo "=================================================================="
echo "        COMPILADOR DE ISO BOOTABLE: MrDemonc-SHELL                "
echo "=================================================================="
echo -e "${NC}"

# Verificar archiso
if ! command -v mkarchiso >/dev/null 2>&1; then
    echo -e "${YELLOW}[1/4] 'archiso' no está instalado. Instalando con pacman...${NC}"
    sudo pacman -S --needed --noconfirm archiso
else
    echo -e "${GREEN}[1/4] 'archiso' ya está instalado.${NC}"
fi

# Verificar y sincronizar estructura del perfil si faltan directorios de boot
if [ ! -d "$ISO_DIR/syslinux" ] || [ ! -d "$ISO_DIR/efiboot" ]; then
    echo -e "${YELLOW}[2/4] Completando estructura de arranque desde /usr/share/archiso/configs/releng...${NC}"
    for d in syslinux efiboot grub; do
        if [ ! -d "$ISO_DIR/$d" ] && [ -d "/usr/share/archiso/configs/releng/$d" ]; then
            cp -r "/usr/share/archiso/configs/releng/$d" "$ISO_DIR/"
        fi
    done
    if [ ! -f "$ISO_DIR/pacman.conf" ] && [ -f "/usr/share/archiso/configs/releng/pacman.conf" ]; then
        cp "/usr/share/archiso/configs/releng/pacman.conf" "$ISO_DIR/"
    fi
fi

# Actualizar el script instalador dentro de la ISO
echo -e "${YELLOW}[2/4] Sincronizando instalador y bienvenida en el perfil de la ISO...${NC}"
mkdir -p "$ISO_DIR/airootfs/usr/local/bin"
cp -f "$REPO_DIR/arch-iso-install.sh" "$ISO_DIR/airootfs/usr/local/bin/mrdemonc-installer"
chmod +x "$ISO_DIR/airootfs/usr/local/bin/mrdemonc-installer"


# Limpiar trabajo previo
echo -e "${YELLOW}[3/4] Preparando directorios de compilación (usando /var/tmp)...${NC}"
sudo rm -rf "$WORK_DIR"
sudo rm -rf "/tmp/archiso-mrdemonc-work"
mkdir -p "$OUT_DIR"

# Ejecutar compilación de la ISO con mkarchiso
echo -e "${YELLOW}[4/4] Compilando imagen ISO bootable con mkarchiso (esto puede tardar unos minutos)...${NC}"
sudo mkarchiso -v -w "$WORK_DIR" -o "$OUT_DIR" "$ISO_DIR"

echo ""
echo -e "${GREEN}${BOLD}=================================================================="
echo -e "      ¡IMAGEN ISO CREADA CON ÉXITO EN: $OUT_DIR/!                "
echo -e "==================================================================${NC}"
echo -e "Puedes grabar la ISO en tu pendrive USB con:"
echo -e "  ${CYAN}sudo dd bs=4M if=\$(ls -t \"$OUT_DIR\"/*.iso | head -n 1) of=/dev/sdX status=progress oflag=sync${NC}"
echo -e "o usar herramientas gráficas como ${BOLD}Ventoy${NC}, ${BOLD}BalenaEtcher${NC} o ${BOLD}Rufus${NC}."
