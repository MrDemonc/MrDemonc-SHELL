import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: clockRoot
    property string hoursStr: "00"
    property string minutesStr: "00"
    property string fullDateStr: ""

    implicitWidth: PopoutManager.isVertical ? 22 : (horizontalText.implicitWidth + (CaffeineManager.isActive ? 22 : 0))
    width: implicitWidth
    implicitHeight: PopoutManager.isVertical ? (verticalCol.implicitHeight + (CaffeineManager.isActive ? 16 : 0)) : 22
    height: implicitHeight

    // 1. Reloj en formato horizontal con taza de café a la derecha si modo cafeína está activo
    RowLayout {
        id: horizontalRow
        visible: !PopoutManager.isVertical
        anchors.centerIn: parent
        spacing: 6

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

    // 2. Reloj en formato vertical para laterales (HH arriba, MM abajo, Cafeína abajo)
    ColumnLayout {
        id: verticalCol
        visible: PopoutManager.isVertical
        anchors.centerIn: parent
        spacing: 1

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
