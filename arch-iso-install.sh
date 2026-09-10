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

# Logo ARCH elaborado (tipografía idéntica a Omarchy, 47 columnas, 9 líneas)
LOGO_TEXT=$(cat << "EOF"
 ▄███████    ▄███████     ▄███████    ▄█   █▄  
███   ███   ███   ███    ███   ███   ███   ███ 
███   ███   ███   ███    ███   █▀    ███   ███ 
███▄▄▄███   ███▄▄▄██▀    ███         ███▄▄▄███▄
███▀▀▀███   ███▀▀▀▀      ███         ███▀▀▀███ 
███   ███   █████████    ███   █▄    ███   ███ 
███   ███   ███   ███    ███   ███   ███   ███ 
███   █▀    ███   ███    ███████▀    ███   █▀  
            ███   █▀                           
EOF
)
LOGO_WIDTH=47
LOGO_HEIGHT=9

CONTENT_WIDTH=74

# Medición dinámica del ancho del terminal y cálculo de padding para centrado
measure_terminal() {
    local new_ts
    new_ts=$(stty size 2>/dev/null </dev/tty || true)
    local new_h=$(echo "$new_ts" | awk '{print $1}')
    local new_w=$(echo "$new_ts" | awk '{print $2}')
    
    if [[ "$new_w" =~ ^[0-9]+$ ]] && [[ "$new_h" =~ ^[0-9]+$ ]] && [ "$new_w" -gt 0 ] && [ "$new_h" -gt 0 ]; then
        TERM_WIDTH=$new_w
        TERM_HEIGHT=$new_h
    elif [ -z "$TERM_WIDTH" ] || [ -z "$TERM_HEIGHT" ]; then
        TERM_WIDTH=$(tput cols 2>/dev/null || echo "${COLUMNS:-80}")
        TERM_HEIGHT=$(tput lines 2>/dev/null || echo "${LINES:-24}")
    fi

    PADDING_LEFT=$(((TERM_WIDTH - CONTENT_WIDTH) / 2))
    (( PADDING_LEFT < 0 )) && PADDING_LEFT=0
    PADDING_LEFT_SPACES=$(printf "%*s" "$PADDING_LEFT" "")

    LOGO_PADDING=$(((TERM_WIDTH - LOGO_WIDTH) / 2))
    (( LOGO_PADDING < 0 )) && LOGO_PADDING=0
    LOGO_PADDING_SPACES=$(printf "%*s" "$LOGO_PADDING" "")

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
    printf '\033[2K%*s%b\n' "$pad" '' "$text"
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
            3) color="\033[38;5;220m" ;;
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
    local start_row=2
    printf "\033[%d;1H" "$start_row"

    echo ""
    while IFS= read -r line; do
        echo -e "${LOGO_PADDING_SPACES}${GREEN}${line}${NC}"
    done <<< "$LOGO_TEXT"
    echo ""
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
        gum choose --limit 1 "$@"
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

        local last_printed_lines=0
        while true; do
            if [ "$last_printed_lines" -gt 0 ]; then
                for ((l=0; l<last_printed_lines; l++)); do
                    echo -ne "\033[1A\033[2K"
                done
            fi

            local printed_lines=0
            if [ -n "$header" ]; then
                echo -e "${PADDING_LEFT_SPACES}${BOLD}${header}${NC}"
                echo ""
                ((printed_lines += 2))
            fi

            if [ "$num_opts" -gt "$max_visible" ]; then
                if [ "$selected" -ge $((window_start + max_visible)) ]; then
                    window_start=$((selected - max_visible + 1))
                elif [ "$selected" -lt "$window_start" ]; then
                    window_start=$selected
                fi

                if [ "$window_start" -gt 0 ]; then
                    echo -e "${PADDING_LEFT_SPACES}  ${ARCH_BLUE}▲ (${window_start} más arriba)${NC}"
                else
                    echo -e "${PADDING_LEFT_SPACES}  ${DARK_GRAY}•${NC}"
                fi
                ((printed_lines++))

                for ((i=window_start; i<window_start+max_visible && i<num_opts; i++)); do
                    if [ "$i" -eq "$selected" ]; then
                        echo -e "${PADDING_LEFT_SPACES}  ${GREEN}${BOLD}> ${items[$i]}${NC}"
                    else
                        echo -e "${PADDING_LEFT_SPACES}    ${GRAY}${items[$i]}${NC}"
                    fi
                    ((printed_lines++))
                done

                local rem=$((num_opts - (window_start + max_visible)))
                if [ "$rem" -gt 0 ]; then
                    echo -e "${PADDING_LEFT_SPACES}  ${ARCH_BLUE}▼ (${rem} más abajo)${NC}"
                else
                    echo -e "${PADDING_LEFT_SPACES}  ${DARK_GRAY}•${NC}"
                fi
                ((printed_lines++))
            else
                for i in "${!items[@]}"; do
                    if [ "$i" -eq "$selected" ]; then
                        echo -e "${PADDING_LEFT_SPACES}  ${GREEN}${BOLD}> ${items[$i]}${NC}"
                    else
                        echo -e "${PADDING_LEFT_SPACES}    ${GRAY}${items[$i]}${NC}"
                    fi
                    ((printed_lines++))
                done
            fi

            last_printed_lines=$printed_lines

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
        local has_default=0
        for arg in "$@"; do
            [[ "$arg" == --default* ]] && has_default=1
        done
        if [ "$has_default" -eq 0 ]; then
            gum confirm --default=true "$@"
        else
            gum confirm "$@"
        fi
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
    local top=2

    printf '\033[?25l\033[H\033[2J'
    for ((i=0; i<top; i++)); do echo ""; done

    while IFS= read -r line; do
        echo -e "${LOGO_PADDING_SPACES}${GREEN}${line}${NC}"
    done <<< "$LOGO_TEXT"
    echo ""

    local tagline="Arch Linux + Hyprland"
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
    while true; do
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

        local action
        action=$(g_choose --header "¿Comenzar la instalación del sistema ahora?" \
            "[ Instalar ]   Formatear disco y comenzar instalación" \
            "[ Modificar ]  Regresar a configurar parámetros" \
            "[ Cancelar ]   Salir a la consola de Arch Linux")

        case "$action" in
            *"Instalar"*)
                return 0
                ;;
            *"Modificar"*)
                user_form_wizard
                disk_wizard
                ;;
            *"Cancelar"*)
                say --foreground 8 "Instalación cancelada por el usuario. No se modificó ningún disco."
                exit 0
                ;;
        esac
    done
}
install_confirm

