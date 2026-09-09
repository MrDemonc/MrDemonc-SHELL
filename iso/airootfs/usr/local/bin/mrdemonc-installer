#!/usr/bin/env bash
# ==============================================================================
#  ARCH LINUX: Instalador Automatizado (Live ISO)
#  Diseño de interfaz TUI inspirado en Omarchy (Charm gum, Tokyo Night, Box TUI)
# ==============================================================================
set -eo pipefail

# ------------------------------------------------------------------------------
# 1. Configuración de Terminal, Paleta Tokyo Night y Logo
# ------------------------------------------------------------------------------
set_tokyo_night_colors() {
    # Paleta Tokyo Night para Linux Virtual Console (VT)
    echo -en "\e]P01a1b26"; echo -en "\e]P1f7768e"; echo -en "\e]P29ece6a"
    echo -en "\e]P3e0af68"; echo -en "\e]P47aa2f7"; echo -en "\e]P5bb9af7"
    echo -en "\e]P67dcfff"; echo -en "\e]P7a9b1d6"; echo -en "\e]P8414868"
    echo -en "\e]P9f7768e"; echo -en "\e]PA9ece6a"; echo -en "\e]PBe0af68"
    echo -en "\e]PC7aa2f7"; echo -en "\e]PDbb9af7"; echo -en "\e]PE7dcfff"
    echo -en "\e]PFc0caf5"
    echo -en "\033[0m"
}
set_tokyo_night_colors 2>/dev/null || true

ARCH_BLUE="\033[38;5;39m"
GREEN="\033[38;5;42m"
RED="\033[38;5;196m"
YELLOW="\033[38;5;220m"
PURPLE="\033[38;5;141m"
GRAY="\033[38;5;242m"
DARK_GRAY="\033[38;5;238m"
BOLD="\033[1m"
DIM="\033[2m"
NC="\033[0m"

# Variables de estilo para gum
export GUM_CONFIRM_PROMPT_FOREGROUND="6"
export GUM_CONFIRM_SELECTED_FOREGROUND="0"
export GUM_CONFIRM_SELECTED_BACKGROUND="2"
export GUM_CONFIRM_UNSELECTED_FOREGROUND="7"
export GUM_CONFIRM_UNSELECTED_BACKGROUND="0"

# Logo ARCH en tipografía de bloques (49 columnas)
LOGO_TEXT=$(cat << "EOF"
  ▄███████▄    ▄████████▄     ▄███████▄   ▄█   █▄
 ███     ███   ███    ███    ███     ▀▀   ███ ███
 ███     ███   ███    ███    ███          ███ ███
 ███████████   █████████▀    ███          ███████
 ███     ███   ███  ███      ███          ███ ███
 ███     ███   ███   ███     ███     ▄▄   ███ ███
 ███     ███   ███    ███     ▀███████▀   ███ ███
EOF
)
LOGO_WIDTH=49
LOGO_HEIGHT=7

# Medición dinámica del ancho del terminal y cálculo de padding para centrado
measure_terminal() {
    TERM_WIDTH=$(stty size 2>/dev/null </dev/tty | awk '{print $2}')
    (( TERM_WIDTH > 0 )) || TERM_WIDTH=${COLUMNS:-80}

    PADDING_LEFT=$(((TERM_WIDTH - LOGO_WIDTH) / 2))
    (( PADDING_LEFT < 0 )) && PADDING_LEFT=0
    PADDING_LEFT_SPACES=$(printf "%*s" "$PADDING_LEFT" "")

    PADDING="0 0 0 $PADDING_LEFT"
    export GUM_CHOOSE_PADDING="$PADDING"
    export GUM_FILTER_PADDING="$PADDING"
    export GUM_INPUT_PADDING="$PADDING"
    export GUM_SPIN_PADDING="$PADDING"
    export GUM_TABLE_PADDING="$PADDING"
    export GUM_CONFIRM_PADDING="$PADDING"
}

center_text() {
    local text="$1"
    local width="${2:-$TERM_WIDTH}"
    local clean
    clean=$(printf '%b' "$text" | sed -E $'s/\x1b\\[[0-9;?]*[A-Za-z]//g')
    local len=${#clean}
    local pad=$(( (width - len) / 2 ))
    (( pad < 0 )) && pad=0
    printf '%*s%b\n' "$pad" '' "$text"
}

# ------------------------------------------------------------------------------
# 2. Capa de Compatibilidad / Wrappers para gum (con Fallback nativo ANSI)
# ------------------------------------------------------------------------------
g_style() {
    if command -v gum >/dev/null 2>&1; then
        gum style "$@"
    else
        local fg="" pad=""
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --foreground) fg="$2"; shift 2 ;;
                --padding) pad="$2"; shift 2 ;;
                *) break ;;
            esac
        done
        local color="\033[0m"
        case "$fg" in
            1) color="\033[38;5;196m" ;;
            2) color="\033[38;5;42m" ;;
            6) color="\033[38;5;39m" ;;
            8) color="\033[38;5;242m" ;;
        esac
        while IFS= read -r line; do
            echo -e "${PADDING_LEFT_SPACES}${color}${line}${NC}"
        done <<< "$*"
    fi
}

clear_logo() {
    measure_terminal
    printf "\033[H\033[2J"
    if command -v gum >/dev/null 2>&1; then
        gum style --foreground 2 --padding "1 0 0 $PADDING_LEFT" "$LOGO_TEXT"
    else
        echo ""
        while IFS= read -r line; do
            echo -e "${PADDING_LEFT_SPACES}${GREEN}${line}${NC}"
        done <<< "$LOGO_TEXT"
        echo ""
    fi
}

say() {
    if command -v gum >/dev/null 2>&1; then
        gum style --padding "0 0 0 $PADDING_LEFT" "$@"
    else
        local fg=""
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --foreground) fg="$2"; shift 2 ;;
                *) break ;;
            esac
        done
        local color="\033[0m"
        case "$fg" in
            1) color="\033[38;5;196m" ;;
            2) color="\033[38;5;42m" ;;
            6) color="\033[38;5;39m" ;;
            8) color="\033[38;5;242m" ;;
        esac
        echo -e "${PADDING_LEFT_SPACES}${color}$*${NC}"
    fi
}

step() {
    clear_logo
    echo
    say "$1"
    echo
}

