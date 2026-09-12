import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: sidebarWindow

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    WlrLayershell.namespace: "shell-notification-sidebar"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: NotificationManager.sidebarOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    visible: NotificationManager.sidebarOpen || scrim.opacity > 0.01

    // Fondo oscurecido con transición suave
    Rectangle {
        id: scrim
        anchors.fill: parent
        color: "#000000"
        opacity: NotificationManager.sidebarOpen ? 0.60 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: 220
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: NotificationManager.sidebarOpen
            onClicked: NotificationManager.sidebarOpen = false
        }
    }

    // Atajo Escape para cerrar
    Shortcut {
        sequence: "Escape"
        enabled: NotificationManager.sidebarOpen
        onActivated: NotificationManager.sidebarOpen = false
    }

    // Panel Flotante Deslizable (Floating Drawer) exclusivamente desde la derecha
    Rectangle {
        id: drawer
        width: 396
        anchors.top: parent.top
        anchors.topMargin: 38 // Flotante: margen para no chocar con la barra superior
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 18 // Flotante: separación estética del borde inferior

        // Anclaje a la derecha para garantizar deslizamiento exclusivamente desde la derecha sin saltos desde la izquierda al inicio
        anchors.right: parent.right
        anchors.rightMargin: NotificationManager.sidebarOpen ? 18 : (-width - 50)
        opacity: NotificationManager.sidebarOpen ? 1.0 : 0.0

        Behavior on anchors.rightMargin {
            NumberAnimation {
                duration: 280
                easing.type: Easing.OutCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }

        color: Theme.bg
        border.color: Theme.border
        border.width: 1
        radius: Theme.radiusLarge // Esquinas redondeadas flotantes (16px)
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // =================================================================
            // 1. BARRA MINIMALISTA DE CONTROLES: DND, CONTADOR Y LIMPIAR
            // =================================================================
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Botón Silenciar / No Molestar (DND)
                Rectangle {
                    implicitHeight: 32
                    implicitWidth: dndRow.implicitWidth + 20
                    radius: 8
                    color: NotificationManager.silenced
                           ? Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.22)
                           : (dndMouse.containsMouse ? Theme.bgHover : Qt.rgba(Theme.bgHover.r, Theme.bgHover.g, Theme.bgHover.b, 0.4))
                    border.color: NotificationManager.silenced ? Theme.warning : Theme.border
                    border.width: 1

                    RowLayout {
                        id: dndRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: NotificationManager.silenced ? "󰂛" : "󰂚"
                            font.family: Theme.iconFontFamily
                            font.pixelSize: 12
                            color: NotificationManager.silenced ? Theme.warning : Theme.subtext
                        }

                        Text {
                            text: NotificationManager.silenced ? "Silenciado" : "Silenciar"
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: NotificationManager.silenced
                            color: NotificationManager.silenced ? Theme.warning : Theme.text
                        }
                    }

                    MouseArea {
                        id: dndMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NotificationManager.toggleSilenced()
                    }
                }

                // Contador de notificaciones (badge minimalista)
                Rectangle {
                    implicitHeight: 28
                    implicitWidth: countRow.implicitWidth + 14
                    radius: Theme.radiusFull
                    color: Qt.rgba(Theme.bgHover.r, Theme.bgHover.g, Theme.bgHover.b, 0.5)
                    border.color: Theme.border
                    border.width: 1

                    RowLayout {
                        id: countRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: "󰂚"
                            font.family: Theme.iconFontFamily
                            font.pixelSize: 10
                            color: NotificationManager.history.length > 0 ? Theme.primary : Theme.subtext
                        }

                        Text {
                            text: String(NotificationManager.history.length)
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                            color: NotificationManager.history.length > 0 ? Theme.primary : Theme.subtext
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Botón Limpiar Todo
                Rectangle {
                    implicitHeight: 32
                    implicitWidth: clearTxt.implicitWidth + 20
                    radius: 8
                    color: clearMouse.containsMouse ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.22) : Qt.rgba(Theme.bgHover.r, Theme.bgHover.g, Theme.bgHover.b, 0.3)
                    border.color: clearMouse.containsMouse ? Theme.danger : Theme.border
                    border.width: 1
                    visible: NotificationManager.history.length > 0

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: "󰆴"
                            font.family: Theme.iconFontFamily
                            font.pixelSize: 11
                            color: clearMouse.containsMouse ? Theme.danger : Theme.subtext
                        }

                        Text {
                            id: clearTxt
                            text: "Limpiar"
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            color: clearMouse.containsMouse ? Theme.danger : Theme.subtext
                        }
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NotificationManager.clearAll()
                    }
                }
            }

            // Separador horizontal sutil
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.border
                opacity: 0.7
            }

            // =================================================================
            // 2. CUERPO: LISTA DE NOTIFICACIONES O ESTADO VACÍO
            // =================================================================
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // A. Estado Vacío (Sin notificaciones)
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 10
                    visible: NotificationManager.history.length === 0

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: 54
                        implicitHeight: 54
                        radius: Theme.radiusFull
                        color: Qt.rgba(Theme.bgHover.r, Theme.bgHover.g, Theme.bgHover.b, 0.5)

                        Text {
                            anchors.centerIn: parent
                            text: "󰂛"
                            font.family: Theme.iconFontFamily
                            font.pixelSize: 26
                            color: Theme.overlay
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Sin notificaciones"
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        font.bold: true
                        color: Theme.text
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Todo está al día y tranquilo"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: Theme.subtext
                    }
                }

                // B. Vista con Scroll de Notificaciones
                ListView {
                    id: historyList
                    anchors.fill: parent
                    spacing: 10
                    clip: true
                    model: NotificationManager.history
                    visible: NotificationManager.history.length > 0

                    delegate: Rectangle {
                        id: historyCard
                        width: historyList.width
                        implicitHeight: itemCol.implicitHeight + 22
                        radius: Theme.radiusMedium
                        color: itemHover.containsMouse ? Qt.rgba(Theme.bgSurface.r, Theme.bgSurface.g, Theme.bgSurface.b, 0.85) : Qt.rgba(Theme.bgSurface.r, Theme.bgSurface.g, Theme.bgSurface.b, 0.6)
                        border.color: itemHover.containsMouse ? Theme.primary : Theme.border
                        border.width: 1

                        property bool isCopied: false

                        Timer {
                            id: copyTimer
                            interval: 1600
                            running: false
                            onTriggered: historyCard.isCopied = false
                        }

                        // Clic en toda la tarjeta para abrir la aplicación directamente
                        MouseArea {
                            id: itemHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton
                            onClicked: NotificationManager.openNotification(modelData)
                            z: 0
                        }

                        ColumnLayout {
                            id: itemCol
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8
                            z: 1

                            // 1. Cabecera del Item: Icono, AppName, Hora, Copiar (solo icono) y Eliminar
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Rectangle {
                                    implicitWidth: 20
                                    implicitHeight: 20
                                    radius: 5
                                    color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.16)

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰂚"
                                        font.family: Theme.iconFontFamily
                                        font.pixelSize: 12
                                        color: Theme.primary
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.appName
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: Theme.text
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: modelData.time
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: Theme.subtext
                                }

                                // Botón Copiar Contenido (solo icono compacto)
                                Rectangle {
                                    implicitWidth: 22
                                    implicitHeight: 22
                                    radius: 5
                                    color: copyHistMouse.containsMouse
                                           ? Theme.bgHover
                                           : (historyCard.isCopied ? Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.2) : "transparent")
                                    border.color: historyCard.isCopied ? Theme.success : (copyHistMouse.containsMouse ? Theme.border : "transparent")
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: historyCard.isCopied ? "󰄬" : "󰆏"
                                        font.family: Theme.iconFontFamily
                                        font.pixelSize: 11
                                        color: historyCard.isCopied ? Theme.success : (copyHistMouse.containsMouse ? Theme.primary : Theme.subtext)
                                    }

                                    MouseArea {
                                        id: copyHistMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            let content = modelData.body ? modelData.body : modelData.summary;
                                            NotificationManager.copyContent(content);
                                            historyCard.isCopied = true;
                                            copyTimer.restart();
                                        }
                                    }
                                }

                                // Botón Eliminar una notificación
                                Rectangle {
                                    implicitWidth: 20
                                    implicitHeight: 20
                                    radius: Theme.radiusFull
                                    color: delMouse.containsMouse ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.2) : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅖"
                                        font.family: Theme.iconFontFamily
                                        font.pixelSize: 11
                                        color: delMouse.containsMouse ? Theme.danger : Theme.subtext
                                    }

                                    MouseArea {
                                        id: delMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: NotificationManager.deleteHistoryItem(modelData.id)
                                    }
                                }
                            }

                            // 2. Contenido de la notificación
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.summary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: Theme.text
                                    wrapMode: Text.Wrap
                                    visible: text.length > 0
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.body
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    color: Theme.subtext
                                    wrapMode: Text.Wrap
                                    visible: text.length > 0
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
