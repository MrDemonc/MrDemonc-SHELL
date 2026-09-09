import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property var networkRef: null
    property string connectingSsid: ""
    property string passwordInput: ""
    property bool showHiddenPrompt: false

    implicitWidth: 320
    implicitHeight: layout.implicitHeight + 20

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        // 1. Header: Redes Wi-Fi + Rescan + Botón Red Oculta
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "󰤨  REDES WI-FI"
                color: Theme.cyan
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            // Botón Red Oculta (+)
            Rectangle {
                implicitWidth: 28
                implicitHeight: 28
                radius: 7
                color: addHiddenMouse.containsMouse ? Theme.bgHover : Theme.bgSurface
                border.color: root.showHiddenPrompt ? Theme.primary : "transparent"
                border.width: 1

                Behavior on color { ColorAnimation { duration: Theme.anim.fastEffects } }

                Text {
                    anchors.centerIn: parent
                    text: "󰤪"
                    color: root.showHiddenPrompt ? Theme.primary : Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }

                MouseArea {
                    id: addHiddenMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.showHiddenPrompt = !root.showHiddenPrompt;
                    }
                }
            }

            // Botón Rescan (Refrescar)
            Rectangle {
                implicitWidth: 28
                implicitHeight: 28
                radius: 7
                color: rescanMouse.containsMouse ? Theme.bgHover : Theme.bgSurface

                Behavior on color { ColorAnimation { duration: Theme.anim.fastEffects } }

                Text {
                    anchors.centerIn: parent
                    text: "󰑐"
                    color: (networkRef && networkRef.isScanning) ? Theme.primary : Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    rotation: (networkRef && networkRef.isScanning) ? 360 : 0
                    Behavior on rotation {
                        NumberAnimation { duration: 600; loops: Animation.Infinite }
                    }
                }

                MouseArea {
                    id: rescanMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (networkRef) networkRef.rescan();
                    }
                }
            }
        }

        // 2. Información Importante de la Red Actual (IP, Gateway, Señal)
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
                columns: 4
                rowSpacing: 2
                columnSpacing: 6

                ColumnLayout {
                    spacing: 1
                    Text { text: "ESTADO"; color: Theme.overlay; font.family: Theme.fontFamily; font.pixelSize: 8 }
                    Text { 
                        text: (networkRef && networkRef.isConnected) ? "Conectado" : "Desconectado"
                        color: (networkRef && networkRef.isConnected) ? Theme.success : Theme.danger
                        font.family: Theme.fontFamily; font.pixelSize: 9; font.bold: true 
                    }
                }

                ColumnLayout {
                    spacing: 1
                    Text { text: "IP LOCAL"; color: Theme.overlay; font.family: Theme.fontFamily; font.pixelSize: 8 }
                    Text { 
                        text: (networkRef && networkRef.ipAddress) ? networkRef.ipAddress : "---"
                        color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 9 
                    }
                }

                ColumnLayout {
                    spacing: 1
                    Text { text: "GATEWAY"; color: Theme.overlay; font.family: Theme.fontFamily; font.pixelSize: 8 }
                    Text { 
                        text: (networkRef && networkRef.gateway) ? networkRef.gateway : "---"
                        color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 9 
                    }
                }

                ColumnLayout {
                    spacing: 1
                    Text { text: "SEÑAL"; color: Theme.overlay; font.family: Theme.fontFamily; font.pixelSize: 8 }
                    Text { 
                        text: (networkRef && networkRef.isConnected) ? networkRef.signalStrength + "%" : "0%"
                        color: Theme.cyan; font.family: Theme.fontFamily; font.pixelSize: 9 
                    }
                }
            }
        }

        // 3. Formulario para conectar a Red Oculta
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: root.showHiddenPrompt ? 84 : 0
            visible: implicitHeight > 0
            clip: true
            radius: 8
            color: Theme.bgSurface
            border.color: Theme.border
            border.width: 1

            Behavior on implicitHeight {
                NumberAnimation {
                    duration: Theme.anim.fastEffects
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.anim.expressiveFastEffects
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 4

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 22
                    radius: 5
                    color: Theme.bg
                    TextInput {
                        id: hiddenNameEdit
                        anchors.fill: parent
                        anchors.margins: 4
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        clip: true
                        Text {
                            text: "Nombre de Red Oculta (SSID)..."
                            color: Theme.overlay
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            visible: !hiddenNameEdit.text
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 22
                        radius: 5
                        color: Theme.bg
                        TextInput {
                            id: hiddenPassEdit
                            anchors.fill: parent
                            anchors.margins: 4
                            color: Theme.text
                            echoMode: TextInput.Password
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            clip: true
                            Text {
                                text: "Contraseña de la red..."
                                color: Theme.overlay
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                visible: !hiddenPassEdit.text
                            }
                        }
                    }

                    // Botón Cancelar
                    Rectangle {
                        implicitWidth: 26
                        implicitHeight: 22
                        radius: 5
                        color: cancelHiddenMouse.containsMouse ? Theme.bgHover : Theme.bg
                        Text {
                            anchors.centerIn: parent
                            text: "󰅖"
                            color: Theme.overlay
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                        MouseArea {
                            id: cancelHiddenMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                hiddenNameEdit.text = "";
                                hiddenPassEdit.text = "";
                                root.showHiddenPrompt = false;
                            }
                        }
                    }

                    // Botón Unirse
                    Rectangle {
                        implicitWidth: 54
                        implicitHeight: 22
                        radius: 5
                        color: connectHiddenMouse.containsMouse ? Theme.primary : Theme.bgHover
                        Text {
                            anchors.centerIn: parent
                            text: "Unirse"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }
                        MouseArea {
                            id: connectHiddenMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (hiddenNameEdit.text.trim().length > 0 && networkRef) {
                                    networkRef.connectToNetwork(hiddenNameEdit.text.trim(), hiddenPassEdit.text, true);
                                    hiddenNameEdit.text = "";
                                    hiddenPassEdit.text = "";
                                    root.showHiddenPrompt = false;
                                }
                            }
                        }
                    }
                }
            }
        }

        // 4. Formulario de contraseña para red seleccionada
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: root.connectingSsid.length > 0 ? 56 : 0
            visible: implicitHeight > 0
            clip: true
            radius: 8
            color: Theme.bgSurface
            border.color: Theme.primary
            border.width: 1

            Behavior on implicitHeight {
                NumberAnimation {
                    duration: Theme.anim.fastEffects
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.anim.expressiveFastEffects
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        Layout.fillWidth: true
                        text: "Clave para: " + root.connectingSsid
                        color: Theme.primary
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        implicitWidth: 18
                        implicitHeight: 18
                        radius: 4
                        color: closePassMouse.containsMouse ? Theme.danger : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "󰅖"
                            color: closePassMouse.containsMouse ? (Theme.isDark ? "#11111b" : "#ffffff") : Theme.overlay
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }
                        MouseArea {
                            id: closePassMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.connectingSsid = "";
                                passInput.text = "";
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 22
                        radius: 5
                        color: Theme.bg
                        TextInput {
                            id: passInput
                            anchors.fill: parent
                            anchors.margins: 4
                            color: Theme.text
                            echoMode: TextInput.Password
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            clip: true
                            Keys.onEscapePressed: {
                                root.connectingSsid = "";
                                passInput.text = "";
                            }
                            onAccepted: connectBtnMouse.clicked(null)
                        }
                    }

                    Rectangle {
                        implicitWidth: 60
                        implicitHeight: 22
                        radius: 5
                        color: connectBtnMouse.containsMouse ? Theme.primary : Theme.bgHover
                        Text {
                            anchors.centerIn: parent
                            text: "Conectar"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                        }
                        MouseArea {
                            id: connectBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (networkRef) {
                                    networkRef.connectToNetwork(root.connectingSsid, passInput.text, false);
                                    root.connectingSsid = "";
                                    passInput.text = "";
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Theme.border
        }

        // 5. Lista de redes disponibles con indicador de conexión actual
        ListView {
            id: netListView
            Layout.fillWidth: true
            implicitHeight: Math.min(180, Math.max(60, count * 31))
            clip: true
            spacing: 3
            model: networkRef ? networkRef.networks : []

            delegate: Rectangle {
                required property var modelData
                width: netListView.width
                implicitHeight: 28
                radius: 6
                color: {
                    if (modelData.inUse) return Theme.bgHover;
                    if (netItemMouse.containsMouse) return Theme.bgSurface;
                    return "transparent";
                }
                border.color: modelData.inUse ? Theme.cyan : "transparent"
                border.width: 1

                Behavior on color { ColorAnimation { duration: 120 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 6

                    Text {
                        text: {
                            if (modelData.signal >= 75) return "󰤨";
                            if (modelData.signal >= 50) return "󰤥";
                            if (modelData.signal >= 25) return "󰤢";
                            return "󰤟";
                        }
                        color: modelData.inUse ? Theme.cyan : Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData.ssid
                        color: modelData.inUse ? Theme.cyan : Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.bold: modelData.inUse
                        elide: Text.ElideRight
                    }

                    Text {
                        visible: modelData.isSaved && !modelData.inUse
                        text: "󰌨"
                        color: Theme.primary
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                    }

                    Text {
                        visible: !modelData.isSaved && modelData.security && modelData.security !== "Abierta"
                        text: "󰌾"
                        color: Theme.overlay
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                    }

                    Text {
                        visible: modelData.inUse
                        text: "󰄬"
                        color: Theme.success
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                    }
                }

                MouseArea {
                    id: netItemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData.inUse) return;
                        if (modelData.isSaved) {
                            if (networkRef) networkRef.connectToNetwork(modelData.rawSsid, "", false);
                            return;
                        }
                        if (modelData.security && modelData.security !== "Abierta") {
                            if (root.connectingSsid === modelData.rawSsid) {
                                root.connectingSsid = "";
                                passInput.text = "";
                            } else {
                                root.connectingSsid = modelData.rawSsid;
                                passInput.forceActiveFocus();
                            }
                        } else {
                            if (networkRef) networkRef.connectToNetwork(modelData.rawSsid, "", false);
                        }
                    }
                }
            }
        }
    }
}
