# Auto-start MrDemonc-SHELL installer on tty1
if [ "$(tty)" = "/dev/tty1" ]; then
    clear
    /usr/local/bin/mrdemonc-installer
fi
