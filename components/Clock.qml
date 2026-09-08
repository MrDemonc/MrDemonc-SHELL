import QtQuick
import Quickshell

Item {
    id: clockRoot
    implicitWidth: PopoutManager.isVertical ? 22 : clockText.implicitWidth
    implicitHeight: PopoutManager.isVertical ? 22 : clockText.implicitHeight

    Text {
        id: clockText
        anchors.centerIn: parent
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: PopoutManager.isVertical ? 13 : 11
        font.bold: false
        text: PopoutManager.isVertical ? "󰥔" : ""
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (PopoutManager.isVertical) {
                clockText.text = "󰥔";
            } else {
                let now = new Date();
                let hours = String(now.getHours()).padStart(2, '0');
                let minutes = String(now.getMinutes()).padStart(2, '0');
                let dateStr = Qt.formatDate(now, "ddd d MMM");
                clockText.text = `${dateStr}  ${hours}:${minutes}`;
            }
        }
    }
}
