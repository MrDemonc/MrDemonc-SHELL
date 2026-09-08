import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property var batteryRef: null

    implicitWidth: 320
    implicitHeight: layout.implicitHeight + 20

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        // Header: Animalito pixel y toggle de porcentaje
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            PixelCat {}

            Item { Layout.fillWidth: true }

            Rectangle {
                implicitWidth: 28
                implicitHeight: 28
                radius: 7
                color: toggleMouse.containsMouse ? Theme.bgHover : Theme.bgSurface

                Behavior on color { ColorAnimation { duration: Theme.anim.fastEffects } }

                Text {
                    anchors.centerIn: parent
                    text: (batteryRef && batteryRef.showPercentage) ? "󰈈" : "󰈉"
                    color: (batteryRef && batteryRef.showPercentage) ? Theme.primary : Theme.overlay
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                }

                MouseArea {
                    id: toggleMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    propagateComposedEvents: true
                    onClicked: {
                        if (batteryRef) batteryRef.togglePercentage();
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Theme.border
        }

        // Grid de información detallada (Estado, Potencia, Salud, Ciclos)
        GridLayout {
            Layout.fillWidth: true
            columns: 4
            rowSpacing: 4
            columnSpacing: 6

            ColumnLayout {
                spacing: 2
                Text {
                    text: "ESTADO"
                    color: Theme.overlay
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                }
                Text {
                    text: batteryRef ? (batteryRef.hasBattery ? batteryRef.status : "Alimentación CA") : "Unknown"
                    color: batteryRef && batteryRef.status === "Charging" ? Theme.success : Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.bold: true
                }
            }

            ColumnLayout {
                spacing: 2
                Text {
                    text: batteryRef && batteryRef.status === "Charging" ? "CARGA" : "CONSUMO"
                    color: Theme.overlay
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                }
                Text {
                    text: batteryRef ? batteryRef.powerRate : "0.0 W"
                    color: Theme.cyan
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }
            }

            ColumnLayout {
                spacing: 2
                Text {
                    text: "SALUD"
                    color: Theme.overlay
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                }
                Text {
                    text: batteryRef ? batteryRef.health : "100%"
                    color: Theme.success
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }
            }

            ColumnLayout {
                spacing: 2
                Text {
                    text: "CICLOS"
                    color: Theme.overlay
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                }
                Text {
                    text: batteryRef ? batteryRef.cycleCount.toString() : "0"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Theme.border
        }

        // Selector de Perfiles
        Text {
            text: "PERFIL DE RENDIMIENTO"
            color: Theme.overlay
            font.family: Theme.fontFamily
            font.pixelSize: 9
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            // Power Saver
            Rectangle {
                id: saverBtn
                Layout.fillWidth: true
                implicitHeight: 28
                radius: 7
                color: {
                    if (batteryRef && batteryRef.currentProfile === "power-saver") return Theme.success;
                    if (saverMouse.containsMouse) return Theme.bgHover;
                    return Theme.bgSurface;
                }
                border.color: saverMouse.containsMouse ? Theme.primary : "transparent"
                border.width: 1

                Behavior on color { ColorAnimation { duration: Theme.anim.fastEffects } }
                Behavior on border.color { ColorAnimation { duration: Theme.anim.fastEffects } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    Text {
                        text: ""
                        color: (batteryRef && batteryRef.currentProfile === "power-saver") ? (Theme.isDark ? "#11111b" : "#ffffff") : Theme.success
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }
                    Text {
                        text: "Ahorro"
                        color: (batteryRef && batteryRef.currentProfile === "power-saver") ? (Theme.isDark ? "#11111b" : "#ffffff") : Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                    }
                }

                MouseArea {
                    id: saverMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    propagateComposedEvents: true
                    onClicked: {
                        if (batteryRef) batteryRef.setProfile("power-saver");
                    }
                }
            }

            // Balanced
            Rectangle {
                id: balBtn
                Layout.fillWidth: true
                implicitHeight: 28
                radius: 7
                color: {
                    if (batteryRef && batteryRef.currentProfile === "balanced") return Theme.primary;
                    if (balMouse.containsMouse) return Theme.bgHover;
                    return Theme.bgSurface;
                }
                border.color: balMouse.containsMouse ? Theme.primary : "transparent"
                border.width: 1

                Behavior on color { ColorAnimation { duration: Theme.anim.fastEffects } }
                Behavior on border.color { ColorAnimation { duration: Theme.anim.fastEffects } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    Text {
                        text: "󰾅"
                        color: (batteryRef && batteryRef.currentProfile === "balanced") ? (Theme.isDark ? "#11111b" : "#ffffff") : Theme.primary
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }
                    Text {
                        text: "Equil."
                        color: (batteryRef && batteryRef.currentProfile === "balanced") ? (Theme.isDark ? "#11111b" : "#ffffff") : Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                    }
                }

                MouseArea {
                    id: balMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    propagateComposedEvents: true
                    onClicked: {
                        if (batteryRef) batteryRef.setProfile("balanced");
                    }
                }
            }

            // Performance
            Rectangle {
                id: perfBtn
                Layout.fillWidth: true
                implicitHeight: 28
                radius: 7
                color: {
                    if (batteryRef && batteryRef.currentProfile === "performance") return Theme.danger;
                    if (perfMouse.containsMouse) return Theme.bgHover;
                    return Theme.bgSurface;
                }
                border.color: perfMouse.containsMouse ? Theme.primary : "transparent"
                border.width: 1

                Behavior on color { ColorAnimation { duration: Theme.anim.fastEffects } }
                Behavior on border.color { ColorAnimation { duration: Theme.anim.fastEffects } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    Text {
                        text: ""
                        color: (batteryRef && batteryRef.currentProfile === "performance") ? (Theme.isDark ? "#11111b" : "#ffffff") : Theme.danger
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }
                    Text {
                        text: "Max"
                        color: (batteryRef && batteryRef.currentProfile === "performance") ? (Theme.isDark ? "#11111b" : "#ffffff") : Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                    }
                }

                MouseArea {
                    id: perfMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    propagateComposedEvents: true
                    onClicked: {
                        if (batteryRef) batteryRef.setProfile("performance");
                    }
                }
            }
        }
    }
}
