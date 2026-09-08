# Guía de Configuración e Integración: Quickshell + Hyprland

Esta guía detalla la configuración y resolución de problemas para **Quickshell** con **Hyprland** en **Arch Linux**.

---

## ⚡ Instalación Rápida Automatizada (`install.sh`)

Puedes instalar todo el entorno (dependencias de Arch Linux, binarios CLI, configuración modular de Hyprland, tipografía, Kitty y temas dinámicos) con un solo comando:

```bash
cd ~/Documentos/MrDemonc-SHELL
./install.sh
```

El script se encarga de:
1. Instalar paquetes esenciales de pacman y quickshell.
2. Crear directorios de configuración (`~/.config/hypr`, `~/.config/kitty`, `~/.local/bin`, etc.).
3. Desplegar ejecutables (`shell-apps`, `shell-theme`, `shell-wallpaper`, `shell-popout`).
4. Desplegar los módulos de Hyprland (`hyprland.lua`, `windows.lua`, `keybinds.lua`, `theme_colors.lua`).
5. Configurar Kitty con transparencia y fuente JetBrainsMono.
6. Habilitar servicios de Systemd (NetworkManager, Bluetooth) y asociación MIME para Dolphin.
7. Inicializar el tema de color en tiempo real.

Si falta alguna función (como Bluetooth o utilidades de red), instala los paquetes correspondientes:

```bash
# Paquetes esenciales
sudo pacman -S --needed quickshell pipewire wireplumber libpulse networkmanager bluez bluez-utils kitty xdg-utils ttf-jetbrains-mono-nerd

# Habilitar servicios requeridos
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth
```

