pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: mgr

    property bool keybindsOpen: false
    property string searchQuery: ""
    property string selectedCategory: "all" // "all", "quickshell", "windows", "workspaces", "clipboard", "system", "cli"

    readonly property var categories: [
        { id: "all", name: "Todos los Atajos", icon: "󰌌" },
        { id: "quickshell", name: "Lanzadores y Shell", icon: "󰀻" },
        { id: "windows", name: "Ventanas", icon: "󰖲" },
        { id: "workspaces", name: "Espacios de Trabajo", icon: "󰍹" },
        { id: "clipboard", name: "Portapapeles", icon: "󰅌" },
        { id: "system", name: "Sistema y Sesión", icon: "󰐥" }
    ]

    readonly property var allKeybinds: [
        // --- LANZADORES Y QUICKSHELL ---
        {
            category: "quickshell",
            categoryName: "Lanzadores y Shell",
            keys: ["SUPER", "K"],
            title: "Guía de Atajos y Comandos",
            description: "Abre este centro visual para consultar todos los atajos de teclado y comandos del sistema."
        },
        {
            category: "quickshell",
            categoryName: "Lanzadores y Shell",
            keys: ["SUPER", "Espacio"],
            title: "Lanzador de Aplicaciones",
            description: "Abre el buscador interactivo para encontrar y ejecutar rápidamente cualquier app instalada."
        },
        {
            category: "quickshell",
            categoryName: "Lanzadores y Shell",
            keys: ["SUPER", "SHIFT", "W"],
            title: "Selector de Fondos de Pantalla",
            description: "Abre el carrusel CoverFlow 3D animado para previsualizar y cambiar fondos de pantalla."
        },
        {
            category: "quickshell",
            categoryName: "Lanzadores y Shell",
            keys: ["SUPER", "SHIFT", "T"],
            title: "Selector de Temas",
            description: "Abre el selector de temas visuales (Tokyo Night, Catppuccin, Nord, Gruvbox, Kanagawa, etc.)."
        },
        {
            category: "quickshell",
            categoryName: "Lanzadores y Shell",
            keys: ["SUPER", "SHIFT", "S"],
            title: "Configuración de Pantallas y Monitores",
            description: "Controla monitores externos y laptop, apaga pantalla integrada, ajusta resolución y escala HiDPI."
        },
        {
            category: "quickshell",
            categoryName: "Lanzadores y Shell",
            keys: ["SUPER", "N"],
            title: "Centro de Notificaciones",
            description: "Abre el panel lateral de historial de notificaciones, silenciar (DND) y acciones rápidas."
        },
        {
            category: "quickshell",
            categoryName: "Lanzadores y Shell",
            keys: ["SUPER", "SHIFT", "C"],
            title: "Modo Cafeína (Caffeine)",
            description: "Activa o desactiva el modo cafeína para evitar la suspensión y el bloqueo de pantalla por inactividad."
        },
        {
            category: "quickshell",
            categoryName: "Lanzadores y Shell",
            keys: ["SUPER", "SHIFT", "R"],
            title: "Grabación de Pantalla",
            description: "Abre el menú de grabación (pantalla completa o región, audio interno y micrófono) o detiene una grabación activa."
        },
        {
            category: "quickshell",
            categoryName: "Lanzadores y Shell",
            keys: ["SUPER", "SHIFT", "P"],
            title: "Cuentagotas de Color (Eyedropper)",
            description: "Selecciona interactivamente cualquier píxel de la pantalla y muestra una ventana con sus valores HEX, RGB, HSL y HSV."
        },
        {
            category: "quickshell",
            categoryName: "Lanzadores y Shell",
            keys: ["SUPER", "ENTER"],
            title: "Terminal del Sistema",
            description: "Lanza la terminal Kitty con shell Zsh configurada, soporte de fuentes Nerd y Starship."
        },
        {
            category: "quickshell",
            categoryName: "Lanzadores y Shell",
            keys: ["SUPER", "B"],
            title: "Navegador Web",
            description: "Abre el navegador web predeterminado (Zen Browser o Firefox)."
        },
        {
            category: "quickshell",
            categoryName: "Lanzadores y Shell",
            keys: ["SUPER", "E"],
            title: "Explorador de Archivos",
            description: "Abre el gestor de archivos del sistema (Nautilus o Dolphin)."
        },

        // --- GESTIÓN DE VENTANAS ---
        {
            category: "windows",
            categoryName: "Ventanas",
            keys: ["SUPER", "F"],
            title: "Pantalla Completa (Fullscreen)",
            description: "Alterna la ventana o aplicación activa en pantalla completa."
        },
        {
            category: "windows",
            categoryName: "Ventanas",
            keys: ["SUPER", "W"],
            title: "Cerrar Ventana",
            description: "Cierra inmediatamente la ventana que tiene el foco activo."
        },
        {
            category: "windows",
            categoryName: "Ventanas",
            keys: ["SUPER", "T"],
            title: "Alternar Flotante (Float)",
            description: "Cambia la ventana activa entre modo mosaico inteligente (tiling) y ventana flotante libre."
        },
        {
            category: "windows",
            categoryName: "Ventanas",
            keys: ["SUPER", "P"],
            title: "Modo Pseudo-Tiling",
            description: "Conserva el tamaño flotante predeterminado de la ventana pero respetando la cuadrícula."
        },
        {
            category: "windows",
            categoryName: "Ventanas",
            keys: ["SUPER", "J"],
            title: "Alternar División (Toggle Split)",
            description: "Alterna la orientación horizontal o vertical de división en el mosaico de ventanas."
        },
        {
            category: "windows",
            categoryName: "Ventanas",
            keys: ["SUPER", "← / → / ↑ / ↓"],
            title: "Mover Foco entre Ventanas",
            description: "Cambia el foco del teclado hacia la ventana vecina en la dirección de la flecha pulsada."
        },
        {
            category: "windows",
            categoryName: "Ventanas",
            keys: ["SUPER", "SHIFT", "← / → / ↑ / ↓"],
            title: "Desplazar Posición de Ventana",
            description: "Mueve y reorganiza la posición de la ventana activa dentro del mosaico de la pantalla."
        },
        {
            category: "windows",
            categoryName: "Ventanas",
            keys: ["SUPER", "Clic Izq + Arrastrar"],
            title: "Mover Ventana Flotante",
            description: "Arrastra y reubica libremente una ventana flotante con el ratón."
        },
        {
            category: "windows",
            categoryName: "Ventanas",
            keys: ["SUPER", "Clic Der + Arrastrar"],
            title: "Redimensionar Ventana",
            description: "Ajusta las dimensiones de cualquier ventana arrastrando con el botón derecho."
        },

        // --- ESPACIOS DE TRABAJO ---
        {
            category: "workspaces",
            categoryName: "Espacios de Trabajo",
            keys: ["SUPER", "1 .. 9"],
            title: "Ir al Espacio de Trabajo",
            description: "Cambia inmediatamente al espacio de trabajo (workspace) numérico seleccionado."
        },
        {
            category: "workspaces",
            categoryName: "Espacios de Trabajo",
            keys: ["SUPER", "SHIFT", "1 .. 9"],
            title: "Mover Ventana a Espacio",
            description: "Envía la ventana activa actual al espacio de trabajo numérico indicado."
        },
        {
            category: "workspaces",
            categoryName: "Espacios de Trabajo",
            keys: ["SUPER", "Rueda del Ratón"],
            title: "Navegar entre Espacios",
            description: "Alterna sucesivamente entre los espacios de trabajo activos rodando la rueda del ratón."
        },

        // --- PORTAPAPELES ---
        {
            category: "clipboard",
            categoryName: "Portapapeles",
            keys: ["SUPER", "C"],
            title: "Copiar al Portapapeles",
            description: "Copia la selección activa (conmutación inteligente CTRL+C / CTRL+SHIFT+C en terminal)."
        },
        {
            category: "clipboard",
            categoryName: "Portapapeles",
            keys: ["SUPER", "X"],
            title: "Cortar al Portapapeles",
            description: "Corta el texto seleccionado de forma universal bajo Wayland."
        },
        {
            category: "clipboard",
            categoryName: "Portapapeles",
            keys: ["SUPER", "V"],
            title: "Pegar desde Portapapeles",
            description: "Pega el contenido almacenado en el portapapeles en la ventana o terminal activa."
        },

        // --- SISTEMA Y SESIÓN ---
        {
            category: "system",
            categoryName: "Sistema y Sesión",
            keys: ["SUPER", "L"],
            title: "Bloquear Pantalla (Lockscreen)",
            description: "Bloquea la sesión activando la pantalla de bloqueo nativa con reloj, clima, visualizador Cava y autenticación."
        },
        {
            category: "system",
            categoryName: "Sistema y Sesión",
            keys: ["SUPER", "ESC"],
            title: "Menú de Apagado y Sesión",
            description: "Abre la ventana de energía para apagar, reiniciar, suspender, bloquear, cerrar sesión o hibernar."
        }
    ]

    readonly property var filteredKeybinds: {
        let q = searchQuery.trim().toLowerCase();
        let cat = selectedCategory;
        let res = [];

        for (let i = 0; i < allKeybinds.length; i++) {
            let item = allKeybinds[i];
            // Filtro por categoría
            if (cat !== "all" && item.category !== cat) {
                continue;
            }

            // Filtro por texto de búsqueda
            if (q.length > 0) {
                let matchTitle = item.title.toLowerCase().indexOf(q) !== -1;
                let matchDesc = item.description.toLowerCase().indexOf(q) !== -1;
                let matchCategory = item.categoryName.toLowerCase().indexOf(q) !== -1;
                let matchKeys = false;
                for (let k = 0; k < item.keys.length; k++) {
                    if (item.keys[k].toLowerCase().indexOf(q) !== -1) {
                        matchKeys = true;
                        break;
                    }
                }
                if (!matchTitle && !matchDesc && !matchCategory && !matchKeys) {
                    continue;
                }
            }

            res.push(item);
        }
        return res;
    }

    // Monitoreo del toggle SUPER + K
    property var watchToggleProc: Process {
        command: ["sh", "-c", "STATE=\"${XDG_RUNTIME_DIR:-/tmp}/quickshell_keybinds.toggle\"; while true; do if [ -f \"$STATE\" ]; then rm -f \"$STATE\"; echo 'TOGGLE'; fi; sleep 0.15; done"]
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                if (String(data).indexOf("TOGGLE") !== -1) {
                    mgr.toggle();
                }
            }
        }
    }

    function toggle() {
        keybindsOpen = !keybindsOpen;
        if (keybindsOpen) {
            searchQuery = "";
        }
    }
}