# Selector interactivo compatible con gum y fallback con flechas
g_choose() {
    if command -v gum >/dev/null 2>&1; then
        gum choose "$@"
    else
        local header="" selected_default="" height=8
        local -a items=()
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --header) header="$2"; shift 2 ;;
                --selected) selected_default="$2"; shift 2 ;;
                --height) height="$2"; shift 2 ;;
                *) items+=("$1"); shift ;;
            esac
        done
        if [ ${#items[@]} -eq 0 ]; then
            mapfile -t items
        fi

        local selected=0
        local num_opts=${#items[@]}
        local max_visible=$height
        local window_start=0

        for i in "${!items[@]}"; do
            if [[ -n "$selected_default" && "${items[$i]}" == "$selected_default"* ]]; then
                selected=$i
                break
            fi
        done

        tput civis 2>/dev/null || echo -ne "\033[?25l"

        while true; do
            if [ "$num_opts" -gt "$max_visible" ]; then
                if [ "$selected" -ge $((window_start + max_visible)) ]; then
                    window_start=$((selected - max_visible + 1))
                elif [ "$selected" -lt "$window_start" ]; then
                    window_start=$selected
                fi
            fi

            [ -n "$header" ] && echo -e "${PADDING_LEFT_SPACES}${BOLD}${header}${NC}\n"

            if [ "$num_opts" -gt "$max_visible" ]; then
                if [ "$window_start" -gt 0 ]; then
                    echo -e "${PADDING_LEFT_SPACES}  ${ARCH_BLUE}▲ (${window_start} más arriba)${NC}"
                else
                    echo -e "${PADDING_LEFT_SPACES}  ${DARK_GRAY}•${NC}"
                fi

                for ((i=window_start; i<window_start+max_visible && i<num_opts; i++)); do
                    if [ "$i" -eq "$selected" ]; then
                        echo -e "${PADDING_LEFT_SPACES}${GREEN}${BOLD}> ${items[$i]}${NC}"
                    else
                        echo -e "${PADDING_LEFT_SPACES}  ${GRAY}${items[$i]}${NC}"
                    fi
                done

                local rem=$((num_opts - (window_start + max_visible)))
                if [ "$rem" -gt 0 ]; then
                    echo -e "${PADDING_LEFT_SPACES}  ${ARCH_BLUE}▼ (${rem} más abajo)${NC}"
                else
                    echo -e "${PADDING_LEFT_SPACES}  ${DARK_GRAY}•${NC}"
                fi
            else
                for i in "${!items[@]}"; do
                    if [ "$i" -eq "$selected" ]; then
                        echo -e "${PADDING_LEFT_SPACES}${GREEN}${BOLD}> ${items[$i]}${NC}"
                    else
                        echo -e "${PADDING_LEFT_SPACES}  ${GRAY}${items[$i]}${NC}"
                    fi
                done
            fi

            local key="" key2=""
            if [ -e /dev/tty ] && [ -r /dev/tty ]; then
                IFS= read -rsn1 key < /dev/tty || break
                if [[ "$key" == $'\x1b' ]]; then
                    read -rsn2 -t 0.1 key2 < /dev/tty || true
                fi
            else
                IFS= read -rsn1 key || break
                if [[ "$key" == $'\x1b' ]]; then
                    read -rsn2 -t 0.1 key2 || true
                fi
            fi

            if [[ "$key" == $'\x1b' ]]; then
                if [[ "$key2" == "[A" ]]; then
                    ((selected--))
                    [ $selected -lt 0 ] && selected=$((num_opts - 1))
                elif [[ "$key2" == "[B" ]]; then
                    ((selected++))
                    [ $selected -ge $num_opts ] && selected=0
                fi
            elif [[ "$key" == "" ]]; then
                break
            fi

            local lines_to_clear
            if [ "$num_opts" -gt "$max_visible" ]; then
                lines_to_clear=$((max_visible + 4))
            else
                lines_to_clear=$((num_opts + 2))
            fi
            [ -n "$header" ] && ((lines_to_clear += 2))

            for ((l=0; l<lines_to_clear; l++)); do
                echo -ne "\033[1A\033[2K"
            done
        done

        tput cnorm 2>/dev/null || echo -ne "\033[?25h"
        echo "${items[$selected]}"
    fi
}

g_filter() {
    if command -v gum >/dev/null 2>&1; then
        gum filter "$@"
    else
        g_choose "$@"
    fi
}

g_input() {
    if command -v gum >/dev/null 2>&1; then
        gum input "$@"
    else
        local prompt="> " is_pw=0 placeholder=""
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --prompt) prompt="$2"; shift 2 ;;
                --prompt.foreground=*) shift ;;
                --password) is_pw=1; shift ;;
                --placeholder) placeholder="$2"; shift 2 ;;
                *) shift ;;
            esac
        done
        local val=""
        echo -ne "${PADDING_LEFT_SPACES}\033[38;5;141m${prompt}\033[0m"
        if [ $is_pw -eq 1 ]; then
            read -s -r val </dev/tty || read -s -r val || true
            echo ""
        else
            read -r val </dev/tty || read -r val || true
        fi
        echo "$val"
    fi
}

g_confirm() {
    if command -v gum >/dev/null 2>&1; then
        gum confirm "$@"
    else
        local affirmative="Sí" negative="No" question="¿Confirmar?"
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --affirmative) affirmative="$2"; shift 2 ;;
                --negative) negative="$2"; shift 2 ;;
                *) question="$1"; shift ;;
            esac
        done

        local selected=0
        local key="" key2=""

        tput civis 2>/dev/null || echo -ne "\033[?25l"

        while true; do
            echo -e "${PADDING_LEFT_SPACES}${BOLD}$question${NC}\n"
            if [ "$selected" -eq 0 ]; then
                echo -e "${PADDING_LEFT_SPACES}  ${GREEN}${BOLD}▶ [ $affirmative ] ◀${NC}       ${GRAY}  [ $negative ]  ${NC}"
            else
                echo -e "${PADDING_LEFT_SPACES}    ${GRAY}[ $affirmative ]  ${NC}     ${RED}${BOLD}▶ [ $negative ] ◀${NC}"
            fi

            if [ -e /dev/tty ] && [ -r /dev/tty ]; then
                IFS= read -rsn1 key < /dev/tty || break
                if [[ "$key" == $'\x1b' ]]; then
                    read -rsn2 -t 0.1 key2 < /dev/tty || true
                else
                    key2=""
                fi
            else
                IFS= read -rsn1 key || break
                if [[ "$key" == $'\x1b' ]]; then
                    read -rsn2 -t 0.1 key2 || true
                else
                    key2=""
                fi
            fi

            if [[ "$key" == $'\x1b' ]]; then
                if [[ "$key2" == "[D" || "$key2" == "[A" ]]; then
                    selected=0
                elif [[ "$key2" == "[C" || "$key2" == "[B" ]]; then
                    selected=1
                fi
            elif [[ "$key" == $'\t' ]]; then
                selected=$((1 - selected))
            elif [[ "$key" == "" ]]; then
                break
            fi

            echo -ne "\033[1A\033[2K\033[1A\033[2K\033[1A\033[2K"
        done

        tput cnorm 2>/dev/null || echo -ne "\033[?25h"
        return "$selected"
    fi
}