# ------------------------------------------------------------------------------
# 10. Vista de Instalación y Dashboard Dinámico
# ------------------------------------------------------------------------------
INSTALL_STATE_FILE="/tmp/arch-install.state"
INSTALL_LOG_FILE="/tmp/arch-install.log"

set_phase() {
    local phase="$1"
    local pct="$2"
    echo "${phase}|${pct}" > "$INSTALL_STATE_FILE"
}

tips=(
    "Super + Return abre la terminal Kitty con la paleta de colores activa"
    "Super + Space abre el menú lanzador de aplicaciones del sistema"
    "Super + W cierra de inmediato la ventana seleccionada"
    "Super + E abre el gestor de archivos Dolphin"
    "Super + Shift + W abre el selector dinámico de fondos de pantalla"
    "Super + Shift + T cambia rápidamente entre temas oscuros y claros"
    "Super + L bloquea tu sesión de forma segura mediante Hyprlock"
    "Super + T conmuta la ventana activa entre modo flotante y mosaico"
    "Super + V abre el gestor de portapapeles nativo de Wayland"
    "Super + 1..9 permite alternar rápidamente entre escritorios virtuales"
    "El gestor Limine Bootloader ofrece un inicio ultraveloz, limpio y moderno"
    "El sistema cuenta con Btrfs, subvolúmenes optimizados y cifrado seguro LUKS2"
    "Zsh incluye autosugerencias inteligentes, sintaxis coloreada y Starship prompt"
    "El inicio de sesión te conecta directo a Hyprland sin intermediarios"
)

