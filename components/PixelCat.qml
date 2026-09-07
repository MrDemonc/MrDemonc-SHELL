import QtQuick
import QtQuick.Layouts

Item {
    id: root
    implicitWidth: 80
    implicitHeight: 48

    property int frame: 0
    property string statusText: "purr..."

    Timer {
        interval: 600
        running: true
        repeat: true
        onTriggered: {
            root.frame = (root.frame + 1) % 4;
            if (root.frame === 0) root.statusText = "purr...";
            else if (root.frame === 1) root.statusText = "zZz...";
            else if (root.frame === 2) root.statusText = "=^.^=";
            else root.statusText = "♥ nya";
        }
    }

    Canvas {
        id: pixelCanvas
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 36
        height: 36

        readonly property var catFrame0: [
            "  #     #   ",
            " ###   ###  ",
            "##### ##### ",
            " #########  ",
            " # #   # #  ",
            " #########  ",
            "  #######   ",
            " #########  ",
            "########### ",
            "########### ",
            " #   # #  # ",
            " ##  # ## # "
        ]

        readonly property var catFrame1: [
            "  #     #   ",
            " ###   ###  ",
            "##### ##### ",
            " #########  ",
            " - -   - -  ",
            " #########  ",
            "  #######   ",
            " #########  ",
            "########### ",
            "########### ",
            " #   # #  # ",
            " ##  # ## # "
        ]

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            var map = (root.frame % 2 === 0) ? catFrame0 : catFrame1;
            var pixelSize = 3;

            for (var r = 0; r < map.length; r++) {
                var row = map[r];
                for (var c = 0; c < row.length; c++) {
                    var ch = row[c];
                    if (ch === '#') {
                        ctx.fillStyle = "#fab387";
                        ctx.fillRect(c * pixelSize, r * pixelSize, pixelSize, pixelSize);
                    } else if (ch === '-') {
                        ctx.fillStyle = Theme.isDark ? "#11111b" : "#4c4f69";
                        ctx.fillRect(c * pixelSize, r * pixelSize, pixelSize, pixelSize);
                    }
                }
            }
        }

        Connections {
            target: root
            function onFrameChanged() {
                pixelCanvas.requestPaint();
            }
        }
    }

    Text {
        anchors.left: pixelCanvas.right
        anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        text: root.statusText
        color: Theme.pink
        font.family: Theme.fontFamily
        font.pixelSize: 10
        font.bold: false
    }
}
