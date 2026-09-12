# 🎨 Guía de Creación e Instalación de Temas - MrDemonc-SHELL

Bienvenido a la guía oficial para crear, empaquetar, instalar y compartir temas personalizados en **MrDemonc-SHELL**.

El sistema de temas de **MrDemonc-SHELL** es unificado y reactivo: al cambiar o aplicar un tema, los colores se propagan **en tiempo real y sin necesidad de reiniciar** a todos los componentes del sistema:
- **Quickshell**: Barra superior, menús emergentes (*popouts* de audio, brillo, wifi, bluetooth, batería, reloj), lanzador de aplicaciones, selector de fondos y pantalla de bloqueo.
- **Hyprland**: Colores y degradados de los bordes de ventanas activas e inactivas.
- **Terminales (Kitty y Foot)**: Paleta ANSI completa de 16 colores y fondo del terminal recargados en caliente (`SIGUSR1`).
- **Pantalla de Bloqueo (Quickshell Lock Screen & Hyprlock)**: Controles, tarjeta y textos coordinados.
- **Cargador de Arranque Limine**: Paleta del menú de inicio (`/boot/limine.conf`).
- **Fondo de Pantalla**: Si el tema incluye una imagen de fondo, se aplica automáticamente al activarlo.

---

## 📁 1. Estructura de un Tema

Los temas de usuario se almacenan en:
```bash
~/.config/quickshell/themes/<identificador-del-tema>/
```

Un tema completo consta de una carpeta con la siguiente estructura:

```text
~/.config/quickshell/themes/cyberpunk-neon/
├── theme.json        # [Obligatorio] Definición de colores y metadatos
└── wallpaper.jpg     # [Opcional] Fondo de pantalla coordinado (.jpg, .png, .webp)
```

> **Rutas de búsqueda del sistema:**
> 1. `~/.config/quickshell/themes/` (Temas personalizados del usuario)
> 2. `~/Documentos/MrDemonc-SHELL/themes/` (Temas del repositorio local)
> 3. `/usr/share/mrdemonc-shell/themes/` (Temas globales instalados en el sistema)

---

## 🛠️ 2. Especificación del Archivo `theme.json`

El archivo `theme.json` es un documento JSON estándar con los metadatos y la paleta de colores en formato hexadecimal (`#RRGGBB` o `#RGB`).

### Plantilla Base Completa

```json
{
  "id": "cyberpunk-neon",
  "name": "Cyberpunk Neon",
  "description": "Tema futurista oscuro con acentos neón cian y magenta",
  "author": "Tu Nombre o Alias",
  "isDark": true,
  "wallpaper": "wallpaper.jpg",
  "bg": "#0f111a",
  "bgSurface": "#171a26",
  "bgHover": "#222738",
  "border": "#2f364d",
  "text": "#e6edf3",
  "subtext": "#98a2b3",
  "overlay": "#5d677a",
  "primary": "#00e5ff",
  "success": "#00e676",
  "warning": "#ffea00",
  "danger": "#ff1744",
  "cyan": "#00f0ff",
  "pink": "#ff007f"
}
```

### Detalle de cada Clave

