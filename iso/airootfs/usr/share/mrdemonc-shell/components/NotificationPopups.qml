import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: popupsWindow

    anchors {
        top: true
        right: true
    }

    implicitWidth: 390
    implicitHeight: popupColumn.implicitHeight + 36
    color: "transparent"

    WlrLayershell.namespace: "shell-notification-popups"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    visible: NotificationManager.activePopups.length > 0 && !NotificationManager.sidebarOpen

    Column {
        id: popupColumn
        anchors.top: parent.top
        anchors.topMargin: 36 // Margen para no chocar con la barra superior de 26px
        anchors.right: parent.right
        anchors.margins: 14
        spacing: 12
        width: 360

        Repeater {
            model: NotificationManager.activePopups

            delegate: Rectangle {
                id: popupCard
                width: 360
                implicitHeight: cardContent.implicitHeight + 20
                color: Theme.bg
                border.color: hoverArea.containsMouse ? Theme.primary : Theme.border
                border.width: 1
                radius: Theme.radiusMedium
                clip: true

                property bool isDismissing: false
                property bool isCopied: false

                // Estado y animaciones fluidas de entrada y salida
                opacity: 0.0
                x: 60
                scale: 0.92

                Component.onCompleted: {
                    enterAnimation.start();
                }

                ParallelAnimation {
                    id: enterAnimation
                    NumberAnimation { target: popupCard; property: "opacity"; to: 1.0; duration: 260; easing.type: Easing.OutCubic }
                    NumberAnimation { target: popupCard; property: "x"; to: 0; duration: 280; easing.type: Easing.OutCubic }
                    NumberAnimation { target: popupCard; property: "scale"; to: 1.0; duration: 280; easing.type: Easing.OutBack; easing.overshoot: 1.06 }
                }

                ParallelAnimation {
                    id: exitAnimation
                    NumberAnimation { target: popupCard; property: "opacity"; to: 0.0; duration: 220; easing.type: Easing.InCubic }
                    NumberAnimation { target: popupCard; property: "x"; to: 80; duration: 240; easing.type: Easing.InCubic }
                    NumberAnimation { target: popupCard; property: "scale"; to: 0.88; duration: 220; easing.type: Easing.InCubic }
                    onFinished: {
                        NotificationManager.dismissPopup(modelData.id);
                    }
                }

                property int remainingMs: 5000
                readonly property int totalMs: 5000
                readonly property real progressVal: Math.max(0.0, Math.min(1.0, remainingMs / totalMs))

                function startDismiss() {
                    if (isDismissing) return;
                    isDismissing = true;
                    tickTimer.stop();
                    exitAnimation.start();
                }

                // Temporizador por pasos para pausar exactamente en el milisegundo actual al pasar el mouse
                Timer {
                    id: tickTimer
                    interval: 50
                    repeat: true
                    running: !hoverArea.containsMouse && !popupCard.isDismissing
                    onTriggered: {
                        popupCard.remainingMs -= 50;
                        if (popupCard.remainingMs <= 0) {
                            tickTimer.stop();
                            popupCard.startDismiss();
                        }
                    }
                }

                Timer {
                    id: copiedResetTimer
                    interval: 1600
                    running: false
                    onTriggered: popupCard.isCopied = false
                }

                // Area de clic en toda la tarjeta para abrir la aplicación directamente
                MouseArea {
                    id: hoverArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton
                    onClicked: {
                        NotificationManager.openNotification(modelData);
                        popupCard.startDismiss();
                    }
                    z: 0
                }

                // Barra de progreso elegante inset (no se sale de las esquinas redondeadas de la tarjeta)
                Rectangle {
                    id: progressTrack
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 5
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    height: 3
                    radius: 2
                    color: Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.35)
                    clip: true
                    z: 1

                    Rectangle {
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        width: parent.width * popupCard.progressVal
                        radius: 2
                        color: Theme.primary
                        opacity: 0.85

                        Behavior on width {
                            NumberAnimation {
                                duration: 50
                            }
                        }
                    }
                }

                ColumnLayout {
                    id: cardContent
                    anchors.fill: parent
                    anchors.margins: 12
                    anchors.bottomMargin: 14
                    spacing: 6
                    z: 2

                    // 1. Cabecera: Icono, Nombre de App, Hora, Copiar (solo icono) y Cerrar
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        // Icono de la App
                        Rectangle {
                            implicitWidth: 22
                            implicitHeight: 22
                            radius: 6
                            color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.16)

                            Text {
                                anchors.centerIn: parent
                                text: "󰂚"
                                font.family: Theme.iconFontFamily
                                font.pixelSize: 13
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
                            radius: 6
                            color: copyMouse.containsMouse
                                   ? Theme.bgHover
                                   : (popupCard.isCopied ? Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.2) : "transparent")
                            border.color: popupCard.isCopied ? Theme.success : (copyMouse.containsMouse ? Theme.border : "transparent")
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: popupCard.isCopied ? "󰄬" : "󰆏"
                                font.family: Theme.iconFontFamily
                                font.pixelSize: 12
                                color: popupCard.isCopied ? Theme.success : (copyMouse.containsMouse ? Theme.primary : Theme.subtext)
                            }

                            MouseArea {
                                id: copyMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    let content = modelData.body ? modelData.body : modelData.summary;
                                    NotificationManager.copyContent(content);
                                    popupCard.isCopied = true;
                                    copiedResetTimer.restart();
                                }
                            }
                        }

                        // Botón descartar popup individual
                        Rectangle {
                            implicitWidth: 20
                            implicitHeight: 20
                            radius: Theme.radiusFull
                            color: closeMouse.containsMouse ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.2) : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "󰅖"
                                font.family: Theme.iconFontFamily
                                font.pixelSize: 11
                                color: closeMouse.containsMouse ? Theme.danger : Theme.subtext
                            }

                            MouseArea {
                                id: closeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: popupCard.startDismiss()
                            }
                        }
                    }

                    // 2. Contenido: Resumen y Cuerpo
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
                            maximumLineCount: 3
                            elide: Text.ElideRight
                            visible: text.length > 0
                        }
                    }
                }
            }
        }
    }
}
