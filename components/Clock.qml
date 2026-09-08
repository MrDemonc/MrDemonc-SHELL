import QtQuick
import Quickshell

Item {
    id: clockRoot
    property string hoursStr: "00"
    property string minutesStr: "00"
    property string fullDateStr: ""

    implicitWidth: PopoutManager.isVertical ? 22 : horizontalText.implicitWidth
    implicitHeight: PopoutManager.isVertical ? verticalCol.implicitHeight : horizontalText.implicitHeight

    // 1. Reloj en formato horizontal
    Text {
        id: horizontalText
        visible: !PopoutManager.isVertical
        anchors.centerIn: parent
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: 11
        font.bold: false
        text: fullDateStr
    }

    // 2. Reloj en formato vertical para laterales (HH arriba, MM abajo)
    Column {
        id: verticalCol
        visible: PopoutManager.isVertical
        anchors.centerIn: parent
        spacing: -1

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 10
            font.weight: Font.DemiBold
            text: clockRoot.hoursStr
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            color: Theme.subtext
            font.family: Theme.fontFamily
            font.pixelSize: 10
            font.weight: Font.Medium
            text: clockRoot.minutesStr
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