perform_installation_worker() {
    set -eo pipefail
    exec >> "$INSTALL_LOG_FILE" 2>&1

    set_phase "Preparando particiones en el almacenamiento" 5
    echo "==> Limpiando montajes previos y contenedores abiertos en $TARGET_DISK..."
    findmnt -R /mnt >/dev/null 2>&1 && umount -R /mnt 2>/dev/null || true
    while read -r dev; do
        [[ -b "$dev" ]] || continue
        swapoff "$dev" 2>/dev/null || true
        while read -r target; do
            [[ -n "$target" ]] && umount "$target" 2>/dev/null || true
        done < <(findmnt -rn -S "$dev" -o TARGET 2>/dev/null || true)
    done < <(lsblk -rnpo PATH "$TARGET_DISK" 2>/dev/null || true)

    while read -r dev type; do
        [[ "$type" == "disk" || "$type" == "part" || "$type" == "crypt" ]] || continue
        while read -r vg; do
            [[ -n "$vg" ]] && vgchange -an "$vg" 2>/dev/null || true
        done < <(pvs --noheadings -o vg_name "$dev" 2>/dev/null | awk '{$1=$1; print}' | sort -u || true)
    done < <(lsblk -rnpo PATH,TYPE "$TARGET_DISK" 2>/dev/null || true)

    while read -r dev type; do
        [[ "$type" == "crypt" ]] && cryptsetup close "$dev" 2>/dev/null || true
    done < <(lsblk -rnpo PATH,TYPE "$TARGET_DISK" 2>/dev/null || true)

    cryptsetup close cryptroot 2>/dev/null || true
    blockdev --flushbufs "$TARGET_DISK" 2>/dev/null || true
    partprobe "$TARGET_DISK" 2>/dev/null || true
    udevadm settle 2>/dev/null || true

    echo "==> Eliminando firmas de disco previas en $TARGET_DISK..."
    wipefs -af "$TARGET_DISK" >/dev/null 2>&1 || true
    parted --script "$TARGET_DISK" mklabel gpt
    partprobe "$TARGET_DISK" 2>/dev/null || true
    udevadm settle 2>/dev/null || true
    sleep 1

    echo "==> Creando tabla de particiones GPT..."
    # Partición 1: EFI 1024MB | Partición 2: LUKS2 Linux (100% restante)
    parted --script "$TARGET_DISK" mkpart "EFI" fat32 1MiB 1025MiB
    parted --script "$TARGET_DISK" set 1 esp on
    parted --script "$TARGET_DISK" mkpart "cryptroot" 1025MiB 100%
    partprobe "$TARGET_DISK" 2>/dev/null || true
    udevadm settle 2>/dev/null || true
    sleep 1

    if [[ "$TARGET_DISK" == *nvme* || "$TARGET_DISK" == *mmcblk* || "$TARGET_DISK" =~ [0-9]$ ]]; then
        PART_EFI="${TARGET_DISK}p1"
        PART_ROOT="${TARGET_DISK}p2"
    else
        PART_EFI="${TARGET_DISK}1"
        PART_ROOT="${TARGET_DISK}2"
    fi

    echo "==> Esperando nodos de partición $PART_EFI y $PART_ROOT..."
    for i in {1..15}; do
        [ -b "$PART_EFI" ] && [ -b "$PART_ROOT" ] && break
        partprobe "$TARGET_DISK" 2>/dev/null || true
        udevadm settle 2>/dev/null || true
        sleep 0.5
    done

    if [ ! -b "$PART_EFI" ] || [ ! -b "$PART_ROOT" ]; then
        echo "ERROR: No se detectaron las particiones creadas ($PART_EFI, $PART_ROOT)" >&2
        exit 1
    fi

    set_phase "Formateando partición EFI y configurando LUKS2" 15
    echo "==> Formateando partición EFI ($PART_EFI)..."
    wipefs -af "$PART_EFI" >/dev/null 2>&1 || true
    mkfs.fat -F 32 -n EFI "$PART_EFI"

    echo "==> Cifrando partición raíz con LUKS2..."
    wipefs -af "$PART_ROOT" >/dev/null 2>&1 || true
    echo -n "$MASTER_PASS" | cryptsetup luksFormat --type luks2 --iter-time 2000 --batch-mode "$PART_ROOT" -
    echo -n "$MASTER_PASS" | cryptsetup open "$PART_ROOT" cryptroot -

    for i in {1..15}; do
        [ -b "/dev/mapper/cryptroot" ] && break
        udevadm settle 2>/dev/null || true
        sleep 0.5
    done

    if [ ! -b "/dev/mapper/cryptroot" ]; then
        echo "ERROR: No se pudo abrir el contenedor LUKS /dev/mapper/cryptroot" >&2
        exit 1
    fi

    set_phase "Creando sistema de archivos y subvolúmenes Btrfs" 25
    ROOT_DEV="/dev/mapper/cryptroot"
    echo "==> Formateando Btrfs en $ROOT_DEV..."
    mkfs.btrfs -f -L ARCHROOT "$ROOT_DEV"

    echo "==> Creando subvolúmenes Btrfs (@, @home, @snapshots, @var_log, @pkg)..."
    mount "$ROOT_DEV" /mnt
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@snapshots
    btrfs subvolume create /mnt/@var_log
    btrfs subvolume create /mnt/@pkg
    umount /mnt

    echo "==> Montando subvolúmenes Btrfs en /mnt..."
    BTRFS_MOUNT_OPTS="noatime,compress=zstd,space_cache=v2"
    mount -o "$BTRFS_MOUNT_OPTS,subvol=@" "$ROOT_DEV" /mnt
    mkdir -p /mnt/{home,.snapshots,var/log,var/cache/pacman/pkg,boot}
    mount -o "$BTRFS_MOUNT_OPTS,subvol=@home" "$ROOT_DEV" /mnt/home
    mount -o "$BTRFS_MOUNT_OPTS,subvol=@snapshots" "$ROOT_DEV" /mnt/.snapshots
    mount -o "$BTRFS_MOUNT_OPTS,subvol=@var_log" "$ROOT_DEV" /mnt/var/log
    mount -o "$BTRFS_MOUNT_OPTS,subvol=@pkg" "$ROOT_DEV" /mnt/var/cache/pacman/pkg
    mount "$PART_EFI" /mnt/boot

    set_phase "Instalando paquetes base con pacstrap" 35
    echo "==> Iniciando instalación de paquetes del sistema..."
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
        neovim
        hyprland
        hyprlock
        hypridle
        quickshell
        kitty
        nautilus
        capitaine-cursors
        gum
        ttf-jetbrains-mono-nerd
        noto-fonts
        noto-fonts-emoji
        pipewire
        pipewire-pulse
        pipewire-alsa
        pipewire-jack
        wireplumber
        sof-firmware
        alsa-ucm-conf
        alsa-utils
        pavucontrol
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
        mesa
        xorg-xwayland
        polkit
        polkit-gnome
        xdg-desktop-portal
        xdg-desktop-portal-hyprland
        limine
        gtk3
        libxt
        dbus-glib
        nss
        ffmpeg
        tar
        xz
    )
    [ -n "$UCODE_PKG" ] && BASE_PACKAGES+=("$UCODE_PKG")

    pacstrap -K /mnt "${BASE_PACKAGES[@]}"
    genfstab -U /mnt >> /mnt/etc/fstab

    set_phase "Configurando sistema interno, usuarios e initramfs" 75

    # Preparar hook personalizado de desbloqueo TUI (arch-encrypt)
    ROOT_UUID=$(blkid -s UUID -o value "$PART_ROOT")
    BOOT_ENTRY_OPTIONS="cryptdevice=UUID=$ROOT_UUID:cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rw quiet splash"
    MKINITCPIO_HOOKS="base udev autodetect modconf kms keyboard keymap consolefont block arch-encrypt btrfs filesystems fsck"

    # Instalar hook personalizado de descifrado visual TUI (arch-encrypt)
    mkdir -p /mnt/usr/lib/initcpio/install /mnt/usr/lib/initcpio/hooks
        if [ -f "/usr/lib/initcpio/install/arch-encrypt" ]; then
            cp -f /usr/lib/initcpio/install/arch-encrypt /mnt/usr/lib/initcpio/install/arch-encrypt
            cp -f /usr/lib/initcpio/hooks/arch-encrypt /mnt/usr/lib/initcpio/hooks/arch-encrypt
        elif [ -f "/iso/airootfs/usr/lib/initcpio/install/arch-encrypt" ]; then
            cp -f /iso/airootfs/usr/lib/initcpio/install/arch-encrypt /mnt/usr/lib/initcpio/install/arch-encrypt
            cp -f /iso/airootfs/usr/lib/initcpio/hooks/arch-encrypt /mnt/usr/lib/initcpio/hooks/arch-encrypt
        else
            cat << 'INSTALL_HOOK_EOF' > /mnt/usr/lib/initcpio/install/arch-encrypt
#!/bin/bash
build() {
    map add_module 'dm-crypt' 'dm-integrity' 'hid-generic?'
    add_all_modules '/crypto/'
    add_binary 'cryptsetup'
    add_binary 'dmsetup'
    add_binary 'stty'
    add_binary 'gum'
    map add_udev_rule '10-dm.rules' '13-dm-disk.rules' '95-dm-notify.rules'
    add_binary '/usr/lib/libgcc_s.so.1' 2>/dev/null || true
    add_binary '/usr/lib/ossl-modules/legacy.so' 2>/dev/null || true
    if [[ -d /usr/share/terminfo/l ]]; then
        add_file '/usr/share/terminfo/l/linux' 2>/dev/null || true
    fi
    add_runscript
}
help() { echo "Pantalla gráfica TUI estilizada de desbloqueo LUKS2"; }
INSTALL_HOOK_EOF

            cat << 'HOOK_RUN_EOF' > /mnt/usr/lib/initcpio/hooks/arch-encrypt
