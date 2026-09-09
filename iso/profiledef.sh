#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="mrdemonc-shell"
iso_label="MRDEMONC_$(date +%Y%m)"
iso_publisher="MrDemonc <https://github.com/MrDemonc/MrDemonc-SHELL>"
iso_application="MrDemonc-SHELL Live & Install Media"
iso_version="$(date +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito' 'uefi-ia32.systemd-boot.esp' 'uefi-x64.systemd-boot.esp' 'uefi-ia32.systemd-boot.eltorito' 'uefi-x64.systemd-boot.eltorito')
arch="x86_64"
pacman_conf="/etc/pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'zstd')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/usr/local/bin/mrdemonc-installer"]="0:0:755"
)
