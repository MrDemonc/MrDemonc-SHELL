import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: contextWindow

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    WlrLayershell.namespace: "shell-tray-context-menu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    visible: TrayMenuManager.isOpen || menuCard.opacity > 0.01

    // Cerrar al hacer clic en cualquier lugar fuera del menú
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onPressed: {
            TrayMenuManager.closeMenu();
        }
    }

    // Tarjeta emergente del menú contextual
    Rectangle {
        id: menuCard
        width: 190
        height: cardContent.implicitHeight + 16
        radius: Theme.radiusSmall
        color: Theme.bgSurface
        border.color: Theme.border
        border.width: 1

        property real screenW: contextWindow.screen ? contextWindow.screen.width : 1280
        property real screenH: contextWindow.screen ? contextWindow.screen.height : 800

        x: {
            let posX = 0;
            if (PopoutManager.barPosition === "left") {
                posX = 32;
            } else if (PopoutManager.barPosition === "right") {
                posX = screenW - width - 32;
            } else {
                posX = TrayMenuManager.targetX - (width / 2);
            }
            return Math.max(10, Math.min(screenW - width - 10, posX));
        }

        y: {
            let posY = 0;
            if (PopoutManager.barPosition === "bottom") {
                posY = screenH - height - 32;
            } else if (PopoutManager.barPosition === "left" || PopoutManager.barPosition === "right") {
                posY = TrayMenuManager.targetY - (height / 2);
            } else {
                posY = 32;
            }
            return Math.max(10, Math.min(screenH - height - 10, posY));
        }

        opacity: TrayMenuManager.isOpen ? 1.0 : 0.0
        scale: TrayMenuManager.isOpen ? 1.0 : 0.94

        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
        }
        Behavior on scale {
            NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
        }

        // Evitar que los clics sobre la tarjeta cierren el menú
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: {}
        }

        ColumnLayout {
            id: cardContent
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 8
            spacing: 4

            // Cabecera con Icono y Nombre de la App
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 24
                Layout.leftMargin: 6
                Layout.rightMargin: 6
                spacing: 8

                Text {
                    text: TrayMenuManager.appIcon
                    font.family: Theme.iconFontFamily
                    font.pixelSize: 14
                    color: Theme.primary
                }

                Text {
                    text: TrayMenuManager.appTitle
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.bold: true
                    color: Theme.text
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }

            // Separador sutil
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.border
                opacity: 0.6
                Layout.topMargin: 2
                Layout.bottomMargin: 4
            }

            // Lista de opciones disponibles
            Repeater {
                model: TrayMenuManager.options

                delegate: Item {
                    id: optionDelegate
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    Layout.preferredHeight: modelData.isSeparator ? 7 : 28

                    // Separador si la opción lo indica
                    Rectangle {
                        visible: !!optionDelegate.modelData.isSeparator
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 1
                        color: Theme.border
                        opacity: 0.4
                    }

                    // Botón de la opción
                    Rectangle {
                        visible: !optionDelegate.modelData.isSeparator
                        anchors.fill: parent
                        radius: 5
                        color: optMouse.containsMouse 
                            ? (optionDelegate.modelData.isDanger ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.18) : Theme.bgHover) 
                            : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            Text {
                                text: optionDelegate.modelData.icon || ""
                                font.family: Theme.iconFontFamily
                                font.pixelSize: 12
                                color: optionDelegate.modelData.isDanger 
                                    ? Theme.danger 
                                    : (optMouse.containsMouse ? Theme.primary : Theme.subtext)
                            }

                            Text {
                                text: optionDelegate.modelData.label || ""
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                color: optionDelegate.modelData.isDanger 
                                    ? Theme.danger 
                                    : (optMouse.containsMouse ? Theme.text : Theme.subtext)
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: optMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                let act = optionDelegate.modelData.action;
                                TrayMenuManager.closeMenu();
                                if (typeof act === "function") {
                                    act();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
