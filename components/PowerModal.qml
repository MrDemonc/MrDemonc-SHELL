import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: powerModalWindow

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    WlrLayershell.namespace: "shell-power-modal"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: PowerManager.powerOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    visible: PowerManager.powerOpen || modalCard.opacity > 0.01

    onVisibleChanged: {
        if (visible && PowerManager.powerOpen) {
            keyHandler.forceActiveFocus();
        }
    }

    // Fondo oscurecido con transición suave
    Rectangle {
        id: scrim
        anchors.fill: parent
        color: "#000000"
        opacity: PowerManager.powerOpen ? 0.70 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.anim.defaultEffects
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.anim.expressiveDefaultEffects
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: PowerManager.powerOpen
            onClicked: {
                if (PowerManager.pendingAction !== null) {
                    PowerManager.cancelConfirm();
                } else {
                    PowerManager.powerOpen = false;
                }
            }
        }
    }

    // Capturador de eventos de teclado
    Item {
        id: keyHandler
        anchors.fill: parent
        focus: PowerManager.powerOpen

        Keys.onPressed: function(event) {
            if (!PowerManager.powerOpen) return;

            // Escape: cancela confirmación o cierra modal
            if (event.key === Qt.Key_Escape) {
                if (PowerManager.pendingAction !== null) {
                    PowerManager.cancelConfirm();
                } else {
                    PowerManager.powerOpen = false;
                }
                event.accepted = true;
                return;
            }

            // Confirmación activa
            if (PowerManager.pendingAction !== null) {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                    PowerManager.executeAction(PowerManager.pendingAction);
                    event.accepted = true;
                    return;
                }
                let act = PowerManager.pendingAction;
                if (event.text === act.key || (event.text.length > 0 && event.text.toUpperCase() === act.letter)) {
                    PowerManager.executeAction(act);
                    event.accepted = true;
                    return;
                }
            }

            // Navegación con flechas
            let total = PowerManager.actions.length;
            if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
                PowerManager.selectedIndex = (PowerManager.selectedIndex - 1 + total) % total;
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_Right || event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                PowerManager.selectedIndex = (PowerManager.selectedIndex + 1) % total;
                event.accepted = true;
                return;
            }

            // Enter o Espacio
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                let sel = PowerManager.actions[PowerManager.selectedIndex];
                PowerManager.triggerAction(sel);
                event.accepted = true;
                return;
            }

            // Atajos rápidos numéricos y alfabéticos (1-6, P, R, S, L, E, H)
            for (let i = 0; i < PowerManager.actions.length; i++) {
                let a = PowerManager.actions[i];
                if (event.text === a.key || (event.text.length > 0 && event.text.toUpperCase() === a.letter)) {
                    PowerManager.selectedIndex = i;
                    PowerManager.triggerAction(a);
                    event.accepted = true;
                    return;
                }
            }
        }
    }

    // Tarjeta Modal Central Minimalista
    Rectangle {
        id: modalCard
        anchors.centerIn: parent

        implicitWidth: 700
        implicitHeight: PowerManager.pendingAction ? 115 : 125
        color: Theme.bg
        border.color: Theme.border
        border.width: 1
        radius: Theme.radiusLarge
        clip: true

        opacity: PowerManager.powerOpen ? 1.0 : 0.0
        scale: PowerManager.powerOpen ? 1.0 : 0.90

        Behavior on implicitHeight {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: PowerManager.powerOpen ? 320 : 180
                easing.type: PowerManager.powerOpen ? Easing.OutBack : Easing.InQuad
                easing.overshoot: 1.15
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.anim.defaultEffects
            }
        }

        // Contenido de la tarjeta
        Item {
            anchors.fill: parent
            anchors.margins: 14

            // A. Malla de 6 Botones de Acción
            RowLayout {
                anchors.fill: parent
                spacing: 10
                visible: PowerManager.pendingAction === null
                opacity: visible ? 1.0 : 0.0

                Behavior on opacity {
                    NumberAnimation { duration: 160 }
                }

                Repeater {
                    model: PowerManager.actions

                    delegate: Rectangle {
                        id: actionTile
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Theme.radiusMedium

                        readonly property bool isSelected: PowerManager.selectedIndex === index
                        readonly property bool isHovered: tileMouse.containsMouse
                        readonly property color actColor: modelData.color

                        color: (isSelected || isHovered)
                               ? Qt.rgba(actColor.r, actColor.g, actColor.b, 0.18)
                               : Qt.rgba(Theme.bgHover.r, Theme.bgHover.g, Theme.bgHover.b, 0.40)

                        border.color: (isSelected || isHovered) ? actColor : Theme.border
                        border.width: (isSelected || isHovered) ? 2 : 1

                        scale: isHovered ? 1.04 : 1.0

                        Behavior on scale {
                            NumberAnimation {
                                duration: 150
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on color {
                            ColorAnimation { duration: 130 }
                        }

                        Behavior on border.color {
                            ColorAnimation { duration: 130 }
                        }

                        // Badge con tecla de acceso rápido
                        Rectangle {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 6
                            implicitWidth: 18
                            implicitHeight: 18
                            radius: 4
                            color: (actionTile.isSelected || actionTile.isHovered)
                                   ? actColor
                                   : Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.6)

                            Text {
                                anchors.centerIn: parent
                                text: modelData.key
                                font.family: Theme.monoFontFamily
                                font.pixelSize: 10
                                font.bold: true
                                color: (actionTile.isSelected || actionTile.isHovered)
                                       ? Theme.bgSurface
                                       : Theme.text
                            }
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            // Icono principal
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.icon
                                font.family: Theme.iconFontFamily
                                font.pixelSize: 34
                                color: (actionTile.isSelected || actionTile.isHovered)
                                       ? actColor
                                       : Theme.text
                            }

                            // Título de la acción
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.title
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.bold: true
                                color: (actionTile.isSelected || actionTile.isHovered)
                                       ? actColor
                                       : Theme.text
                            }
                        }

                        MouseArea {
                            id: tileMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: PowerManager.selectedIndex = index
                            onClicked: PowerManager.triggerAction(modelData)
                        }
                    }
                }
            }

            // B. Vista de Confirmación
            RowLayout {
                anchors.centerIn: parent
                spacing: 20
                visible: PowerManager.pendingAction !== null
                opacity: visible ? 1.0 : 0.0

                Behavior on opacity {
                    NumberAnimation { duration: 160 }
                }

                RowLayout {
                    spacing: 12
                    Text {
                        text: PowerManager.pendingAction ? PowerManager.pendingAction.icon : ""
                        font.family: Theme.iconFontFamily
                        font.pixelSize: 34
                        color: PowerManager.pendingAction ? PowerManager.pendingAction.color : Theme.text
                    }

                    Text {
                        text: PowerManager.pendingAction ? PowerManager.pendingAction.confirmTitle : ""
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                        font.bold: true
                        color: Theme.text
                    }
                }

                // Botones Cancelar y Confirmar
                RowLayout {
                    spacing: 10

                    // Botón Cancelar
                    Rectangle {
                        implicitWidth: 125
                        implicitHeight: 38
                        radius: Theme.radiusMedium
                        color: cancelMouse.containsMouse ? Theme.bgHover : Qt.rgba(Theme.bgHover.r, Theme.bgHover.g, Theme.bgHover.b, 0.4)
                        border.color: Theme.border
                        border.width: 1

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: "󰅖"
                                font.family: Theme.iconFontFamily
                                font.pixelSize: 13
                                color: Theme.subtext
                            }
                            Text {
                                text: "Cancelar"
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.bold: true
                                color: Theme.text
                            }
                        }

                        MouseArea {
                            id: cancelMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: PowerManager.cancelConfirm()
                        }
                    }

                    // Botón Confirmar
                    Rectangle {
                        implicitWidth: 140
                        implicitHeight: 38
                        radius: Theme.radiusMedium
                        readonly property color btnColor: PowerManager.pendingAction ? PowerManager.pendingAction.color : Theme.primary
                        color: confirmMouse.containsMouse
                               ? btnColor
                               : Qt.rgba(btnColor.r, btnColor.g, btnColor.b, 0.85)

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: PowerManager.pendingAction ? PowerManager.pendingAction.icon : ""
                                font.family: Theme.iconFontFamily
                                font.pixelSize: 14
                                color: Theme.bgSurface
                            }
                            Text {
                                text: "Confirmar"
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.bold: true
                                color: Theme.bgSurface
                            }
                        }

                        MouseArea {
                            id: confirmMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: PowerManager.executeAction(PowerManager.pendingAction)
                        }
                    }
                }
            }
        }
    }
}