#!/usr/bin/ash
run_hook() {
    modprobe -a -q dm-crypt >/dev/null 2>&1
    if [ -n "${cryptdevice}" ]; then
        IFS=: read cryptdev cryptname cryptoptions <<EOF
${cryptdevice}
EOF
    else
        cryptdev="${root}"
        cryptname="cryptroot"
    fi
    [ -b "/dev/mapper/${cryptname}" ] && return 0
    resolved=$(resolve_device "${cryptdev}")
    [ -z "${resolved}" ] && return 1

    printf "\033]P01a1b26\033]P1f7768e\033]P29ece6a\033]P3e0af68\033]P47aa2f7\033]P5bb9af7\033]P67dcfff\033]P7a9b1d6\033]P8414868\033]P9f7768e\033]PA9ece6a\033]PBe0af68\033]PC7aa2f7\033]PDbb9af7\033]PE7dcfff\033]PFc0caf5\033[0m"

    [ -z "$TERM" ] && export TERM=linux

    local term_size
    term_size=$(stty -F /dev/tty0 size 2>/dev/null || stty -F /dev/tty1 size 2>/dev/null || stty size 2>/dev/null || echo "24 80")
    local lines cols
    set -- $term_size
    lines=${1:-24}
    cols=${2:-80}
    [ -z "$cols" ] || [ "$cols" -le 0 ] && cols=80
    [ -z "$lines" ] || [ "$lines" -le 0 ] && lines=24

    local logo_w=47
    local logo_pad=$(( (cols - logo_w) / 2 ))
    [ "$logo_pad" -lt 0 ] && logo_pad=0
    local logo_spaces=""
    local i=0
    while [ "$i" -lt "$logo_pad" ]; do logo_spaces="${logo_spaces} "; i=$((i + 1)); done

    local prompt_text="Contraseña: "
    local prompt_w=46
    [ "$prompt_w" -gt "$cols" ] && prompt_w=$cols
    local prompt_pad=$(( (cols - prompt_w) / 2 ))
    [ "$prompt_pad" -lt 0 ] && prompt_pad=0
    local prompt_spaces=""
    i=0
    while [ "$i" -lt "$prompt_pad" ]; do prompt_spaces="${prompt_spaces} "; i=$((i + 1)); done

    local top_pad=2

    while true; do
        printf "\033[H\033[2J"
        i=0
        while [ "$i" -lt "$top_pad" ]; do printf "\n"; i=$((i + 1)); done

        printf "\033[38;5;42m"
        printf "%s ▄███████    ▄███████     ▄███████    ▄█   █▄  \n" "$logo_spaces"
        printf "%s███   ███   ███   ███    ███   ███   ███   ███ \n" "$logo_spaces"
        printf "%s███   ███   ███   ███    ███   █▀    ███   ███ \n" "$logo_spaces"
        printf "%s███▄▄▄███   ███▄▄▄██▀    ███         ███▄▄▄███▄\n" "$logo_spaces"
        printf "%s███▀▀▀███   ███▀▀▀▀      ███         ███▀▀▀███ \n" "$logo_spaces"
        printf "%s███   ███   █████████    ███   █▄    ███   ███ \n" "$logo_spaces"
        printf "%s███   ███   ███   ███    ███   ███   ███   ███ \n" "$logo_spaces"
        printf "%s███   █▀    ███   ███    ███████▀    ███   █▀  \n" "$logo_spaces"
        printf "%s            ███   █▀                           \n" "$logo_spaces"
        printf "\033[0m\n"

        local pass=""
        if command -v gum >/dev/null 2>&1; then
            gum style --foreground 6 --bold --align center --width "$cols" "DESBLOQUEO DE DISCO CIFRADO"
            printf "\n"
            pass=$(gum input --password --placeholder "Introduce tu clave para desbloquear..." --prompt "${prompt_spaces}${prompt_text}" --prompt.foreground 4)
        else
            printf "%s\033[1;36mDESBLOQUEO DE DISCO CIFRADO\033[0m\n\n" "$logo_spaces"
            printf "%s\033[1;36m%s\033[0m" "$prompt_spaces" "$prompt_text"
            stty -echo 2>/dev/null || true
            read -r pass
            stty echo 2>/dev/null || true
            printf "\n"
        fi

        if [ -z "$pass" ]; then
            continue
        fi

        if printf "%s" "$pass" | cryptsetup open --type luks --key-file - "${resolved}" "${cryptname}"; then
            if command -v gum >/dev/null 2>&1; then
                printf "\n"
                gum style --foreground 2 --bold --align center --width "$cols" "✔ Disco descifrado correctamente. Iniciando sistema..."
            else
                printf "\n%s\033[1;32m✔ Desbloqueado. Iniciando sistema...\033[0m\n" "$prompt_spaces"
            fi
            sleep 1
            break
        else
            if command -v gum >/dev/null 2>&1; then
                printf "\n"
                gum style --foreground 1 --bold --align center --width "$cols" "✖ Contraseña incorrecta. Inténtalo de nuevo."
            else
                printf "\n%s\033[1;31m✖ Contraseña incorrecta. Inténtalo de nuevo.\033[0m\n" "$prompt_spaces"
            fi
            sleep 2
        fi
    done
}
HOOK_RUN_EOF
        fi
        chmod +x /mnt/usr/lib/initcpio/install/arch-encrypt /mnt/usr/lib/initcpio/hooks/arch-encrypt

    cat << CHROOT_SCRIPT > /mnt/root/setup_chroot.sh
#!/usr/bin/env bash
set -e

ln -sf /usr/share/zoneinfo/$SYS_TIMEZONE /etc/localtime
hwclock --systohc 2>/dev/null || true

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
id -u "$SYS_USER" &>/dev/null || useradd -m -g users -G wheel,video,audio,storage,optical,network -s /usr/bin/zsh "$SYS_USER"
echo "$SYS_USER:$MASTER_PASS" | chpasswd

echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel
chmod 440 /etc/sudoers.d/wheel

if [ -n "$GIT_USER_NAME" ]; then
    su - "$SYS_USER" -s /bin/bash -c "git config --global user.name '$GIT_USER_NAME'" 2>/dev/null || true
fi
if [ -n "$GIT_USER_EMAIL" ]; then
    su - "$SYS_USER" -s /bin/bash -c "git config --global user.email '$GIT_USER_EMAIL'" 2>/dev/null || true
fi
su - "$SYS_USER" -s /bin/bash -c "git config --global init.defaultBranch main" 2>/dev/null || true

sed -i "s/^HOOKS=.*/HOOKS=($MKINITCPIO_HOOKS)/" /etc/mkinitcpio.conf
mkinitcpio -P

