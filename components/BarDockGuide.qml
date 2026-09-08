import Quickshell
import Quickshell.Wayland
import QtQuick
import "./"

PanelWindow {
    id: dockGuideWindow

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    visible: PopoutManager.isBarDragging

    WlrLayershell.namespace: "shell-dock-guide"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    Item {
        anchors.fill: parent

        // 1. Overlay oscuro muy sutil para enfocar la acción de arrastre
        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.25
        }

        // 2. Franja de docking en el borde candidato (Arriba)
        Rectangle {
            visible: PopoutManager.candidateBarPosition === "top"
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 32
            color: Theme.primary
            opacity: 0.35
            border.color: Theme.primary
            border.width: 2
            radius: 4
        }

        // Franja de docking en el borde candidato (Abajo)
        Rectangle {
            visible: PopoutManager.candidateBarPosition === "bottom"
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 32
            color: Theme.primary
            opacity: 0.35
            border.color: Theme.primary
            border.width: 2
            radius: 4
        }

        // Franja de docking en el borde candidato (Izquierda)
        Rectangle {
            visible: PopoutManager.candidateBarPosition === "left"
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 42
            color: Theme.primary
            opacity: 0.35
            border.color: Theme.primary
            border.width: 2
            radius: 4
        }

        // Franja de docking en el borde candidato (Derecha)
        Rectangle {
            visible: PopoutManager.candidateBarPosition === "right"
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 42
            color: Theme.primary
            opacity: 0.35
            border.color: Theme.primary
            border.width: 2
            radius: 4
        }

        // 3. HUD flotante en el centro indicando la acción
        Rectangle {
            anchors.centerIn: parent
            implicitWidth: hudContent.implicitWidth + 36
            implicitHeight: 46
            radius: 12
            color: Theme.bg
            border.color: Theme.primary
            border.width: 1.5

            Row {
                id: hudContent
                anchors.centerIn: parent
                spacing: 12

                Text {
                    text: {
                        let c = PopoutManager.candidateBarPosition;
                        if (c === "top") return "󰁝";
                        if (c === "bottom") return "󰁅";
                        if (c === "left") return "󰁍";
                        if (c === "right") return "󰁔";
                        return "󰪹";
                    }
                    font.family: Theme.fontFamily
                    font.pixelSize: 20
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: {
                        let c = PopoutManager.candidateBarPosition;
                        let edgeName = c === "top" ? "Arriba" : (c === "bottom" ? "Abajo" : (c === "left" ? "Izquierda (solo iconos)" : "Derecha (solo iconos)"));
                        return "Soltar barra: " + edgeName;
                    }
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: Theme.text
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}
