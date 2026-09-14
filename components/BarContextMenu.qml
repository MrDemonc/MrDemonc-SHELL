import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "./"

PanelWindow {
    id: barMenuWindow

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    WlrLayershell.namespace: "shell-bar-context-menu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    visible: PopoutManager.barMenuOpen || menuCard.opacity > 0.01

    // Cerrar al hacer clic fuera
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onPressed: {
            PopoutManager.closeBarMenu();
        }
    }

    Rectangle {
        id: menuCard
        width: 190
        height: cardCol.implicitHeight + 16
        radius: Theme.radiusSmall
        color: Theme.bgSurface
        border.color: Theme.border
        border.width: 1

        property real screenW: barMenuWindow.screen ? barMenuWindow.screen.width : 1280
        property real screenH: barMenuWindow.screen ? barMenuWindow.screen.height : 800

        x: Math.max(10, Math.min(screenW - width - 10, PopoutManager.barMenuX - (width / 2)))
        y: Math.max(10, Math.min(screenH - height - 10, PopoutManager.barMenuY))

        opacity: PopoutManager.barMenuOpen ? 1.0 : 0.0
        scale: PopoutManager.barMenuOpen ? 1.0 : 0.95

        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }
        Behavior on scale {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        ColumnLayout {
            id: cardCol
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4

            Text {
                text: "Posición de la barra"
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.weight: Font.Bold
                color: Theme.overlay
                Layout.leftMargin: 8
                Layout.bottomMargin: 4
            }

            Repeater {
                model: [
                    { id: "top", label: "Arriba", icon: "󰁝" },
                    { id: "bottom", label: "Abajo", icon: "󰁅" },
                    { id: "left", label: "Izquierda", icon: "󰁍" },
                    { id: "right", label: "Derecha", icon: "󰁔" }
                ]

                delegate: Rectangle {
                    id: itemBtn
                    Layout.fillWidth: true
                    height: 28
                    radius: 6
                    readonly property bool isCurrent: PopoutManager.barPosition === modelData.id
                    readonly property bool isHovered: itemMouse.containsMouse

                    color: isHovered ? Theme.bgHover : (isCurrent ? Theme.bgSurface : "transparent")

                    Behavior on color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        Text {
                            text: modelData.icon
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            color: itemBtn.isCurrent ? Theme.primary : Theme.text
                        }

                        Text {
                            text: modelData.label
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: itemBtn.isCurrent ? Font.Bold : Font.Normal
                            color: itemBtn.isCurrent ? Theme.primary : Theme.text
                            Layout.fillWidth: true
                        }

                        Text {
                            visible: itemBtn.isCurrent
                            text: "●"
                            font.pixelSize: 8
                            color: Theme.primary
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            PopoutManager.setBarPosition(modelData.id);
                            PopoutManager.closeBarMenu();
                        }
                    }
                }
            }
        }
    }
}
