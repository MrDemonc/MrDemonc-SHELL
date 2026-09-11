import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "./components"

PanelWindow {
    id: win

    WlrLayershell.namespace: "shell-screenshot"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    function closeApp() {
        Quickshell.execDetached(["kill", "-9", String(Quickshell.processId)]);
    }

    function takeShot(mode) {
        Quickshell.execDetached([
            "bash",
            "-c",
            "command -v shell-screenshot >/dev/null 2>&1 && exec shell-screenshot \"" + mode + "\" || exec bash \"" + Quickshell.shellDir + "/../../scripts/take_screenshot.sh\" \"" + mode + "\""
        ]);
        closeApp();
    }

    // Atajos globales de teclado
    Item {
        anchors.fill: parent
        focus: true

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape || event.key === Qt.Key_Q) {
                closeApp();
                event.accepted = true;
            } else if (event.key === Qt.Key_1 || event.key === Qt.Key_F || event.key === Qt.Key_Return) {
                takeShot("full");
                event.accepted = true;
            } else if (event.key === Qt.Key_2 || event.key === Qt.Key_A || event.key === Qt.Key_Space) {
                takeShot("area");
                event.accepted = true;
            }
        }
    }

    // Clic fuera de la píldora para cerrar
    MouseArea {
        anchors.fill: parent
        onClicked: closeApp()
    }

    // Píldora flotante minimalista centrada
    Rectangle {
        id: pill
        anchors.centerIn: parent
        implicitWidth: 280
        implicitHeight: 46
        radius: 23
        color: Theme.bgSurface
        border.color: Theme.border
        border.width: 1

        // Prevenir que clics dentro de la píldora cierren el selector
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: 8

            // Opción 1: Pantalla Completa (1 / F / Enter)
            Rectangle {
                implicitWidth: 124
                implicitHeight: 32
                radius: 16
                color: fullHover.containsMouse ? Theme.bgHover : "transparent"
                border.color: fullHover.containsMouse ? Theme.primary : "transparent"
                border.width: 1
                Behavior on color { ColorAnimation { duration: 120 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        text: "󰹑"
                        color: fullHover.containsMouse ? Theme.primary : Theme.text
                        font.family: Theme.iconFontFamily
                        font.pixelSize: 13
                    }
                    Text {
                        text: "Completa (1)"
                        color: fullHover.containsMouse ? Theme.primary : Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                    }
                }

                MouseArea {
                    id: fullHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: takeShot("full")
                }
            }

            // Separador vertical
            Rectangle {
                implicitWidth: 1
                implicitHeight: 18
                color: Theme.border
            }

            // Opción 2: Seleccionar Área (2 / A / Espacio)
            Rectangle {
                implicitWidth: 124
                implicitHeight: 32
                radius: 16
                color: areaHover.containsMouse ? Theme.bgHover : "transparent"
                border.color: areaHover.containsMouse ? Theme.primary : "transparent"
                border.width: 1
                Behavior on color { ColorAnimation { duration: 120 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        text: "󰩭"
                        color: areaHover.containsMouse ? Theme.primary : Theme.text
                        font.family: Theme.iconFontFamily
                        font.pixelSize: 13
                    }
                    Text {
                        text: "Área (2)"
                        color: areaHover.containsMouse ? Theme.primary : Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                    }
                }

                MouseArea {
                    id: areaHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: takeShot("area")
                }
            }
        }
    }
}
