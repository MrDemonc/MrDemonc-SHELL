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
    readonly property real cornerR: Math.min(20, Math.max(8, root.currentHeight * 0.25))
    readonly property real filletW: 16 * Math.min(1.0, root.animProgress * 1.5)
    readonly property real filletH: 12 * Math.min(1.0, root.animProgress * 1.5)

    // 1. Masa líquida fusionada con la barra (curvas cóncavas orgánicas simétricas)
    Shape {
        id: liquidBg
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.currentHeight
        layer.enabled: true
        layer.samples: 4
        visible: root.animProgress > 0.005
        opacity: root.animProgress < 0.12 ? (root.animProgress / 0.12) : 1.0
        z: 1

        // Relleno sólido que fusiona con la barra superior
        ShapePath {
            fillColor: Theme.bg
            strokeColor: "transparent"
            strokeWidth: 0

            startX: 0
            startY: 0

            // 1. Curva cóncava superior izquierda de unión con la barra
            PathCubic {
                x: root.filletW
                y: root.filletH
                control1X: root.filletW * 0.45
                control1Y: 0
                control2X: root.filletW
                control2Y: root.filletH * 0.35
            }

            // 2. Lateral izquierdo
            PathLine {
                x: root.filletW
                y: Math.max(root.filletH, root.currentHeight - root.cornerR)
            }

            // 3. Esquina inferior izquierda redonda convexa
            PathQuad {
                x: root.filletW + root.cornerR
                y: root.currentHeight
                controlX: root.filletW
                controlY: root.currentHeight
            }

            // 4. Borde inferior
            PathLine {
                x: root.width - root.filletW - root.cornerR
                y: root.currentHeight
            }

            // 5. Esquina inferior derecha redonda convexa
            PathQuad {
                x: root.width - root.filletW
                y: Math.max(root.filletH, root.currentHeight - root.cornerR)
                controlX: root.width - root.filletW
                controlY: root.currentHeight
            }

            // 6. Lateral derecho
            PathLine {
                x: root.width - root.filletW
                y: root.filletH
            }

            // 7. Curva cóncava superior derecha de unión con la barra
            PathCubic {
                x: root.width
                y: 0
                control1X: root.width - root.filletW
                control1Y: root.filletH * 0.35
                control2X: root.width - root.filletW * 0.45
                control2Y: 0
            }

            // 8. Cierre superior en la barra
            PathLine {
                x: 0
                y: 0
            }
        }
    }

    // 2. Contenedor de Vistas con intercambio instantáneo y suave a 60FPS
    Item {
        id: viewContainer
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Math.max(0, root.currentHeight - 8)
        anchors.leftMargin: Math.max(8, root.filletW)
        anchors.rightMargin: Math.max(8, root.filletW)
        anchors.topMargin: Math.max(6, root.filletH)
        anchors.bottomMargin: 8
        clip: true
        opacity: Math.max(0, (root.animProgress - 0.12) / 0.88)
        visible: opacity > 0.01
        transform: Translate {
            y: (1.0 - root.animProgress) * -10
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
