import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property var batteryRef: null
    property var networkRef: null
    property var bluetoothRef: null
    property var audioRef: null

    readonly property string effectiveTab: PopoutManager.activePopout !== "" ? PopoutManager.activePopout : (PopoutManager.lastActivePopout !== "" ? PopoutManager.lastActivePopout : "battery")
    readonly property bool isOpen: PopoutManager.hasPopout

    readonly property Item activeChildItem: {
        if (effectiveTab === "battery") return batteryComp;
        if (effectiveTab === "wifi") return wifiComp;
        if (effectiveTab === "bluetooth") return btComp;
        if (effectiveTab === "audio") return audioComp;
        if (effectiveTab === "theme") return themeComp;
        return null;
    }

    readonly property real preferredHeight: {
        if (activeChildItem && activeChildItem.implicitHeight > 0) {
            return activeChildItem.implicitHeight + 20;
        }
        if (effectiveTab === "audio") return 260;
        if (effectiveTab === "battery") return 270;
        if (effectiveTab === "wifi") return 320;
        if (effectiveTab === "bluetooth") return 300;
        if (effectiveTab === "theme") return 280;
        return 280;
    }

    anchors.fill: parent

    // Animación fluida con tokens espaciales de Caelestia
    property real animProgress: isOpen ? 1.0 : 0.0
    Behavior on animProgress {
        NumberAnimation {
            duration: root.isOpen ? Theme.anim.fastSpatial : Theme.anim.closeSpatial
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.isOpen
                ? Theme.anim.expressiveFastSpatial
                : Theme.anim.emphasizedAccel
        }
    }

    // Parámetros calculados de la curvatura líquida continua
    readonly property real currentHeight: Math.max(12, root.preferredHeight * root.animProgress)
    readonly property real currentWidth: Math.max(12, root.width * root.animProgress)
    readonly property real cornerR: {
        if (PopoutManager.isVertical) return Math.min(20, Math.max(8, root.currentWidth * 0.25));
        return Math.min(20, Math.max(8, root.currentHeight * 0.25));
    }
    readonly property real filletW: (PopoutManager.isVertical ? 12 : 16) * Math.min(1.0, root.animProgress * 1.5)
    readonly property real filletH: (PopoutManager.isVertical ? 16 : 12) * Math.min(1.0, root.animProgress * 1.5)

    // 1. Masa líquida fusionada con la barra (curvas cóncavas orgánicas adaptativas según posición)
    Item {
        id: liquidBgContainer
        anchors.fill: parent
        visible: root.animProgress > 0.005
        opacity: root.animProgress < 0.12 ? (root.animProgress / 0.12) : 1.0
        z: 1

        // A. TOP (Nace de la barra superior hacia abajo)
        Shape {
            visible: PopoutManager.barPosition === "top"
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: root.currentHeight
            layer.enabled: true
            layer.samples: 4

            ShapePath {
                fillColor: Theme.bg
                strokeColor: "transparent"
                strokeWidth: 0
                startX: 0
                startY: 0
                PathCubic {
                    x: root.filletW
                    y: root.filletH
                    control1X: root.filletW * 0.45
                    control1Y: 0
                    control2X: root.filletW
                    control2Y: root.filletH * 0.35
                }
                PathLine {
                    x: root.filletW
                    y: Math.max(root.filletH, root.currentHeight - root.cornerR)
                }
                PathQuad {
                    x: root.filletW + root.cornerR
                    y: root.currentHeight
                    controlX: root.filletW
                    controlY: root.currentHeight
                }
                PathLine {
                    x: root.width - root.filletW - root.cornerR
                    y: root.currentHeight
                }
                PathQuad {
                    x: root.width - root.filletW
                    y: Math.max(root.filletH, root.currentHeight - root.cornerR)
                    controlX: root.width - root.filletW
                    controlY: root.currentHeight
                }
                PathLine {
                    x: root.width - root.filletW
                    y: root.filletH
                }
                PathCubic {
                    x: root.width
                    y: 0
                    control1X: root.width - root.filletW
                    control1Y: root.filletH * 0.35
                    control2X: root.width - root.filletW * 0.45
                    control2Y: 0
                }
                PathLine {
                    x: 0
                    y: 0
                }
            }
        }

        // B. BOTTOM (Nace de la barra inferior hacia arriba)
        Shape {
            visible: PopoutManager.barPosition === "bottom"
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: root.currentHeight
            layer.enabled: true
            layer.samples: 4

            ShapePath {
                fillColor: Theme.bg
                strokeColor: "transparent"
                strokeWidth: 0
                startX: 0
                startY: root.currentHeight
                PathCubic {
                    x: root.filletW
                    y: root.currentHeight - root.filletH
                    control1X: root.filletW * 0.45
                    control1Y: root.currentHeight
                    control2X: root.filletW
                    control2Y: root.currentHeight - root.filletH * 0.35
                }
                PathLine {
                    x: root.filletW
                    y: Math.min(root.currentHeight - root.filletH, root.cornerR)
                }
                PathQuad {
                    x: root.filletW + root.cornerR
                    y: 0
                    controlX: root.filletW
                    controlY: 0
                }
                PathLine {
                    x: root.width - root.filletW - root.cornerR
                    y: 0
                }
                PathQuad {
                    x: root.width - root.filletW
                    y: Math.min(root.currentHeight - root.filletH, root.cornerR)
                    controlX: root.width - root.filletW
                    controlY: 0
                }
                PathLine {
                    x: root.width - root.filletW
                    y: root.currentHeight - root.filletH
                }
                PathCubic {
                    x: root.width
                    y: root.currentHeight
                    control1X: root.width - root.filletW
                    control1Y: root.currentHeight - root.filletH * 0.35
                    control2X: root.width - root.filletW * 0.45
                    control2Y: root.currentHeight
                }
                PathLine {
                    x: 0
                    y: root.currentHeight
                }
            }
        }

        // C. LEFT (Nace de la barra izquierda hacia la derecha)
        Shape {
            visible: PopoutManager.barPosition === "left"
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: root.currentWidth
            layer.enabled: true
            layer.samples: 4

            ShapePath {
                fillColor: Theme.bg
                strokeColor: "transparent"
                strokeWidth: 0
                startX: 0
                startY: 0
                PathCubic {
                    x: root.filletW
                    y: root.filletH
                    control1X: 0
                    control1Y: root.filletH * 0.45
                    control2X: root.filletW * 0.35
                    control2Y: root.filletH
                }
                PathLine {
                    x: Math.max(root.filletW, root.currentWidth - root.cornerR)
                    y: root.filletH
                }
                PathQuad {
                    x: root.currentWidth
                    y: root.filletH + root.cornerR
                    controlX: root.currentWidth
                    controlY: root.filletH
                }
                PathLine {
                    x: root.currentWidth
                    y: Math.max(root.filletH + root.cornerR, root.preferredHeight - root.filletH - root.cornerR)
                }
                PathQuad {
                    x: Math.max(root.filletW, root.currentWidth - root.cornerR)
                    y: root.preferredHeight - root.filletH
                    controlX: root.currentWidth
                    controlY: root.preferredHeight - root.filletH
                }
                PathLine {
                    x: root.filletW
                    y: root.preferredHeight - root.filletH
                }
                PathCubic {
                    x: 0
                    y: root.preferredHeight
                    control1X: root.filletW * 0.35
                    control1Y: root.preferredHeight - root.filletH
                    control2X: 0
                    control2Y: root.preferredHeight - root.filletH * 0.45
                }
                PathLine {
                    x: 0
                    y: 0
                }
            }
        }

        // D. RIGHT (Nace de la barra derecha hacia la izquierda)
        Shape {
            visible: PopoutManager.barPosition === "right"
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: root.currentWidth
            layer.enabled: true
            layer.samples: 4

            ShapePath {
                fillColor: Theme.bg
                strokeColor: "transparent"
                strokeWidth: 0
                startX: root.currentWidth
                startY: 0
                PathCubic {
                    x: root.currentWidth - root.filletW
                    y: root.filletH
                    control1X: root.currentWidth
                    control1Y: root.filletH * 0.45
                    control2X: root.currentWidth - root.filletW * 0.35
                    control2Y: root.filletH
                }
                PathLine {
                    x: Math.min(root.currentWidth - root.filletW, root.cornerR)
                    y: root.filletH
                }
                PathQuad {
                    x: 0
                    y: root.filletH + root.cornerR
                    controlX: 0
                    controlY: root.filletH
                }
                PathLine {
                    x: 0
                    y: Math.max(root.filletH + root.cornerR, root.preferredHeight - root.filletH - root.cornerR)
                }
                PathQuad {
                    x: Math.min(root.currentWidth - root.filletW, root.cornerR)
                    y: root.preferredHeight - root.filletH
                    controlX: 0
                    controlY: root.preferredHeight - root.filletH
                }
                PathLine {
                    x: root.currentWidth - root.filletW
                    y: root.preferredHeight - root.filletH
                }
                PathCubic {
                    x: root.currentWidth
                    y: root.preferredHeight
                    control1X: root.currentWidth - root.filletW * 0.35
                    control1Y: root.preferredHeight - root.filletH
                    control2X: root.currentWidth
                    control2Y: root.preferredHeight - root.filletH * 0.45
                }
                PathLine {
                    x: root.currentWidth
                    y: 0
                }
            }
        }
    }

    // 2. Contenedor de Vistas con intercambio instantáneo y suave a 60FPS
    Item {
        id: viewContainer
        anchors.fill: parent
        anchors.topMargin: {
            if (PopoutManager.barPosition === "top") return Math.max(6, root.filletH);
            if (PopoutManager.barPosition === "bottom") return 8;
            return Math.max(8, root.filletH);
        }
        anchors.bottomMargin: {
            if (PopoutManager.barPosition === "bottom") return Math.max(6, root.filletH);
            if (PopoutManager.barPosition === "top") return 8;
            return Math.max(8, root.filletH);
        }
        anchors.leftMargin: {
            if (PopoutManager.barPosition === "left") return Math.max(6, root.filletW);
            if (PopoutManager.barPosition === "right") return 8;
            return Math.max(8, root.filletW);
        }
        anchors.rightMargin: {
            if (PopoutManager.barPosition === "right") return Math.max(6, root.filletW);
            if (PopoutManager.barPosition === "left") return 8;
            return Math.max(8, root.filletW);
        }
        clip: true
        opacity: Math.max(0, (root.animProgress - 0.12) / 0.88)
        visible: opacity > 0.01
        transform: Translate {
            x: {
                if (PopoutManager.barPosition === "left") return (1.0 - root.animProgress) * -10;
                if (PopoutManager.barPosition === "right") return (1.0 - root.animProgress) * 10;
                return 0;
            }
            y: {
                if (PopoutManager.barPosition === "top") return (1.0 - root.animProgress) * -10;
                if (PopoutManager.barPosition === "bottom") return (1.0 - root.animProgress) * 10;
                return 0;
            }
        }
        z: 5

        // 1. Batería
        Item {
            id: batteryView
            anchors.fill: parent
            visible: opacity > 0.01
            opacity: (root.effectiveTab === "battery" && root.isOpen) ? 1.0 : 0.0
            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.anim.fastEffects
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.anim.expressiveFastEffects
                }
            }
            BatteryPopout {
                id: batteryComp
                batteryRef: root.batteryRef
                anchors.fill: parent
            }
        }

        // 2. Wi-Fi
        Item {
            id: wifiView
            anchors.fill: parent
            visible: opacity > 0.01
            opacity: (root.effectiveTab === "wifi" && root.isOpen) ? 1.0 : 0.0
            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.anim.fastEffects
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.anim.expressiveFastEffects
                }
            }
            WifiPopout {
                id: wifiComp
                networkRef: root.networkRef
                anchors.fill: parent
            }
        }

        // 3. Bluetooth
        Item {
            id: btView
            anchors.fill: parent
            visible: opacity > 0.01
            opacity: (root.effectiveTab === "bluetooth" && root.isOpen) ? 1.0 : 0.0
            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.anim.fastEffects
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.anim.expressiveFastEffects
                }
            }
            BluetoothPopout {
                id: btComp
                bluetoothRef: root.bluetoothRef
                anchors.fill: parent
            }
        }

        // 4. Audio
        Item {
            id: audioView
            anchors.fill: parent
            visible: opacity > 0.01
            opacity: (root.effectiveTab === "audio" && root.isOpen) ? 1.0 : 0.0
            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.anim.fastEffects
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.anim.expressiveFastEffects
                }
            }
            AudioPopout {
                id: audioComp
                audioRef: root.audioRef
                anchors.fill: parent
            }
        }

        // 5. Temas
        Item {
            id: themeView
            anchors.fill: parent
            visible: opacity > 0.01
            opacity: (root.effectiveTab === "theme" && root.isOpen) ? 1.0 : 0.0
            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.anim.fastEffects
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.anim.expressiveFastEffects
                }
            }
            ThemePopout {
                id: themeComp
                anchors.fill: parent
            }
        }
    }

}