g_table() {
    local sep="|"
    local -a args=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -s|--separator)
                sep="$2"
                args+=("$1" "$2")
                shift 2
                ;;
            *)
                args+=("$1")
                shift
                ;;
        esac
    done

    local raw
    raw=$(cat)

    if command -v gum >/dev/null 2>&1; then
        if ! echo "$raw" | gum table "${args[@]}"; then
            local -a lines
            mapfile -t lines <<< "$raw"
            local col1_w=20 col2_w=46
            printf "┌%s┬%s┐\n" "$(printf "─%.0s" $(seq 1 $((col1_w + 2))))" "$(printf "─%.0s" $(seq 1 $((col2_w + 2))))"
            local first=1
            for l in "${lines[@]}"; do
                [ -z "$l" ] && continue
                IFS="$sep" read -r c1 c2 <<< "$l"
                printf "│ %-${col1_w}s │ %-${col2_w}s │\n" "$c1" "$c2"
                if [ $first -eq 1 ]; then
                    printf "├%s┼%s┤\n" "$(printf "─%.0s" $(seq 1 $((col1_w + 2))))" "$(printf "─%.0s" $(seq 1 $((col2_w + 2))))"
                    first=0
                fi
            done
            printf "└%s┴%s┘\n" "$(printf "─%.0s" $(seq 1 $((col1_w + 2))))" "$(printf "─%.0s" $(seq 1 $((col2_w + 2))))"
        fi
    else
        local -a lines
        mapfile -t lines <<< "$raw"
        local col1_w=20 col2_w=46
        printf "┌%s┬%s┐\n" "$(printf "─%.0s" $(seq 1 $((col1_w + 2))))" "$(printf "─%.0s" $(seq 1 $((col2_w + 2))))"
        local first=1
        for l in "${lines[@]}"; do
            [ -z "$l" ] && continue
            IFS="$sep" read -r c1 c2 <<< "$l"
            printf "│ %-${col1_w}s │ %-${col2_w}s │\n" "$c1" "$c2"
            if [ $first -eq 1 ]; then
                printf "├%s┼%s┤\n" "$(printf "─%.0s" $(seq 1 $((col1_w + 2))))" "$(printf "─%.0s" $(seq 1 $((col2_w + 2))))"
                first=0
            fi
        done
        printf "└%s┴%s┘\n" "$(printf "─%.0s" $(seq 1 $((col1_w + 2))))" "$(printf "─%.0s" $(seq 1 $((col2_w + 2))))"
    fi
}

g_spin() {
    if command -v gum >/dev/null 2>&1; then
        gum spin "$@"
    else
        local title=""
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --title) title="$2"; shift 2 ;;
                --spinner) shift 2 ;;
                --) shift; break ;;
                *) break ;;
            esac
        done
        echo -e "${PADDING_LEFT_SPACES}\033[38;5;39m• ${title}\033[0m"
        "$@"
    fi
}

