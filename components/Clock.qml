import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: clockRoot
    property string hoursStr: "00"
    property string minutesStr: "00"
    property string fullDateStr: ""

    implicitWidth: PopoutManager.isVertical ? 22 : horizontalRow.implicitWidth
    width: implicitWidth
    implicitHeight: PopoutManager.isVertical ? verticalCol.implicitHeight : 22
    height: implicitHeight

    // 1. Reloj en formato horizontal con píldora de grabación y taza de café
    RowLayout {
        id: horizontalRow
        visible: !PopoutManager.isVertical
        anchors.centerIn: parent
        spacing: 6

        // Píldora de Grabación en vivo (si se está grabando)
        Rectangle {
            id: recPillHorizontal
            visible: ScreenRecordManager.isRecording
            implicitHeight: 20
            implicitWidth: recRow.implicitWidth + 12
            radius: 10
            color: "#2a1215"
            border.color: "#ef4444"
            border.width: 1
            Layout.alignment: Qt.AlignVCenter

            RowLayout {
                id: recRow
                anchors.centerIn: parent
                spacing: 4

                Text {
                    font.family: Theme.iconFontFamily
                    font.pixelSize: 11
                    color: "#ef4444"
                    text: "󰑋"

                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        running: ScreenRecordManager.isRecording
                        NumberAnimation { from: 1.0; to: 0.2; duration: 500; easing.type: Easing.InOutQuad }
                        NumberAnimation { from: 0.2; to: 1.0; duration: 500; easing.type: Easing.InOutQuad }
                    }
                }

                Text {
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.bold: true
                    color: "#f87171"
                    text: ScreenRecordManager.recordTimeFormatted
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: ScreenRecordManager.stopRecording()
            }
        }

        Text {
            id: horizontalText
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 11
            font.bold: false
            text: clockRoot.fullDateStr
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            id: coffeeIconHorizontal
            visible: CaffeineManager.isActive
            color: Theme.warning
            font.family: Theme.iconFontFamily
            font.pixelSize: 13
            text: "󰅶"
            Layout.alignment: Qt.AlignVCenter
        }
    }

    // 2. Reloj en formato vertical para laterales (HH arriba, MM abajo, Cafeína abajo, Grabación)
    ColumnLayout {
        id: verticalCol
        visible: PopoutManager.isVertical
        anchors.centerIn: parent
        spacing: 2

        Text {
            id: recIconVertical
            visible: ScreenRecordManager.isRecording
            color: "#ef4444"
            font.family: Theme.iconFontFamily
            font.pixelSize: 13
            text: "󰑋"
            Layout.alignment: Qt.AlignHCenter

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: ScreenRecordManager.isRecording
                NumberAnimation { from: 1.0; to: 0.2; duration: 500; easing.type: Easing.InOutQuad }
                NumberAnimation { from: 0.2; to: 1.0; duration: 500; easing.type: Easing.InOutQuad }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: ScreenRecordManager.stopRecording()
            }
        }

        Text {
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 10
            font.weight: Font.DemiBold
            text: clockRoot.hoursStr
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            color: Theme.subtext
            font.family: Theme.fontFamily
            font.pixelSize: 10
            font.weight: Font.Medium
            text: clockRoot.minutesStr
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            id: coffeeIconVertical
            visible: CaffeineManager.isActive
            color: Theme.warning
            font.family: Theme.iconFontFamily
            font.pixelSize: 12
            text: "󰅶"
            Layout.alignment: Qt.AlignHCenter
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            let now = new Date();
            clockRoot.hoursStr = String(now.getHours()).padStart(2, '0');
            clockRoot.minutesStr = String(now.getMinutes()).padStart(2, '0');
            let dateStr = Qt.formatDate(now, "ddd d MMM");
            clockRoot.fullDateStr = `${dateStr}  ${clockRoot.hoursStr}:${clockRoot.minutesStr}`;
        }
    }
}
