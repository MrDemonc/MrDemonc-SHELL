import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: wallWindow

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "#0a0a0f"

    WlrLayershell.namespace: "shell-wallpaper"
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    property string targetPath: WallpaperManager.currentWallpaper
    property string activeLayer: "A"

    onTargetPathChanged: {
        if (!targetPath) return;
        let fileUrl = "file://" + targetPath;

        if (activeLayer === "A") {
            if (imageA.source.toString() !== fileUrl) {
                imageB.source = fileUrl;
                activeLayer = "B";
            }
        } else {
            if (imageB.source.toString() !== fileUrl) {
                imageA.source = fileUrl;
                activeLayer = "A";
            }
        }
    }

    Component.onCompleted: {
        if (targetPath) {
            imageA.source = "file://" + targetPath;
            activeLayer = "A";
        }
    }

    // Capa A
    Image {
        id: imageA
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        cache: false
        smooth: true

        opacity: wallWindow.activeLayer === "A" ? 1.0 : 0.0
        scale: wallWindow.activeLayer === "A" ? 1.0 : 1.05

        Behavior on opacity {
            NumberAnimation {
                duration: 650
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.anim.expressiveSlowSpatial
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 750
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.anim.expressiveSlowSpatial
            }
        }
    }

    // Capa B (para crossfade y zoom cinemático elegante)
    Image {
        id: imageB
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        cache: false
        smooth: true

        opacity: wallWindow.activeLayer === "B" ? 1.0 : 0.0
        scale: wallWindow.activeLayer === "B" ? 1.0 : 1.05

        Behavior on opacity {
            NumberAnimation {
                duration: 650
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.anim.expressiveSlowSpatial
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 750
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.anim.expressiveSlowSpatial
            }
        }
    }
}
