import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: weatherModalWindow

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    WlrLayershell.namespace: "shell-weather-modal"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WeatherLocationManager.modalOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    visible: WeatherLocationManager.modalOpen || modalCard.opacity > 0.01

    onVisibleChanged: {
        if (visible && WeatherLocationManager.modalOpen) {
            searchInput.text = "";
            searchTimer.stop();
            searchInput.forceActiveFocus();
        }
    }

    // Fondo oscurecido (Scrim)
    Rectangle {
        id: scrim
        anchors.fill: parent
        color: "#000000"
        opacity: WeatherLocationManager.modalOpen ? 0.65 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.anim.defaultEffects
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.anim.expressiveDefaultEffects
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: WeatherLocationManager.modalOpen
            onClicked: WeatherLocationManager.close()
        }
    }

    // Tarjeta Modal Central Minimalista
    Rectangle {
        id: modalCard
        anchors.centerIn: parent

        implicitWidth: 540
        implicitHeight: 380
        color: Theme.bg
        border.color: Theme.border
        border.width: 1
        radius: Theme.radiusLarge
        clip: true

        opacity: WeatherLocationManager.modalOpen ? 1.0 : 0.0
        scale: WeatherLocationManager.modalOpen ? 1.0 : 0.92

        Behavior on scale {
            NumberAnimation {
                duration: WeatherLocationManager.modalOpen ? 320 : 180
                easing.type: WeatherLocationManager.modalOpen ? Easing.OutBack : Easing.InQuad
                easing.overshoot: 1.15
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.anim.defaultEffects
            }
        }

        Shortcut {
            sequence: "Escape"
            enabled: WeatherLocationManager.modalOpen
            onActivated: WeatherLocationManager.close()
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            // -----------------------------------------------------------------
            // 1. BUSCADOR INTERACTIVO
            // -----------------------------------------------------------------
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 40
                color: Theme.bgSurface
                radius: 10
                border.color: searchInput.activeFocus ? Theme.primary : Theme.border
                border.width: searchInput.activeFocus ? 1.5 : 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    Text {
                        text: "󰍉"
                        color: searchInput.activeFocus ? Theme.primary : Theme.subtext
                        font.family: Theme.iconFontFamily
                        font.pixelSize: 14
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        verticalAlignment: TextInput.AlignVCenter
                        selectByMouse: true
                        clip: true

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: "Escribe una ciudad (ej. Madrid, Buenos Aires, Tokio)..."
                            color: Theme.overlay
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            visible: !searchInput.text && !searchInput.activeFocus
                        }

                        onTextChanged: {
                            searchTimer.restart();
                        }

                        onAccepted: {
                            WeatherLocationManager.search(text);
                        }
                    }

                    Rectangle {
                        implicitWidth: 18
                        implicitHeight: 18
                        radius: 9
                        color: Theme.bgHover
                        visible: searchInput.text.length > 0

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: Theme.subtext
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                searchInput.text = "";
                                WeatherLocationManager.searchResults = [];
                            }
                        }
                    }
                }

                Timer {
                    id: searchTimer
                    interval: 250
                    repeat: false
                    onTriggered: {
                        WeatherLocationManager.search(searchInput.text);
                    }
                }
            }

            // -----------------------------------------------------------------
            // 3. OPCIÓN RÁPIDA: UBICACIÓN AUTOMÁTICA
            // -----------------------------------------------------------------
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 44
                radius: 10
                color: autoLocMouse.containsMouse ? Theme.bgHover : Theme.bgSurface
                border.color: (WeatherLocationManager.currentLocation && WeatherLocationManager.currentLocation.auto) ? Theme.primary : Theme.border
                border.width: (WeatherLocationManager.currentLocation && WeatherLocationManager.currentLocation.auto) ? 1.5 : 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    Rectangle {
                        implicitWidth: 26
                        implicitHeight: 26
                        radius: 13
                        color: Theme.bgHover
                        Text {
                            anchors.centerIn: parent
                            text: "󰖑"
                            color: Theme.cyan
                            font.family: Theme.iconFontFamily
                            font.pixelSize: 14
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            text: "Ubicación Automática"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                        }
                        Text {
                            text: "Detectar automáticamente mi ubicación por red / dirección IP"
                            color: Theme.subtext
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                        }
                    }

                    Rectangle {
                        implicitWidth: 20
                        implicitHeight: 20
                        radius: 10
                        color: (WeatherLocationManager.currentLocation && WeatherLocationManager.currentLocation.auto) ? Theme.primary : "transparent"
                        border.color: (WeatherLocationManager.currentLocation && WeatherLocationManager.currentLocation.auto) ? Theme.primary : Theme.border
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "󰄬"
                            color: Theme.bg
                            font.family: Theme.iconFontFamily
                            font.pixelSize: 11
                            visible: (WeatherLocationManager.currentLocation && WeatherLocationManager.currentLocation.auto)
                        }
                    }
                }

                MouseArea {
                    id: autoLocMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: WeatherLocationManager.selectAutoLocation()
                }
            }

            // -----------------------------------------------------------------
            // 4. LISTA DE RESULTADOS DE BÚSQUEDA
            // -----------------------------------------------------------------
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Theme.bgSurface
                radius: 10
                border.color: Theme.border
                border.width: 1
                clip: true

                ListView {
                    id: resultsList
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 4
                    model: WeatherLocationManager.searchResults

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        width: resultsList.width
                        implicitHeight: 42
                        radius: 8
                        color: itemMouse.containsMouse ? Theme.bgHover : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10

                            Rectangle {
                                implicitWidth: 24
                                implicitHeight: 24
                                radius: 12
                                color: Theme.bg
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰍎"
                                    color: Theme.primary
                                    font.family: Theme.iconFontFamily
                                    font.pixelSize: 12
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    text: modelData.name || ""
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.bold: true
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: modelData.sub_label || modelData.country || ""
                                    color: Theme.subtext
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            Text {
                                text: "Seleccionar"
                                color: Theme.primary
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                font.bold: true
                                visible: itemMouse.containsMouse
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: WeatherLocationManager.selectLocation(modelData)
                        }
                    }

                    // Estado vacío / indicador
                    Item {
                        anchors.centerIn: parent
                        width: parent.width - 40
                        height: 100
                        visible: resultsList.count === 0

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: WeatherLocationManager.isSearching ? "󰑐" : "󰖐"
                                color: Theme.overlay
                                font.family: Theme.iconFontFamily
                                font.pixelSize: 24
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: WeatherLocationManager.isSearching ? "Buscando ciudades..." : (searchInput.text.length >= 2 ? "No se encontraron resultados" : "Escribe el nombre de una ciudad para buscar")
                                color: Theme.subtext
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                            }
                        }
                    }
                }
            }

            // Mensaje de estado inferior
            Text {
                text: WeatherLocationManager.statusMessage
                color: Theme.primary
                font.family: Theme.fontFamily
                font.pixelSize: 10
                font.bold: true
                visible: text.length > 0
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}