# ------------------------------------------------------------------------------
# 3. Pantalla de Bienvenida (Greeter estilo Omarchy)
# ------------------------------------------------------------------------------
greeter() {
    measure_terminal
    local rows=$(stty size 2>/dev/null </dev/tty | awk '{print $1}')
    [[ $rows =~ ^[0-9]+$ ]] || rows=${LINES:-24}
    local content_h=$((LOGO_HEIGHT + 4))
    local top=$(((rows - content_h) / 2))
    (( top < 0 )) && top=0

    printf '\033[?25l\033[H\033[2J'
    for ((i=0; i<top; i++)); do echo ""; done

    if command -v gum >/dev/null 2>&1; then
        gum style --foreground 2 --padding "0 0 0 $PADDING_LEFT" "$LOGO_TEXT"
    else
        while IFS= read -r line; do
            echo -e "${PADDING_LEFT_SPACES}${GREEN}${line}${NC}"
        done <<< "$LOGO_TEXT"
    fi
    echo ""

    local tagline="Arch Linux + Hyprland + MrDemonc-SHELL"
    local tpad=$(((TERM_WIDTH - ${#tagline}) / 2))
    (( tpad < 0 )) && tpad=0
    printf "%*s\033[1;37m%s\033[0m\n\n" "$tpad" "" "$tagline"

    local hint="Presiona [Enter] para iniciar la instalación"
    local hpad=$(((TERM_WIDTH - ${#hint}) / 2))
    (( hpad < 0 )) && hpad=0
    printf "%*s\033[2m%s\033[0m\n" "$hpad" "" "$hint"

    IFS= read -r _ </dev/tty || IFS= read -r _ || true
    printf '\033[0m\033[H\033[2J\033[?25h'
}

# ------------------------------------------------------------------------------
# 4. Verificaciones Previas (Root y Modo UEFI)
# ------------------------------------------------------------------------------
greeter

if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}[ERROR] Este instalador debe ejecutarse como root desde la ISO de Arch Linux.${NC}"
    exit 1
fi

if [ ! -d "/sys/firmware/efi/efivars" ]; then
    echo -e "${RED}[ERROR] El sistema no arrancó en modo UEFI. Configura tu BIOS en modo UEFI.${NC}"
    exit 1
fi

timedatectl set-ntp true 2>/dev/null || true

# ------------------------------------------------------------------------------
# 5. ASISTENTE: Conexión a Internet y Redes
# ------------------------------------------------------------------------------
network_wizard() {
    if command -v systemctl >/dev/null 2>&1; then
        systemctl start NetworkManager 2>/dev/null || true
        systemctl start iwd 2>/dev/null || true
    fi
    rfkill unblock all 2>/dev/null || true
    nmcli radio wifi on 2>/dev/null || true

    while true; do
        step "Configuración de red e Internet..."

        local is_online=false
        if ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1 || ping -c 1 -W 2 archlinux.org >/dev/null 2>&1; then
            is_online=true
        fi

        local NET_OPTIONS=()
        if [ "$is_online" = true ]; then
            say --foreground 2 "Conexión a Internet verificada y activa."
            echo
            NET_OPTIONS=(
                "Continuar al siguiente paso"
                "Escanear y conectar a otra red Wi-Fi"
                "Conectar a una red Wi-Fi OCULTA (Hidden SSID)"
                "Probar conexión por cable Ethernet (DHCP)"
                "Abrir consola manual iwctl"
            )
        else
            say --foreground 1 "● Desconectado (se recomienda Internet para descargar actualizaciones)"
            echo
            NET_OPTIONS=(
                "Escanear y conectar a una red Wi-Fi visible"
                "Conectar a una red Wi-Fi OCULTA (Hidden SSID)"
                "Probar conexión por cable Ethernet (DHCP)"
                "Abrir consola manual iwctl"
                "Continuar sin conexión (Instalación offline)"
            )
        fi

        local sel
        sel=$(printf '%s\n' "${NET_OPTIONS[@]}" | g_choose --height 6 --header "Opciones de conexión disponibles:")

        if [[ "$sel" =~ ^Continuar ]]; then
            return 0
        elif [[ "$sel" =~ ^Escanear ]]; then
            step "Escaneando redes Wi-Fi cercanas..."
            if command -v nmcli >/dev/null 2>&1; then
                nmcli dev wifi rescan 2>/dev/null || true
                g_spin --spinner "pulse" --title "Buscando puntos de acceso inalámbricos..." -- sleep 2
                mapfile -t FOUND_SSIDS < <(nmcli -t -f SSID dev wifi list 2>/dev/null | grep -v '^$' | awk '!seen[$0]++' | head -n 12)
                
                local wifi_choice=""
                if [ ${#FOUND_SSIDS[@]} -gt 0 ]; then
                    wifi_choice=$(printf '%s\n' "${FOUND_SSIDS[@]}" "Escribir SSID manualmente" | \
                        g_choose --height 8 --header "Selecciona tu red Wi-Fi:")
                    if [ "$wifi_choice" == "Escribir SSID manualmente" ]; then
                        wifi_choice=$(g_input --placeholder "Nombre de la red" --prompt.foreground="#845DF9" --prompt "SSID> ")
                    fi
                else
                    wifi_choice=$(g_input --placeholder "Nombre de la red" --prompt.foreground="#845DF9" --prompt "SSID> ")
                fi

                if [ -n "$wifi_choice" ]; then
                    local wifi_pass
                    wifi_pass=$(g_input --placeholder "Contraseña (dejar vacío si es abierta)" --password --prompt.foreground="#845DF9" --prompt "Contraseña> ")
                    step "Conectando a $wifi_choice..."
                    if [ -n "$wifi_pass" ]; then
                        nmcli dev wifi connect "$wifi_choice" password "$wifi_pass" || say --foreground 1 "Falló la conexión."
                    else
                        nmcli dev wifi connect "$wifi_choice" || true
                    fi
                    sleep 2
                fi
            elif command -v iwctl >/dev/null 2>&1; then
                local wlan_dev
                wlan_dev=$(iwctl device list 2>/dev/null | awk '/station/ {print $2}' | head -n 1)
                wlan_dev="${wlan_dev:-wlan0}"
                iwctl station "$wlan_dev" scan 2>/dev/null || true
                sleep 1
                local wifi_choice
                wifi_choice=$(g_input --placeholder "Nombre de la red" --prompt.foreground="#845DF9" --prompt "SSID> ")
                if [ -n "$wifi_choice" ]; then
                    iwctl station "$wlan_dev" connect "$wifi_choice" || true
                fi
                sleep 2
            fi
        elif [[ "$sel" =~ OCULTA ]]; then
            step "Conectar a red Wi-Fi OCULTA..."
            local hidden_ssid hidden_pass
            hidden_ssid=$(g_input --placeholder "Nombre exacto de la red oculta" --prompt.foreground="#845DF9" --prompt "SSID> ")
            if [ -n "$hidden_ssid" ]; then
                hidden_pass=$(g_input --placeholder "Contraseña" --password --prompt.foreground="#845DF9" --prompt "Contraseña> ")
                step "Conectando a red oculta $hidden_ssid..."
                if command -v nmcli >/dev/null 2>&1; then
                    if [ -n "$hidden_pass" ]; then
                        nmcli dev wifi connect "$hidden_ssid" password "$hidden_pass" hidden yes || true
                    else
                        nmcli dev wifi connect "$hidden_ssid" hidden yes || true
                    fi
                fi
                sleep 2
            fi
        elif [[ "$sel" =~ Ethernet ]]; then
            g_spin --spinner "pulse" --title "Solicitando dirección IP vía DHCP..." -- dhcpcd 2>/dev/null || true
            sleep 2
        elif [[ "$sel" =~ iwctl ]]; then
            clear
            iwctl || true
        fi
    done
}
network_wizard

# ------------------------------------------------------------------------------
# 6. ASISTENTE: Teclado e Idioma
# ------------------------------------------------------------------------------
keyboard_wizard() {
    step "Configuración del teclado..."

    local KB_CHOICES=(
        "Latinoamericano (la-latin1)"
        "Español España (es)"
        "Inglés / US (us)"
    )

    local kb_selected
    kb_selected=$(printf '%s\n' "${KB_CHOICES[@]}" | g_choose --height 5 --selected "Latinoamericano (la-latin1)" --header "Selecciona la distribución de teclado:")

    case "$kb_selected" in
        *"Español España"*)
            KEYMAP="es"
            HYPR_KB="es"
            ;;
        *"Inglés / US"*)
            KEYMAP="us"
            HYPR_KB="us"
            ;;
        *)
            KEYMAP="la-latin1"
            HYPR_KB="latam"
            ;;
    esac

    loadkeys "$KEYMAP" 2>/dev/null || true
}
keyboard_wizard

locale_wizard() {
    step "Configuración del idioma del sistema..."

    local LOCALE_CHOICES=(
        "Español (España) [es_ES.UTF-8]"
        "Español (Latinoamérica) [es_MX.UTF-8]"
        "Español (Perú) [es_PE.UTF-8]"
        "Español (Argentina) [es_AR.UTF-8]"
        "Español (Chile) [es_CL.UTF-8]"
        "Español (Colombia) [es_CO.UTF-8]"
        "English (United States) [en_US.UTF-8]"
    )

    local loc_selected
    loc_selected=$(printf '%s\n' "${LOCALE_CHOICES[@]}" | g_choose --height 7 --selected "Español (España) [es_ES.UTF-8]" --header "Selecciona el idioma principal:")

    case "$loc_selected" in
        *"es_MX"*) SYS_LOCALE="es_MX.UTF-8" ;;
        *"es_PE"*) SYS_LOCALE="es_PE.UTF-8" ;;
        *"es_AR"*) SYS_LOCALE="es_AR.UTF-8" ;;
        *"es_CL"*) SYS_LOCALE="es_CL.UTF-8" ;;
        *"es_CO"*) SYS_LOCALE="es_CO.UTF-8" ;;
        *"en_US"*) SYS_LOCALE="en_US.UTF-8" ;;
        *)         SYS_LOCALE="es_ES.UTF-8" ;;
    esac
}
locale_wizard

