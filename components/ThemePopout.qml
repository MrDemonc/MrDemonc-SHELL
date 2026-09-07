import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    implicitWidth: 320
    implicitHeight: layout.implicitHeight + 20

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "󰔎  TEMAS Y APARIENCIA"
                color: Theme.primary
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            Text {
                text: Theme.isDark ? "󰖔 Oscuro" : "󰖙 Claro"
                color: Theme.overlay
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }
        }

        // Separador
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Theme.border
        }

        // Grid de temas
        ListView {
            id: themeListView
            Layout.fillWidth: true
            implicitHeight: Math.min(220, count * 36)
            clip: true
            spacing: 4
            model: Theme.availableThemes

            delegate: Rectangle {
                required property var modelData
                width: themeListView.width
                implicitHeight: 32
                radius: 7
                color: modelData.isCurrent ? Theme.bgHover : (itemMouse.containsMouse ? Theme.bgSurface : "transparent")
                border.color: modelData.isCurrent ? Theme.primary : "transparent"
                border.width: 1

                Behavior on color { ColorAnimation { duration: 120 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8

                    // Muestra de color de fondo y acento
                    Rectangle {
                        implicitWidth: 16
                        implicitHeight: 16
                        radius: 8
                        color: modelData.bg || "#1e1e2e"
                        border.color: Theme.border
                        border.width: 1

                        Rectangle {
                            anchors.centerIn: parent
                            implicitWidth: 8
                            implicitHeight: 8
                            radius: 4
                            color: modelData.primary || "#89b4fa"
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData.name || modelData.id
                        color: modelData.isCurrent ? Theme.primary : Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.bold: modelData.isCurrent
                        elide: Text.ElideRight
                    }

                    Text {
                        text: modelData.isDark ? "󰖔" : "󰖙"
                        color: Theme.overlay
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }

                    Text {
                        visible: modelData.isCurrent
                        text: "󰄬"
                        color: Theme.primary
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Theme.setTheme(modelData.id);
                    }
                }
            }
        }
    }
}
