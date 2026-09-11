import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    implicitWidth: PopoutManager.isVertical ? 320 : 600
    implicitHeight: PopoutManager.isVertical ? 428 : 252

    property var sysData: ({
        user: { username: "usuario", hostname: "archlinux", uptime: "0m", avatar: "" },
        weather: { city: "Ubicación actual", country: "", temp: "--°C", feels_like: "--°C", desc: "Consultando clima...", icon: "󰖐", humidity: "--%", wind: "-- km/h", available: false },
        media: { active: false, status: "Stopped", player: "", title: "Sin reproducción", artist: "Reproductor inactivo", artUrl: "", isPlaying: false },
        cpu: { percent: 0 },
        ram: { total_gb: 0, used_gb: 0, percent: 0 },
        disk: { total_gb: 0, used_gb: 0, percent: 0 }
    })

    // Monitor demonio en tiempo real
    Process {
        id: sysInfoProc
        command: [Quickshell.shellDir + "/scripts/get_system_info.py", "--daemon"]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                try {
                    let str = String(line).trim();
                    if (str.length > 0 && str.startsWith("{")) {
                        root.sysData = JSON.parse(str);
                    }
                } catch (e) {}
            }
        }
    }

    // Acciones de medios y comandos de sistema
    Process { id: mediaActionProc }
    Process { id: sysCmdProc }

    function runMedia(cmd) {
        mediaActionProc.command = ["playerctl", cmd];
        mediaActionProc.running = true;
    }

    function runSysCmd(args) {
        PopoutManager.close();
        sysCmdProc.command = args;
        sysCmdProc.running = true;
    }

    // =========================================================================
    // 1. VISTA HORIZONTAL (Barra en Top o Bottom)
    // =========================================================================
    ColumnLayout {
        id: horizontalView
        visible: !PopoutManager.isVertical
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 6
        anchors.bottomMargin: 6
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 7

        // ---------------------------------------------------------------------
        // SECCIÓN SUPERIOR: Información de Usuario & Bienvenida (Top Header)
        // ---------------------------------------------------------------------
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 46
            color: Theme.bgSurface
            radius: 12
            border.color: Theme.border
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 12

                // Icono Arch Linux Animado
                Rectangle {
                    implicitWidth: 32
                    implicitHeight: 32
                    radius: 16
                    color: Theme.bgHover
                    border.color: Theme.primary
                    border.width: 1.5

                    Text {
                        anchors.centerIn: parent
                        text: "󰣇"
                        color: Theme.primary
                        font.family: Theme.iconFontFamily
                        font.pixelSize: 18

                        SequentialAnimation on scale {
                            loops: Animation.Infinite
                            running: true
                            NumberAnimation { from: 1.0; to: 1.15; duration: 1200; easing.type: Easing.InOutSine }
                            NumberAnimation { from: 1.15; to: 1.0; duration: 1200; easing.type: Easing.InOutSine }
                        }

                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            running: true
                            NumberAnimation { from: 0.85; to: 1.0; duration: 1200; easing.type: Easing.InOutSine }
                            NumberAnimation { from: 1.0; to: 0.85; duration: 1200; easing.type: Easing.InOutSine }
                        }
                    }
                }

                // Nombre de Usuario y Hostname
                RowLayout {
                    spacing: 6
                    Text {
                        text: root.sysData.user.username.toUpperCase()
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.bold: true
                    }

                    Text {
                        text: "@" + root.sysData.user.hostname
                        color: Theme.overlay
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }
                }

                Item { Layout.fillWidth: true }

                // Tiempo de actividad (Uptime)
                RowLayout {
                    spacing: 4
                    Text {
                        text: "󱎫"
                        color: Theme.primary
                        font.family: Theme.iconFontFamily
                        font.pixelSize: 12
                    }
                    Text {
                        text: root.sysData.user.uptime
                        color: Theme.subtext
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }
                }

                // Frase Welcome
                Rectangle {
                    implicitHeight: 26
                    implicitWidth: 92
                    radius: 7
                    color: Theme.bgHover
                    border.color: Theme.primary
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: "󰄛"
                            color: Theme.primary
                            font.family: Theme.iconFontFamily
                            font.pixelSize: 11
                        }

                        Text {
                            text: "WELCOME"
                            color: Theme.primary
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            font.bold: true
                            font.letterSpacing: 1.0
                        }
                    }
                }
            }
        }

        // ---------------------------------------------------------------------
        // SECCIÓN MEDIA: Clima, Control Multimedia (Sin Cover) y Recursos
        // ---------------------------------------------------------------------
        RowLayout {
            id: contentRow
            Layout.fillWidth: true
            implicitHeight: 122
            spacing: 8

            // Módulo A: Información del Clima Actual
            Rectangle {
                Layout.preferredWidth: 185
                implicitHeight: 122
                Layout.preferredHeight: 122
                color: Theme.bgSurface
                radius: 12
                border.color: Theme.border
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6

                    // Ubicación / Ciudad (Clickeable para cambiar ubicación)
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 22
                        radius: 6
                        color: locMouseH.containsMouse ? Theme.bgHover : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 4
                            anchors.rightMargin: 4
                            spacing: 4

                            Text {
                                text: "󰍎"
                                color: Theme.primary
                                font.family: Theme.iconFontFamily
                                font.pixelSize: 11
                            }

                            Text {
                                text: (root.sysData.weather && root.sysData.weather.city) ? (root.sysData.weather.city + (root.sysData.weather.country ? (", " + root.sysData.weather.country) : "")) : "Ubicación"
                                color: locMouseH.containsMouse ? Theme.primary : Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.bold: true
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: "󰏫"
                                color: Theme.overlay
                                font.family: Theme.iconFontFamily
                                font.pixelSize: 10
                                visible: locMouseH.containsMouse
                            }
                        }

                        MouseArea {
                            id: locMouseH
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                PopoutManager.close();
                                WeatherLocationManager.open();
                            }
                        }
                    }

                    // Temperatura e Icono
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: (root.sysData.weather && root.sysData.weather.icon) ? root.sysData.weather.icon : "󰖐"
                            color: Theme.primary
                            font.family: Theme.iconFontFamily
                            font.pixelSize: 28
                        }

                        ColumnLayout {
                            spacing: 1
                            Layout.fillWidth: true

                            Text {
                                text: (root.sysData.weather && root.sysData.weather.temp) ? root.sysData.weather.temp : "--°C"
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 16
                                font.bold: true
                            }

                            Text {
                                text: "Sensación " + ((root.sysData.weather && root.sysData.weather.feels_like) ? root.sysData.weather.feels_like : "--°C")
                                color: Theme.subtext
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }
                        }
                    }

                    // Condición climática
                    Text {
                        text: (root.sysData.weather && root.sysData.weather.desc) ? root.sysData.weather.desc : "Clima actual"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    // Humedad y Viento
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: "󰖌 " + ((root.sysData.weather && root.sysData.weather.humidity) ? root.sysData.weather.humidity : "--%")
                            color: Theme.overlay
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }

                        Text {
                            text: "•"
                            color: Theme.border
                            font.pixelSize: 8
                        }

                        Text {
                            text: "󰖝 " + ((root.sysData.weather && root.sysData.weather.wind) ? root.sysData.weather.wind : "--")
                            color: Theme.overlay
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            // Módulo B: Control Multimedia (Sin Cover)
            Rectangle {
                Layout.preferredWidth: 185
                implicitHeight: 122
                Layout.preferredHeight: 122
                color: Theme.bgSurface
                radius: 12
                border.color: root.sysData.media.isPlaying ? Theme.primary : Theme.border
                border.width: 1

                Behavior on border.color { ColorAnimation { duration: 180 } }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 4

                    // Encabezado con Icono y Reproductor
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: "󰎆"
                            color: root.sysData.media.isPlaying ? Theme.primary : Theme.overlay
                            font.family: Theme.iconFontFamily
                            font.pixelSize: 13
                        }

                        Text {
                            text: root.sysData.media.player ? root.sysData.media.player.toUpperCase() : "MULTIMEDIA"
                            color: Theme.primary
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    // Título de la pista
                    Text {
                        text: root.sysData.media.title
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    // Artista
                    Text {
                        text: root.sysData.media.artist
                        color: Theme.subtext
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Item { Layout.fillHeight: true }

                    // Botones de control centrados
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 12

                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter
                            implicitWidth: 24
                            implicitHeight: 24
                            radius: 12
                            color: prevM.containsMouse ? Theme.bgHover : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "󰒮"
                                color: prevM.containsMouse ? Theme.primary : Theme.text
                                font.family: Theme.iconFontFamily
                                font.pixelSize: 12
                            }

                            MouseArea {
                                id: prevM
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.runMedia("previous")
                            }
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter
                            implicitWidth: 26
                            implicitHeight: 26
                            radius: 13
                            color: Theme.primary

                            Text {
                                anchors.centerIn: parent
                                anchors.horizontalCenterOffset: root.sysData.media.isPlaying ? 0 : 1
                                text: root.sysData.media.isPlaying ? "󰏤" : "󰐊"
                                color: Theme.bg
                                font.family: Theme.iconFontFamily
                                font.pixelSize: 12
                                font.bold: true
                            }

                            MouseArea {
                                id: playM
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.runMedia("play-pause")
                            }
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter
                            implicitWidth: 24
                            implicitHeight: 24
                            radius: 12
                            color: nextM.containsMouse ? Theme.bgHover : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "󰒭"
                                color: nextM.containsMouse ? Theme.primary : Theme.text
                                font.family: Theme.iconFontFamily
                                font.pixelSize: 12
                            }

                            MouseArea {
                                id: nextM
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.runMedia("next")
                            }
                        }
                    }
                }
            }

            // Módulo C: Recursos del Sistema
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 122
                Layout.preferredHeight: 122
                color: Theme.bgSurface
                radius: 12
                border.color: Theme.border
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 5

                    // CPU
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: " CPU"; color: Theme.subtext; font.family: Theme.fontFamily; font.pixelSize: 10 }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: root.sysData.cpu.percent + "%"
                                color: root.sysData.cpu.percent > 85 ? Theme.danger : Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 4
                            radius: 2
                            color: Theme.bgHover

                            Rectangle {
                                height: parent.height
                                radius: 2
                                width: Math.max(0, Math.min(parent.width, parent.width * (root.sysData.cpu.percent / 100)))
                                color: root.sysData.cpu.percent > 85 ? Theme.danger : Theme.primary
                                Behavior on width { NumberAnimation { duration: 250 } }
                            }
                        }
                    }

                    // RAM
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "󰘚 RAM"; color: Theme.subtext; font.family: Theme.fontFamily; font.pixelSize: 10 }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: root.sysData.ram.used_gb + "G (" + root.sysData.ram.percent + "%)"
                                color: root.sysData.ram.percent > 85 ? Theme.warning : Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 4
                            radius: 2
                            color: Theme.bgHover

                            Rectangle {
                                height: parent.height
                                radius: 2
                                width: Math.max(0, Math.min(parent.width, parent.width * (root.sysData.ram.percent / 100)))
                                color: root.sysData.ram.percent > 85 ? Theme.warning : Theme.cyan
                                Behavior on width { NumberAnimation { duration: 250 } }
                            }
                        }
                    }

                    // DISCO
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "󰋊 Disco"; color: Theme.subtext; font.family: Theme.fontFamily; font.pixelSize: 10 }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: root.sysData.disk.used_gb + "G (" + root.sysData.disk.percent + "%)"
                                color: root.sysData.disk.percent > 90 ? Theme.danger : Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 4
                            radius: 2
                            color: Theme.bgHover

                            Rectangle {
                                height: parent.height
                                radius: 2
                                width: Math.max(0, Math.min(parent.width, parent.width * (root.sysData.disk.percent / 100)))
                                color: root.sysData.disk.percent > 90 ? Theme.danger : Theme.success
                                Behavior on width { NumberAnimation { duration: 250 } }
                            }
                        }
                    }
                }
            }
        }

        // ---------------------------------------------------------------------
        // SECCIÓN INFERIOR: Fila de Acciones de Energía
        // ---------------------------------------------------------------------
        Rectangle {
            id: pwrPanelH
            Layout.fillWidth: true
            implicitHeight: 36
            color: Theme.bgSurface
            radius: 10
            border.color: Theme.border
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 6

                // 1. Bloquear Pantalla
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 7
                    color: btnLockH.containsMouse ? Theme.bgHover : "transparent"

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 5
                        Text { text: "󰌾"; color: Theme.primary; font.family: Theme.iconFontFamily; font.pixelSize: 12 }
                        Text { text: "Bloquear"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 10; font.bold: true }
                    }

                    MouseArea {
                        id: btnLockH
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.runSysCmd(["hyprlock"])
                    }
                }

                // 2. Suspender
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 7
                    color: btnSuspendH.containsMouse ? Theme.bgHover : "transparent"

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 5
                        Text { text: "󰤄"; color: Theme.warning; font.family: Theme.iconFontFamily; font.pixelSize: 12 }
                        Text { text: "Suspender"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 10; font.bold: true }
                    }

                    MouseArea {
                        id: btnSuspendH
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.runSysCmd(["systemctl", "suspend"])
                    }
                }

                // 3. Reiniciar
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 7
                    color: btnRebootH.containsMouse ? Theme.bgHover : "transparent"

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 5
                        Text { text: "󰑐"; color: Theme.cyan; font.family: Theme.iconFontFamily; font.pixelSize: 12 }
                        Text { text: "Reiniciar"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 10; font.bold: true }
                    }

                    MouseArea {
                        id: btnRebootH
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.runSysCmd(["systemctl", "reboot"])
                    }
                }

                // 4. Apagar
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 7
                    color: btnPowerH.containsMouse ? Theme.bgHover : "transparent"

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 5
                        Text { text: "󰐥"; color: Theme.danger; font.family: Theme.iconFontFamily; font.pixelSize: 12 }
                        Text { text: "Apagar"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 10; font.bold: true }
                    }

                    MouseArea {
                        id: btnPowerH
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.runSysCmd(["systemctl", "poweroff"])
                    }
                }

                // 5. Salir / Cerrar Sesión
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 7
                    color: btnLogoutH.containsMouse ? Theme.bgHover : "transparent"

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 5
                        Text { text: "󰗼"; color: Theme.pink; font.family: Theme.iconFontFamily; font.pixelSize: 12 }
                        Text { text: "Salir"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 10; font.bold: true }
                    }

                    MouseArea {
                        id: btnLogoutH
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.runSysCmd(["hyprctl", "dispatch", "exit"])
                    }
                }
            }
        }
    }

    // =========================================================================
    // 2. VISTA VERTICAL (Barra en Left o Right)
    // =========================================================================
    ColumnLayout {
        id: verticalView
        visible: PopoutManager.isVertical
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 6
        anchors.bottomMargin: 6
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 7

        // Módulo 1: Perfil de Usuario y Frase Welcome
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 58
            color: Theme.bgSurface
            radius: 12
            border.color: Theme.border
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Rectangle {
                    implicitWidth: 36
                    implicitHeight: 36
                    radius: 18
                    color: Theme.bgHover
                    border.color: Theme.primary
                    border.width: 1.5

                    Text {
                        anchors.centerIn: parent
                        text: "󰣇"
                        color: Theme.primary
                        font.family: Theme.iconFontFamily
                        font.pixelSize: 20

                        SequentialAnimation on scale {
                            loops: Animation.Infinite
                            running: true
                            NumberAnimation { from: 1.0; to: 1.15; duration: 1200; easing.type: Easing.InOutSine }
                            NumberAnimation { from: 1.15; to: 1.0; duration: 1200; easing.type: Easing.InOutSine }
                        }

                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            running: true
                            NumberAnimation { from: 0.85; to: 1.0; duration: 1200; easing.type: Easing.InOutSine }
                            NumberAnimation { from: 1.0; to: 0.85; duration: 1200; easing.type: Easing.InOutSine }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: root.sysData.user.username.toUpperCase()
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.bold: true
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "󱎫 " + root.sysData.user.uptime
                        color: Theme.subtext
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Rectangle {
                    implicitHeight: 26
                    implicitWidth: 80
                    radius: 7
                    color: Theme.bgHover
                    border.color: Theme.primary
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: "󰄛"
                            color: Theme.primary
                            font.family: Theme.iconFontFamily
                            font.pixelSize: 11
                        }

                        Text {
                            text: "WELCOME"
                            color: Theme.primary
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            font.bold: true
                            font.letterSpacing: 1.0
                        }
                    }
                }
            }
        }

        // Módulo 2: Clima Actual Vertical
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 78
            color: Theme.bgSurface
            radius: 12
            border.color: Theme.border
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Text {
                    text: (root.sysData.weather && root.sysData.weather.icon) ? root.sysData.weather.icon : "󰖐"
                    color: Theme.primary
                    font.family: Theme.iconFontFamily
                    font.pixelSize: 30
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: (root.sysData.weather && root.sysData.weather.temp) ? root.sysData.weather.temp : "--°C"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 15
                            font.bold: true
                        }

                        Text {
                            text: (root.sysData.weather && root.sysData.weather.desc) ? root.sysData.weather.desc : ""
                            color: Theme.subtext
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 20
                            radius: 5
                            color: locMouseV.containsMouse ? Theme.bgHover : "transparent"
                            Behavior on color { ColorAnimation { duration: 120 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 2
                                anchors.rightMargin: 2
                                spacing: 3

                                Text {
                                    text: "󰍎 " + ((root.sysData.weather && root.sysData.weather.city) ? root.sysData.weather.city : "Ubicación")
                                    color: locMouseV.containsMouse ? Theme.text : Theme.primary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: "󰏫"
                                    color: Theme.overlay
                                    font.family: Theme.iconFontFamily
                                    font.pixelSize: 9
                                    visible: locMouseV.containsMouse
                                }
                            }

                            MouseArea {
                                id: locMouseV
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    PopoutManager.close();
                                    WeatherLocationManager.open();
                                }
                            }
                        }

                        Text {
                            text: "• 󰖌 " + ((root.sysData.weather && root.sysData.weather.humidity) ? root.sysData.weather.humidity : "")
                            color: Theme.overlay
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                        }
                    }
                }
            }
        }

        // Módulo 3: Control Multimedia Vertical (Sin Cover)
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 66
            color: Theme.bgSurface
            radius: 12
            border.color: root.sysData.media.isPlaying ? Theme.primary : Theme.border
            border.width: 1

            Behavior on border.color { ColorAnimation { duration: 180 } }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                Text {
                    text: "󰎆"
                    color: root.sysData.media.isPlaying ? Theme.primary : Theme.overlay
                    font.family: Theme.iconFontFamily
                    font.pixelSize: 18
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: root.sysData.media.title
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: root.sysData.media.artist
                        color: Theme.subtext
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                RowLayout {
                    spacing: 6

                    Rectangle {
                        implicitWidth: 22
                        implicitHeight: 22
                        radius: 11
                        color: prevMV.containsMouse ? Theme.bgHover : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "󰒮"
                            color: prevMV.containsMouse ? Theme.primary : Theme.text
                            font.family: Theme.iconFontFamily
                            font.pixelSize: 11
                        }

                        MouseArea {
                            id: prevMV
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.runMedia("previous")
                        }
                    }

                    Rectangle {
                        implicitWidth: 26
                        implicitHeight: 26
                        radius: 13
                        color: Theme.primary

                        Text {
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: root.sysData.media.isPlaying ? 0 : 1
                            text: root.sysData.media.isPlaying ? "󰏤" : "󰐊"
                            color: Theme.bg
                            font.family: Theme.iconFontFamily
                            font.pixelSize: 12
                            font.bold: true
                        }

                        MouseArea {
                            id: playMV
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.runMedia("play-pause")
                        }
                    }

                    Rectangle {
                        implicitWidth: 22
                        implicitHeight: 22
                        radius: 11
                        color: nextMV.containsMouse ? Theme.bgHover : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "󰒭"
                            color: nextMV.containsMouse ? Theme.primary : Theme.text
                            font.family: Theme.iconFontFamily
                            font.pixelSize: 11
                        }

                        MouseArea {
                            id: nextMV
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.runMedia("next")
                        }
                    }
                }
            }
        }

        // Módulo 4: Recursos del Sistema Vertical
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 96
            color: Theme.bgSurface
            radius: 12
            border.color: Theme.border
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4

                // CPU
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: " CPU"; color: Theme.subtext; font.family: Theme.fontFamily; font.pixelSize: 10 }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: root.sysData.cpu.percent + "%"
                            color: root.sysData.cpu.percent > 85 ? Theme.danger : Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 4
                        radius: 2
                        color: Theme.bgHover

                        Rectangle {
                            height: parent.height
                            radius: 2
                            width: Math.max(0, Math.min(parent.width, parent.width * (root.sysData.cpu.percent / 100)))
                            color: root.sysData.cpu.percent > 85 ? Theme.danger : Theme.primary
                            Behavior on width { NumberAnimation { duration: 250 } }
                        }
                    }
                }

                // RAM
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "󰘚 RAM"; color: Theme.subtext; font.family: Theme.fontFamily; font.pixelSize: 10 }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: root.sysData.ram.used_gb + "G (" + root.sysData.ram.percent + "%)"
                            color: root.sysData.ram.percent > 85 ? Theme.warning : Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 4
                        radius: 2
                        color: Theme.bgHover

                        Rectangle {
                            height: parent.height
                            radius: 2
                            width: Math.max(0, Math.min(parent.width, parent.width * (root.sysData.ram.percent / 100)))
                            color: root.sysData.ram.percent > 85 ? Theme.warning : Theme.cyan
                            Behavior on width { NumberAnimation { duration: 250 } }
                        }
                    }
                }

                // DISCO
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "󰋊 Disco"; color: Theme.subtext; font.family: Theme.fontFamily; font.pixelSize: 10 }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: root.sysData.disk.used_gb + "G (" + root.sysData.disk.percent + "%)"
                            color: root.sysData.disk.percent > 90 ? Theme.danger : Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 4
                        radius: 2
                        color: Theme.bgHover

                        Rectangle {
                            height: parent.height
                            radius: 2
                            width: Math.max(0, Math.min(parent.width, parent.width * (root.sysData.disk.percent / 100)))
                            color: root.sysData.disk.percent > 90 ? Theme.danger : Theme.success
                            Behavior on width { NumberAnimation { duration: 250 } }
                        }
                    }
                }
            }
        }

        // Módulo 5: Acciones de Energía Vertical
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 68
            color: Theme.bgSurface
            radius: 10
            border.color: Theme.border
            border.width: 1

            GridLayout {
                anchors.fill: parent
                anchors.margins: 4
                columns: 3
                rowSpacing: 4
                columnSpacing: 4

                // 1. Bloquear
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 7
                    color: btnLockV.containsMouse ? Theme.bgHover : "transparent"

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Text { text: "󰌾"; color: Theme.primary; font.family: Theme.iconFontFamily; font.pixelSize: 11 }
                        Text { text: "Bloquear"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 10 }
                    }

                    MouseArea {
                        id: btnLockV
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.runSysCmd(["hyprlock"])
                    }
                }

                // 2. Suspender
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 7
                    color: btnSuspendV.containsMouse ? Theme.bgHover : "transparent"

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Text { text: "󰤄"; color: Theme.warning; font.family: Theme.iconFontFamily; font.pixelSize: 11 }
                        Text { text: "Suspender"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 10 }
                    }

                    MouseArea {
                        id: btnSuspendV
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.runSysCmd(["systemctl", "suspend"])
                    }
                }

                // 3. Reiniciar
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 7
                    color: btnRebootV.containsMouse ? Theme.bgHover : "transparent"

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Text { text: "󰑐"; color: Theme.cyan; font.family: Theme.iconFontFamily; font.pixelSize: 11 }
                        Text { text: "Reiniciar"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 10 }
                    }

                    MouseArea {
                        id: btnRebootV
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.runSysCmd(["systemctl", "reboot"])
                    }
                }

                // 4. Apagar
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 7
                    color: btnPowerV.containsMouse ? Theme.bgHover : "transparent"

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Text { text: "󰐥"; color: Theme.danger; font.family: Theme.iconFontFamily; font.pixelSize: 11 }
                        Text { text: "Apagar"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 10 }
                    }

                    MouseArea {
                        id: btnPowerV
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.runSysCmd(["systemctl", "poweroff"])
                    }
                }

                // 5. Salir
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 7
                    color: btnLogoutV.containsMouse ? Theme.bgHover : "transparent"

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Text { text: "󰗼"; color: Theme.pink; font.family: Theme.iconFontFamily; font.pixelSize: 11 }
                        Text { text: "Salir"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 10 }
                    }

                    MouseArea {
                        id: btnLogoutV
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.runSysCmd(["hyprctl", "dispatch", "exit"])
                    }
                }
            }
        }
    }
}