# ------------------------------------------------------------------------------
# 7. ASISTENTE: Cuenta de Usuario, Clave Maestra, Hostname y Git
# ------------------------------------------------------------------------------
user_form_wizard() {
    local TIMEZONES=(
        "America/Lima"
        "America/Santiago"
        "America/Bogota"
        "America/Argentina/Buenos_Aires"
        "America/Mexico_City"
        "America/Caracas"
        "America/La_Paz"
        "America/Montevideo"
        "America/Guayaquil"
        "America/Asuncion"
        "America/Panama"
        "America/Costa_Rica"
        "America/Guatemala"
        "America/Madrid"
        "America/New_York"
        "America/Chicago"
        "America/Los_Angeles"
        "UTC"
    )

    while true; do
        step "Configuración de la cuenta de usuario..."
        say "Crea tu usuario personal. La contraseña maestra servirá para LUKS2, root y sudo."
        echo

        SYS_USER=""
        while [[ -z "$SYS_USER" || ! "$SYS_USER" =~ ^[a-z_][a-z0-9_-]*$ ]]; do
            SYS_USER=$(g_input --placeholder "Solo minúsculas y números (ej: usuario)" --prompt.foreground="#845DF9" --prompt "Usuario> ")
            if [[ -z "$SYS_USER" || ! "$SYS_USER" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
                say --foreground 1 "El usuario debe contener únicamente letras minúsculas y números."
            fi
        done

        while true; do
            MASTER_PASS=$(g_input --placeholder "Contraseña maestra unificada" --password --prompt.foreground="#845DF9" --prompt "Contraseña Maestra> ")
            local pass_confirm
            pass_confirm=$(g_input --placeholder "Confirma la contraseña maestra" --password --prompt.foreground="#845DF9" --prompt "Confirmar> ")
            if [[ -n "$MASTER_PASS" && "$MASTER_PASS" == "$pass_confirm" ]]; then
                break
            else
                say --foreground 1 "Las contraseñas no coinciden o están vacías. Inténtalo de nuevo."
                echo
            fi
        done

        SYS_HOSTNAME=$(g_input --placeholder "Nombre de la máquina (o Enter para 'archlinux')" --prompt.foreground="#845DF9" --prompt "Hostname> ")
        SYS_HOSTNAME="${SYS_HOSTNAME:-archlinux}"

        GIT_USER_NAME=$(g_input --placeholder "Nombre completo para Git (Enter para omitir)" --prompt.foreground="#845DF9" --prompt "Nombre Git> ")
        GIT_USER_EMAIL=$(g_input --placeholder "Correo electrónico para Git (Enter para omitir)" --prompt.foreground="#845DF9" --prompt "Correo Git> ")

        echo
        SYS_TIMEZONE=$(printf '%s\n' "${TIMEZONES[@]}" | g_choose --height 8 --selected "America/Lima" --header "Selecciona tu Zona Horaria:")
        SYS_TIMEZONE="${SYS_TIMEZONE:-America/Lima}"

        # Tabla de resumen estilo Omarchy
        step "Resumen de la configuración de usuario"
        local table_data="Campo|Valor
Usuario|$SYS_USER
Contraseña|$(printf "%${#MASTER_PASS}s" | tr ' ' '*')
Hostname|$SYS_HOSTNAME
Zona Horaria|$SYS_TIMEZONE
Idioma|$SYS_LOCALE
Teclado|$KEYMAP
Nombre Git|${GIT_USER_NAME:-[Omitido]}
Correo Git|${GIT_USER_EMAIL:-[Omitido]}"

        echo "$table_data" | g_table -s "|" -p | sed "s/^/${PADDING_LEFT_SPACES}/" || true
        echo

        if g_confirm --affirmative "Sí, continuar" --negative "No, modificar" "¿Los datos de usuario son correctos?"; then
            break
        fi
    done
}
user_form_wizard

# ------------------------------------------------------------------------------
# 8. ASISTENTE: Disco Objetivo de Instalación
# ------------------------------------------------------------------------------
disk_wizard() {
    step "Selección de unidad de almacenamiento..."

    mapfile -t RAW_DISKS < <(lsblk -d -p -n -l -o NAME,SIZE,MODEL,TYPE 2>/dev/null | grep -E "disk" | grep -v -E "zram|loop|airoot")
    if [ ${#RAW_DISKS[@]} -eq 0 ]; then
        say --foreground 1 "No se detectaron discos de almacenamiento disponibles."
        exit 1
    fi

    local bootmnt_dev bootmnt_parent=""
    bootmnt_dev=$(findmnt -n -o SOURCE /run/archiso/bootmnt 2>/dev/null || true)
    if [ -n "$bootmnt_dev" ]; then
        bootmnt_parent=$(lsblk -n -o PKNAME "$bootmnt_dev" 2>/dev/null || true)
        [ -n "$bootmnt_parent" ] && bootmnt_parent="/dev/$bootmnt_parent"
    fi

    local DISK_OPTIONS=()
    for d_line in "${RAW_DISKS[@]}"; do
        local d_name d_size d_model label
        d_name=$(echo "$d_line" | awk '{print $1}')
        d_size=$(echo "$d_line" | awk '{print $2}')
        d_model=$(echo "$d_line" | awk '{$1=$2=""; print $0}' | sed 's/disk//g' | xargs)
        label="$d_name ($d_size${d_model:+ - $d_model})"
        if [ -n "$bootmnt_parent" ] && [ "$d_name" == "$bootmnt_parent" ]; then
            label="$label [USB Live]"
        fi
        DISK_OPTIONS+=("$label")
    done

    local disk_selected
    disk_selected=$(printf '%s\n' "${DISK_OPTIONS[@]}" | g_choose --height 6 --header "Selecciona el disco para la instalación:")
    TARGET_DISK=$(echo "$disk_selected" | awk '{print $1}')

    if [ -n "$bootmnt_parent" ] && [ "$TARGET_DISK" == "$bootmnt_parent" ]; then
        say --foreground 1 "El disco elegido parece ser el medio USB de instalación."
        if ! g_confirm --affirmative "Continuar" --negative "Cancelar" "¿Deseas formatear este dispositivo de todas formas?"; then
            exit 1
        fi
    fi
}
disk_wizard

# ------------------------------------------------------------------------------
# 9. PANTALLA FINAL: Botón [ 🚀 INSTALAR ] estilo Omarchy
# ------------------------------------------------------------------------------
install_confirm() {
    clear_logo
    echo
    say --foreground 1 "¡ADVERTENCIA: SE FORMATEARÁ POR COMPLETO EL DISCO $TARGET_DISK!"
    say "Se creará una partición EFI y una partición Linux cifrada con LUKS2 (BTRFS)."
    echo

    local table_summary="Parámetro|Configuración
Disco|$TARGET_DISK
Cifrado|LUKS2 (Argon2id Automático)
Sistema de Archivos|BTRFS (@, @home, @snapshots, @var_log, @pkg)
Usuario|$SYS_USER (Sudo activo)
Hostname|$SYS_HOSTNAME
Zona Horaria|$SYS_TIMEZONE
Idioma / Teclado|$SYS_LOCALE / $KEYMAP"

    echo "$table_summary" | g_table -s "|" -p | sed "s/^/${PADDING_LEFT_SPACES}/" || true
    echo

    if ! g_confirm --affirmative "INSTALAR" --negative "CANCELAR" "¿Comenzar la instalación del sistema ahora?"; then
        say --foreground 8 "Instalación cancelada por el usuario. No se modificó ningún disco."
        exit 0
    fi
}
install_confirm

# ------------------------------------------------------------------------------
# 10. Vista de Instalación y Dashboard Dinámico (Estilo Omarchy)
# ------------------------------------------------------------------------------
INSTALL_STATE_FILE="/tmp/arch-install.state"
INSTALL_LOG_FILE="/tmp/arch-install.log"

set_phase() {
    local phase="$1"
    local pct="$2"
    echo "${phase}|${pct}" > "$INSTALL_STATE_FILE"
}

tips=(
    "Super + Space abre el lanzador de aplicaciones de MrDemonc-SHELL"
    "Super + Return abre la terminal Kitty con la paleta Tokyo Night"
    "Super + 1..9 cambia rápidamente entre los escritorios virtuales"
    "Super + Shift + Q cierra la ventana actualmente seleccionada"
    "Super + E abre el gestor de archivos Dolphin"
    "Super + V abre el historial del gestor de portapapeles"
    "La barra superior es totalmente interactiva y modular con Quickshell"
    "El sistema cuenta con Btrfs, snapshots y cifrado LUKS2 para máxima seguridad"
    "Zsh viene preconfigurado con autosugerencias, resaltado y Starship prompt"
    "El inicio de sesión Seamless te lleva directo a Hyprland sin intermediarios"
    "Super + K muestra la guía completa de atajos de teclado"
    "Puedes personalizar temas y acentos de color desde ~/.config/hypr"
)

perform_installation_worker() {
    set -eo pipefail
    exec >> "$INSTALL_LOG_FILE" 2>&1

    set_phase "Preparando particiones en el almacenamiento" 5
    swapoff -a 2>/dev/null || true
    umount -R /mnt 2>/dev/null || true
    cryptsetup close cryptroot 2>/dev/null || true

    sgdisk --zap-all "$TARGET_DISK" >/dev/null 2>&1 || true
    wipefs -a "$TARGET_DISK" >/dev/null 2>&1 || true
    partprobe "$TARGET_DISK" 2>/dev/null || true
    udevadm settle 2>/dev/null || true
    sleep 1

    # Partición 1: EFI 1024MB | Partición 2: LUKS2 Linux
    sgdisk -n 1:0:+1024M -t 1:ef00 -c 1:"EFI System Partition" "$TARGET_DISK"
    sgdisk -n 2:0:0 -t 2:8300 -c 2:"Linux LUKS Btrfs" "$TARGET_DISK"
    partprobe "$TARGET_DISK" 2>/dev/null || true
    udevadm settle 2>/dev/null || true
    sleep 1

    if [[ "$TARGET_DISK" =~ [0-9]$ ]]; then
        PART_EFI="${TARGET_DISK}p1"
        PART_ROOT="${TARGET_DISK}p2"
    else
        PART_EFI="${TARGET_DISK}1"
        PART_ROOT="${TARGET_DISK}2"
    fi

    set_phase "Formateando partición EFI y configurando LUKS2" 15
    mkfs.fat -F 32 -n EFI "$PART_EFI" >/dev/null

    echo -n "$MASTER_PASS" | cryptsetup luksFormat --type luks2 --pbkdf argon2id --batch-mode "$PART_ROOT" -
    echo -n "$MASTER_PASS" | cryptsetup open "$PART_ROOT" cryptroot -

    set_phase "Creando sistema de archivos y subvolúmenes Btrfs" 25
    ROOT_DEV="/dev/mapper/cryptroot"
    mkfs.btrfs -f -L ARCHROOT "$ROOT_DEV" >/dev/null

    mount "$ROOT_DEV" /mnt
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

    set_phase "Instalando paquetes base con pacstrap" 35
    UCODE_PKG=""
    if grep -q "AuthenticAMD" /proc/cpuinfo; then
        UCODE_PKG="amd-ucode"
    elif grep -q "GenuineIntel" /proc/cpuinfo; then
        UCODE_PKG="intel-ucode"
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
    [ -n "$UCODE_PKG" ] && BASE_PACKAGES+=("$UCODE_PKG")

    pacstrap -K /mnt "${BASE_PACKAGES[@]}"
    genfstab -U /mnt >> /mnt/etc/fstab

    set_phase "Configurando sistema interno, usuarios e initramfs" 75
    ROOT_UUID=$(blkid -s UUID -o value "$PART_ROOT")
    BOOT_ENTRY_OPTIONS="cryptdevice=UUID=$ROOT_UUID:cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rw quiet splash"
    MKINITCPIO_HOOKS="base udev autodetect modconf kms keyboard keymap consolefont block encrypt btrfs filesystems fsck"

    UCODE_LINE=""
    [ -n "$UCODE_PKG" ] && UCODE_LINE="initrd  /$UCODE_PKG.img"

    cat << CHROOT_SCRIPT > /mnt/tmp/setup_chroot.sh
#!/usr/bin/env bash
set -e

ln -sf /usr/share/zoneinfo/$SYS_TIMEZONE /etc/localtime
hwclock --systohc

sed -i "s/#$SYS_LOCALE UTF-8/$SYS_LOCALE UTF-8/" /etc/locale.gen
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen 2>/dev/null || true
locale-gen
echo "LANG=$SYS_LOCALE" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

echo "$SYS_HOSTNAME" > /etc/hostname
cat << HOSTS > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   $SYS_HOSTNAME.localdomain $SYS_HOSTNAME
HOSTS

echo "root:$MASTER_PASS" | chpasswd
useradd -m -g users -G wheel,video,audio,storage,optical,network -s /usr/bin/zsh "$SYS_USER"
echo "$SYS_USER:$MASTER_PASS" | chpasswd

echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel
chmod 440 /etc/sudoers.d/wheel

if [ -n "$GIT_USER_NAME" ]; then
    su - "$SYS_USER" -c "git config --global user.name '$GIT_USER_NAME'"
fi
if [ -n "$GIT_USER_EMAIL" ]; then
    su - "$SYS_USER" -c "git config --global user.email '$GIT_USER_EMAIL'"
fi
su - "$SYS_USER" -c "git config --global init.defaultBranch main" 2>/dev/null || true

sed -i "s/^HOOKS=.*/HOOKS=($MKINITCPIO_HOOKS)/" /etc/mkinitcpio.conf
mkinitcpio -P

bootctl install --esp-path=/boot

cat << LOADER > /boot/loader/loader.conf
default  arch.conf
timeout  3
console-mode max
editor   no
LOADER

cat << ENTRY > /boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
$UCODE_LINE
initrd  /initramfs-linux.img
options $BOOT_ENTRY_OPTIONS
ENTRY

cat << ENTRY_FALLBACK > /boot/loader/entries/arch-fallback.conf
title   Arch Linux (fallback initramfs)
linux   /vmlinuz-linux
$UCODE_LINE
initrd  /initramfs-linux-fallback.img
options $BOOT_ENTRY_OPTIONS
ENTRY_FALLBACK

systemctl enable NetworkManager.service
systemctl enable bluetooth.service 2>/dev/null || true
systemctl enable systemd-timesyncd.service 2>/dev/null || true

# Seamless Login en tty1
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat << GETTY_CONF > /etc/systemd/system/getty@tty1.service.d/autologin.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty -o '-p -f -- \\u' --noclear --autologin $SYS_USER %I \$TERM
Type=idle
GETTY_CONF

# Oh My Zsh
su - "$SYS_USER" -c 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended' || true

USER_ZSHRC="/home/$SYS_USER/.zshrc"
touch "\$USER_ZSHRC"
if ! grep -q "plugins=" "\$USER_ZSHRC" 2>/dev/null; then
    echo "plugins=(git zsh-autosuggestions zsh-syntax-highlighting)" >> "\$USER_ZSHRC"
else
    sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "\$USER_ZSHRC" 2>/dev/null || true
fi

if ! grep -q "exec Hyprland" "\$USER_ZSHRC" 2>/dev/null; then
    cat << 'AUTO_HYPR' >> "\$USER_ZSHRC"

# Auto-start Hyprland en tty1
if [ -z "\$DISPLAY" ] && [ "\$(tty)" = "/dev/tty1" ]; then
    exec Hyprland
fi
AUTO_HYPR
fi

# Configuración Starship
mkdir -p "/home/$SYS_USER/.config"
if ! grep -q "starship init zsh" "\$USER_ZSHRC" 2>/dev/null; then
    echo 'eval "$(starship init zsh)"' >> "\$USER_ZSHRC"
fi

CHROOT_SCRIPT

    chmod +x /mnt/tmp/setup_chroot.sh
    arch-chroot /mnt /tmp/setup_chroot.sh
    rm -f /mnt/tmp/setup_chroot.sh

    set_phase "Desplegando entorno gráfico MrDemonc-SHELL" 88
    DEST_REPO="/mnt/home/$SYS_USER/Documentos/MrDemonc-SHELL"
    mkdir -p "/mnt/home/$SYS_USER/Documentos"

    if [ -d "/usr/share/mrdemonc-shell" ]; then
        cp -a /usr/share/mrdemonc-shell "$DEST_REPO"
    elif [ -d "/home/demonc-test/Documentos/MrDemonc-SHELL" ]; then
        cp -a "/home/demonc-test/Documentos/MrDemonc-SHELL" "$DEST_REPO"
    else
        git clone https://github.com/MrDemonc/MrDemonc-SHELL.git "$DEST_REPO" || true
    fi

    chmod +x "$DEST_REPO"/scripts/*.sh 2>/dev/null || true
    chmod +x "$DEST_REPO"/scripts/*.py 2>/dev/null || true

    USER_HOME="/mnt/home/$SYS_USER"
    mkdir -p "$USER_HOME/.config/hypr"
    mkdir -p "$USER_HOME/.config/kitty"
    mkdir -p "$USER_HOME/.config/quickshell"
    mkdir -p "$USER_HOME/.local/bin"
    mkdir -p "$USER_HOME/.local/state/mrdemonc/current/theme"
    mkdir -p "$USER_HOME/Pictures/Wallpapers"

    if [ -d "$DEST_REPO/hypr" ]; then
        cp -f "$DEST_REPO/hypr/windows.lua" "$USER_HOME/.config/hypr/windows.lua"
        cp -f "$DEST_REPO/hypr/keybinds.lua" "$USER_HOME/.config/hypr/keybinds.lua"
        cp -f "$DEST_REPO/hypr/theme_colors.lua" "$USER_HOME/.config/hypr/theme_colors.lua" 2>/dev/null || true
        cp -f "$DEST_REPO/hypr/hyprlock.conf" "$USER_HOME/.config/hypr/hyprlock.conf" 2>/dev/null || true
        cp -f "$DEST_REPO/hypr/hyprlock_colors.conf" "$USER_HOME/.config/hypr/hyprlock_colors.conf" 2>/dev/null || true
        cp -f "$DEST_REPO/hypr/hypridle.conf" "$USER_HOME/.config/hypr/hypridle.conf" 2>/dev/null || true

        sed "s|userHome .. \"/Documentos/MrDemonc-SHELL\"|\"/home/$SYS_USER/Documentos/MrDemonc-SHELL\"|g" \
            "$DEST_REPO/hypr/hyprland.lua" > "$USER_HOME/.config/hypr/hyprland.lua"
        sed -i "s/kb_layout  = \".*\"/kb_layout  = \"$HYPR_KB\"/g" "$USER_HOME/.config/hypr/hyprland.lua"
    fi

    cat << WRAP_APPS > "$USER_HOME/.local/bin/shell-apps"
#!/usr/bin/env bash
exec /home/$SYS_USER/Documentos/MrDemonc-SHELL/scripts/toggle_apps.sh "\$@"
WRAP_APPS

    cat << WRAP_WALL > "$USER_HOME/.local/bin/shell-wallpaper"
#!/usr/bin/env bash
exec /home/$SYS_USER/Documentos/MrDemonc-SHELL/scripts/toggle_wallpaper.sh "\$@"
WRAP_WALL

    chmod +x "$USER_HOME/.local/bin"/* 2>/dev/null || true

    if [ -d "$DEST_REPO/kitty" ]; then
        cp -f "$DEST_REPO/kitty/kitty.conf" "$USER_HOME/.config/kitty/kitty.conf"
    fi

    cat << QS_CONFIG > "$USER_HOME/.config/quickshell/shell.qml"
import Quickshell
import "/home/$SYS_USER/Documentos/MrDemonc-SHELL"

ShellRoot {
}
QS_CONFIG

    cat << 'THEME_TOML' > "$USER_HOME/.local/state/mrdemonc/current/theme/colors.toml"
accent = "#89b4fa"
background = "#1e1e2e"
color0 = "#45475a"
color1 = "#f38ba8"
color2 = "#a6e3a1"
color3 = "#f9e2af"
color4 = "#89b4fa"
color5 = "#f5c2e7"
color6 = "#89dceb"
color7 = "#bac2de"
color8 = "#585b70"
color9 = "#f38ba8"
color10 = "#a6e3a1"
color11 = "#f9e2af"
color12 = "#89b4fa"
color13 = "#f5c2e7"
color14 = "#89dceb"
color15 = "#a6adc8"
foreground = "#cdd6f4"
THEME_TOML

    if [ -f "$DEST_REPO/scripts/theme_manager.py" ]; then
        python3 "$DEST_REPO/scripts/theme_manager.py" apply catppuccin-mocha 2>/dev/null || true
    fi

    cat << STARSHIP_CONF > "$USER_HOME/.config/starship.toml"
add_newline = false
format = "[╭─](bold cyan)\$all[╰─❯ ](bold cyan)"

[character]
success_symbol = "[➜](bold green)"
error_symbol = "[➜](bold red)"

[directory]
truncation_length = 3
truncation_symbol = "…/"
style = "bold cyan"

[git_branch]
style = "bold purple"
symbol = " "

[git_status]
style = "bold red"
STARSHIP_CONF

    arch-chroot /mnt chown -R "$SYS_USER:users" "/home/$SYS_USER"

    set_phase "Finalizando instalación y sincronizando almacenamiento" 98
    sync
    umount -R /mnt 2>/dev/null || true
    cryptsetup close cryptroot 2>/dev/null || true

    set_phase "Instalación completada" 100
}

run_install_with_dashboard() {
    local start_epoch=$SECONDS
    local tty_cols=$(stty size 2>/dev/null </dev/tty | awk '{print $2}')
    (( tty_cols > 0 )) || tty_cols=${COLUMNS:-80}
    local tty_rows=$(stty size 2>/dev/null </dev/tty | awk '{print $1}')
    [[ $tty_rows =~ ^[0-9]+$ ]] || tty_rows=${LINES:-24}

    # Centrado vertical idéntico a Omarchy
    local content_h=$((LOGO_HEIGHT + 7))
    local top_row=$(((tty_rows - content_h) / 2))
    (( top_row < 0 )) && top_row=0
    local dynamic_row=$((top_row + LOGO_HEIGHT + 2))

    # Ocultar cursor y limpiar pantalla
    printf '\033[?25l\033[H\033[2J'

    # Dibujar logo centrado una vez en la posición inicial
    printf '\033[%d;1H' "$((top_row + 1))"
    if command -v gum >/dev/null 2>&1; then
        gum style --foreground 2 --padding "0 0 0 $PADDING_LEFT" "$LOGO_TEXT"
    else
        while IFS= read -r line; do
            echo -e "${PADDING_LEFT_SPACES}${GREEN}${line}${NC}"
        done <<< "$LOGO_TEXT"
    fi

    rm -f "$INSTALL_STATE_FILE" "$INSTALL_LOG_FILE"
    touch "$INSTALL_LOG_FILE"

    # Lanzar trabajador de instalación en segundo plano con registros redirigidos
    perform_installation_worker &
    local worker_pid=$!

    local last_pct=5
    local current_phase="Iniciando instalación de Arch Linux..."
    local tip_idx=0
    local last_tip_time=$SECONDS

    while kill -0 "$worker_pid" 2>/dev/null; do
        if [ -f "$INSTALL_STATE_FILE" ]; then
            local state_line
            state_line=$(cat "$INSTALL_STATE_FILE" 2>/dev/null || true)
            if [ -n "$state_line" ]; then
                IFS="|" read -r current_phase raw_pct <<< "$state_line"
                if [[ "$raw_pct" =~ ^[0-9]+$ ]]; then
                    if [ "$raw_pct" -gt "$last_pct" ]; then
                        last_pct=$raw_pct
                    fi
                fi
            fi
        fi

        # Si estamos en pacstrap, extrapolar avance en tiempo real según paquetes instalados en /mnt
        if [[ "$current_phase" =~ pacstrap ]]; then
            local pkg_count
            pkg_count=$(ls -1 /mnt/var/lib/pacman/local 2>/dev/null | wc -l)
            if [ "$pkg_count" -gt 0 ]; then
                local dynamic_calc=$(( 35 + (pkg_count * 38 / 115) ))
                if [ "$dynamic_calc" -gt "$last_pct" ] && [ "$dynamic_calc" -lt 75 ]; then
                    last_pct=$dynamic_calc
                fi
            fi
        fi

        if (( SECONDS - last_tip_time >= 8 )); then
            tip_idx=$(( (tip_idx + 1) % ${#tips[@]} ))
            last_tip_time=$SECONDS
        fi
        local tip="${tips[$tip_idx]}"

        # Renderizado estático-dinámico sin parpadeo (usando posicionamiento de cursor ANSI)
        printf '\033[%d;1H' "$dynamic_row"

        center_text "\033[1;37mInstalando Arch Linux\033[0m" "$tty_cols"
        printf '\r\033[2K\n'

        center_text "\033[38;5;242m${current_phase}\033[0m" "$tty_cols"
        printf '\r\033[2K\n'

        local bar_w=36
        local filled=$(( last_pct * bar_w / 100 ))
        local empty=$(( bar_w - filled ))
        local bar_str=""
        for ((i=0; i<filled; i++)); do bar_str+="█"; done
        local empty_str=""
        for ((i=0; i<empty; i++)); do empty_str+="░"; done
        local bar_rendered="\033[38;5;42m${bar_str}\033[38;5;238m${empty_str}\033[0m  \033[1;37m${last_pct}%\033[0m"
        center_text "$bar_rendered" "$tty_cols"
        printf '\r\033[2K\n'

        center_text "\033[2mTip:\033[0m \033[38;5;42m${tip}\033[0m" "$tty_cols"
        printf '\r\033[2K\n'
        printf '\033[J'

        sleep 0.5
    done

    wait "$worker_pid"
    local worker_exit=$?

    # Restaurar cursor visible
    printf '\033[?25h'

    if [ "$worker_exit" -ne 0 ]; then
        printf '\033[H\033[2J'
        echo
        say --foreground 1 "¡ERROR DURANTE LA INSTALACIÓN (Código de salida: $worker_exit)!"
        say "Fase: $current_phase"
        echo
        say --foreground 8 "Últimas líneas del registro (/tmp/arch-install.log):"
        echo
        tail -n 18 "$INSTALL_LOG_FILE" 2>/dev/null | sed "s/^/${PADDING_LEFT_SPACES}/"
        echo
        say "Puedes revisar el registro completo con: cat /tmp/arch-install.log"
        exit "$worker_exit"
    fi

    local elapsed=$(( SECONDS - start_epoch ))
    local mins=$(( elapsed / 60 ))
    local secs=$(( elapsed % 60 ))
    local duration_str=""
    if [ "$mins" -gt 0 ]; then
        duration_str="${mins}m ${secs}s"
    else
        duration_str="${secs}s"
    fi

    # Pantalla final de finalización (Finish Screen estilo Omarchy)
    clear_logo
    echo
    center_text "\033[1;32m¡Arch Linux instalado con éxito en ${duration_str}!\033[0m" "$tty_cols"
    echo
    center_text "\033[38;5;242mEl sistema está configurado y listo para iniciar directamente en Hyprland.\033[0m" "$tty_cols"
    echo
    echo

    if g_confirm --affirmative "Reiniciar ahora" --negative "Salir a la consola" "¿Deseas reiniciar el equipo ahora?"; then
        echo
        say --foreground 6 "Reiniciando equipo..."
        sleep 1
        reboot
    else
        echo
        say --foreground 8 "Puedes reiniciar manualmente escribiendo: reboot"
    fi
}

run_install_with_dashboard