# Instalación y configuración de Limine Bootloader
mkdir -p /boot/EFI/BOOT /boot/limine
cp -f /usr/share/limine/BOOTX64.EFI /boot/EFI/BOOT/BOOTX64.EFI 2>/dev/null || true
cp -f /usr/share/limine/BOOTIA32.EFI /boot/EFI/BOOT/BOOTIA32.EFI 2>/dev/null || true
cp -f /usr/share/limine/limine-bios.sys /boot/limine-bios.sys 2>/dev/null || true
cp -f /usr/share/limine/limine-bios.sys /boot/limine/limine-bios.sys 2>/dev/null || true

cat << 'LIMINE_HEAD' > /boot/limine.conf
timeout: 3
interface_branding: Arch Linux (Limine)
interface_branding_color: 7aa2f7

/Arch Linux
    protocol: linux
    path: boot():/vmlinuz-linux
LIMINE_HEAD

if [ -n "$UCODE_PKG" ]; then
    echo "    module_path: boot():/$UCODE_PKG.img" >> /boot/limine.conf
fi

cat << LIMINE_PART1 >> /boot/limine.conf
    module_path: boot():/initramfs-linux.img
    cmdline: $BOOT_ENTRY_OPTIONS

/Arch Linux (fallback initramfs)
    protocol: linux
    path: boot():/vmlinuz-linux
LIMINE_PART1

if [ -n "$UCODE_PKG" ]; then
    echo "    module_path: boot():/$UCODE_PKG.img" >> /boot/limine.conf
fi

cat << LIMINE_PART2 >> /boot/limine.conf
    module_path: boot():/initramfs-linux-fallback.img
    cmdline: $BOOT_ENTRY_OPTIONS
LIMINE_PART2

cp -f /boot/limine.conf /boot/limine/limine.conf 2>/dev/null || true
cp -f /boot/limine.conf /boot/EFI/BOOT/limine.conf 2>/dev/null || true

# Registrar entrada en UEFI NVRAM
efibootmgr --create --disk "$TARGET_DISK" --part 1 --label "Arch Linux" --loader /EFI/BOOT/BOOTX64.EFI --unicode 2>/dev/null || true

# Instalación híbrida BIOS/GPT
limine bios-install "$TARGET_DISK" 2>/dev/null || true

systemctl enable NetworkManager.service
systemctl enable bluetooth.service 2>/dev/null || true
systemctl enable systemd-timesyncd.service 2>/dev/null || true
systemctl --global enable pipewire.socket pipewire-pulse.socket wireplumber.service 2>/dev/null || true

# Seamless Login en tty1 con systemd
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat << GETTY_CONF > /etc/systemd/system/getty@tty1.service.d/autologin.conf
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --skip-login --nonewline --noreset --noissue --autologin $SYS_USER %I 38400 linux
Type=idle
StandardInput=tty
StandardOutput=tty
GETTY_CONF

# Desinstalar cualquier otro navegador para mantener el sistema minimalista y limpio
pacman -Rns --noconfirm firefox firefox-esr chromium epiphany midori 2>/dev/null || true

# Descarga e instalación de Zen Browser (zen-browser-bin)
echo "Instalando Zen Browser..."
mkdir -p /opt/zen-browser-bin
if curl -sL "https://github.com/zen-browser/desktop/releases/latest/download/zen.linux-x86_64.tar.xz" | tar -xJ -C /opt/zen-browser-bin --strip-components=1 2>/dev/null; then
    cat << 'ZEN_SH' > /usr/bin/zen-browser
#!/bin/bash
exec /opt/zen-browser-bin/zen-bin "$@"
ZEN_SH
    chmod +x /usr/bin/zen-browser
    ln -sf /usr/bin/zen-browser /usr/bin/zen

    cat << 'ZEN_DESK' > /usr/share/applications/zen.desktop
[Desktop Entry]
Version=1.0
Name=Zen Browser
Comment=Experience tranquility while browsing the web without sacrificing speed or privacy.
GenericName=Web Browser
Keywords=Internet;WWW;Browser;Web;Explorer
Exec=/usr/bin/zen-browser %u
Terminal=false
X-MultipleArgs=false
Type=Application
Icon=zen
Categories=Network;WebBrowser;Internet;
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/vnd.mozilla.xul+xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;
StartupNotify=true
Actions=new-window;new-private-window;

[Desktop Action new-window]
Name=Open a New Window
Exec=/usr/bin/zen-browser --new-window %u

[Desktop Action new-private-window]
Name=Open a New Private Window
Exec=/usr/bin/zen-browser --private-window %u
ZEN_DESK
    chmod 644 /usr/share/applications/zen.desktop

    for sz in 16 32 48 64 128; do
        mkdir -p "/usr/share/icons/hicolor/${sz}x${sz}/apps"
        ln -sf "/opt/zen-browser-bin/browser/chrome/icons/default/default${sz}.png" "/usr/share/icons/hicolor/${sz}x${sz}/apps/zen.png" 2>/dev/null || true
    done
    gtk-update-icon-cache -q /usr/share/icons/hicolor 2>/dev/null || true
fi