| Clave | Tipo | Descripción | Dónde se utiliza |
| :--- | :--- | :--- | :--- |
| **`id`** | String | Identificador único en minúsculas y sin espacios (ej: `tokyo-night`). | CLI, nombres de archivo y configuración interna. |
| **`name`** | String | Nombre visual legible para los usuarios (ej: `Tokyo Night`). | Título en el Selector de Temas GUI. |
| **`description`** | String | Descripción breve del estilo visual. | Tarjeta informativa del tema en el Selector. |
| **`author`** | String | Creador o autor del tema. | Información de créditos. |
| **`isDark`** | Boolean | `true` para temas oscuros, `false` para temas claros. | Ajusta el contraste de iconos, terminales y capas de desenfoque. |
| **`wallpaper`** | String | Nombre del archivo de fondo relativo a la carpeta del tema (ej: `wallpaper.jpg`). | Aplicado automáticamente al seleccionar el tema. |
| **`bg`** | Hex `#RGB` | Color de fondo principal. | Fondo de la barra superior, popouts, docks y terminal. |
| **`bgSurface`** | Hex `#RGB` | Color de superficies secundarias. | Tarjetas interiores, campos de búsqueda y widgets. |
| **`bgHover`** | Hex `#RGB` | Color al pasar el cursor o elemento activo. | Botones interactivos, filas de listas enfocadas. |
| **`border`** | Hex `#RGB` | Color de bordes y separadores sutiles. | Bordes de interfaces y ventanas inactivas en Hyprland. |
| **`text`** | Hex `#RGB` | Color de texto principal con alto contraste. | Títulos, reloj principal, etiquetas activas. |
| **`subtext`** | Hex `#RGB` | Color de texto secundario y descriptivo. | Fechas, subtítulos, porcentajes y descripciones. |
| **`overlay`** | Hex `#RGB` | Color de elementos atenuados o placeholders. | Texto de ayuda en buscadores, iconos secundarios. |
| **`primary`** | Hex `#RGB` | Color de acento primordial del tema. | Borde de ventana activa en Hyprland, sliders, cursor de terminal. |
| **`success`** | Hex `#RGB` | Color de éxito y estado normal (verde). | Batería cargada, indicador de conexión, ANSI 2/10 en terminal. |
| **`warning`** | Hex `#RGB` | Color de advertencia y atención (amarillo/naranja). | Batería media, advertencias, ANSI 3/11 en terminal. |
| **`danger`** | Hex `#RGB` | Color de alerta y error (rojo). | Botón de apagar, batería crítica, fallos, ANSI 1/9 en terminal. |
| **`cyan`** | Hex `#RGB` | Acento complementario cian/azul. | Degradado secundario de ventanas en Hyprland, ANSI 4/12. |
| **`pink`** | Hex `#RGB` | Acento terciario magenta/púrpura. | Detalles destacados, badges y ANSI 5/13 en terminal. |

---

## ⚡ 3. Creación Rápida con Asistente CLI

Puedes crear la estructura y plantilla de un tema nuevo con un solo comando:

```bash
# Crear un tema oscuro
shell-theme create sunset-glow --name "Sunset Glow"

# Crear un tema claro
shell-theme create paper-white --name "Paper White" --light
```

Esto generará automáticamente la carpeta y el archivo:
```text
~/.config/quickshell/themes/sunset-glow/theme.json
```

Simplemente edita ese archivo con tu editor favorito (ej. `nano`, `micro`, `code` o `nvim`), añade una imagen `wallpaper.jpg` a la misma carpeta si lo deseas, ¡y listo!

---

## 📥 4. Instalación de Temas (`shell-theme install`)

La herramienta `shell-theme install` permite instalar temas fácilmente desde cualquier fuente:

### A. Desde un archivo JSON local
```bash
shell-theme install ~/Descargas/mi-tema.json
```
Si deseas aplicarlo de inmediato:
```bash
shell-theme install ~/Descargas/mi-tema.json --apply
```

### B. Desde una carpeta local
```bash
shell-theme install ~/Proyectos/tema-nordico/ --apply
```

### C. Desde un archivo comprimido (.zip o .tar.gz)
```bash
shell-theme install ~/Descargas/catppuccin-mocha.zip --apply
```

### D. Directamente desde Internet (URL o GitHub)
```bash
# Desde una URL directa a un archivo JSON o .zip:
shell-theme install https://ejemplo.com/temas/solarized-dark.json --apply

# Desde un repositorio Git:
shell-theme install https://github.com/usuario/mi-tema-quickshell --apply
```

El instalador:
1. Valida automáticamente la sintaxis JSON y que los colores sean hexadecimales válidos.
2. Completa cualquier clave faltante con valores armoniosos según sea oscuro o claro.
3. Copia el fondo de pantalla si viene incluido.
4. Registra el tema en `~/.config/quickshell/themes/<id>/`.
5. Si incluyes `--apply`, sincroniza la pantalla, Hyprland, Quickshell y terminales en caliente.

