pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: theme

    // Tema Default basado en La Gran Ola de Kanagawa (default.jpg) y tonos nórdicos
    property bool isDark: true
    property color bg: isDark ? "#1a1d24" : "#e2e6ee"
    property color bgSurface: isDark ? "#14161d" : "#d5dbe6"
    property color bgHover: isDark ? "#282d38" : "#cbd3e1"
    property color border: isDark ? "#353b49" : "#b8c2d1"
    property color text: isDark ? "#eceff4" : "#2e3440"
    property color subtext: isDark ? "#d8dee9" : "#3b4252"
    property color overlay: isDark ? "#7b889b" : "#7b88a1"
    
    // Colores de acento
    property color primary: isDark ? "#88c0d0" : "#5e81ac"
    property color success: isDark ? "#a3be8c" : "#4c566a"
    property color warning: isDark ? "#ebcb8b" : "#d08770"
    property color danger: isDark ? "#bf616a" : "#bf616a"
    property color cyan: isDark ? "#81a1c1" : "#88c0d0"
    property color pink: isDark ? "#b48ead" : "#b48ead"

    // Tipografía estándar
    property string fontFamily: "JetBrainsMono Nerd Font Mono"
    property string iconFontFamily: "JetBrainsMono Nerd Font Mono"
    property string monoFontFamily: "JetBrainsMono Nerd Font Mono"

    // Espaciado y Paddings al estilo Caelestia
    readonly property int paddingExtraSmall: 4
    readonly property int paddingSmall: 8
    readonly property int paddingMedium: 12
    readonly property int paddingLarge: 16
    readonly property int paddingExtraLarge: 20

    readonly property int radiusSmall: 8
    readonly property int radiusMedium: 12
    readonly property int radiusLarge: 16
    readonly property int radiusFull: 9999

    // Tokens de animación oficiales de Caelestia (Caelestia Config.Tokens)
    readonly property var anim: QtObject {
        // Curvas Bézier Caelestia
        readonly property var expressiveFastSpatial: [0.42, 1.67, 0.21, 0.90, 1.0, 1.0]
        readonly property var expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1.00, 1.0, 1.0]
        readonly property var expressiveSlowSpatial: [0.39, 1.29, 0.35, 0.98, 1.0, 1.0]
        readonly property var emphasizedAccel: [0.30, 0.00, 0.80, 0.15, 1.0, 1.0]
        readonly property var emphasizedDecel: [0.05, 0.70, 0.10, 1.00, 1.0, 1.0]
        readonly property var expressiveFastEffects: [0.31, 0.94, 0.34, 1.00, 1.0, 1.0]
        readonly property var expressiveDefaultEffects: [0.34, 0.80, 0.34, 1.00, 1.0, 1.0]

        // Duraciones exactas Caelestia (ms)
        readonly property int fastEffects: 150
        readonly property int defaultEffects: 200
        readonly property int fastSpatial: 350
        readonly property int defaultSpatial: 500
        readonly property int slowSpatial: 650
        readonly property int closeSpatial: 280
    }

    // Lista de temas disponibles y tema activo
    property string activeThemeId: "default"
    property var availableThemes: []
    property int previewIndex: 0
    readonly property var previewThemeData: {
        if (availableThemes && availableThemes.length > 0) {
            return availableThemes[Math.max(0, Math.min(availableThemes.length - 1, previewIndex))];
        }
        return null;
    }

    function applyThemeData(parsed) {
        if (!parsed || !parsed.bg) return;
        theme.activeThemeId = parsed.id || theme.activeThemeId;
        theme.isDark = parsed.isDark !== undefined ? parsed.isDark : true;
        theme.bg = parsed.bg;
        theme.bgSurface = parsed.bgSurface || (theme.isDark ? "#181825" : "#e6e9ef");
        theme.bgHover = parsed.bgHover || (theme.isDark ? "#313244" : "#ccd0da");
        theme.border = parsed.border || (theme.isDark ? "#45475a" : "#bcc0cc");
        theme.text = parsed.text || (theme.isDark ? "#cdd6f4" : "#4c4f69");
        theme.subtext = parsed.subtext || (theme.isDark ? "#a6adc8" : "#6c6f85");
        theme.overlay = parsed.overlay || (theme.isDark ? "#6c7086" : "#9ca0b0");
        theme.primary = parsed.primary || (theme.isDark ? "#89b4fa" : "#1e66f5");
        theme.success = parsed.success || (theme.isDark ? "#a6e3a1" : "#40a02b");
        theme.warning = parsed.warning || (theme.isDark ? "#f9e2af" : "#df8e1d");
        theme.danger = parsed.danger || (theme.isDark ? "#f38ba8" : "#d20f39");
        theme.cyan = parsed.cyan || (theme.isDark ? "#89dceb" : "#04a5e5");
        theme.pink = parsed.pink || (theme.isDark ? "#f5c2e7" : "#ea76cb");
    }

    // Observador para cambios externos de tema (vía shell-theme o script)
    property var watchThemeChangeProc: Process {
        command: ["sh", "-c", "STATE=\"${XDG_RUNTIME_DIR:-/tmp}/quickshell_theme_reload.toggle\"; while true; do if [ -f \"$STATE\" ]; then rm -f \"$STATE\"; echo 'RELOAD'; fi; sleep 0.15; done"]
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                if (String(data).indexOf("RELOAD") !== -1) {
                    theme.themeProc.running = false;
                    theme.themeProc.running = true;
                }
            }
        }
    }

    // Detección automática y sincronización del tema nativo de la shell
    property Process themeProc: Process {
        command: [Quickshell.shellDir + "/scripts/theme_manager.py"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                try {
                    let str = String(data).trim();
                    let match = str.match(/\{[\s\S]*\}/);
                    if (match) {
                        let parsed = JSON.parse(match[0]);
                        applyThemeData(parsed);
                    }
                } catch (e) {}
            }
        }
    }

    property Process themeListProc: Process {
        command: [Quickshell.shellDir + "/scripts/theme_manager.py", "list"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                try {
                    let str = String(data).trim();
                    let match = str.match(/\[[\s\S]*\]/);
                    if (match) {
                        let list = JSON.parse(match[0]);
                        if (Array.isArray(list)) {
                            theme.availableThemes = list;
                        }
                    }
                } catch (e) {}
            }
        }
    }

    function refresh() {
        themeListProc.running = false;
        themeListProc.running = true;
    }

    property Process setThemeProc: Process {
        stdout: SplitParser {
            onRead: data => {
                try {
                    let str = String(data).trim();
                    let match = str.match(/\{[\s\S]*\}/);
                    if (match) {
                        let parsed = JSON.parse(match[0]);
                        applyThemeData(parsed);
                    }
                } catch (e) {}
            }
        }
        onExited: {
            theme.themeProc.running = false;
            theme.themeProc.running = true;
            theme.themeListProc.running = false;
            theme.themeListProc.running = true;
        }
    }

    function applyTheme(themeId) {
        setTheme(themeId);
    }

    function setTheme(themeId) {
        if (!themeId) return;
        // Aplicación inmediata si ya está cargado en la lista
        if (availableThemes && Array.isArray(availableThemes)) {
            for (let i = 0; i < availableThemes.length; i++) {
                if (availableThemes[i].id === themeId) {
                    applyThemeData(availableThemes[i]);
                    break;
                }
            }
        }
        setThemeProc.command = [Quickshell.shellDir + "/scripts/theme_manager.py", "set", themeId];
        setThemeProc.running = false;
        setThemeProc.running = true;
    }

    property Timer syncTimer: Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            theme.themeProc.running = false;
            theme.themeProc.running = true;
        }
    }
}
