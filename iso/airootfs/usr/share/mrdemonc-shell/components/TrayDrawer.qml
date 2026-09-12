import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray

Item {
    id: root

    property bool isExpanded: false

    property bool telegramRunning: false
    property bool discordRunning: false
    property bool spotifyRunning: false
    property bool steamRunning: false

    readonly property bool showTelegram: telegramRunning
    readonly property bool showDiscord: discordRunning
    readonly property bool showSpotify: spotifyRunning
    readonly property bool showSteam: steamRunning

    readonly property int activeStandaloneCount: (showTelegram ? 1 : 0) + (showDiscord ? 1 : 0) + (showSpotify ? 1 : 0) + (showSteam ? 1 : 0)
    readonly property int sniCount: (SystemTray.items && SystemTray.items.values) ? SystemTray.items.values.length : 0
    readonly property int totalActiveApps: sniCount + activeStandaloneCount
    readonly property bool hasActiveApps: totalActiveApps > 0

    visible: hasActiveApps
    clip: true

    property real currentWidth: {
        if (!hasActiveApps) return 0;
        if (PopoutManager.isVertical) return 22;
        return isExpanded ? (26 + appsLayout.implicitWidth) : 22;
    }

    property real currentHeight: {
        if (!hasActiveApps) return 0;
        if (!PopoutManager.isVertical) return 22;
        return isExpanded ? (26 + appsLayout.implicitHeight) : 22;
    }

    readonly property bool isAnimating: widthAnim.running || heightAnim.running

    Behavior on currentWidth {
        id: widthBehavior
        enabled: !PopoutManager.isVertical
        NumberAnimation {
            id: widthAnim
            duration: 200
            easing.type: Easing.OutQuad
        }
    }

    Behavior on currentHeight {
        id: heightBehavior
        enabled: PopoutManager.isVertical
        NumberAnimation {
            id: heightAnim
            duration: 200
            easing.type: Easing.OutQuad
        }
    }

    implicitWidth: currentWidth
    width: currentWidth
    implicitHeight: currentHeight
    height: currentHeight

    // Detección de hover en toda el área del tray
    HoverHandler {
        id: hoverHandler
        onHoveredChanged: {
            if (hovered) {
                collapseTimer.stop();
                root.isExpanded = true;
            } else {
                collapseTimer.restart();
            }
        }
    }

    // Temporizador para colapsar suavemente al retirar el cursor
    Timer {
        id: collapseTimer
        interval: 280
        repeat: false
        onTriggered: {
            if (!hoverHandler.hovered && !TrayMenuManager.isOpen) {
                root.isExpanded = false;
            }
        }
    }

    Connections {
        target: TrayMenuManager
        function onIsOpenChanged() {
            if (!TrayMenuManager.isOpen && !hoverHandler.hovered) {
                collapseTimer.restart();
            }
        }
    }

    function getScreenPos(item, localX, localY) {
        let pt = item.mapToItem(null, localX, localY);
        if (typeof barWindow !== "undefined" && barWindow.getScreenCoords) {
            return barWindow.getScreenCoords(pt.x, pt.y);
        }
        return { x: pt.x, y: pt.y };
    }

    // Verificación continua de procesos activos (cada 2.5s)
    property var checkProc: Process {
        command: ["sh", "-c", "while true; do " + Quickshell.shellDir + "/scripts/check_background_apps.sh; sleep 2.5; done"]
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                try {
                    let line = String(data).trim();
                    if (line.indexOf('{') !== -1) {
                        let jsonStr = line.substring(line.indexOf('{'), line.lastIndexOf('}') + 1);
                        let res = JSON.parse(jsonStr);
                        root.telegramRunning = !!res.telegram;
                        root.discordRunning = !!res.discord;
                        root.spotifyRunning = !!res.spotify;
                        root.steamRunning = !!res.steam;
                    }
                } catch(e) {
                    console.log("TRAY DETECT ERROR:", e);
                }
            }
        }
    }

    property var launchProc: Process {
        running: false
    }

    function openOrFocusApp(appId) {
        let cmd = "";
        if (appId === "telegram") {
            cmd = "hyprctl dispatch focuswindow TelegramDesktop 2>/dev/null || gtk-launch org.telegram.desktop.desktop 2>/dev/null || telegram-desktop 2>/dev/null || Telegram 2>/dev/null &";
        } else if (appId === "discord") {
            cmd = "hyprctl dispatch focuswindow discord 2>/dev/null || gtk-launch discord.desktop 2>/dev/null || discord 2>/dev/null || webcord 2>/dev/null &";
        } else if (appId === "spotify") {
            cmd = "hyprctl dispatch focuswindow spotify 2>/dev/null || gtk-launch spotify.desktop 2>/dev/null || spotify 2>/dev/null &";
        } else if (appId === "steam") {
            cmd = "hyprctl dispatch focuswindow steam 2>/dev/null || gtk-launch steam.desktop 2>/dev/null || steam 2>/dev/null &";
        }
        if (cmd !== "") {
            launchProc.command = ["sh", "-c", cmd];
            launchProc.running = false;
            launchProc.running = true;
        }
    }

    // Estructura totalmente sin contenedor exterior
    Item {
        anchors.fill: parent

        // 1. Icono de flecha sin palito (Chevron)
        Rectangle {
            id: chevronBtn
            width: 22
            height: 22
            anchors.left: !PopoutManager.isVertical ? parent.left : undefined
            anchors.top: PopoutManager.isVertical ? parent.top : undefined
            anchors.horizontalCenter: PopoutManager.isVertical ? parent.horizontalCenter : undefined
            anchors.verticalCenter: !PopoutManager.isVertical ? parent.verticalCenter : undefined
            radius: 5
            color: (hoverHandler.hovered && !root.isExpanded) ? Theme.bgHover : "transparent"

            Text {
                anchors.centerIn: parent
                // Flecha sin palito (Chevron):
                // En horizontal: 󰅁 cuando está contraído, 󰅂 cuando se expande
                // En vertical: 󰅃 cuando está contraído, 󰅀 cuando se expande
                text: {
                    if (PopoutManager.isVertical) {
                        return root.isExpanded ? "󰅀" : "󰅃";
                    } else {
                        return root.isExpanded ? "󰅂" : "󰅁";
                    }
                }
                font.family: Theme.iconFontFamily
                font.pixelSize: 13
                color: hoverHandler.hovered ? Theme.primary : Theme.text
            }
        }

        // 2. Apps activas en segundo plano (Horizontal o Vertical según orientación)
        Item {
            id: appsContainer
            anchors.left: !PopoutManager.isVertical ? chevronBtn.right : undefined
            anchors.leftMargin: !PopoutManager.isVertical ? 4 : 0
            anchors.top: PopoutManager.isVertical ? chevronBtn.bottom : undefined
            anchors.topMargin: PopoutManager.isVertical ? 4 : 0
            anchors.verticalCenter: !PopoutManager.isVertical ? parent.verticalCenter : undefined
            anchors.horizontalCenter: PopoutManager.isVertical ? parent.horizontalCenter : undefined
            width: appsLayout.implicitWidth
            height: appsLayout.implicitHeight
            visible: root.isExpanded
            opacity: root.isExpanded ? 1.0 : 0.0

            Behavior on opacity {
                NumberAnimation { duration: 150 }
            }

            GridLayout {
                id: appsLayout
                columns: PopoutManager.isVertical ? 1 : 50
                rows: PopoutManager.isVertical ? 50 : 1
                rowSpacing: 3
                columnSpacing: 3

                // Botón Telegram (solo si está activo en segundo plano)
                Rectangle {
                    visible: root.showTelegram
                    implicitWidth: visible ? 22 : 0
                    implicitHeight: visible ? 22 : 0
                    radius: 5
                    color: tgMouse.containsMouse ? Theme.bgHover : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        font.family: Theme.iconFontFamily
                        font.pixelSize: 12
                        color: tgMouse.containsMouse ? Theme.primary : Theme.text
                    }

                    MouseArea {
                        id: tgMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                let sc = root.getScreenPos(tgMouse, mouse.x, mouse.y);
                                TrayMenuManager.openMenu("telegram", sc.x, sc.y);
                            } else {
                                root.openOrFocusApp("telegram");
                            }
                        }
                    }
                }

                // Botón Discord (solo si está activo en segundo plano)
                Rectangle {
                    visible: root.showDiscord
                    implicitWidth: visible ? 22 : 0
                    implicitHeight: visible ? 22 : 0
                    radius: 5
                    color: dcMouse.containsMouse ? Theme.bgHover : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "󰙯"
                        font.family: Theme.iconFontFamily
                        font.pixelSize: 12
                        color: dcMouse.containsMouse ? Theme.primary : Theme.text
                    }

                    MouseArea {
                        id: dcMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                let sc = root.getScreenPos(dcMouse, mouse.x, mouse.y);
                                TrayMenuManager.openMenu("discord", sc.x, sc.y);
                            } else {
                                root.openOrFocusApp("discord");
                            }
                        }
                    }
                }

                // Botón Spotify (solo si está activo en segundo plano)
                Rectangle {
                    visible: root.showSpotify
                    implicitWidth: visible ? 22 : 0
                    implicitHeight: visible ? 22 : 0
                    radius: 5
                    color: spMouse.containsMouse ? Theme.bgHover : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "󰓇"
                        font.family: Theme.iconFontFamily
                        font.pixelSize: 12
                        color: spMouse.containsMouse ? Theme.primary : Theme.text
                    }

                    MouseArea {
                        id: spMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                let sc = root.getScreenPos(spMouse, mouse.x, mouse.y);
                                TrayMenuManager.openMenu("spotify", sc.x, sc.y);
                            } else {
                                root.openOrFocusApp("spotify");
                            }
                        }
                    }
                }

                // Botón Steam (solo si está activo en segundo plano)
                Rectangle {
                    visible: root.showSteam
                    implicitWidth: visible ? 22 : 0
                    implicitHeight: visible ? 22 : 0
                    radius: 5
                    color: stmMouse.containsMouse ? Theme.bgHover : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "󰓓"
                        font.family: Theme.iconFontFamily
                        font.pixelSize: 12
                        color: stmMouse.containsMouse ? Theme.primary : Theme.text
                    }

                    MouseArea {
                        id: stmMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                let sc = root.getScreenPos(stmMouse, mouse.x, mouse.y);
                                TrayMenuManager.openMenu("steam", sc.x, sc.y);
                            } else {
                                root.openOrFocusApp("steam");
                            }
                        }
                    }
                }

                // Ítems dinámicos de SystemTray (SNI) activos en el sistema
                Repeater {
                    model: SystemTray.items
                    delegate: Rectangle {
                        id: sniItem
                        visible: {
                            let idStr = ((modelData.id || "") + " " + (modelData.title || "")).toLowerCase();
                            if (root.showTelegram && idStr.indexOf("telegram") !== -1) return false;
                            if (root.showDiscord && (idStr.indexOf("discord") !== -1 || idStr.indexOf("webcord") !== -1)) return false;
                            if (root.showSpotify && idStr.indexOf("spotify") !== -1) return false;
                            if (root.showSteam && idStr.indexOf("steam") !== -1) return false;
                            return true;
                        }
                        implicitWidth: visible ? 22 : 0
                        implicitHeight: visible ? 22 : 0
                        radius: 5
                        color: sniMouse.containsMouse ? Theme.bgHover : "transparent"

                        Image {
                            anchors.centerIn: parent
                            width: 15
                            height: 15
                            source: (modelData.icon && String(modelData.icon).length > 0) ? modelData.icon : ""
                            visible: status === Image.Ready
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: !modelData.icon || String(modelData.icon).length === 0
                            text: "󰅁"
                            font.family: Theme.iconFontFamily
                            font.pixelSize: 12
                            color: Theme.primary
                        }

                        MouseArea {
                            id: sniMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton) {
                                    let sc = root.getScreenPos(sniMouse, mouse.x, mouse.y);
                                    TrayMenuManager.openMenu("sni", sc.x, sc.y, modelData);
                                } else {
                                    modelData.activate();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
