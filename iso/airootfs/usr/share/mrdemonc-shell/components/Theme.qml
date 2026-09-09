pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: theme

    // Catppuccin Mocha / Dark & Light
    property bool isDark: true
    property color bg: isDark ? "#1e1e2e" : "#eff1f5"
    property color bgSurface: isDark ? "#181825" : "#e6e9ef"
    property color bgHover: isDark ? "#313244" : "#ccd0da"
    property color border: isDark ? "#313244" : "#bcc0cc"
    property color text: isDark ? "#cdd6f4" : "#4c4f69"
    property color subtext: isDark ? "#a6adc8" : "#6c6f85"
    property color overlay: isDark ? "#6c7086" : "#9ca0b0"
    
    // Colores de acento
    property color primary: isDark ? "#89b4fa" : "#1e66f5"
    property color success: isDark ? "#a6e3a1" : "#40a02b"
    property color warning: isDark ? "#f9e2af" : "#df8e1d"
    property color danger: isDark ? "#f38ba8" : "#d20f39"
    property color cyan: isDark ? "#89dceb" : "#04a5e5"
    property color pink: isDark ? "#f5c2e7" : "#ea76cb"

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
    property string activeThemeId: "catppuccin-mocha"
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
