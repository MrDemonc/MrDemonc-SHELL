import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "./"

GridLayout {
    id: root
    columns: PopoutManager.isVertical ? 1 : 99
    rows: PopoutManager.isVertical ? 99 : 1
    rowSpacing: 5
    columnSpacing: 5

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

    readonly property var currentActiveToplevel: {
        if (Hyprland.activeToplevel) return Hyprland.activeToplevel;
        if (Hyprland.toplevels && Hyprland.toplevels.values) {
            for (let i = 0; i < Hyprland.toplevels.values.length; i++) {
                let t = Hyprland.toplevels.values[i];
                if (t && t.lastIpcObject && t.lastIpcObject.focusHistoryID === 0) {
                    return t;
                }
            }
            if (Hyprland.toplevels.values.length === 1) {
                return Hyprland.toplevels.values[0];
            }
        }
        return null;
    }

    readonly property string focusedAppName: {
        let toplevel = root.currentActiveToplevel;
        if (!toplevel) return "";

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
        if (toplevel.class) {
            cls = toplevel.class;
        } else if (toplevel.initialClass) {
            cls = toplevel.initialClass;
        } else if (toplevel.lastIpcObject) {
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
            if (lower === "kitty" || lower.includes("kitty")) return "Kitty";
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

        let initTitle = "";
        if (toplevel.initialTitle) initTitle = toplevel.initialTitle;
        if (!initTitle && toplevel.lastIpcObject) initTitle = toplevel.lastIpcObject.initialTitle || "";
        if (initTitle) {
            let lowerInit = initTitle.toLowerCase();
            if (lowerInit === "kitty" || lowerInit.includes("kitty")) return "Kitty";
            if (lowerInit === "alacritty") return "Alacritty";
            if (lowerInit === "foot") return "Foot";
            if (lowerInit === "ghostty") return "Ghostty";
        }

        let title = toplevel.title || "";
        if (title) {
            let lowerTitle = title.toLowerCase();
            if (lowerTitle === "kitty" || lowerTitle.includes("kitty") || lowerTitle.startsWith("~") || lowerTitle.includes("@") || lowerTitle.includes("bash") || lowerTitle.includes("zsh")) {
                return "Kitty";
            }
            if (lowerTitle.includes("dolphin")) return "Dolphin";
            if (lowerTitle.includes("thunar")) return "Thunar";
            if (lowerTitle.includes("nautilus")) return "Files";
            return title.length > 20 ? (title.slice(0, 18) + "…") : title;
        }
        return "";
    }

    readonly property string focusedAppIcon: {
        let app = root.focusedAppName.toLowerCase();
        if (!app) return "";
        if (app.includes("kitty")) return "󰄛";
        if (app.includes("alacritty") || app.includes("foot") || app.includes("ghostty") || app.includes("term")) return "";
        if (app.includes("zen") || app.includes("browser") || app.includes("firefox")) return "󰈹";
        if (app.includes("chrome") || app.includes("chromium") || app.includes("brave")) return "󰊯";
        if (app.includes("code") || app.includes("vscode") || app.includes("codium")) return "󰨞";
        if (app.includes("neovim") || app.includes("nvim")) return "";
        if (app.includes("discord") || app.includes("vesktop") || app.includes("webcord")) return "󰙯";
        if (app.includes("telegram")) return "";
        if (app.includes("spotify")) return "󰓇";
        if (app.includes("files") || app.includes("dolphin") || app.includes("thunar") || app.includes("nemo") || app.includes("nautilus")) return "󰉋";
        if (app.includes("obsidian")) return "󱓧";
        if (app.includes("steam")) return "󰓓";
        if (app.includes("vlc") || app.includes("mpv")) return "󰕼";
        if (app.includes("gimp") || app.includes("inkscape") || app.includes("blender")) return "󰥟";
        if (app.includes("obs")) return "󰑋";
        return "󱂬";
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

            Layout.alignment: Qt.AlignCenter

            implicitHeight: {
                if (PopoutManager.isVertical) {
                    if (isFocused) return (hasApp && root.focusedAppIcon !== "") ? 24 : 18;
                    if (isHovered) return 14;
                    return isOccupied ? 10 : 6;
                }
                return 20;
            }
            implicitWidth: {
                if (PopoutManager.isVertical) {
                    return 20;
                }
                if (isFocused) {
                    return (hasApp && !PopoutManager.isVertical) ? Math.min(200, contentLayout.implicitWidth + 16) : 18;
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

            Behavior on implicitHeight {
                NumberAnimation {
                    duration: Theme.anim.fastSpatial
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.anim.expressiveFastSpatial
                }
            }

            Rectangle {
                id: pillBg
                anchors.centerIn: parent
                width: PopoutManager.isVertical ? (wsItem.isFocused ? 20 : 6) : parent.width
                height: PopoutManager.isVertical ? parent.height : (wsItem.isFocused ? 20 : 6)
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
                Behavior on width { NumberAnimation { duration: 150 } }
                Behavior on radius { NumberAnimation { duration: 150 } }

                // Icono de la aplicación en foco (para formato vertical)
                Text {
                    visible: PopoutManager.isVertical && wsItem.isFocused && wsItem.hasApp && root.focusedAppIcon !== ""
                    anchors.centerIn: parent
                    text: root.focusedAppIcon
                    color: Theme.primary
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }

                // Contenido interno del workspace horizontal
                RowLayout {
                    id: contentLayout
                    anchors.centerIn: parent
                    spacing: 6
                    visible: !PopoutManager.isVertical || !(wsItem.isFocused && wsItem.hasApp && root.focusedAppIcon !== "")

                    // Icono de la aplicación en foco (modo horizontal)
                    Text {
                        visible: !PopoutManager.isVertical && wsItem.isFocused && wsItem.hasApp && root.focusedAppIcon !== ""
                        text: root.focusedAppIcon
                        color: Theme.primary
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // Punto indicador de foco (visible cuando no hay icono de app en foco)
                    Rectangle {
                        visible: !(!PopoutManager.isVertical && wsItem.isFocused && wsItem.hasApp && root.focusedAppIcon !== "")
                        width: wsItem.isFocused ? 6 : (wsItem.isHovered ? 8 : 4)
                        height: wsItem.isFocused ? 6 : 4
                        radius: 3
                        color: wsItem.isFocused ? Theme.primary : (wsItem.isHovered ? Theme.text : "transparent")
                        Layout.alignment: Qt.AlignVCenter

                        Behavior on width { NumberAnimation { duration: 120 } }
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    // Nombre de la app en foco (solo visible en el workspace activo en modo horizontal)
                    Text {
                        visible: !PopoutManager.isVertical && wsItem.isFocused && wsItem.hasApp
                        text: root.focusedAppName
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                        Layout.maximumWidth: 150
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }

            MouseArea {
                id: wsMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: isDraggingThis ? Qt.ClosedHandCursor : Qt.PointingHandCursor

                property real pressGlobalCoord: 0
                property real initialModuleCoord: 0
                property bool isDraggingThis: false
                property bool wasDragged: false

                onPressed: mouse => {
                    wasDragged = false;
                    isDraggingThis = false;
                    if (root.barContentRef) {
                        let globalPt = mapToItem(root.barContentRef, mouse.x, mouse.y);
                        pressGlobalCoord = PopoutManager.isVertical ? globalPt.y : globalPt.x;
                    }
                    let m = root.barWindowRef ? root.barWindowRef.getModule("workspaces") : null;
                    if (PopoutManager.isVertical) {
                        initialModuleCoord = m ? m.y : (root.barWindowRef ? root.barWindowRef.getSlotY("workspaces") : 0);
                    } else {
                        initialModuleCoord = m ? m.x : (root.barWindowRef ? root.barWindowRef.getSlotX("workspaces") : 0);
                    }
                }

                onPositionChanged: mouse => {
                    if (!pressed) return;
                    if (!root.barContentRef || !root.barWindowRef) return;
                    let globalPt = mapToItem(root.barContentRef, mouse.x, mouse.y);
                    let currentCoord = PopoutManager.isVertical ? globalPt.y : globalPt.x;
                    let delta = currentCoord - pressGlobalCoord;
                    if (!isDraggingThis) {
                        if (Math.abs(delta) > 6) {
                            isDraggingThis = true;
                            wasDragged = true;
                            root.barWindowRef.startModuleDrag("workspaces", initialModuleCoord);
                        }
                    }
                    if (isDraggingThis) {
                        root.barWindowRef.updateModuleDrag("workspaces", initialModuleCoord + delta);
                    }
                }

                onClicked: {
                    if (!wasDragged && !isDraggingThis) {
                        try {
                            Hyprland.dispatch("hl.dsp.focus({ workspace = " + wsItem.wsId + " })");
                        } catch (e) {}
                        switchWsProc.command = ["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + wsItem.wsId + " })"];
                        switchWsProc.running = false;
                        switchWsProc.running = true;
                    }
                    wasDragged = false;
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
                    wasDragged = false;
                }
            }
        }
    }
}
