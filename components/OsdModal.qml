import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: osdWindow

    WlrLayershell.namespace: "shell-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    anchors {
        bottom: true
    }
    margins {
        bottom: 100
    }

    implicitWidth: 156
    implicitHeight: 156
    color: "transparent"

    visible: OsdManager.isOsdVisible || osdCard.opacity > 0.01

    Rectangle {
        id: osdCard
        anchors.centerIn: parent
        width: 150
        height: 150
        radius: 20
        color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.92)
        border.color: Qt.rgba(1.0, 1.0, 1.0, 0.15)
        border.width: 1
        clip: true

        // Animación fluida de escala y transparencia estilo macOS
        opacity: OsdManager.isOsdVisible ? 1.0 : 0.0
        scale: OsdManager.isOsdVisible ? 1.0 : 0.88

        Behavior on opacity {
            NumberAnimation {
                duration: OsdManager.isOsdVisible ? 130 : 240
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: OsdManager.isOsdVisible ? 150 : 240
                easing.type: OsdManager.isOsdVisible ? Easing.OutBack : Easing.InCubic
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 9

            // Icono principal estilizado
            Text {
                Layout.alignment: Qt.AlignHCenter
                font.family: Theme.iconFontFamily
                font.pixelSize: 40
                color: {
                    if (OsdManager.osdMuted) return Theme.danger;
                    return Theme.text;
                }

                text: {
                    if (OsdManager.osdType === "brightness") {
                        if (OsdManager.osdValue <= 33) return "󰃞";
                        if (OsdManager.osdValue <= 66) return "󰃟";
                        return "󰃠";
                    } else if (OsdManager.osdType === "mic") {
                        return OsdManager.osdMuted ? "󰍭" : "󰍬";
                    } else {
                        // Volumen
                        if (OsdManager.osdMuted || OsdManager.osdValue === 0) return "󰝟";
                        if (OsdManager.osdValue <= 33) return "󰕿";
                        if (OsdManager.osdValue <= 66) return "󰖀";
                        return "󰕾";
                    }
                }

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }

            // Barra de progreso continua estilo macOS
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 104
                Layout.preferredHeight: 6
                width: 104
                height: 6
                radius: 3
                color: Qt.rgba(1.0, 1.0, 1.0, 0.18)
                clip: true

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    radius: 3
                    width: Math.max(0, Math.min(parent.width, (OsdManager.osdValue / 100.0) * parent.width))
                    color: {
                        if (OsdManager.osdMuted) return Theme.danger;
                        return Theme.primary;
                    }

                    Behavior on width {
                        NumberAnimation {
                            duration: 90
                            easing.type: Easing.OutQuad
                        }
                    }

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }
            }

            // Etiqueta de porcentaje o estado
            Text {
                Layout.alignment: Qt.AlignHCenter
                font.family: Theme.monoFontFamily
                font.pixelSize: 11
                font.bold: true
                color: OsdManager.osdMuted ? Theme.danger : Theme.subtext
                text: {
                    if (OsdManager.osdMuted) return "Silenciado";
                    return OsdManager.osdValue + "%";
                }
            }
        }
    }
}
