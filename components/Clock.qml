import QtQuick
import Quickshell

Text {
    id: clockText
    color: Theme.text
    font.family: Theme.fontFamily
    font.pixelSize: 11
    font.bold: false

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            let now = new Date();
            let hours = String(now.getHours()).padStart(2, '0');
            let minutes = String(now.getMinutes()).padStart(2, '0');
            let dateStr = Qt.formatDate(now, "ddd d MMM");
            clockText.text = `${dateStr}  ${hours}:${minutes}`;
        }
    }
}