> **Tipografía (JetBrainsMono Nerd Font Mono):** Toda la interfaz (barra, menús, reloj, iconos e indicadores) utiliza de manera centralizada la fuente `JetBrainsMono Nerd Font Mono` configurada en [`components/Theme.qml`](file:///home/demonc-test/Documentos/MrDemonc-SHELL/components/Theme.qml). También se configuró en `~/.config/kitty/kitty.conf` y en el sistema GTK para mantener consistencia visual.

> **Importante para Bluetooth:** Arch Linux **no** incluye la utilidad `bluetoothctl` por defecto a menos que instales `bluez-utils`. Además, en máquinas virtuales (QEMU/KVM/VirtualBox), se requiere un adaptador Bluetooth USB pasado por passthrough; de lo contrario el sistema reportará "Sin adaptador".

---

## 2. Detección Inteligente de Hardware

El código de la shell incluye soporte automático para todo tipo de entornos (Portátiles, Sobremesas y Máquinas Virtuales):

1. **Batería (`scripts/get_battery_info.py`):**
   - **En Laptops:** Busca dinámicamente cualquier batería física (`BAT0`, `BAT1`, etc.), mostrando el porcentaje real, estado de carga y salud.
   - **En Sobremesas y VMs:** Detecta que no hay batería física y muestra automáticamente el icono de corriente directa `󰚥` con estado **"AC"** en lugar de un `0%` engañoso.

2. **Red e Internet con `nmcli` (`scripts/get_network_info.py`):**
   - **Wi-Fi:** Escanea redes cercanas con `nmcli dev wifi list`, muestra el nivel de señal, SSID y permite conectarse.
   - **Ethernet (Cableada):** Si estás conectado por cable o en una máquina virtual (`enp1s0`, etc.), detecta la conexión activa mediante `nmcli`, muestra el icono cableado `󰈀`, el nombre de conexión y la IP local activa.

3. **Bluetooth (`scripts/get_bluetooth_info.py`):**
   - Controla el estado mediante `bluetoothctl`. Si no hay adaptador físico o falta el demonio, indica claramente "Sin adaptador Bluetooth".

---

## 3. Binarios CLI en `~/.local/bin`

Se han creado ejecutables globales en `~/.local/bin/`:

| Comando | Función |
| :--- | :--- |
| `shell-apps` | Alterna el lanzador y buscador flotante de aplicaciones |
| `shell-theme` | Alterna el selector visual de temas o cambia tema por CLI (`set`, `list`) |
| `shell-wallpaper` | Alterna el selector de fondos o asigna uno (`list`, `set <ruta>`, `folder`) |
| `shell-popout <menú>` | Despliega menús de la barra: `audio`, `wifi`, `battery`, `bluetooth`, `close` |

---

## 4. Configuración en Hyprland (`hyprland.lua`)

En `~/.config/hypr/hyprland.lua`, se configuran las variables de entorno, el autostart y las rutas absolutas para evitar problemas con `$PATH`:

```lua
-- Definición de directorios y programa de menú
local userHome    = os.getenv("HOME") or "/home/demonc-test"
local binDir      = userHome .. "/.local/bin"
local menu        = binDir .. "/shell-apps"

-- Variables de entorno
hl.env("PATH", binDir .. ":" .. (os.getenv("PATH") or "/usr/local/bin:/usr/bin"))

-- Inicio automático de Quickshell
hl.on("hyprland.start", function () 
    hl.exec_cmd("quickshell -p " .. userHome .. "/Documentos/MrDemonc-SHELL")
end)

-- Módulos separados y limpios:
require("windows")   -- Diseño, bordes rectos (rounding=0), gaps compactos y colores adaptativos
require("keybinds")  -- Todos los atajos de teclado
```

Archivos modulares creados en `~/.config/hypr/`:
- 📁 **`~/.config/hypr/keybinds.lua`**: Atajos de teclado organizados de forma independiente.
- 📁 **`~/.config/hypr/windows.lua`**: Configuración de diseño de ventanas (esquinas rectas `rounding = 0`, `gaps_in = 3`, `gaps_out = 6`, `border_size = 2`).
- 📁 **`~/.config/hypr/theme_colors.lua`**: Paleta generada automáticamente que sincroniza los bordes de Hyprland con el tema activo en tiempo real.

---

---

## 5. Sistema de Temas Dinámico

El gestor de temas (`scripts/theme_manager.py`) soporta cambio en caliente en Quickshell y terminales compatibles (Kitty/Foot):

- **Temas incluidos:** `catppuccin-mocha`, `catppuccin-latte`, `tokyo-night`, `tokyo-night-light`, `nord`, `nord-light`, `gruvbox-dark`, `gruvbox-light`, `rose-pine`, `rose-pine-dawn`, `oled-pure`.
- **Cambiar tema por CLI:**
  ```bash
  shell-theme set tokyo-night
  shell-theme set nord
  shell-theme set catppuccin-mocha
  ```
- **Selector Gráfico (UI):** Pulsa <kbd>Super</kbd> + <kbd>T</kbd> o ejecuta `shell-theme`. Navega con las flechas del teclado y presiona <kbd>Enter</kbd> o haz clic en "Aplicar este Tema".

---

## 6. Posición Dinámica de la Barra y Arrastre con el Ratón

La barra de la shell puede ubicarse en cualquiera de los 4 bordes de la pantalla (`top`, `bottom`, `left`, `right`):

### Movimiento Interactivo (Arrastre):
1. Haz **clic sostenido** con el botón izquierdo en cualquier espacio vacío de la barra (donde no haya un icono o módulo).
2. Arrastra el ratón hacia el borde de pantalla deseado (**Arriba**, **Abajo**, **Izquierda** o **Derecha**).
3. Se mostrará una **guía visual de acoplamiento** (`BarDockGuide`) con una franja luminosa en el borde candidato y un HUD central indicando la posición de destino.
4. Al soltar el ratón, la barra se fijará inmediatamente y guardará la preferencia en `~/.config/quickshell/bar_position.json`.

### Comportamiento en Laterales (Izquierda y Derecha):
- **Solo Iconos:** Todo el texto se oculta automáticamente (porcentajes de batería/audio, nombres de red Wi-Fi, nombres de aplicaciones).
- **Reloj:** Pasa a mostrar un icono limpio `󰥔`.
- **Escritorios:** Se distribuyen de forma vertical como indicadores y cápsulas compactas.
- **Popouts Adaptativos:** Los paneles desplegables de audio, red, bluetooth y batería se abren alineados lateralmente al borde de la barra.

### Control por Terminal / Scripts:
```bash
shell-bar pos top       # Fijar arriba (horizontal con texto)
shell-bar pos bottom    # Fijar abajo (horizontal con texto)
shell-bar pos left      # Fijar a la izquierda (vertical solo iconos)
shell-bar pos right     # Fijar a la derecha (vertical solo iconos)
shell-bar get-pos       # Consultar posición activa
```

---

## 7. Control y Depuración Rápida

Si modificas el código QML o deseas reiniciar la barra:

```bash
# Reiniciar Quickshell
killall -9 quickshell; quickshell -p ~/Documentos/MrDemonc-SHELL -d

# Probar popouts individualmente
shell-popout wifi
shell-popout audio
shell-popout battery
shell-popout close

# Ver capas activas en Hyprland
hyprctl layers
```

