import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: controlCenterWindow

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    WlrLayershell.namespace: "shell-control-center-modal"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: ControlCenterManager.isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    visible: ControlCenterManager.isOpen || modalCard.opacity > 0.01

    // Fondo oscurecido (Scrim)
    Rectangle {
        id: scrim
        anchors.fill: parent
        color: "#000000"
        opacity: ControlCenterManager.isOpen ? 0.65 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.anim.defaultEffects
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.anim.expressiveDefaultEffects
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: ControlCenterManager.isOpen
            onClicked: ControlCenterManager.close()
        }
    }

    // Modal Flotante Central
    Rectangle {
        id: modalCard
        anchors.centerIn: parent

        width: Math.min(840, parent.width - 48)
        height: Math.min(570, parent.height - 48)

        color: Theme.bg
        border.color: Theme.border
        border.width: 1
        radius: Theme.radiusLarge
        clip: true

        opacity: ControlCenterManager.isOpen ? 1.0 : 0.0
        scale: ControlCenterManager.isOpen ? 1.0 : 0.92

        Behavior on scale {
            NumberAnimation {
                duration: ControlCenterManager.isOpen ? 340 : 180
                easing.type: ControlCenterManager.isOpen ? Easing.OutBack : Easing.InQuad
                easing.overshoot: 1.12
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.anim.defaultEffects
            }
        }

        // Atajo Escape para cerrar
        Shortcut {
            sequence: "Escape"
            enabled: ControlCenterManager.isOpen
            onActivated: {
                if (ControlCenterManager.isAuthModalOpen) {
                    ControlCenterManager.cancelSudoAuth();
                } else {
                    ControlCenterManager.close();
                }
            }
        }

        // Consumir clics sobre la tarjeta para que no caigan en el scrim
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        // -------------------------------------------------------------
        // CUERPO PRINCIPAL: BARRA LATERAL + ÁREA DE CONTENIDO
        // -------------------------------------------------------------
        RowLayout {
            anchors.fill: parent
            spacing: 0

            // =========================================================
            // BARRA LATERAL IZQUIERDA (NAVEGACIÓN)
            // =========================================================
            Rectangle {
                Layout.fillHeight: true
                implicitWidth: 200
                color: Theme.bgSurface

                // Línea divisoria derecha
                Rectangle {
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        width: 1
                        color: Theme.border
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.topMargin: 12
                        anchors.bottomMargin: 12
                        spacing: 4

                        readonly property var tabs: [
                            { id: "network", label: "Wi-Fi y Red", icon: "󰖩" },
                            { id: "bluetooth", label: "Bluetooth", icon: "󰂯" },
                            { id: "audio", label: "Audio y Sonido", icon: "󰕾" },
                            { id: "display", label: "Pantalla y Luz", icon: "󰃠" },
                            { id: "power", label: "Batería y Energía", icon: "󰂄" },
                            { id: "bar", label: "Barra de Sistema", icon: "󰒓" },
                            { id: "apps", label: "Aplicaciones", icon: "󰏖" }
                        ]

                        Repeater {
                            model: parent.tabs

                            delegate: Rectangle {
                                id: tabBtn
                                Layout.fillWidth: true
                                Layout.leftMargin: 8
                                Layout.rightMargin: 8
                                implicitHeight: 38
                                radius: Theme.radiusSmall

                                readonly property bool isSelected: ControlCenterManager.activeTab === modelData.id
                                readonly property bool isHovered: tabMouse.containsMouse

                                color: isSelected ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.18) :
                                       (isHovered ? Theme.bgHover : "transparent")
                                border.color: isSelected ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.35) : "transparent"
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: Theme.anim.fastEffects } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 10

                                    // Indicador visual vertical
                                    Rectangle {
                                        implicitWidth: 3
                                        implicitHeight: 18
                                        radius: 2
                                        color: tabBtn.isSelected ? Theme.primary : "transparent"
                                    }

                                    Text {
                                        text: modelData.icon
                                        color: tabBtn.isSelected ? Theme.primary : (tabBtn.isHovered ? Theme.text : Theme.overlay)
                                        font.family: Theme.iconFontFamily
                                        font.pixelSize: 15
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.label
                                        color: tabBtn.isSelected ? Theme.text : (tabBtn.isHovered ? Theme.text : Theme.subtext)
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        font.bold: tabBtn.isSelected
                                        elide: Text.ElideRight
                                    }
                                }

                                MouseArea {
                                    id: tabMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        ControlCenterManager.activeTab = modelData.id;
                                    }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }

                        // Accesos rápidos del sistema (Atajos, Pantallas, Apagado)
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 10
                            Layout.rightMargin: 10
                            spacing: 6

                            // Botón Atajos de Teclado
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 28
                                radius: 6
                                color: btnSideKeyMouse.containsMouse ? Theme.bgHover : Theme.bg
                                border.color: Theme.border
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰌌"
                                    color: btnSideKeyMouse.containsMouse ? Theme.primary : Theme.overlay
                                    font.family: Theme.iconFontFamily
                                    font.pixelSize: 13
                                }

                                MouseArea {
                                    id: btnSideKeyMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        ControlCenterManager.close();
                                        Qt.callLater(() => {
                                            KeybindsManager.open();
                                        });
                                    }
                                }
                            }

                            // Botón Pantallas
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 28
                                radius: 6
                                color: btnSideMonMouse.containsMouse ? Theme.bgHover : Theme.bg
                                border.color: Theme.border
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰍹"
                                    color: btnSideMonMouse.containsMouse ? Theme.cyan : Theme.overlay
                                    font.family: Theme.iconFontFamily
                                    font.pixelSize: 13
                                }

                                MouseArea {
                                    id: btnSideMonMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        ControlCenterManager.close();
                                        Qt.callLater(() => {
                                            MonitorManager.open();
                                        });
                                    }
                                }
                            }

                            // Botón Apagado
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 28
                                radius: 6
                                color: btnSidePowMouse.containsMouse ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.2) : Theme.bg
                                border.color: btnSidePowMouse.containsMouse ? Theme.danger : Theme.border
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰐥"
                                    color: btnSidePowMouse.containsMouse ? Theme.danger : Theme.overlay
                                    font.family: Theme.iconFontFamily
                                    font.pixelSize: 13
                                }

                                MouseArea {
                                    id: btnSidePowMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        ControlCenterManager.close();
                                        Qt.callLater(() => {
                                            PowerManager.open();
                                        });
                                    }
                                }
                            }
                        }

                        // Chip de estado rápido en el pie de la barra lateral
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 10
                            Layout.rightMargin: 10
                            implicitHeight: 34
                            radius: Theme.radiusSmall
                            color: Theme.bg
                            border.color: Theme.border
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 6

                                Text {
                                    text: "󰌢"
                                    color: Theme.primary
                                    font.family: Theme.iconFontFamily
                                    font.pixelSize: 12
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: (ControlCenterManager.sysUser ? ControlCenterManager.sysUser : "usuario") + "@" + (ControlCenterManager.sysHost ? ControlCenterManager.sysHost : "arch")
                                    color: Theme.overlay
                                    font.family: Theme.monoFontFamily
                                    font.pixelSize: 9
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }

                // =========================================================
                // ÁREA DE CONTENIDO DINÁMICO SEGÚN PESTAÑA SELECCIONADA
                // =========================================================
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // 1. PESTAÑA: WI-FI Y RED
                    Item {
                        id: tabNetworkView
                        anchors.fill: parent
                        anchors.margins: 16
                        visible: ControlCenterManager.activeTab === "network"

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 12

                            // Fila Superior: Switch Maestro + Botón Escanear
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                ColumnLayout {
                                    spacing: 2
                                    Text {
                                        text: "Red Inalámbrica (Wi-Fi)"
                                        color: Theme.text
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 13
                                        font.bold: true
                                    }
                                    Text {
                                        text: ControlCenterManager.wifiEnabled ? (ControlCenterManager.isNetworkConnected ? ("Conectado a " + ControlCenterManager.currentSsid) : "Desconectado") : "Wi-Fi desactivado"
                                        color: ControlCenterManager.isNetworkConnected ? Theme.success : Theme.overlay
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                // Botón Escanear Redes
                                Rectangle {
                                    implicitWidth: 84
                                    implicitHeight: 28
                                    radius: Theme.radiusSmall
                                    color: scanNetMouse.containsMouse ? Theme.bgHover : Theme.bgSurface
                                    border.color: Theme.border
                                    border.width: 1
                                    visible: ControlCenterManager.wifiEnabled

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 4
                                        Text {
                                            text: ControlCenterManager.isNetworkScanning ? "󰑐" : "󰑓"
                                            color: Theme.primary
                                            font.family: Theme.iconFontFamily
                                            font.pixelSize: 11
                                            RotationAnimator on rotation {
                                                running: ControlCenterManager.isNetworkScanning
                                                from: 0; to: 360; duration: 1000; loops: Animation.Infinite
                                            }
                                        }
                                        Text {
                                            text: "Escanear"
                                            color: Theme.text
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 10
                                        }
                                    }

                                    MouseArea {
                                        id: scanNetMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: ControlCenterManager.rescanWifi()
                                    }
                                }

                                // Switch Maestro Wi-Fi
                                Rectangle {
                                    implicitWidth: 44
                                    implicitHeight: 24
                                    radius: 12
                                    color: ControlCenterManager.wifiEnabled ? Theme.primary : Theme.bgHover

                                    Behavior on color { ColorAnimation { duration: Theme.anim.fastEffects } }

                                    Rectangle {
                                        x: ControlCenterManager.wifiEnabled ? parent.width - width - 3 : 3
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 18
                                        height: 18
                                        radius: 9
                                        color: "#ffffff"

                                        Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: ControlCenterManager.toggleWifi()
                                    }
                                }
                            }

                            // Tarjeta de Detalles de Red Actual (si está conectado)
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 52
                                radius: Theme.radiusSmall
                                color: Theme.bgSurface
                                border.color: Theme.border
                                border.width: 1
                                visible: ControlCenterManager.wifiEnabled && ControlCenterManager.isNetworkConnected

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 12

                                    Text {
                                        text: "󰤨"
                                        color: Theme.primary
                                        font.family: Theme.iconFontFamily
                                        font.pixelSize: 22
                                    }

                                    ColumnLayout {
                                        spacing: 2
                                        Text {
                                            text: ControlCenterManager.currentSsid
                                            color: Theme.text
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 11
                                            font.bold: true
                                        }
                                        Text {
                                            text: "IP: " + (ControlCenterManager.ipAddress ? ControlCenterManager.ipAddress : "---") + "  •  Puerta: " + (ControlCenterManager.gateway ? ControlCenterManager.gateway : "---")
                                            color: Theme.overlay
                                            font.family: Theme.monoFontFamily
                                            font.pixelSize: 9
                                        }
                                    }

                                    Item { Layout.fillWidth: true }

                                    Rectangle {
                                        implicitWidth: 80
                                        implicitHeight: 26
                                        radius: Theme.radiusSmall
                                        color: disconnNetMouse.containsMouse ? Theme.danger : Theme.bgHover
                                        border.color: Theme.border
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Desconectar"
                                            color: disconnNetMouse.containsMouse ? "#ffffff" : Theme.subtext
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 9
                                            font.bold: true
                                        }

                                        MouseArea {
                                            id: disconnNetMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: ControlCenterManager.disconnectWifi()
                                        }
                                    }
                                }
                            }

                            // Lista de Redes Disponibles
                            Text {
                                text: "REDES DISPONIBLES"
                                color: Theme.overlay
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                                visible: ControlCenterManager.wifiEnabled
                            }

                            ScrollView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                visible: ControlCenterManager.wifiEnabled

                                ListView {
                                    id: wifiListView
                                    model: ControlCenterManager.networksList
                                    spacing: 6

                                    delegate: Rectangle {
                                        width: wifiListView.width
                                        implicitHeight: 38
                                        radius: Theme.radiusSmall
                                        color: netItemMouse.containsMouse ? Theme.bgHover : Theme.bgSurface
                                        border.color: modelData.inUse ? Theme.primary : Theme.border
                                        border.width: 1

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 12
                                            anchors.rightMargin: 12
                                            spacing: 10

                                            Text {
                                                text: modelData.signal >= 75 ? "󰤨" : (modelData.signal >= 50 ? "󰤥" : (modelData.signal >= 25 ? "󰤢" : "󰤟"))
                                                color: modelData.inUse ? Theme.primary : Theme.subtext
                                                font.family: Theme.iconFontFamily
                                                font.pixelSize: 14
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                text: modelData.ssid
                                                color: modelData.inUse ? Theme.primary : Theme.text
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 11
                                                font.bold: modelData.inUse
                                                elide: Text.ElideRight
                                            }

                                            // Candado de seguridad
                                            Text {
                                                text: (modelData.security && modelData.security.length > 0) ? "󰌾" : ""
                                                color: Theme.overlay
                                                font.family: Theme.iconFontFamily
                                                font.pixelSize: 10
                                            }

                                            // Señal %
                                            Text {
                                                text: modelData.signal + "%"
                                                color: Theme.overlay
                                                font.family: Theme.monoFontFamily
                                                font.pixelSize: 9
                                            }

                                            // Botón Conectar
                                            Rectangle {
                                                implicitWidth: 64
                                                implicitHeight: 24
                                                radius: Theme.radiusSmall
                                                color: modelData.inUse ? Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.2) :
                                                       (btnConnMouse.containsMouse ? Theme.primary : Theme.bg)
                                                border.color: modelData.inUse ? Theme.success : Theme.border
                                                border.width: 1

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.inUse ? "Activa" : "Conectar"
                                                    color: modelData.inUse ? Theme.success : (btnConnMouse.containsMouse ? (Theme.isDark ? "#11111b" : "#ffffff") : Theme.subtext)
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: 9
                                                    font.bold: true
                                                }

                                                MouseArea {
                                                    id: btnConnMouse
                                                    anchors.fill: parent
                                                    enabled: !modelData.inUse
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        ControlCenterManager.connectWifi(modelData.rawSsid || modelData.ssid, "", modelData.isHidden);
                                                    }
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: netItemMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            z: -1
                                        }
                                    }
                                }
                            }

                            // Mensaje si Wi-Fi está apagado
                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                visible: !ControlCenterManager.wifiEnabled

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 8
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: "󰖪"
                                        color: Theme.overlay
                                        font.family: Theme.iconFontFamily
                                        font.pixelSize: 42
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: "La conexión Wi-Fi está apagada"
                                        color: Theme.subtext
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12
                                    }
                                }
                            }
                        }
                    }

                    // 2. PESTAÑA: BLUETOOTH
                    Item {
                        id: tabBluetoothView
                        anchors.fill: parent
                        anchors.margins: 16
                        visible: ControlCenterManager.activeTab === "bluetooth"

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 12

                            // Cabecera Bluetooth + Switch Maestro
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                ColumnLayout {
                                    spacing: 2
                                    Text {
                                        text: "Bluetooth"
                                        color: Theme.text
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 13
                                        font.bold: true
                                    }
                                    Text {
                                        text: ControlCenterManager.btPowered ? ("Adaptador: " + (ControlCenterManager.btController ? ControlCenterManager.btController : "Activo")) : "Bluetooth apagado"
                                        color: ControlCenterManager.btPowered ? Theme.success : Theme.overlay
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                // Botón Actualizar / Escanear
                                Rectangle {
                                    implicitWidth: 84
                                    implicitHeight: 28
                                    radius: Theme.radiusSmall
                                    color: scanBtMouse.containsMouse ? Theme.bgHover : Theme.bgSurface
                                    border.color: Theme.border
                                    border.width: 1
                                    visible: ControlCenterManager.btPowered

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 4
                                        Text {
                                            text: "󰑓"
                                            color: Theme.primary
                                            font.family: Theme.iconFontFamily
                                            font.pixelSize: 11
                                        }
                                        Text {
                                            text: "Actualizar"
                                            color: Theme.text
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 10
                                        }
                                    }

                                    MouseArea {
                                        id: scanBtMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: ControlCenterManager.refreshBluetooth()
                                    }
                                }

                                // Switch Maestro Bluetooth
                                Rectangle {
                                    implicitWidth: 44
                                    implicitHeight: 24
                                    radius: 12
                                    color: ControlCenterManager.btPowered ? Theme.primary : Theme.bgHover

                                    Behavior on color { ColorAnimation { duration: Theme.anim.fastEffects } }

                                    Rectangle {
                                        x: ControlCenterManager.btPowered ? parent.width - width - 3 : 3
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 18
                                        height: 18
                                        radius: 9
                                        color: "#ffffff"

                                        Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: ControlCenterManager.toggleBtPower()
                                    }
                                }
                            }

                            // Lista de Dispositivos Bluetooth
                            Text {
                                text: "DISPOSITIVOS VINCULADOS Y DISPONIBLES"
                                color: Theme.overlay
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                                visible: ControlCenterManager.btPowered
                            }

                            ScrollView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                visible: ControlCenterManager.btPowered

                                ListView {
                                    id: btListView
                                    model: ControlCenterManager.btDevices
                                    spacing: 6

                                    delegate: Rectangle {
                                        width: btListView.width
                                        implicitHeight: 40
                                        radius: Theme.radiusSmall
                                        color: btItemMouse.containsMouse ? Theme.bgHover : Theme.bgSurface
                                        border.color: modelData.connected ? Theme.primary : Theme.border
                                        border.width: 1

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 12
                                            anchors.rightMargin: 12
                                            spacing: 10

                                            Text {
                                                text: modelData.connected ? "󰂱" : "󰂯"
                                                color: modelData.connected ? Theme.primary : Theme.subtext
                                                font.family: Theme.iconFontFamily
                                                font.pixelSize: 15
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 1
                                                Text {
                                                    text: modelData.name || modelData.alias || "Dispositivo"
                                                    color: modelData.connected ? Theme.primary : Theme.text
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: 11
                                                    font.bold: modelData.connected
                                                    elide: Text.ElideRight
                                                }
                                                Text {
                                                    text: modelData.mac || ""
                                                    color: Theme.overlay
                                                    font.family: Theme.monoFontFamily
                                                    font.pixelSize: 9
                                                }
                                            }

                                            // Botón Conectar / Desconectar
                                            Rectangle {
                                                implicitWidth: 78
                                                implicitHeight: 24
                                                radius: Theme.radiusSmall
                                                color: modelData.connected ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.15) :
                                                       (btnBtMouse.containsMouse ? Theme.primary : Theme.bg)
                                                border.color: modelData.connected ? Theme.danger : Theme.border
                                                border.width: 1

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.connected ? "Desconectar" : "Conectar"
                                                    color: modelData.connected ? Theme.danger : (btnBtMouse.containsMouse ? (Theme.isDark ? "#11111b" : "#ffffff") : Theme.subtext)
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: 9
                                                    font.bold: true
                                                }

                                                MouseArea {
                                                    id: btnBtMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        if (modelData.connected) {
                                                            ControlCenterManager.disconnectBt(modelData.mac);
                                                        } else {
                                                            ControlCenterManager.connectBt(modelData.mac);
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: btItemMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            z: -1
                                        }
                                    }
                                }
                            }

                            // Mensaje si no hay dispositivos
                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                visible: ControlCenterManager.btPowered && ControlCenterManager.btDevices.length === 0

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 8
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: "󰂲"
                                        color: Theme.overlay
                                        font.family: Theme.iconFontFamily
                                        font.pixelSize: 36
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: "No hay dispositivos Bluetooth vinculados"
                                        color: Theme.subtext
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                    }
                                }
                            }

                            // Mensaje si Bluetooth apagado
                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                visible: !ControlCenterManager.btPowered

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 8
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: "󰂲"
                                        color: Theme.overlay
                                        font.family: Theme.iconFontFamily
                                        font.pixelSize: 42
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: "El adaptador Bluetooth está apagado"
                                        color: Theme.subtext
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12
                                    }
                                }
                            }
                        }
                    }

                    // 3. PESTAÑA: AUDIO Y SONIDO
                    Item {
                        id: tabAudioView
                        anchors.fill: parent
                        anchors.margins: 16
                        visible: ControlCenterManager.activeTab === "audio"

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 16

                            Text {
                                text: "VOLUMEN PRINCIPAL (ALTAVOCES / AURICULARES)"
                                color: Theme.overlay
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                            }

                            // Control Volumen Maestro
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 52
                                radius: Theme.radiusSmall
                                color: Theme.bgSurface
                                border.color: Theme.border
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 12

                                    // Botón Mute Maestro
                                    Rectangle {
                                        implicitWidth: 32
                                        implicitHeight: 32
                                        radius: Theme.radiusSmall
                                        color: ControlCenterManager.masterMuted ? Theme.danger : (muteVolMouse.containsMouse ? Theme.bgHover : Theme.bg)
                                        border.color: Theme.border
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: ControlCenterManager.masterMuted ? "󰝟" : (ControlCenterManager.masterVolume > 50 ? "󰕾" : (ControlCenterManager.masterVolume > 0 ? "󰖀" : "󰕿"))
                                            color: ControlCenterManager.masterMuted ? "#ffffff" : Theme.primary
                                            font.family: Theme.iconFontFamily
                                            font.pixelSize: 14
                                        }

                                        MouseArea {
                                            id: muteVolMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: ControlCenterManager.toggleMasterMute()
                                        }
                                    }

                                    // Slider de Volumen
                                    Slider {
                                        id: volSlider
                                        Layout.fillWidth: true
                                        from: 0
                                        to: 150
                                        stepSize: 1
                                        value: ControlCenterManager.masterVolume
                                        onMoved: ControlCenterManager.setMasterVolume(value)

                                        background: Rectangle {
                                            x: volSlider.leftPadding
                                            y: volSlider.topPadding + volSlider.availableHeight / 2 - height / 2
                                            implicitWidth: 200
                                            implicitHeight: 6
                                            width: volSlider.availableWidth
                                            height: implicitHeight
                                            radius: 3
                                            color: Theme.bgHover

                                            Rectangle {
                                                width: volSlider.visualPosition * parent.width
                                                height: parent.height
                                                color: ControlCenterManager.masterMuted ? Theme.overlay : Theme.primary
                                                radius: 3
                                            }
                                        }

                                        handle: Rectangle {
                                            x: volSlider.leftPadding + volSlider.visualPosition * (volSlider.availableWidth - width)
                                            y: volSlider.topPadding + volSlider.availableHeight / 2 - height / 2
                                            implicitWidth: 16
                                            implicitHeight: 16
                                            radius: 8
                                            color: "#ffffff"
                                            border.color: Theme.primary
                                            border.width: 2
                                        }
                                    }

                                    Text {
                                        Layout.preferredWidth: 42
                                        horizontalAlignment: Text.AlignRight
                                        text: Math.round(volSlider.value) + "%"
                                        color: ControlCenterManager.masterMuted ? Theme.overlay : Theme.text
                                        font.family: Theme.monoFontFamily
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }
                            }

                            Text {
                                text: "MICRÓFONO / ENTRADA DE AUDIO"
                                color: Theme.overlay
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                            }

                            // Control Micrófono
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 52
                                radius: Theme.radiusSmall
                                color: Theme.bgSurface
                                border.color: Theme.border
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 12

                                    // Botón Mute Mic
                                    Rectangle {
                                        implicitWidth: 32
                                        implicitHeight: 32
                                        radius: Theme.radiusSmall
                                        color: ControlCenterManager.micMuted ? Theme.danger : (muteMicMouse.containsMouse ? Theme.bgHover : Theme.bg)
                                        border.color: Theme.border
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: ControlCenterManager.micMuted ? "󰍭" : "󰍬"
                                            color: ControlCenterManager.micMuted ? "#ffffff" : Theme.primary
                                            font.family: Theme.iconFontFamily
                                            font.pixelSize: 14
                                        }

                                        MouseArea {
                                            id: muteMicMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: ControlCenterManager.toggleMicMute()
                                        }
                                    }

                                    // Slider de Micrófono
                                    Slider {
                                        id: micSlider
                                        Layout.fillWidth: true
                                        from: 0
                                        to: 100
                                        stepSize: 1
                                        value: ControlCenterManager.micVolume
                                        onMoved: ControlCenterManager.setMicVolume(value)

                                        background: Rectangle {
                                            x: micSlider.leftPadding
                                            y: micSlider.topPadding + micSlider.availableHeight / 2 - height / 2
                                            implicitWidth: 200
                                            implicitHeight: 6
                                            width: micSlider.availableWidth
                                            height: implicitHeight
                                            radius: 3
                                            color: Theme.bgHover

                                            Rectangle {
                                                width: micSlider.visualPosition * parent.width
                                                height: parent.height
                                                color: ControlCenterManager.micMuted ? Theme.overlay : Theme.cyan
                                                radius: 3
                                            }
                                        }

                                        handle: Rectangle {
                                            x: micSlider.leftPadding + micSlider.visualPosition * (micSlider.availableWidth - width)
                                            y: micSlider.topPadding + micSlider.availableHeight / 2 - height / 2
                                            implicitWidth: 16
                                            implicitHeight: 16
                                            radius: 8
                                            color: "#ffffff"
                                            border.color: Theme.cyan
                                            border.width: 2
                                        }
                                    }

                                    Text {
                                        Layout.preferredWidth: 42
                                        horizontalAlignment: Text.AlignRight
                                        text: Math.round(micSlider.value) + "%"
                                        color: ControlCenterManager.micMuted ? Theme.overlay : Theme.text
                                        font.family: Theme.monoFontFamily
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }
                            }

                            // Dispositivos de salida
                            Text {
                                text: "DISPOSITIVO DE SALIDA PREDETERMINADO"
                                color: Theme.overlay
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                            }

                            ScrollView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true

                                ListView {
                                    id: sinksListView
                                    model: ControlCenterManager.audioSinks
                                    spacing: 6

                                    delegate: Rectangle {
                                        width: sinksListView.width
                                        implicitHeight: 36
                                        radius: Theme.radiusSmall
                                        color: modelData.isDefault ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) :
                                               (sinkMouse.containsMouse ? Theme.bgHover : Theme.bgSurface)
                                        border.color: modelData.isDefault ? Theme.primary : Theme.border
                                        border.width: 1

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 12
                                            anchors.rightMargin: 12
                                            spacing: 10

                                            Text {
                                                text: modelData.isDefault ? "󰓃" : "󰕾"
                                                color: modelData.isDefault ? Theme.primary : Theme.subtext
                                                font.family: Theme.iconFontFamily
                                                font.pixelSize: 13
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                text: modelData.description || modelData.name || "Altavoz"
                                                color: modelData.isDefault ? Theme.text : Theme.subtext
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 11
                                                font.bold: modelData.isDefault
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                text: modelData.isDefault ? "Predeterminado" : "Seleccionar"
                                                color: modelData.isDefault ? Theme.primary : Theme.overlay
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 10
                                                font.bold: modelData.isDefault
                                            }
                                        }

                                        MouseArea {
                                            id: sinkMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (modelData.name) {
                                                    ControlCenterManager.setDefaultSink(modelData.name);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 4. PESTAÑA: PANTALLA Y LUZ NOCTURNA
                    Item {
                        id: tabDisplayView
                        anchors.fill: parent
                        anchors.margins: 16
                        visible: ControlCenterManager.activeTab === "display"

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 16

                            Text {
                                text: "BRILLO DE LA PANTALLA"
                                color: Theme.overlay
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                            }

                            // Slider de Brillo
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 52
                                radius: Theme.radiusSmall
                                color: Theme.bgSurface
                                border.color: Theme.border
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 12

                                    Text {
                                        text: "󰃠"
                                        color: Theme.warning
                                        font.family: Theme.iconFontFamily
                                        font.pixelSize: 16
                                    }

                                    Slider {
                                        id: brightSlider
                                        Layout.fillWidth: true
                                        from: 5
                                        to: 100
                                        stepSize: 1
                                        value: ControlCenterManager.brightness
                                        onMoved: ControlCenterManager.setBrightness(value)

                                        background: Rectangle {
                                            x: brightSlider.leftPadding
                                            y: brightSlider.topPadding + brightSlider.availableHeight / 2 - height / 2
                                            implicitWidth: 200
                                            implicitHeight: 6
                                            width: brightSlider.availableWidth
                                            height: implicitHeight
                                            radius: 3
                                            color: Theme.bgHover

                                            Rectangle {
                                                width: brightSlider.visualPosition * parent.width
                                                height: parent.height
                                                color: Theme.warning
                                                radius: 3
                                            }
                                        }

                                        handle: Rectangle {
                                            x: brightSlider.leftPadding + brightSlider.visualPosition * (brightSlider.availableWidth - width)
                                            y: brightSlider.topPadding + brightSlider.availableHeight / 2 - height / 2
                                            implicitWidth: 16
                                            implicitHeight: 16
                                            radius: 8
                                            color: "#ffffff"
                                            border.color: Theme.warning
                                            border.width: 2
                                        }
                                    }

                                    Text {
                                        Layout.preferredWidth: 42
                                        horizontalAlignment: Text.AlignRight
                                        text: Math.round(brightSlider.value) + "%"
                                        color: Theme.text
                                        font.family: Theme.monoFontFamily
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }
                            }

                            // Sección Luz Nocturna
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                ColumnLayout {
                                    spacing: 2
                                    Text {
                                        text: "Filtro de Luz Azul (Luz Nocturna)"
                                        color: Theme.text
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 13
                                        font.bold: true
                                    }
                                    Text {
                                        text: ControlCenterManager.nightLightEnabled ? ("Temperatura cálida activa: " + ControlCenterManager.nightLightTemp + " K") : "Colores naturales de pantalla"
                                        color: ControlCenterManager.nightLightEnabled ? Theme.warning : Theme.overlay
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                // Switch Maestro Luz Nocturna
                                Rectangle {
                                    implicitWidth: 44
                                    implicitHeight: 24
                                    radius: 12
                                    color: ControlCenterManager.nightLightEnabled ? Theme.warning : Theme.bgHover

                                    Behavior on color { ColorAnimation { duration: Theme.anim.fastEffects } }

                                    Rectangle {
                                        x: ControlCenterManager.nightLightEnabled ? parent.width - width - 3 : 3
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 18
                                        height: 18
                                        radius: 9
                                        color: "#ffffff"

                                        Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: ControlCenterManager.toggleNightLight()
                                    }
                                }
                            }

                            // Slider Temperatura de Color
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 64
                                radius: Theme.radiusSmall
                                color: Theme.bgSurface
                                border.color: Theme.border
                                border.width: 1

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 4

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text {
                                            text: "Calidez de Color"
                                            color: Theme.subtext
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 11
                                        }
                                        Item { Layout.fillWidth: true }
                                        Text {
                                            text: ControlCenterManager.nightLightTemp + " K"
                                            color: Theme.warning
                                            font.family: Theme.monoFontFamily
                                            font.pixelSize: 11
                                            font.bold: true
                                        }
                                    }

                                    Slider {
                                        id: tempSlider
                                        Layout.fillWidth: true
                                        from: 2500
                                        to: 6500
                                        stepSize: 100
                                        value: ControlCenterManager.nightLightTemp
                                        onMoved: ControlCenterManager.setNightLightTemp(value)

                                        background: Rectangle {
                                            x: tempSlider.leftPadding
                                            y: tempSlider.topPadding + tempSlider.availableHeight / 2 - height / 2
                                            implicitWidth: 200
                                            implicitHeight: 6
                                            width: tempSlider.availableWidth
                                            height: implicitHeight
                                            radius: 3
                                            gradient: Gradient {
                                                orientation: Gradient.Horizontal
                                                GradientStop { position: 0.0; color: "#ff8438" }
                                                GradientStop { position: 0.5; color: "#ffc17a" }
                                                GradientStop { position: 1.0; color: "#bcdcff" }
                                            }
                                        }

                                        handle: Rectangle {
                                            x: tempSlider.leftPadding + tempSlider.visualPosition * (tempSlider.availableWidth - width)
                                            y: tempSlider.topPadding + tempSlider.availableHeight / 2 - height / 2
                                            implicitWidth: 16
                                            implicitHeight: 16
                                            radius: 8
                                            color: "#ffffff"
                                            border.color: Theme.warning
                                            border.width: 2
                                        }
                                    }
                                }
                            }

                            // Presets rápidos de temperatura
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                readonly property var presets: [
                                    { label: "Lectura (3000K)", temp: 3000 },
                                    { label: "Noche (4000K)", temp: 4000 },
                                    { label: "Atardecer (5000K)", temp: 5000 },
                                    { label: "Neutral (6500K)", temp: 6500 }
                                ]

                                Repeater {
                                    model: parent.presets
                                    delegate: Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: 28
                                        radius: Theme.radiusSmall
                                        color: (ControlCenterManager.nightLightTemp === modelData.temp && ControlCenterManager.nightLightEnabled) ?
                                               Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.2) :
                                               (preMouse.containsMouse ? Theme.bgHover : Theme.bgSurface)
                                        border.color: (ControlCenterManager.nightLightTemp === modelData.temp && ControlCenterManager.nightLightEnabled) ? Theme.warning : Theme.border
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.label
                                            color: (ControlCenterManager.nightLightTemp === modelData.temp && ControlCenterManager.nightLightEnabled) ? Theme.warning : Theme.subtext
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 9
                                            font.bold: true
                                        }

                                        MouseArea {
                                            id: preMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                ControlCenterManager.setNightLightTemp(modelData.temp);
                                                if (!ControlCenterManager.nightLightEnabled && modelData.temp < 6500) {
                                                    ControlCenterManager.toggleNightLight();
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }
                    }

                    // 5. PESTAÑA: BATERÍA Y ENERGÍA
                    Item {
                        id: tabPowerView
                        anchors.fill: parent
                        anchors.margins: 16
                        visible: ControlCenterManager.activeTab === "power"

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 14

                            // Tarjeta de Estado de Batería
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 80
                                radius: Theme.radiusSmall
                                color: Theme.bgSurface
                                border.color: Theme.border
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    spacing: 16

                                    Text {
                                        text: ControlCenterManager.batteryPercentage >= 90 ? "󰂂" : (ControlCenterManager.batteryPercentage >= 60 ? "󰁿" : (ControlCenterManager.batteryPercentage >= 30 ? "󰁼" : "󰁺"))
                                        color: ControlCenterManager.batteryPercentage > 20 ? Theme.primary : Theme.danger
                                        font.family: Theme.iconFontFamily
                                        font.pixelSize: 36
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 4

                                        RowLayout {
                                            Text {
                                                text: "Batería del Sistema: " + ControlCenterManager.batteryPercentage + "%"
                                                color: Theme.text
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 13
                                                font.bold: true
                                            }
                                            Item { Layout.fillWidth: true }
                                            Text {
                                                text: ControlCenterManager.batteryStatus
                                                color: Theme.primary
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 11
                                                font.bold: true
                                            }
                                        }

                                        // Barra de progreso de batería
                                        Rectangle {
                                            Layout.fillWidth: true
                                            implicitHeight: 8
                                            radius: 4
                                            color: Theme.bgHover

                                            Rectangle {
                                                width: Math.min(parent.width, parent.width * (ControlCenterManager.batteryPercentage / 100.0))
                                                height: parent.height
                                                radius: 4
                                                color: ControlCenterManager.batteryPercentage > 20 ? Theme.primary : Theme.danger
                                            }
                                        }

                                        RowLayout {
                                            Text {
                                                text: "Salud: " + ControlCenterManager.batteryHealth + "  •  Ciclos: " + ControlCenterManager.batteryCycleCount
                                                color: Theme.overlay
                                                font.family: Theme.monoFontFamily
                                                font.pixelSize: 9
                                            }
                                            Item { Layout.fillWidth: true }
                                            Text {
                                                text: "Consumo: " + ControlCenterManager.batteryPowerRate
                                                color: Theme.overlay
                                                font.family: Theme.monoFontFamily
                                                font.pixelSize: 9
                                            }
                                        }
                                    }
                                }
                            }

                            // Modo Cafeína
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 48
                                radius: Theme.radiusSmall
                                color: Theme.bgSurface
                                border.color: CaffeineManager.isActive ? Theme.warning : Theme.border
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 12

                                    Text {
                                        text: "󰅶"
                                        color: CaffeineManager.isActive ? Theme.warning : Theme.overlay
                                        font.family: Theme.iconFontFamily
                                        font.pixelSize: 18
                                    }

                                    ColumnLayout {
                                        spacing: 1
                                        Text {
                                            text: "Modo Cafeína (Inhibir Suspensión)"
                                            color: Theme.text
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 11
                                            font.bold: true
                                        }
                                        Text {
                                            text: CaffeineManager.isActive ? "Activo: El equipo permanecerá encendido sin apagarse" : "Inactivo: Suspensión normal por inactividad"
                                            color: CaffeineManager.isActive ? Theme.warning : Theme.overlay
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 9
                                        }
                                    }

                                    Item { Layout.fillWidth: true }

                                    // Switch Cafeína
                                    Rectangle {
                                        implicitWidth: 44
                                        implicitHeight: 24
                                        radius: 12
                                        color: CaffeineManager.isActive ? Theme.warning : Theme.bgHover

                                        Behavior on color { ColorAnimation { duration: Theme.anim.fastEffects } }

                                        Rectangle {
                                            x: CaffeineManager.isActive ? parent.width - width - 3 : 3
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 18
                                            height: 18
                                            radius: 9
                                            color: "#ffffff"

                                            Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: CaffeineManager.toggle()
                                        }
                                    }
                                }
                            }

                            // Perfiles de Energía
                            Text {
                                text: "PERFIL DE RENDIMIENTO"
                                color: Theme.overlay
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                readonly property var profiles: [
                                    { id: "power-saver", label: "Ahorro de Batería", icon: "󰌪" },
                                    { id: "balanced", label: "Equilibrado", icon: "󰾆" },
                                    { id: "performance", label: "Alto Rendimiento", icon: "󰓅" }
                                ]

                                Repeater {
                                    model: parent.profiles
                                    delegate: Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: 44
                                        radius: Theme.radiusSmall

                                        readonly property bool isSelected: ControlCenterManager.currentPowerProfile === modelData.id
                                        color: isSelected ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.18) :
                                               (profMouse.containsMouse ? Theme.bgHover : Theme.bgSurface)
                                        border.color: isSelected ? Theme.primary : Theme.border
                                        border.width: 1

                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: 6
                                            Text {
                                                text: modelData.icon
                                                color: parent.parent.isSelected ? Theme.primary : Theme.subtext
                                                font.family: Theme.iconFontFamily
                                                font.pixelSize: 14
                                            }
                                            Text {
                                                text: modelData.label
                                                color: parent.parent.isSelected ? Theme.text : Theme.subtext
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 10
                                                font.bold: parent.parent.isSelected
                                            }
                                        }

                                        MouseArea {
                                            id: profMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: ControlCenterManager.setPowerProfile(modelData.id)
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }
                    }

                    // 6. PESTAÑA: CONFIGURACIÓN DE LA BARRA DE SISTEMA
                    Item {
                        id: tabBarView
                        anchors.fill: parent
                        anchors.margins: 16
                        visible: ControlCenterManager.activeTab === "bar"

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 12

                            ColumnLayout {
                                spacing: 2
                                Text {
                                    text: "CONFIGURACIÓN Y VISIBILIDAD DE LA BARRA"
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                                Text {
                                    text: "Activa o desactiva qué indicadores se muestran en la barra y define su posición en pantalla."
                                    color: Theme.overlay
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                }
                            }

                            // Subsección: Posición de la Barra
                            Text {
                                text: "POSICIÓN DE LA BARRA EN PANTALLA"
                                color: Theme.overlay
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                readonly property var positions: [
                                    { id: "top", label: "Arriba", icon: "󰁝" },
                                    { id: "bottom", label: "Abajo", icon: "󰁅" },
                                    { id: "left", label: "Izquierda", icon: "󰁍" },
                                    { id: "right", label: "Derecha", icon: "󰁔" }
                                ]

                                Repeater {
                                    model: parent.positions
                                    delegate: Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: 34
                                        radius: Theme.radiusSmall

                                        readonly property bool isSelected: PopoutManager.barPosition === modelData.id
                                        color: isSelected ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2) :
                                               (posMouse.containsMouse ? Theme.bgHover : Theme.bgSurface)
                                        border.color: isSelected ? Theme.primary : Theme.border
                                        border.width: 1

                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: 6
                                            Text {
                                                text: modelData.icon
                                                color: parent.parent.isSelected ? Theme.primary : Theme.subtext
                                                font.family: Theme.iconFontFamily
                                                font.pixelSize: 12
                                            }
                                            Text {
                                                text: modelData.label
                                                color: parent.parent.isSelected ? Theme.text : Theme.subtext
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 10
                                                font.bold: parent.parent.isSelected
                                            }
                                        }

                                        MouseArea {
                                            id: posMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: PopoutManager.setBarPosition(modelData.id)
                                        }
                                    }
                                }
                            }

                            // Subsección: Indicadores Activos
                            Text {
                                text: "INDICADORES EN LA BARRA (MOSTRAR / OCULTAR)"
                                color: Theme.overlay
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                            }

                            ListView {
                                id: indListView
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                spacing: 6
                                boundsBehavior: Flickable.StopAtBounds

                                model: [
                                    { id: "workspaces", name: "Espacios de Trabajo", desc: "Selector interactivo de escritorios virtuales", icon: "󰍹" },
                                    { id: "cava", name: "Visualizador de Audio (Cava)", desc: "Barras reactivas al sonido en tiempo real", icon: "󰎆" },
                                    { id: "clock", name: "Reloj, Fecha y Calendario", desc: "Indicador horario y menú desplegable", icon: "󰥔" },
                                    { id: "tray", name: "Bandeja del Sistema (Tray)", desc: "Iconos de apps en segundo plano", icon: "󰇮" },
                                    { id: "audio", name: "Control de Audio", desc: "Nivel de volumen y selección de salida", icon: "󰕾" },
                                    { id: "bluetooth", name: "Conexión Bluetooth", desc: "Estado y emparejamiento de dispositivos", icon: "󰂯" },
                                    { id: "wifi", name: "Red Wi-Fi y Ethernet", desc: "Señal, redes e indicador de conexión", icon: "󰖩" },
                                    { id: "battery", name: "Nivel de Batería", desc: "Carga y perfil de energía", icon: "󰂄" }
                                ]

                                delegate: Rectangle {
                                    width: indListView.width
                                    height: 40
                                    radius: Theme.radiusSmall
                                    color: indMouse.containsMouse ? Theme.bgHover : Theme.bgSurface
                                    border.color: Theme.border
                                    border.width: 1

                                    readonly property bool isVisibleOnBar: PopoutManager.isModuleVisible(modelData.id)

                                    Text {
                                        id: indIcon
                                        anchors.left: parent.left
                                        anchors.leftMargin: 14
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 20
                                        horizontalAlignment: Text.AlignHCenter
                                        text: modelData.icon
                                        color: isVisibleOnBar ? Theme.primary : Theme.overlay
                                        font.family: Theme.iconFontFamily
                                        font.pixelSize: 16
                                    }

                                    // Switch perfectamente anclado a la derecha de la tarjeta
                                    Rectangle {
                                        id: indSwitch
                                        anchors.right: parent.right
                                        anchors.rightMargin: 14
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 40
                                        height: 22
                                        radius: 11
                                        color: isVisibleOnBar ? Theme.primary : Theme.bgHover

                                        Behavior on color { ColorAnimation { duration: Theme.anim.fastEffects } }

                                        Rectangle {
                                            x: isVisibleOnBar ? parent.width - width - 2 : 2
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 18
                                            height: 18
                                            radius: 9
                                            color: "#ffffff"

                                            Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: PopoutManager.toggleModuleVisibility(modelData.id)
                                        }
                                    }

                                    Column {
                                        anchors.left: indIcon.right
                                        anchors.leftMargin: 12
                                        anchors.right: indSwitch.left
                                        anchors.rightMargin: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 2

                                        Text {
                                            width: parent.width
                                            text: modelData.name
                                            color: isVisibleOnBar ? Theme.text : Theme.subtext
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 11
                                            font.bold: isVisibleOnBar
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            width: parent.width
                                            text: modelData.desc
                                            color: Theme.overlay
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 9
                                            elide: Text.ElideRight
                                        }
                                    }

                                    MouseArea {
                                        id: indMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        z: -1
                                        onClicked: PopoutManager.toggleModuleVisibility(modelData.id)
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }
                    }

                    // 7. PESTAÑA: GESTIÓN DE APLICACIONES Y PAQUETES (PACMAN Y AUR)
                    Item {
                        id: tabAppsView
                        anchors.fill: parent
                        anchors.margins: 14
                        visible: ControlCenterManager.activeTab === "apps"

                        property var pendingUninstallPkg: null

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 10

                            // ---------------------------------------------------------
                            // ENCABEZADO Y RESUMEN DE PAQUETES (CON FILTROS INTERACTIVOS)
                            // ---------------------------------------------------------
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                ColumnLayout {
                                    spacing: 4
                                    Text {
                                        text: "APLICACIONES Y PAQUETES INSTALADOS"
                                        color: Theme.overlay
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.bold: true
                                    }

                                    // Chips interactivos de filtro y conteo rápido
                                    RowLayout {
                                        spacing: 6

                                        // Total / Todas
                                        Rectangle {
                                            implicitHeight: 22
                                            implicitWidth: totalTxt.implicitWidth + 14
                                            radius: 11
                                            color: ControlCenterManager.packagesFilter === "all" ? Theme.primary : Theme.bgSurface
                                            border.color: ControlCenterManager.packagesFilter === "all" ? Theme.primary : Theme.border
                                            border.width: 1
                                            Text {
                                                id: totalTxt
                                                anchors.centerIn: parent
                                                text: "Todas: " + ControlCenterManager.totalPackagesCount
                                                color: ControlCenterManager.packagesFilter === "all" ? Theme.bg : Theme.text
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 9
                                                font.bold: ControlCenterManager.packagesFilter === "all"
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: ControlCenterManager.packagesFilter = "all"
                                            }
                                        }

                                        // Pacman
                                        Rectangle {
                                            implicitHeight: 22
                                            implicitWidth: pacCountTxt.implicitWidth + 14
                                            radius: 11
                                            color: ControlCenterManager.packagesFilter === "pacman" ? Theme.cyan : Qt.rgba(Theme.cyan.r, Theme.cyan.g, Theme.cyan.b, 0.14)
                                            border.color: Theme.cyan
                                            border.width: 1
                                            Text {
                                                id: pacCountTxt
                                                anchors.centerIn: parent
                                                text: "󰮯 Pacman: " + ControlCenterManager.pacmanPackagesCount
                                                color: ControlCenterManager.packagesFilter === "pacman" ? Theme.bg : Theme.cyan
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 9
                                                font.bold: true
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: ControlCenterManager.packagesFilter = "pacman"
                                            }
                                        }

                                        // AUR
                                        Rectangle {
                                            implicitHeight: 22
                                            implicitWidth: aurCountTxt.implicitWidth + 14
                                            radius: 11
                                            color: ControlCenterManager.packagesFilter === "aur" ? Theme.warning : Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.14)
                                            border.color: Theme.warning
                                            border.width: 1
                                            Text {
                                                id: aurCountTxt
                                                anchors.centerIn: parent
                                                text: "󰣇 AUR (yay): " + ControlCenterManager.aurPackagesCount
                                                color: ControlCenterManager.packagesFilter === "aur" ? Theme.bg : Theme.warning
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 9
                                                font.bold: true
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: ControlCenterManager.packagesFilter = "aur"
                                            }
                                        }

                                        // Actualizaciones
                                        Rectangle {
                                            visible: ControlCenterManager.updatesPackagesCount > 0
                                            implicitHeight: 22
                                            implicitWidth: upCountTxt.implicitWidth + 14
                                            radius: 11
                                            color: ControlCenterManager.packagesFilter === "updates" ? Theme.success : Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.18)
                                            border.color: Theme.success
                                            border.width: 1
                                            Text {
                                                id: upCountTxt
                                                anchors.centerIn: parent
                                                text: "󰚰 " + ControlCenterManager.updatesPackagesCount + " actualizables"
                                                color: ControlCenterManager.packagesFilter === "updates" ? Theme.bg : Theme.success
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 9
                                                font.bold: true
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: ControlCenterManager.packagesFilter = "updates"
                                            }
                                        }
                                    }
                                }

                                Item { Layout.fillWidth: true }
                            }

                            // ---------------------------------------------------------
                            // BARRA DE BÚSQUEDA Y ACCIONES DE ACTUALIZACIÓN
                            // ---------------------------------------------------------
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                // Caja de Búsqueda
                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: 32
                                    radius: Theme.radiusSmall
                                    color: Theme.bgSurface
                                    border.color: searchInput.activeFocus ? Theme.primary : Theme.border
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 6

                                        Text {
                                            text: "󰍉"
                                            color: Theme.overlay
                                            font.family: Theme.iconFontFamily
                                            font.pixelSize: 12
                                        }

                                        TextInput {
                                            id: searchInput
                                            Layout.fillWidth: true
                                            color: Theme.text
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 10
                                            clip: true
                                            text: ControlCenterManager.packagesSearchQuery
                                            onTextChanged: ControlCenterManager.packagesSearchQuery = text

                                            Text {
                                                text: "Buscar aplicación o paquete..."
                                                color: Theme.overlay
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 10
                                                visible: !searchInput.text && !searchInput.activeFocus
                                            }
                                        }

                                        // Limpiar búsqueda
                                        Text {
                                            visible: searchInput.text.length > 0
                                            text: "󰅖"
                                            color: clearSearchMouse.containsMouse ? Theme.danger : Theme.overlay
                                            font.family: Theme.iconFontFamily
                                            font.pixelSize: 11

                                            MouseArea {
                                                id: clearSearchMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    searchInput.text = "";
                                                    ControlCenterManager.packagesSearchQuery = "";
                                                }
                                            }
                                        }
                                    }
                                }

                                // Botón Buscar Actualizaciones
                                Rectangle {
                                    implicitHeight: 32
                                    implicitWidth: btnCheckUpLayout.implicitWidth + 16
                                    radius: Theme.radiusSmall
                                    color: btnCheckUpMouse.containsMouse ? Theme.bgHover : Theme.bgSurface
                                    border.color: Theme.border
                                    border.width: 1

                                    RowLayout {
                                        id: btnCheckUpLayout
                                        anchors.centerIn: parent
                                        spacing: 6

                                        Text {
                                            text: "󰑐"
                                            color: ControlCenterManager.isPackagesLoading ? Theme.primary : Theme.subtext
                                            font.family: Theme.iconFontFamily
                                            font.pixelSize: 12

                                            RotationAnimation on rotation {
                                                from: 0
                                                to: 360
                                                duration: 900
                                                loops: Animation.Infinite
                                                running: ControlCenterManager.isPackagesLoading
                                            }
                                        }

                                        Text {
                                            text: "Buscar actualizaciones"
                                            color: btnCheckUpMouse.containsMouse ? Theme.text : Theme.subtext
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 10
                                        }
                                    }

                                    MouseArea {
                                        id: btnCheckUpMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: ControlCenterManager.refreshPackages(true)
                                    }
                                }

                                // Botón Actualizar Todas
                                Rectangle {
                                    implicitHeight: 32
                                    implicitWidth: btnUpAllLayout.implicitWidth + 16
                                    radius: Theme.radiusSmall
                                    color: btnUpAllMouse.containsMouse ? Qt.lighter(Theme.primary, 1.1) : Theme.primary

                                    RowLayout {
                                        id: btnUpAllLayout
                                        anchors.centerIn: parent
                                        spacing: 6
                                        Text { text: "󰚰"; color: Theme.bg; font.family: Theme.iconFontFamily; font.pixelSize: 12; font.bold: true }
                                        Text { text: "Actualizar todas"; color: Theme.bg; font.family: Theme.fontFamily; font.pixelSize: 10; font.bold: true }
                                    }

                                    MouseArea {
                                        id: btnUpAllMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: ControlCenterManager.updateAllPackages()
                                    }
                                }
                            }

                            // ---------------------------------------------------------
                            // LISTA DE APLICACIONES Y PAQUETES
                            // ---------------------------------------------------------
                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                // Indicador de Carga
                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 8
                                    visible: ControlCenterManager.isPackagesLoading && (!ControlCenterManager.installedPackages || ControlCenterManager.installedPackages.length === 0)

                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: "󰑐"
                                        color: Theme.primary
                                        font.family: Theme.iconFontFamily
                                        font.pixelSize: 26

                                        RotationAnimation on rotation {
                                            from: 0
                                            to: 360
                                            duration: 1100
                                            loops: Animation.Infinite
                                            running: ControlCenterManager.isPackagesLoading
                                        }
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: "Cargando paquetes y consultando repositorios oficiales y AUR..."
                                        color: Theme.overlay
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                    }
                                }

                                // Estado Vacío (Sin resultados)
                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    visible: !ControlCenterManager.isPackagesLoading && (!ControlCenterManager.filteredPackages || ControlCenterManager.filteredPackages.length === 0)

                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: "󰏖"
                                        color: Theme.overlay
                                        font.family: Theme.iconFontFamily
                                        font.pixelSize: 32
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: "No se encontraron paquetes con los filtros aplicados"
                                        color: Theme.subtext
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: "Intenta con otro término de búsqueda o cambia la categoría (Pacman / AUR)"
                                        color: Theme.overlay
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 9
                                    }
                                }

                                // Lista
                                ListView {
                                    id: appsList
                                    anchors.fill: parent
                                    anchors.rightMargin: 4
                                    clip: true
                                    spacing: 6
                                    model: ControlCenterManager.filteredPackages

                                    ScrollBar.vertical: ScrollBar {
                                        policy: ScrollBar.AsNeeded
                                    }

                                    delegate: Rectangle {
                                        id: pkgCard
                                        width: appsList.width - 12
                                        implicitHeight: 62
                                        radius: Theme.radiusSmall
                                        color: pkgMouse.containsMouse ? Theme.bgHover : Theme.bgSurface
                                        border.color: modelData.hasUpdate ? Theme.warning : Theme.border
                                        border.width: modelData.hasUpdate ? 1.5 : 1

                                        MouseArea {
                                            id: pkgMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                        }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 10
                                            spacing: 10

                                            // Ícono del paquete / aplicación
                                            Item {
                                                implicitWidth: 36
                                                implicitHeight: 36
                                                Layout.alignment: Qt.AlignVCenter

                                                Image {
                                                    anchors.fill: parent
                                                    visible: !!modelData.icon && (modelData.icon.indexOf("/") === 0 || modelData.icon.indexOf("file:") === 0)
                                                    source: (modelData.icon && modelData.icon.indexOf("/") === 0) ? ("file://" + modelData.icon) : (modelData.icon || "")
                                                    sourceSize.width: 36
                                                    sourceSize.height: 36
                                                    fillMode: Image.PreserveAspectFit
                                                    smooth: true
                                                }

                                                Rectangle {
                                                    anchors.fill: parent
                                                    visible: !modelData.icon || (modelData.icon.indexOf("/") !== 0 && modelData.icon.indexOf("file:") !== 0)
                                                    radius: 6
                                                    color: Theme.bg
                                                    border.color: Theme.border
                                                    border.width: 1

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: modelData.source === "aur" ? "󰣇" : (modelData.isDesktopApp ? "󰀻" : "󰏖")
                                                        color: modelData.source === "aur" ? Theme.warning : Theme.cyan
                                                        font.family: Theme.iconFontFamily
                                                        font.pixelSize: 18
                                                    }
                                                }
                                            }

                                            // Datos del paquete
                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 2
                                                Layout.alignment: Qt.AlignVCenter

                                                // Fila 1: Nombre + Badges
                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 6

                                                    Text {
                                                        text: modelData.displayName || modelData.name
                                                        color: Theme.text
                                                        font.family: Theme.fontFamily
                                                        font.pixelSize: 11
                                                        font.bold: true
                                                        elide: Text.ElideRight
                                                    }

                                                    Text {
                                                        visible: (modelData.displayName && modelData.displayName !== modelData.name)
                                                        text: "(" + modelData.name + ")"
                                                        color: Theme.overlay
                                                        font.family: Theme.monoFontFamily
                                                        font.pixelSize: 9
                                                        elide: Text.ElideRight
                                                    }

                                                    // Badge de Actualización Disponible
                                                    Rectangle {
                                                        visible: !!modelData.hasUpdate
                                                        implicitHeight: 16
                                                        implicitWidth: upBadgeText.implicitWidth + 8
                                                        radius: 4
                                                        color: Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.18)
                                                        border.color: Theme.success
                                                        border.width: 1

                                                        Text {
                                                            id: upBadgeText
                                                            anchors.centerIn: parent
                                                            text: "󰚰 Disp: " + modelData.newVersion
                                                            color: Theme.success
                                                            font.family: Theme.fontFamily
                                                            font.pixelSize: 8
                                                            font.bold: true
                                                        }
                                                    }

                                                    Item { Layout.fillWidth: true }
                                                }

                                                // Fila 2: Descripción
                                                Text {
                                                    Layout.fillWidth: true
                                                    text: modelData.description || "Paquete instalado en Arch Linux"
                                                    color: Theme.subtext
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: 9
                                                    elide: Text.ElideRight
                                                    maximumLineCount: 1
                                                }

                                                // Fila 3: Versión y Tamaño
                                                RowLayout {
                                                    spacing: 6
                                                    Text {
                                                        text: "Versión: " + modelData.version
                                                        color: Theme.overlay
                                                        font.family: Theme.monoFontFamily
                                                        font.pixelSize: 8
                                                    }
                                                    Text {
                                                        visible: !!modelData.size
                                                        text: "•  Tamaño: " + modelData.size
                                                        color: Theme.overlay
                                                        font.family: Theme.monoFontFamily
                                                        font.pixelSize: 8
                                                    }
                                                }
                                            }

                                            // Botones de Acción (Solo Iconos)
                                            RowLayout {
                                                spacing: 6
                                                Layout.alignment: Qt.AlignVCenter

                                                // Botón Actualizar (Solo icono)
                                                Rectangle {
                                                    implicitHeight: 30
                                                    implicitWidth: 30
                                                    radius: 6
                                                    color: modelData.hasUpdate ? Theme.primary : (btnActMouse.containsMouse ? Theme.bgHover : Theme.bgSurface)
                                                    border.color: modelData.hasUpdate ? Theme.primary : Theme.border
                                                    border.width: 1

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "󰚰"
                                                        color: modelData.hasUpdate ? Theme.bg : (btnActMouse.containsMouse ? Theme.primary : Theme.text)
                                                        font.family: Theme.iconFontFamily
                                                        font.pixelSize: 13
                                                    }

                                                    MouseArea {
                                                        id: btnActMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: ControlCenterManager.updatePackage(modelData.name)
                                                    }
                                                }

                                                // Botón Desinstalar (Solo icono)
                                                Rectangle {
                                                    implicitHeight: 30
                                                    implicitWidth: 30
                                                    radius: 6
                                                    color: btnDesMouse.containsMouse ? Theme.danger : Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.12)
                                                    border.color: Theme.danger
                                                    border.width: 1

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "󰆴"
                                                        color: btnDesMouse.containsMouse ? Theme.text : Theme.danger
                                                        font.family: Theme.iconFontFamily
                                                        font.pixelSize: 13
                                                    }

                                                    MouseArea {
                                                        id: btnDesMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: tabAppsView.pendingUninstallPkg = modelData
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // -------------------------------------------------------------
                        // DIÁLOGO MODAL DE CONFIRMACIÓN PARA DESINSTALACIÓN
                        // -------------------------------------------------------------
                        Rectangle {
                            anchors.fill: parent
                            visible: tabAppsView.pendingUninstallPkg !== null
                            color: Qt.rgba(0, 0, 0, 0.65)
                            z: 999

                            MouseArea {
                                anchors.fill: parent
                                onClicked: tabAppsView.pendingUninstallPkg = null
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                width: Math.min(420, parent.width - 32)
                                implicitHeight: confirmLayout.implicitHeight + 36
                                radius: Theme.radiusMedium
                                color: Theme.bg
                                border.color: Theme.danger
                                border.width: 1.5

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {} // Consumir clic
                                }

                                ColumnLayout {
                                    id: confirmLayout
                                    anchors.fill: parent
                                    anchors.margins: 18
                                    spacing: 12

                                    RowLayout {
                                        spacing: 10
                                        Text {
                                            text: "󰆴"
                                            color: Theme.danger
                                            font.family: Theme.iconFontFamily
                                            font.pixelSize: 22
                                        }
                                        Text {
                                            text: "¿Desinstalar paquete?"
                                            color: Theme.text
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 13
                                            font.bold: true
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                        text: "¿Estás seguro de que deseas desinstalar \"" + (tabAppsView.pendingUninstallPkg ? tabAppsView.pendingUninstallPkg.displayName : "") + "\"?"
                                        color: Theme.text
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: detailsLayout.implicitHeight + 14
                                        radius: Theme.radiusSmall
                                        color: Theme.bgSurface
                                        border.color: Theme.border
                                        border.width: 1

                                        ColumnLayout {
                                            id: detailsLayout
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            spacing: 4

                                            Text {
                                                text: "• Paquete: " + (tabAppsView.pendingUninstallPkg ? tabAppsView.pendingUninstallPkg.name : "")
                                                color: Theme.subtext
                                                font.family: Theme.monoFontFamily
                                                font.pixelSize: 10
                                            }
                                            Text {
                                                text: "• Origen: " + (tabAppsView.pendingUninstallPkg ? tabAppsView.pendingUninstallPkg.sourceLabel : "") + "  |  Tamaño: " + (tabAppsView.pendingUninstallPkg ? tabAppsView.pendingUninstallPkg.size : "")
                                                color: Theme.overlay
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 9
                                            }
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                        text: "Se abrirá una terminal segura para verificar dependencias huérfanas y pedir confirmación antes de eliminar los archivos del sistema."
                                        color: Theme.overlay
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 9
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 10

                                        Item { Layout.fillWidth: true }

                                        // Cancelar
                                        Rectangle {
                                            implicitHeight: 32
                                            implicitWidth: 90
                                            radius: Theme.radiusSmall
                                            color: cancelMouse.containsMouse ? Theme.bgHover : Theme.bgSurface
                                            border.color: Theme.border
                                            border.width: 1

                                            Text {
                                                anchors.centerIn: parent
                                                text: "Cancelar"
                                                color: Theme.text
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 10
                                            }
                                            MouseArea {
                                                id: cancelMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: tabAppsView.pendingUninstallPkg = null
                                            }
                                        }

                                        // Confirmar Desinstalación
                                        Rectangle {
                                            implicitHeight: 32
                                            implicitWidth: 150
                                            radius: Theme.radiusSmall
                                            color: confDelMouse.containsMouse ? Qt.darker(Theme.danger, 1.1) : Theme.danger

                                            RowLayout {
                                                anchors.centerIn: parent
                                                spacing: 6
                                                Text { text: "󰆴"; color: Theme.text; font.family: Theme.iconFontFamily; font.pixelSize: 12 }
                                                Text { text: "Confirmar y Eliminar"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 10; font.bold: true }
                                            }
                                            MouseArea {
                                                id: confDelMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    let pkg = tabAppsView.pendingUninstallPkg;
                                                    tabAppsView.pendingUninstallPkg = null;
                                                    if (pkg && pkg.name) {
                                                        ControlCenterManager.removePackage(pkg.name);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // =========================================================================
        // MODAL DE AUTENTICACIÓN SUDO NATIVO (QUICKSHELL)
        // =========================================================================
        Rectangle {
            id: sudoAuthOverlay
            anchors.fill: parent
            z: 1000
            visible: ControlCenterManager.isAuthModalOpen
            color: Qt.rgba(0, 0, 0, 0.75)
            radius: Theme.radiusLarge

            // Consumir clics sobre el scrim del modal
            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            Connections {
                target: ControlCenterManager
                function onIsAuthModalOpenChanged() {
                    if (ControlCenterManager.isAuthModalOpen) {
                        sudoPwdInput.text = "";
                        Qt.callLater(function() {
                            sudoPwdInput.forceActiveFocus();
                        });
                    }
                }
            }

            Rectangle {
                id: sudoAuthCard
                anchors.centerIn: parent
                width: Math.min(430, parent.width - 48)
                implicitHeight: authCol.implicitHeight + 40
                color: Theme.bgSurface
                border.color: ControlCenterManager.authErrorMessage !== "" ? Theme.danger : Theme.border
                border.width: 1
                radius: Theme.radiusMedium

                ColumnLayout {
                    id: authCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 20
                    spacing: 16

                    // Encabezado
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 14

                        Rectangle {
                            implicitWidth: 42
                            implicitHeight: 42
                            radius: 21
                            color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
                            border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3)
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "󰌾"
                                color: Theme.primary
                                font.family: Theme.iconFontFamily
                                font.pixelSize: 20
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: "Autenticación Requerida"
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                font.bold: true
                            }

                            Text {
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                                text: "Se requieren privilegios para " + (ControlCenterManager.authActionDescription || "continuar") + "."
                                color: Theme.overlay
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                            }
                        }
                    }

                    // Campo de entrada de contraseña
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: "Contraseña sudo:"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                        }

                        Rectangle {
                            id: inputContainer
                            Layout.fillWidth: true
                            implicitHeight: 38
                            radius: Theme.radiusSmall
                            color: Theme.bg
                            border.color: ControlCenterManager.authErrorMessage !== "" ? Theme.danger : (sudoPwdInput.activeFocus ? Theme.primary : Theme.border)
                            border.width: sudoPwdInput.activeFocus ? 2 : 1

                            property bool showPassword: false

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 8
                                spacing: 8

                                Text {
                                    text: "󰌋"
                                    color: sudoPwdInput.activeFocus ? Theme.primary : Theme.overlay
                                    font.family: Theme.iconFontFamily
                                    font.pixelSize: 14
                                }

                                TextInput {
                                    id: sudoPwdInput
                                    Layout.fillWidth: true
                                    echoMode: inputContainer.showPassword ? TextInput.Normal : TextInput.Password
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    clip: true
                                    enabled: !ControlCenterManager.isAuthChecking

                                    Text {
                                        anchors.fill: parent
                                        text: "Ingresa tu contraseña..."
                                        color: Theme.overlay
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12
                                        visible: !sudoPwdInput.text && !sudoPwdInput.activeFocus
                                    }

                                    Keys.onReturnPressed: {
                                        if (sudoPwdInput.text.length > 0 && !ControlCenterManager.isAuthChecking) {
                                            ControlCenterManager.verifySudoPassword(sudoPwdInput.text);
                                        }
                                    }
                                    Keys.onEnterPressed: {
                                        if (sudoPwdInput.text.length > 0 && !ControlCenterManager.isAuthChecking) {
                                            ControlCenterManager.verifySudoPassword(sudoPwdInput.text);
                                        }
                                    }
                                }

                                Rectangle {
                                    implicitWidth: 26
                                    implicitHeight: 26
                                    radius: 13
                                    color: eyeMouseArea.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: inputContainer.showPassword ? "󰈈" : "󰈉"
                                        color: Theme.overlay
                                        font.family: Theme.iconFontFamily
                                        font.pixelSize: 13
                                    }

                                    MouseArea {
                                        id: eyeMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: inputContainer.showPassword = !inputContainer.showPassword
                                    }
                                }
                            }
                        }

                        // Mensaje de Error
                        RowLayout {
                            Layout.fillWidth: true
                            visible: ControlCenterManager.authErrorMessage !== ""
                            spacing: 6

                            Text {
                                text: "󰅚"
                                color: Theme.danger
                                font.family: Theme.iconFontFamily
                                font.pixelSize: 12
                            }

                            Text {
                                Layout.fillWidth: true
                                text: ControlCenterManager.authErrorMessage
                                color: Theme.danger
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                wrapMode: Text.Wrap
                            }
                        }
                    }

                    // Botones Cancelar / Autenticar
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            implicitWidth: 90
                            implicitHeight: 32
                            radius: Theme.radiusSmall
                            color: cancelBtnMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : "transparent"
                            border.color: Theme.border
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "Cancelar"
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                            }

                            MouseArea {
                                id: cancelBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    sudoPwdInput.text = "";
                                    ControlCenterManager.cancelSudoAuth();
                                }
                            }
                        }

                        Rectangle {
                            implicitWidth: 120
                            implicitHeight: 32
                            radius: Theme.radiusSmall
                            color: ControlCenterManager.isAuthChecking ? Qt.darker(Theme.primary, 1.2) : (authConfirmMouse.containsMouse ? Qt.lighter(Theme.primary, 1.1) : Theme.primary)

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: ControlCenterManager.isAuthChecking ? "󰑐" : "󰄬"
                                    color: "#ffffff"
                                    font.family: Theme.iconFontFamily
                                    font.pixelSize: 12

                                    RotationAnimation on rotation {
                                        running: ControlCenterManager.isAuthChecking
                                        from: 0
                                        to: 360
                                        duration: 1000
                                        loops: Animation.Infinite
                                    }
                                }

                                Text {
                                    text: ControlCenterManager.isAuthChecking ? "Verificando..." : "Autenticar"
                                    color: "#ffffff"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                id: authConfirmMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: !ControlCenterManager.isAuthChecking
                                onClicked: {
                                    if (sudoPwdInput.text.length > 0) {
                                        ControlCenterManager.verifySudoPassword(sudoPwdInput.text);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
