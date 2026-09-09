# Auto-start MrDemonc-SHELL installer on tty1
if [ "$(tty)" = "/dev/tty1" ]; then
    clear
    /usr/local/bin/mrdemonc-installer || true
    echo
    echo -e "\033[1;36mEl instalador ha finalizado o se encuentra en pausa.\033[0m"
    echo -e "Puedes volver a iniciarlo con: \033[1;32mmrdemonc-installer\033[0m"
    echo
fi
