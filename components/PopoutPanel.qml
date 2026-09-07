import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: popoutWindow

    anchors {
        top: true
        left: true
    }
    margins {
        top: 26
        left: {
            if (PopoutManager.popoutCenter > 0) {
                return Math.max(10, Math.min((popoutWindow.screen ? popoutWindow.screen.width : 1920) - 330, PopoutManager.popoutCenter - 160));
            }
            return Math.max(10, (popoutWindow.screen ? popoutWindow.screen.width : 1920) - 330);
        }
    }
    implicitWidth: 320
    implicitHeight: popout.preferredHeight

    Behavior on margins.left {
        enabled: PopoutManager.hasPopout && popout.animProgress > 0.05
        NumberAnimation {
            duration: Theme.anim.fastSpatial
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.anim.expressiveDefaultSpatial
        }
    }

    Behavior on implicitHeight {
        enabled: popout.animProgress > 0.05
        NumberAnimation {
            duration: Theme.anim.fastSpatial
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.anim.expressiveDefaultSpatial
        }
    }

    color: "transparent"

    WlrLayershell.namespace: "shell-popout"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    visible: PopoutManager.hasPopout || popout.animProgress > 0.001

    LiquidPopout {
        id: popout
        anchors.fill: parent
        batteryRef: batService
        networkRef: netService
        bluetoothRef: btService
        audioRef: audioService
    }

    Item {
        visible: false
        AudioIndicator { id: audioService }
        BluetoothIndicator { id: btService }
        NetworkIndicator { id: netService }
        BatteryIndicator { id: batService }
    }
}