---

## 🖥️ 5. Resumen de Comandos de Temas

| Comando | Acción |
| :--- | :--- |
| `shell-theme` | Abre el Selector Gráfico interactivo (<kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>T</kbd>). |
| `shell-theme list` | Lista todos los temas disponibles en formato JSON. |
| `shell-theme set <id>` | Aplica el tema indicado en caliente a todo el sistema. |
| `shell-theme install <origen> [--apply]` | Instala un tema desde JSON, carpeta, `.zip` o URL web. |
| `shell-theme create <id> [--name <nombre>]` | Genera una plantilla lista para editar en `~/.config/quickshell/themes/`. |
| `shell-theme export <id> [archivo.zip]` | Empaqueta un tema en `.zip` para compartirlo con otros usuarios. |
| `shell-theme remove <id>` | Elimina un tema personalizado del usuario. |
| `shell-theme info [id]` | Muestra la paleta de colores y detalles del tema. |

---

## 💡 6. Ejemplos de Temas Listos para Usar

### Ejemplo 1: Tokyo Night (Oscuro)
Guarda esto en `~/.config/quickshell/themes/tokyo-night/theme.json`:
```json
{
  "id": "tokyo-night",
  "name": "Tokyo Night",
  "description": "Inspirado en las luces nocturnas de Tokio con tonos azules profundos",
  "author": "MrDemonc",
  "isDark": true,
  "bg": "#1a1b26",
  "bgSurface": "#16161e",
  "bgHover": "#2f3549",
  "border": "#3b4261",
  "text": "#c0caf5",
  "subtext": "#9aa5ce",
  "overlay": "#565f89",
  "primary": "#7aa2f7",
  "success": "#9ece6a",
  "warning": "#e0af68",
  "danger": "#f7768e",
  "cyan": "#7dcfff",
  "pink": "#bb9af7"
}
```

### Ejemplo 2: Gruvbox Dark (Cálido / Retro)
Guarda esto en `~/.config/quickshell/themes/gruvbox-dark/theme.json`:
```json
{
  "id": "gruvbox-dark",
  "name": "Gruvbox Dark",
  "description": "Paleta cálida retro basada en tonos tierra y contraste suave",
  "author": "MrDemonc",
  "isDark": true,
  "bg": "#282828",
  "bgSurface": "#1d2021",
  "bgHover": "#3c3836",
  "border": "#504945",
  "text": "#ebdbb2",
  "subtext": "#d5c4a1",
  "overlay": "#928374",
  "primary": "#d79921",
  "success": "#b8bb26",
  "warning": "#fabd2f",
  "danger": "#fb4934",
  "cyan": "#83a598",
  "pink": "#d3869b"
}
```

### Ejemplo 3: Catppuccin Latte (Claro / Minimalista)
Guarda esto en `~/.config/quickshell/themes/catppuccin-latte/theme.json`:
```json
{
  "id": "catppuccin-latte",
  "name": "Catppuccin Latte",
  "description": "Tema claro pastel con excelente legibilidad y diseño relajante",
  "author": "MrDemonc",
  "isDark": false,
  "bg": "#eff1f5",
  "bgSurface": "#e6e9ef",
  "bgHover": "#ccd0da",
  "border": "#bcc0cc",
  "text": "#4c4f69",
  "subtext": "#5c5f77",
  "overlay": "#8c8fa1",
  "primary": "#1e66f5",
  "success": "#40a02b",
  "warning": "#df8e1d",
  "danger": "#d20f39",
  "cyan": "#04a5e5",
  "pink": "#ea76cb"
}
```

---

## 📦 7. Compartir tus Temas

Para compartir un tema creado con amigos o la comunidad:

```bash
shell-theme export cyberpunk-neon ~/Descargas/cyberpunk-neon.zip
```

El destinatario solo necesitará ejecutar:
```bash
shell-theme install ~/Descargas/cyberpunk-neon.zip --apply
```
Y el tema, con todos sus colores y wallpaper asociado, se aplicará al instante.
