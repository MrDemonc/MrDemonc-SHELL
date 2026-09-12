import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Rectangle {
    id: notifIndicator

    implicitWidth: notifRow.implicitWidth + 14
    implicitHeight: 22
    radius: Theme.radiusFull
    color: notifMouse.containsMouse
           ? Theme.bgHover
           : (NotificationManager.silenced
              ? Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.15)
              : "transparent")
    border.color: NotificationManager.silenced ? Theme.warning : "transparent"
    border.width: NotificationManager.silenced ? 1 : 0

    RowLayout {
        id: notifRow
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: NotificationManager.silenced ? "󰂛" : "󰂚"
            font.family: Theme.iconFontFamily
            font.pixelSize: 13
            color: NotificationManager.silenced
                   ? Theme.warning
                   : (NotificationManager.unreadCount > 0 ? Theme.primary : Theme.text)
        }

        // Badge con número de notificaciones pendientes
        Rectangle {
            implicitWidth: Math.max(14, badgeTxt.implicitWidth + 6)
            implicitHeight: 14
            radius: Theme.radiusFull
            color: Theme.primary
            visible: NotificationManager.unreadCount > 0

            Text {
                id: badgeTxt
                anchors.centerIn: parent
                text: String(NotificationManager.unreadCount)
                font.family: Theme.fontFamily
                font.pixelSize: 9
                font.bold: true
                color: Theme.bgSurface
            }
        }
    }

    MouseArea {
        id: notifMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: NotificationManager.toggleSidebar()
    }
}
