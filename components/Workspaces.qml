import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "./"

RowLayout {
    id: root
    spacing: 5

    property var barWindowRef: null
    property var barContentRef: null

    Process {
        id: switchWsProc
    }

    function isWorkspaceOccupied(id) {
        if (Hyprland.toplevels && Hyprland.toplevels.values) {
            for (let i = 0; i < Hyprland.toplevels.values.length; i++) {
                let top = Hyprland.toplevels.values[i];
                if (!top) continue;
                let wsId = (top.workspace && top.workspace.id !== undefined) ? top.workspace.id : (top.lastIpcObject && top.lastIpcObject.workspace ? top.lastIpcObject.workspace.id : -1);
                if (wsId === id) return true;
            }
        }
        if (Hyprland.workspaces && Hyprland.workspaces.values) {
            for (let i = 0; i < Hyprland.workspaces.values.length; i++) {
                let ws = Hyprland.workspaces.values[i];
                if (!ws) continue;
                if (ws.id === id) {
                    if (ws.lastIpcObject && ws.lastIpcObject.windows !== undefined) {
                        if (ws.lastIpcObject.windows > 0) return true;
                    }
                }
            }
        }
        return false;
    }

    readonly property string focusedAppName: {
        if (!Hyprland.activeToplevel) return "";
        let toplevel = Hyprland.activeToplevel;

        // 1. Validar que la ventana pertenece estrictamente al workspace enfocado actualmente
        let curWsId = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1;
        let winWsId = -1;
        if (toplevel.workspace && toplevel.workspace.id !== undefined) {
            winWsId = toplevel.workspace.id;
        } else if (toplevel.lastIpcObject && toplevel.lastIpcObject.workspace) {
            winWsId = toplevel.lastIpcObject.workspace.id;
        }

        if (curWsId !== -1 && winWsId !== -1 && winWsId !== curWsId) {
            return ""; // El workspace actual está vacío o la app está en otro workspace en segundo plano
        }

        if (toplevel.lastIpcObject) {
            if (toplevel.lastIpcObject.mapped === false || toplevel.lastIpcObject.hidden === true) {
                return "";
            }
        }

        // 2. Extraer nombre de la aplicación por su clase (evita mostrar rutas de carpetas)
        let cls = "";
        if (toplevel.lastIpcObject) {
            cls = toplevel.lastIpcObject.initialClass || toplevel.lastIpcObject.class || "";
        }
        if (!cls && toplevel.handle) {
            cls = toplevel.handle.appId || "";
        }

        if (cls) {
            if (cls.includes(".")) {
                let parts = cls.split(".");
                cls = parts[parts.length - 1];
            }

            let lower = cls.toLowerCase();
            // Administradores de archivos
            if (lower === "nautilus" || lower === "org.gnome.nautilus" || lower === "io.elementary.files") return "Files";
            if (lower === "thunar") return "Thunar";
            if (lower === "dolphin" || lower === "org.kde.dolphin") return "Dolphin";
            if (lower === "nemo") return "Nemo";
            if (lower === "pcmanfm" || lower === "pcmanfm-qt") return "PCManFM";

            // Navegadores
            if (lower === "zen-browser" || lower === "zen" || lower === "zen-beta" || lower === "zen-alpha") return "Zen Browser";
            if (lower === "firefox" || lower === "firefox-esr" || lower === "firefox-developer-edition") return "Firefox";
            if (lower === "google-chrome" || lower === "chromium" || lower === "chrome") return "Chrome";
            if (lower === "brave-browser" || lower === "brave") return "Brave";

            // Terminales
            if (lower === "kitty") return "Kitty";
            if (lower === "alacritty") return "Alacritty";
            if (lower === "foot") return "Foot";
            if (lower === "ghostty") return "Ghostty";
            if (lower === "wezterm") return "WezTerm";

            // Editores y herramientas
            if (lower === "code" || lower === "code-oss" || lower === "vscodium" || lower === "vscode") return "VS Code";
            if (lower === "neovim" || lower === "nvim") return "Neovim";
            if (lower === "discord" || lower === "vesktop" || lower === "webcord" || lower === "armcord") return "Discord";
            if (lower === "telegram-desktop" || lower === "ayugram-desktop") return "Telegram";
            if (lower === "spotify") return "Spotify";
            if (lower === "obsidian") return "Obsidian";
            if (lower === "steam") return "Steam";
            if (lower === "vlc") return "VLC";
            if (lower === "mpv") return "MPV";
            if (lower === "gimp") return "GIMP";
            if (lower === "inkscape") return "Inkscape";
            if (lower === "blender") return "Blender";
            if (lower === "obs") return "OBS Studio";

            return cls.charAt(0).toUpperCase() + cls.slice(1);
        }

        let title = toplevel.title || "";
        if (title) {
            if (title.startsWith("/") || title.startsWith("~") || title.includes("/")) {
                return "Files";
            }
            return title;
        }
        return "";
    }

    readonly property int maxWorkspaceCount: {
        let maxId = 5; // Mínimo 5 escritorios siempre visibles

        if (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id > maxId) {
            maxId = Hyprland.focusedWorkspace.id;
        }

        if (Hyprland.toplevels && Hyprland.toplevels.values) {
            for (let i = 0; i < Hyprland.toplevels.values.length; i++) {
                let top = Hyprland.toplevels.values[i];
                if (!top) continue;
                let wsId = (top.workspace && top.workspace.id !== undefined) ? top.workspace.id : (top.lastIpcObject && top.lastIpcObject.workspace ? top.lastIpcObject.workspace.id : -1);
                if (wsId > maxId) {
                    maxId = wsId;
                }
            }
        }

        if (Hyprland.workspaces && Hyprland.workspaces.values) {
            for (let i = 0; i < Hyprland.workspaces.values.length; i++) {
                let ws = Hyprland.workspaces.values[i];
                if (!ws) continue;
                if (ws.id > maxId) {
                    if (ws.lastIpcObject && ws.lastIpcObject.windows !== undefined) {
                        if (ws.lastIpcObject.windows > 0) maxId = ws.id;
                    } else {
                        maxId = ws.id;
                    }
                }
            }
        }

        return maxId;
    }

    Repeater {
        model: root.maxWorkspaceCount

        Item {
            id: wsItem
            property int wsId: index + 1
            property bool isFocused: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id === wsId : false
            property bool isOccupied: root.isWorkspaceOccupied(wsId)
            property bool isHovered: wsMouse.containsMouse
            readonly property bool hasApp: isFocused && root.focusedAppName !== ""

            implicitHeight: 20
            implicitWidth: {
                if (isFocused) {
                    return hasApp ? Math.min(180, contentLayout.implicitWidth + 14) : 18;
                }
                if (isHovered) return 14;
                return isOccupied ? 10 : 6;
            }

            Behavior on implicitWidth {
                NumberAnimation {
                    duration: Theme.anim.fastSpatial
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.anim.expressiveFastSpatial
                }
            }

            Rectangle {
                id: pillBg
                anchors.centerIn: parent
                width: parent.width
                height: wsItem.isFocused ? 20 : 6
                radius: wsItem.isFocused ? 6 : 3
                color: {
                    if (wsItem.isFocused) return Theme.bgHover;
                    if (wsItem.isHovered) return Theme.bgHover;
                    if (wsItem.isOccupied) return Theme.primary;
                    return Theme.overlay;
                }
                opacity: wsItem.isFocused ? 1.0 : (wsItem.isOccupied ? 0.8 : (wsItem.isHovered ? 0.9 : 0.45))

                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on opacity { NumberAnimation { duration: 150 } }
                Behavior on height { NumberAnimation { duration: 150 } }
                Behavior on radius { NumberAnimation { duration: 150 } }

                // Contenido interno del workspace
                RowLayout {
                    id: contentLayout
                    anchors.centerIn: parent
                    spacing: 5

                    // Punto indicador de foco
                    Rectangle {
                        width: wsItem.isFocused ? 6 : (wsItem.isHovered ? 8 : 4)
                        height: wsItem.isFocused ? 6 : 4
                        radius: 3
                        color: wsItem.isFocused ? Theme.primary : (wsItem.isHovered ? Theme.text : "transparent")

                        Behavior on width { NumberAnimation { duration: 120 } }
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    // Nombre de la app en foco (solo visible en el workspace activo)
                    Text {
                        visible: wsItem.isFocused && wsItem.hasApp
                        text: root.focusedAppName
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                        Layout.maximumWidth: 140
                    }
                }
            }

            MouseArea {
                id: wsMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: isDraggingThis ? Qt.ClosedHandCursor : Qt.PointingHandCursor

                property real pressGlobalX: 0
                property real initialModuleX: 0
                property bool isDraggingThis: false

                onPressed: mouse => {
                    if (root.barContentRef) {
                        let globalPt = mapToItem(root.barContentRef, mouse.x, mouse.y);
                        pressGlobalX = globalPt.x;
                    }
                    let m = root.barWindowRef ? root.barWindowRef.getModule("workspaces") : null;
                    initialModuleX = m ? m.x : (root.barWindowRef ? root.barWindowRef.getSlotX("workspaces") : 0);
                    isDraggingThis = false;
                }

                onPositionChanged: mouse => {
                    if (!pressed) return;
                    if (!root.barContentRef || !root.barWindowRef) return;
                    let globalPt = mapToItem(root.barContentRef, mouse.x, mouse.y);
                    let delta = globalPt.x - pressGlobalX;
                    if (!isDraggingThis) {
                        if (Math.abs(delta) > 6) {
                            isDraggingThis = true;
                            root.barWindowRef.startModuleDrag("workspaces", initialModuleX);
                        }
                    }
                    if (isDraggingThis) {
                        root.barWindowRef.updateModuleDrag("workspaces", initialModuleX + delta);
                    }
                }

                onClicked: {
                    if (!isDraggingThis) {
                        try {
                            Hyprland.dispatch("hl.dsp.focus({ workspace = " + wsItem.wsId + " })");
                        } catch (e) {}
                        switchWsProc.command = ["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + wsItem.wsId + " })"];
                        switchWsProc.running = false;
                        switchWsProc.running = true;
                    }
                }

                onReleased: {
                    if (isDraggingThis) {
                        isDraggingThis = false;
                        if (root.barWindowRef) root.barWindowRef.finishModuleDrag();
                    }
                }

                onCanceled: {
                    if (isDraggingThis) {
                        isDraggingThis = false;
                        if (root.barWindowRef) root.barWindowRef.finishModuleDrag();
                    }
                }
            }
        }
    }
}