CHROOT_SCRIPT

    chmod +x /mnt/root/setup_chroot.sh
    arch-chroot /mnt /root/setup_chroot.sh
    rm -f /mnt/root/setup_chroot.sh

    set_phase "Desplegando entorno gráfico y configuraciones" 88
    echo "==> Desplegando configuraciones en el directorio de usuario..."
    DEST_REPO="/mnt/home/$SYS_USER/Documentos/MrDemonc-SHELL"
    mkdir -p "$DEST_REPO"

    if [ -d "/usr/share/mrdemonc-shell" ]; then
        cp -a /usr/share/mrdemonc-shell/. "$DEST_REPO/"
    elif [ -d "/home/demonc-test/Documentos/MrDemonc-SHELL" ]; then
        cp -a "/home/demonc-test/Documentos/MrDemonc-SHELL/." "$DEST_REPO/"
    else
        git clone https://github.com/MrDemonc/MrDemonc-SHELL.git "$DEST_REPO" 2>/dev/null || true
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

    # Copiar fondos de pantalla predeterminados y configurar wallpaper activo
    if [ -d "$DEST_REPO/wallpapers" ]; then
        cp -f "$DEST_REPO"/wallpapers/* "$USER_HOME/Pictures/Wallpapers/" 2>/dev/null || true
    elif [ -d "/home/demonc-test/Pictures/Wallpapers" ]; then
        cp -f /home/demonc-test/Pictures/Wallpapers/* "$USER_HOME/Pictures/Wallpapers/" 2>/dev/null || true
    fi

    cat << WALL_JSON > "$USER_HOME/.config/quickshell/current_wallpaper.json"
{
  "path": "/home/$SYS_USER/Pictures/Wallpapers/wall0.png"
}
WALL_JSON

    # Configurar diseño de cursor (Capitaine) en entorno de usuario
    mkdir -p "$USER_HOME/.icons/default" "$USER_HOME/.config/gtk-3.0" "$USER_HOME/.config/gtk-4.0"
    cat << CURSOR_THEME > "$USER_HOME/.icons/default/index.theme"
[Icon Theme]
Name=Default
Comment=Default Cursor Theme
Inherits=capitaine-cursors
CURSOR_THEME

    cat << GTK3_CONF > "$USER_HOME/.config/gtk-3.0/settings.ini"
[Settings]
gtk-cursor-theme-name=capitaine-cursors
gtk-cursor-theme-size=24
gtk-theme-name=Adwaita-dark
gtk-application-prefer-dark-theme=true
GTK3_CONF

    cat << GTK4_CONF > "$USER_HOME/.config/gtk-4.0/settings.ini"
[Settings]
gtk-cursor-theme-name=capitaine-cursors
gtk-cursor-theme-size=24
gtk-theme-name=Adwaita-dark
gtk-application-prefer-dark-theme=true
GTK4_CONF

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

    cat << WRAP_THEME > "$USER_HOME/.local/bin/shell-theme"
#!/usr/bin/env bash
TARGET_DIR="/home/$SYS_USER/Documentos/MrDemonc-SHELL"
if [ "\$1" = "set" ] || [ "\$1" = "list" ]; then
    exec python3 "\$TARGET_DIR/scripts/theme_manager.py" "\$@"
else
    exec "\$TARGET_DIR/scripts/toggle_theme_picker.sh" "\$@"
fi
WRAP_THEME

    cat << WRAP_POPOUT > "$USER_HOME/.local/bin/shell-popout"
#!/usr/bin/env bash
TARGET="\${1:-audio}"
STATE="\${XDG_RUNTIME_DIR:-/tmp}/quickshell_popout.toggle"
echo "\$TARGET" > "\$STATE"
WRAP_POPOUT

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
        arch-chroot /mnt su - "$SYS_USER" -c "python3 ~/Documentos/MrDemonc-SHELL/scripts/theme_manager.py apply catppuccin-mocha" 2>/dev/null || true
    fi

    mkdir -p "$USER_HOME/.config"
    if [ -f "$DEST_REPO/starship/starship.toml" ]; then
        cp -f "$DEST_REPO/starship/starship.toml" "$USER_HOME/.config/starship.toml"
    elif [ -f "/usr/share/mrdemonc-shell/starship/starship.toml" ]; then
        cp -f /usr/share/mrdemonc-shell/starship/starship.toml "$USER_HOME/.config/starship.toml"
    fi

    echo "==> Configurando perfiles de inicio y shells para $SYS_USER..."

    # ~/.zprofile: Se ejecuta en el login de tty1 (Seamless Login directo a Hyprland)
    cat << 'ZPROF' > "$USER_HOME/.zprofile"
# Variables de entorno para Wayland y Hyprland
export XDG_CURRENT_DESKTOP=Hyprland
export XDG_SESSION_TYPE=wayland
export XDG_SESSION_DESKTOP=Hyprland
export QT_QPA_PLATFORM="wayland;xcb"
export GDK_BACKEND="wayland,x11"
export MOZ_ENABLE_WAYLAND=1
export _JAVA_AWT_WM_NONREPARENTING=1
export BROWSER=zen-browser
export DEFAULT_BROWSER=zen-browser

# Configuración de Cursor
export XCURSOR_THEME=capitaine-cursors
export XCURSOR_SIZE=24
export HYPRCURSOR_THEME=capitaine-cursors
export HYPRCURSOR_SIZE=24

# Compatibilidad con máquinas virtuales y aceleración por software (QEMU / KVM / VirtualBox)
export WLR_NO_HARDWARE_CURSORS=1
export WLR_RENDERER_ALLOW_SOFTWARE=1

# Auto-start Hyprland en tty1 (Seamless Login directo sin advertencias)
if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    printf '\033[?25l\033[H\033[2J'
    mkdir -p "$HOME/.local/state"
    if command -v start-hyprland >/dev/null 2>&1; then
        exec start-hyprland > "$HOME/.local/state/hyprland.log" 2>&1
    else
        exec Hyprland > "$HOME/.local/state/hyprland.log" 2>&1
    fi
fi
ZPROF

    # ~/.zshrc: Configuración interactiva, historial, plugins y Starship
    cat << 'ZSHRC' > "$USER_HOME/.zshrc"
# Arch Linux Zsh Configuration
export PATH="$HOME/.local/bin:$PATH"

# Deshabilitar aviso zsh-newuser-install
zstyle :compinstall filename "$HOME/.zshrc"

# Historial
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_DUPS

# Plugins instalados por pacman
[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Alias
alias ls='ls --color=auto'
alias ll='ls -la --color=auto'
alias la='ls -A --color=auto'
alias grep='grep --color=auto'

# Inicializar Starship Prompt
export STARSHIP_CONFIG="$HOME/.config/starship.toml"
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi
ZSHRC

    # Marcadores para evitar completamente zsh-newuser-install
    echo "# zshenv" > "$USER_HOME/.zshenv"
    echo "# zlogin" > "$USER_HOME/.zlogin"

    # Soporte paralelo para Bash
    cat << 'BPROF' > "$USER_HOME/.bash_profile"
export XDG_CURRENT_DESKTOP=Hyprland
export XDG_SESSION_TYPE=wayland
export XDG_SESSION_DESKTOP=Hyprland
export QT_QPA_PLATFORM="wayland;xcb"
export GDK_BACKEND="wayland,x11"
export MOZ_ENABLE_WAYLAND=1
export _JAVA_AWT_WM_NONREPARENTING=1
export BROWSER=zen-browser
export DEFAULT_BROWSER=zen-browser
export XCURSOR_THEME=capitaine-cursors
export XCURSOR_SIZE=24
export HYPRCURSOR_THEME=capitaine-cursors
export HYPRCURSOR_SIZE=24
export WLR_NO_HARDWARE_CURSORS=1
export WLR_RENDERER_ALLOW_SOFTWARE=1

if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    printf '\033[?25l\033[H\033[2J'
    mkdir -p "$HOME/.local/state"
    if command -v start-hyprland >/dev/null 2>&1; then
        exec start-hyprland > "$HOME/.local/state/hyprland.log" 2>&1
    else
        exec Hyprland > "$HOME/.local/state/hyprland.log" 2>&1
    fi
fi

[[ -f ~/.bashrc ]] && . ~/.bashrc
BPROF

    cat << 'BASHRC' > "$USER_HOME/.bashrc"
export PATH="$HOME/.local/bin:$PATH"
alias ls='ls --color=auto'
alias ll='ls -la --color=auto'
alias la='ls -A --color=auto'
alias grep='grep --color=auto'

export STARSHIP_CONFIG="$HOME/.config/starship.toml"
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi
BASHRC

    # Establecer Nautilus como explorador por defecto
    arch-chroot /mnt su - "$SYS_USER" -c "xdg-mime default org.gnome.Nautilus.desktop inode/directory" 2>/dev/null || true

    # Establecer Zen Browser como navegador por defecto
    mkdir -p "$USER_HOME/.config" "/mnt/etc/skel/.config"
    cat << 'MIME_CONF' > "$USER_HOME/.config/mimeapps.list"
[Default Applications]
text/html=zen.desktop
x-scheme-handler/http=zen.desktop
x-scheme-handler/https=zen.desktop
x-scheme-handler/about=zen.desktop
x-scheme-handler/unknown=zen.desktop

[Added Associations]
text/html=zen.desktop;
x-scheme-handler/http=zen.desktop;
x-scheme-handler/https=zen.desktop;
MIME_CONF
    cp -f "$USER_HOME/.config/mimeapps.list" /mnt/etc/skel/.config/mimeapps.list 2>/dev/null || true
    arch-chroot /mnt su - "$SYS_USER" -c "xdg-settings set default-web-browser zen.desktop 2>/dev/null || true"
    arch-chroot /mnt su - "$SYS_USER" -c "xdg-mime default zen.desktop x-scheme-handler/http 2>/dev/null || true"
    arch-chroot /mnt su - "$SYS_USER" -c "xdg-mime default zen.desktop x-scheme-handler/https 2>/dev/null || true"
    arch-chroot /mnt su - "$SYS_USER" -c "xdg-mime default zen.desktop text/html 2>/dev/null || true"

    # Propagar a /etc/skel para futuros usuarios creados en el sistema
    mkdir -p /mnt/etc/skel/.config /mnt/etc/skel/.local/bin
    cp -f "$USER_HOME/.zprofile" /mnt/etc/skel/
    cp -f "$USER_HOME/.zshrc" /mnt/etc/skel/
    cp -f "$USER_HOME/.zshenv" /mnt/etc/skel/
    cp -f "$USER_HOME/.zlogin" /mnt/etc/skel/
    cp -f "$USER_HOME/.bash_profile" /mnt/etc/skel/
    cp -f "$USER_HOME/.bashrc" /mnt/etc/skel/
    cp -f "$USER_HOME/.config/starship.toml" /mnt/etc/skel/.config/ 2>/dev/null || true
    cp -r "$USER_HOME/.local/bin/." /mnt/etc/skel/.local/bin/ 2>/dev/null || true

    # Corregir rutas hardcodeadas en configs hacia el usuario actual
    sed -i "s|/home/demonc-test|/home/$SYS_USER|g" "$USER_HOME/.config/hypr/"*.lua 2>/dev/null || true
    sed -i "s|/home/demonc-test|/home/$SYS_USER|g" "$USER_HOME/.config/hypr/"*.conf 2>/dev/null || true
    sed -i "s|/home/demonc-test|/home/$SYS_USER|g" "$USER_HOME/.config/quickshell/"*.qml 2>/dev/null || true

    # Asegurar permisos correctos y shell zsh
    arch-chroot /mnt chown -R "$SYS_USER:users" "/home/$SYS_USER"
    arch-chroot /mnt chmod 700 "/home/$SYS_USER"
    arch-chroot /mnt chsh -s /usr/bin/zsh "$SYS_USER" 2>/dev/null || true

    set_phase "Finalizando instalación y sincronizando almacenamiento" 98
    echo "==> Sincronizando datos a disco y desmontando particiones..."
    sync
    fuser -km /mnt 2>/dev/null || true
    umount -R /mnt 2>/dev/null || true
    cryptsetup close cryptroot 2>/dev/null || true

    set_phase "Instalación completada" 100
}

run_install_with_dashboard() {
    local start_epoch=$SECONDS
    measure_terminal

    # Limpiar pantalla y dibujar el logo arriba (idéntico a Omarchy)
    printf '\033[?25l' # Ocultar cursor

    rm -f "$INSTALL_STATE_FILE" "$INSTALL_LOG_FILE"
    touch "$INSTALL_LOG_FILE"

    # Lanzar trabajador de instalación en segundo plano con registros redirigidos
    perform_installation_worker &
    local worker_pid=$!

    local last_pct=5
    local current_phase="Iniciando instalación de Arch Linux..."
    local tip_idx=0
    local last_tip_time=$SECONDS
    local LAST_TERM_SIZE=""

    while kill -0 "$worker_pid" 2>/dev/null; do
        measure_terminal

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

        local log_rows=$(( TERM_HEIGHT - 22 ))
        (( log_rows < 5 )) && log_rows=5
        (( log_rows > 12 )) && log_rows=12
        local total_h=$(( LOGO_HEIGHT + 2 + 1 + 1 + 1 + 1 + log_rows ))
        local start_row=2

        if [[ "$TERM_WIDTH $TERM_HEIGHT" != "$LAST_TERM_SIZE" ]]; then
            LAST_TERM_SIZE="$TERM_WIDTH $TERM_HEIGHT"
            printf "\033[H\033[2J"
            printf "\033[%d;1H" "$start_row"
            while IFS= read -r line; do
                echo -e "${LOGO_PADDING_SPACES}${GREEN}${line}${NC}"
            done <<< "$LOGO_TEXT"
            echo ""
        fi

        local dynamic_row=$(( start_row + LOGO_HEIGHT + 1 ))
        printf "\033[%d;1H" "$dynamic_row"

        # 1. Título y fase actual (Centrado)
        local title_prefix="Instalando Arch Linux...   "
        local max_phase=$(( TERM_WIDTH - ${#title_prefix} - 4 ))
        (( max_phase < 15 )) && max_phase=15
        local disp_phase="$current_phase"
        if (( ${#disp_phase} > max_phase )); then
            disp_phase="${disp_phase:0:$((max_phase - 3))}..."
        fi
        center_text "\033[1;37m${title_prefix}\033[0m\033[38;5;220m${disp_phase}\033[0m"

        # 2. Barra de progreso suave (Centrado)
        local bar_w=44
        (( bar_w > TERM_WIDTH - 16 )) && bar_w=$(( TERM_WIDTH - 16 ))
        (( bar_w < 15 )) && bar_w=15
        local filled=$(( last_pct * bar_w / 100 ))
        local empty=$(( bar_w - filled ))
        local bar_str=""
        for ((i=0; i<filled; i++)); do bar_str+="█"; done
        local empty_str=""
        for ((i=0; i<empty; i++)); do empty_str+="░"; done
        center_text "\033[38;5;42m[$bar_str\033[38;5;238m$empty_str\033[38;5;42m]\033[0m  \033[1;37m$last_pct%\033[0m"

        # 3. Tip rotativo (Centrado)
        local tip_prefix="Tip: "
        local max_tip=$(( TERM_WIDTH - ${#tip_prefix} - 6 ))
        (( max_tip < 15 )) && max_tip=15
        local disp_tip="$tip"
        if (( ${#disp_tip} > max_tip )); then
            disp_tip="${disp_tip:0:$((max_tip - 3))}..."
        fi
        center_text "\033[2m${tip_prefix}\033[0m\033[38;5;42m${disp_tip}\033[0m"

        # 4. Separador
        printf '\033[2K\n'

        # 5. Salida de log en vivo (Centrado en un bloque de 74 columnas)
        local log_w=74
        (( log_w > TERM_WIDTH - 6 )) && log_w=$(( TERM_WIDTH - 6 ))
        local log_pad=$(( (TERM_WIDTH - log_w) / 2 ))
        (( log_pad < 0 )) && log_pad=0
        local log_pad_spaces=$(printf "%*s" "$log_pad" "")
        local max_w=$(( log_w - 6 ))

        mapfile -t lines_tail < <(tail -n "$log_rows" "$INSTALL_LOG_FILE" 2>/dev/null)
        for ((i=0; i<log_rows; i++)); do
            local l="${lines_tail[i]:-}"
            if (( ${#l} > max_w )); then
                l="${l:0:$max_w}..."
            fi
            if [ -n "$l" ]; then
                printf '\033[2K%s\033[38;5;244m  → %s\033[0m\n' "$log_pad_spaces" "$l"
            else
                printf '\033[2K\n'
            fi
        done
        printf '\033[J'

        sleep 0.15
    done

    set +e
    wait "$worker_pid"
    local worker_exit=$?
    set -e

    # Restaurar cursor visible
    printf '\033[?25h'

    # MANEJO DE ERRORES: Muestra el error y permite navegar el registro completo
    if [ "$worker_exit" -ne 0 ]; then
        clear_logo
        echo
        say --foreground 1 "¡LA INSTALACIÓN SE DETUVO DEBIDO A UN ERROR (Código: $worker_exit)!"
        echo
        say "Fase en la que ocurrió el fallo: $current_phase"
        echo
        say --foreground 3 "Últimas líneas del registro (/tmp/arch-install.log):"
        echo
        local max_tail_w=$((TERM_WIDTH - PADDING_LEFT - 6))
        (( max_tail_w < 20 )) && max_tail_w=20
        tail -n 18 "$INSTALL_LOG_FILE" 2>/dev/null | while IFS= read -r line; do
            if (( ${#line} > max_tail_w )); then
                line="${line:0:$max_tail_w}..."
            fi
            echo -e "${PADDING_LEFT_SPACES}\033[38;5;244m  → ${line}\033[0m"
        done
        echo
        say "Opciones de recuperación:"
        echo

        while true; do
            local choice
            choice=$(g_choose --header "Opciones de recuperación:" \
                "Ver registro completo (visor less)" \
                "Reintentar instalación" \
                "Salir a la consola de Arch Linux")
            case "$choice" in
                *"Ver registro"*)
                    if command -v less >/dev/null 2>&1; then
                        less "$INSTALL_LOG_FILE"
                    else
                        cat "$INSTALL_LOG_FILE"
                        read -r -p "Presiona Enter para continuar..."
                    fi
                    clear_logo
                    echo
                    say --foreground 1 "¡LA INSTALACIÓN SE DETUVO DEBIDO A UN ERROR (Código: $worker_exit)!"
                    echo
                    say "Fase en la que ocurrió el fallo: $current_phase"
                    echo
                    ;;
                *"Reintentar"*)
                    run_install_with_dashboard
                    return $?
                    ;;
                *)
                    say --foreground 8 "Saliendo a la consola de recuperación..."
                    return "$worker_exit"
                    ;;
            esac
        done
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

    # PANTALLA FINAL: Instalación exitosa al estilo Omarchy (arriba con padding)
    clear_logo
    echo
    say --foreground 2 "¡Arch Linux instalado con éxito en ${duration_str}!"
    echo
    say --foreground 8 "El sistema está configurado y listo para iniciar directamente en Hyprland."
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

run_install_with_dashboard || true
