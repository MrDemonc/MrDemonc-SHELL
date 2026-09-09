import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: popoutWindow

    anchors {
        top: PopoutManager.barPosition !== "bottom"
        bottom: PopoutManager.barPosition === "bottom"
        left: PopoutManager.barPosition !== "right"
        right: PopoutManager.barPosition === "right"
    }
    margins {
        top: {
            if (PopoutManager.barPosition === "top") return 26;
            if (PopoutManager.barPosition === "bottom") return 0;
            let screenH = popoutWindow.screen ? popoutWindow.screen.height : 800;
            return Math.max(10, Math.min(screenH - popout.preferredHeight - 10, PopoutManager.popoutCenter - popout.preferredHeight / 2));
        }
        bottom: PopoutManager.barPosition === "bottom" ? 26 : 0
        left: {
            if (PopoutManager.barPosition === "left") return 26;
            if (PopoutManager.barPosition === "right") return 0;
            let screenW = popoutWindow.screen ? popoutWindow.screen.width : 1280;
            if (PopoutManager.popoutCenter > 0) {
                return Math.max(10, Math.min(screenW - 330, PopoutManager.popoutCenter - 160));
            }
            return Math.max(10, screenW - 330);
        }
        right: PopoutManager.barPosition === "right" ? 26 : 0
    }
    implicitWidth: 320
    implicitHeight: popout.preferredHeight

    Behavior on margins.left {
        enabled: !PopoutManager.isVertical && PopoutManager.hasPopout && popout.animProgress > 0.05
        NumberAnimation {
            duration: Theme.anim.fastSpatial
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.anim.expressiveDefaultSpatial
        }
    }

    Behavior on margins.top {
        enabled: PopoutManager.isVertical && PopoutManager.hasPopout && popout.animProgress > 0.05
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
