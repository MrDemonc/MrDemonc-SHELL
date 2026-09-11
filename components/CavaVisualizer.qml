import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: cavaRoot

    property var barValues: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    property bool isPlaying: false

    readonly property bool isVertical: PopoutManager.isVertical

    implicitWidth: isVertical ? 22 : (isPlaying ? 46 : 0)
    implicitHeight: isVertical ? (isPlaying ? 46 : 0) : 24
    clip: true

    visible: opacity > 0.01
    opacity: isPlaying ? 1.0 : 0.0

    Behavior on opacity {
        NumberAnimation { duration: 250 }
    }
    Behavior on implicitWidth {
        NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
    }
    Behavior on implicitHeight {
        NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
    }

    // Proceso demonio de audio Cava
    Process {
        id: cavaStreamProc
        command: [Quickshell.shellDir + "/scripts/cava_stream.py"]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                try {
                    let str = String(line).trim();
                    if (str.length > 0 && str.startsWith("{")) {
                        let parsed = JSON.parse(str);
                        cavaRoot.isPlaying = !!parsed.playing;
                        if (parsed.bars && parsed.bars.length > 0) {
                            cavaRoot.barValues = parsed.bars;
                        }
                    }
                } catch (e) {}
            }
        }
    }

    // -------------------------------------------------------------------------
    // 1. MODO HORIZONTAL (Barra en Top o Bottom)
    // Barras verticales en fila (la altura fluctúa con el ritmo)
    // -------------------------------------------------------------------------
    Row {
        anchors.centerIn: parent
        visible: !cavaRoot.isVertical
        spacing: 2

        Repeater {
            model: 8
            delegate: Rectangle {
                required property int index
                readonly property real v: (cavaRoot.barValues && cavaRoot.barValues[index]) ? cavaRoot.barValues[index] : 0.0
                width: 3
                height: Math.max(3, Math.min(16, 16 * v))
                radius: 1.5
                color: Theme.primary
                anchors.verticalCenter: parent ? parent.verticalCenter : undefined

                Behavior on height {
                    NumberAnimation { duration: 55 }
                }
            }
        }
    }

    // -------------------------------------------------------------------------
    // 2. MODO VERTICAL (Barra en Lateral Izquierdo o Derecho)
    // Barras horizontales en columna (el ancho fluctúa con el ritmo)
    // -------------------------------------------------------------------------
    Column {
        anchors.centerIn: parent
        visible: cavaRoot.isVertical
        spacing: 2

        Repeater {
            model: 8
            delegate: Rectangle {
                required property int index
                readonly property real v: (cavaRoot.barValues && cavaRoot.barValues[index]) ? cavaRoot.barValues[index] : 0.0
                height: 2.5
                width: Math.max(3, Math.min(16, 16 * v))
                radius: 1.25
                color: Theme.primary
                anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined

                Behavior on width {
                    NumberAnimation { duration: 55 }
                }
            }
        }
    }

    // Clic para alternar reproducción (Play/Pause)
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            togglePlayProc.command = ["playerctl", "play-pause"];
            togglePlayProc.running = true;
        }
    }
    Process { id: togglePlayProc }
}
