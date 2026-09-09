# 📦 Dependencias de MrDemonc-SHELL

Guía detallada de todos los paquetes necesarios para el correcto funcionamiento de **MrDemonc-SHELL**, Hyprland, Quickshell, el bloqueador de pantalla **Hyprlock** y los servicios del sistema.

---

## 🚀 Instalación en un solo comando

Para instalar todas las dependencias oficiales en **Arch Linux**, ejecuta en la terminal dentro de esta carpeta:

```bash
sudo pacman -S --needed $(grep -vE '^\s*#|^\s*$' dependencies.txt)
```

O instalando individualmente desde el archivo de texto:

```bash
sudo pacman -S --needed \
    hyprland hyprlock hypridle \
    pipewire wireplumber libpulse playerctl \
    networkmanager bluez bluez-utils \
    upower brightnessctl xdg-utils libnotify \
    grim slurp wl-clipboard wtype \
    kitty dolphin ttf-jetbrains-mono-nerd \
    zsh starship python curl git
```

---

## 💎 Dependencia de AUR (Quickshell)

Quickshell es el motor de la barra, popouts y widgets:

```bash
# Con yay:
yay -S --needed quickshell

# O con paru:
paru -S --needed quickshell
```

---

## 📋 Detalle de cada Dependencia por Categoría

### 1. Entorno de Ventanas y Bloqueo de Pantalla
* **`hyprland`**: Compositor dinámico en mosaico Wayland.
* **`hyprlock`**: Bloqueador de pantalla con aceleración GPU, soporte nativo de PAM y efecto de cristal desenfocado (*frosted glass*). Accionado con `SUPER + L`.
* **`hypridle`**: Demonio de inactividad que atenúa la pantalla a los 5m, bloquea con `hyprlock` a los 10m y apaga el monitor a los 15m.

### 2. Audio y Multimedia
* **`pipewire`**: Servidor de audio moderno y de baja latencia.
* **`wireplumber`**: Gestor de sesiones modular para PipeWire.
* **`libpulse`**: Bibliotecas y comandos para consultar y ajustar volumen maestro y micrófonos.
* **`playerctl`**: Control de reproducción multimedia desde la barra o atajos.

### 3. Redes y Conectividad
* **`networkmanager`**: Demonio y herramienta `nmcli` que gestiona conexiones Wi-Fi, Ethernet y puntos de acceso en el popout de red.
* **`bluez`**: Pila de protocolos oficial de Bluetooth para Linux.
* **`bluez-utils`**: Proporciona `bluetoothctl`, utilizado por el popout de Bluetooth para escanear, emparejar y conectar dispositivos.

### 4. Batería, Brillo y Utilidades del Sistema
* **`upower`**: Demonio para consultar el estado, porcentaje y ciclo de carga de la batería en laptops.
* **`brightnessctl`**: Ajuste suave del brillo de retroiluminación de pantalla.
* **`xdg-utils`**: Herramientas estándar (`xdg-open`) para abrir URLs, carpetas y archivos con sus aplicaciones asociadas.
* **`libnotify`**: Proporciona el comando `notify-send` para notificaciones visuales en el escritorio.

### 5. Capturas de Pantalla y Portapapeles
* **`grim`**: Utilidad Wayland para tomar capturas de pantalla de la pantalla completa.
* **`slurp`**: Permite seleccionar una región de pantalla interactiva con el ratón.
* **`wl-clipboard`**: Herramientas `wl-copy` y `wl-paste` para interactuar con el portapapeles en Wayland.
* **`wtype`**: Inyector de pulsaciones de teclado virtual para Wayland, utilizado para los atajos globales de copiar, cortar y pegar (`SUPER + C / X / V`).

### 6. Terminal y Gestor de Archivos
* **`kitty`**: Emulador de terminal GPU rápido, estilizado y configurado con la paleta de colores Catppuccin Mocha de la shell.
* **`dolphin`**: Explorador de archivos gráfico (o tu gestor de archivos preferido como Nautilus o Thunar).

### 7. Shell Interactiva y Prompt
* **`zsh`**: Intérprete de comandos interactivo moderno.
* **`oh-my-zsh`**: Framework para administración de plugins y configuración de Zsh.
* **`starship`**: Prompt personalizable y ultrarrápido configurado con el tema y glifos de MrDemonc (`starship/starship.toml`).

### 8. Tipografía e Iconos
* **`ttf-jetbrains-mono-nerd`**: Fuente principal de la shell que incluye los glifos e iconos Nerd Fonts (`󰄛`, `󰕾`, `󰂯`, `󰤨`, `󰁹`, etc.) para la barra y popouts.

### 9. Runtime de Scripts
* **`python`**: Intérprete para los servicios de monitoreo de la barra (red, audio, batería, bluetooth y selector dinámico de temas).

---

## ⚙️ Servicios Recomendados a Habilitar

Para asegurar que el sonido, la red y el Bluetooth inicien automáticamente:

```bash
# Red y Bluetooth:
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth

# Audio (nivel de usuario):
systemctl --user enable --now pipewire wireplumber
```
