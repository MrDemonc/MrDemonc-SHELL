import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property var bluetoothRef: null

    implicitWidth: 320
    implicitHeight: layout.implicitHeight + 28

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        // 1. Header: Título + Botón Escanear + Toggle de Encendido
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "󰂯  BLUETOOTH"
                color: Theme.primary
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            // Botón Buscar/Escanear
            Rectangle {
                visible: bluetoothRef && bluetoothRef.isPowered
                implicitWidth: 28
                implicitHeight: 28
                radius: 7
                color: scanMouse.containsMouse ? Theme.bgHover : Theme.bgSurface

                Behavior on color { ColorAnimation { duration: Theme.anim.fastEffects } }

                Text {
                    anchors.centerIn: parent
                    text: "󰑐"
                    color: (bluetoothRef && bluetoothRef.isScanning) ? Theme.primary : Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    rotation: (bluetoothRef && bluetoothRef.isScanning) ? 360 : 0
                    Behavior on rotation {
                        NumberAnimation { duration: 600; loops: Animation.Infinite }
                    }
                }

                MouseArea {
                    id: scanMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (bluetoothRef) bluetoothRef.toggleScan();
                    }
                }
            }

            // Botón On/Off Power
            Rectangle {
                implicitWidth: 28
                implicitHeight: 28
                radius: 7
                color: (bluetoothRef && bluetoothRef.isPowered) ? Theme.primary : (powerMouse.containsMouse ? Theme.bgHover : Theme.bgSurface)

                Behavior on color { ColorAnimation { duration: Theme.anim.fastEffects } }

                Text {
                    anchors.centerIn: parent
                    text: "󰐥"
                    color: (bluetoothRef && bluetoothRef.isPowered) ? (Theme.isDark ? "#11111b" : "#ffffff") : Theme.overlay
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }

                MouseArea {
                    id: powerMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (bluetoothRef) bluetoothRef.togglePower();
                    }
                }
            }
        }

        // 2. Información del Adaptador Bluetooth
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 48
            radius: 8
            color: Theme.bgSurface
            border.color: Theme.border
            border.width: 1

            GridLayout {
                anchors.fill: parent
                anchors.margins: 8
                columns: 3
                rowSpacing: 2
                columnSpacing: 6

                ColumnLayout {
                    spacing: 1
                    Text { text: "ESTADO"; color: Theme.overlay; font.family: Theme.fontFamily; font.pixelSize: 8 }
                    Text { 
                        text: (bluetoothRef && bluetoothRef.isPowered) ? "Encendido" : "Apagado"
                        color: (bluetoothRef && bluetoothRef.isPowered) ? Theme.success : Theme.danger
                        font.family: Theme.fontFamily; font.pixelSize: 9; font.bold: true 
                    }
                }

                ColumnLayout {
                    spacing: 1
                    Text { text: "ADAPTADOR"; color: Theme.overlay; font.family: Theme.fontFamily; font.pixelSize: 8 }
                    Text { 
                        text: (bluetoothRef && bluetoothRef.adapterName) ? bluetoothRef.adapterName : "---"
                        color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 9 
                    }
                }

                ColumnLayout {
                    spacing: 1
                    Text { text: "CONECTADOS"; color: Theme.overlay; font.family: Theme.fontFamily; font.pixelSize: 8 }
                    Text { 
                        text: (bluetoothRef && bluetoothRef.connectedCount > 0) ? (bluetoothRef.connectedCount + " disp.") : "Ninguno"
                        color: (bluetoothRef && bluetoothRef.connectedCount > 0) ? Theme.primary : Theme.overlay
                        font.family: Theme.fontFamily; font.pixelSize: 9 
                    }
                }
            }
        }

        // 3. Si Bluetooth está apagado (Mensaje sutil sin botón redundante)
        Item {
            Layout.fillWidth: true
            implicitHeight: 80
            visible: !bluetoothRef || !bluetoothRef.isPowered

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 6

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "󰂲"
                    color: Theme.overlay
                    font.family: Theme.fontFamily
                    font.pixelSize: 26
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: (bluetoothRef && !bluetoothRef.hasAdapter) ? "Sin adaptador Bluetooth" : "Bluetooth Desactivado"
                    color: Theme.overlay
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }
            }
        }

        // 4. Lista de Dispositivos (Solo si está encendido)
        ListView {
            id: btListView
            Layout.fillWidth: true
            implicitHeight: Math.min(180, Math.max(50, count * 34))
            clip: true
            spacing: 3
            visible: bluetoothRef && bluetoothRef.isPowered
            model: (bluetoothRef && bluetoothRef.devices) ? bluetoothRef.devices : []

            delegate: Rectangle {
                required property var modelData
                width: btListView.width
                implicitHeight: 30
                radius: 6
                color: {
                    if (modelData.isConnected) return Theme.bgHover;
                    if (itemMouse.containsMouse) return Theme.bgSurface;
                    return "transparent";
                }
                border.color: modelData.isConnected ? Theme.primary : "transparent"
                border.width: 1

                Behavior on color { ColorAnimation { duration: 120 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 6

                    Text {
                        text: {
                            let icon = (modelData.icon || "").toLowerCase();
                            if (icon.includes("headset") || icon.includes("audio") || icon.includes("headphones")) return "󰋋";
                            if (icon.includes("mouse")) return "󰍽";
                            if (icon.includes("keyboard")) return "󰌌";
                            if (icon.includes("phone")) return "󰏲";
                            return "󰂱";
                        }
                        color: modelData.isConnected ? Theme.primary : Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            Layout.fillWidth: true
                            text: modelData.name || modelData.mac
                            color: modelData.isConnected ? Theme.primary : Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: modelData.isConnected
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: modelData.battery !== undefined && modelData.battery >= 0
                            text: "Batería: " + modelData.battery + "%"
                            color: Theme.overlay
                            font.family: Theme.fontFamily
                            font.pixelSize: 8
                        }
                    }

                    Rectangle {
                        implicitWidth: modelData.isConnected ? 24 : 58
                        implicitHeight: 22
                        radius: 5
                        color: btnMouse.containsMouse ? (modelData.isConnected ? Theme.danger : Theme.primary) : Theme.bg

                        Text {
                            anchors.centerIn: parent
                            text: modelData.isConnected ? "󰅖" : "Conectar"
                            color: btnMouse.containsMouse ? (Theme.isDark ? "#11111b" : "#ffffff") : (modelData.isConnected ? Theme.danger : Theme.text)
                            font.family: Theme.fontFamily
                            font.pixelSize: modelData.isConnected ? 10 : 9
                        }

                        MouseArea {
                            id: btnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (bluetoothRef) {
                                    if (modelData.isConnected) bluetoothRef.disconnectDevice(modelData.mac);
                                    else bluetoothRef.connectDevice(modelData.mac);
                                }
                            }
                        }
                    }

                    Rectangle {
                        visible: modelData.isPaired && !modelData.isConnected
                        implicitWidth: 22
                        implicitHeight: 22
                        radius: 5
                        color: removeMouse.containsMouse ? Theme.danger : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "󰆴"
                            color: removeMouse.containsMouse ? (Theme.isDark ? "#11111b" : "#ffffff") : Theme.overlay
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }

                        MouseArea {
                            id: removeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (bluetoothRef) bluetoothRef.removeDevice(modelData.mac);
                            }
                        }
                    }
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    z: -1
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (bluetoothRef) {
                            if (modelData.isConnected) bluetoothRef.disconnectDevice(modelData.mac);
                            else bluetoothRef.connectDevice(modelData.mac);
                        }
                    }
                }
            }
        }
    }
}
