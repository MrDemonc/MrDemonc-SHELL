import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: scrimWindow

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    margins {
        top: PopoutManager.barPosition === "top" ? 26 : 0
        bottom: PopoutManager.barPosition === "bottom" ? 26 : 0
        left: PopoutManager.barPosition === "left" ? 26 : 0
        right: PopoutManager.barPosition === "right" ? 26 : 0
    }

    color: "transparent"

    WlrLayershell.namespace: "shell-popout-scrim"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    visible: PopoutManager.hasPopout

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onPressed: {
            PopoutManager.close();
        }
    }
}
