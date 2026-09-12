import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: colorPickerWindow

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    WlrLayershell.namespace: "shell-colorpicker-modal"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: ColorPickerManager.isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    visible: ColorPickerManager.isOpen || modalCard.opacity > 0.01
    onVisibleChanged: console.log("COLOR PICKER MODAL visible changed: " + visible)

    // Fondo oscurecido (scrim)
    Rectangle {
        id: scrim
        anchors.fill: parent
        color: "#000000"
        opacity: ColorPickerManager.isOpen ? 0.65 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.anim.defaultEffects
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.anim.expressiveDefaultEffects
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: ColorPickerManager.isOpen
            onClicked: ColorPickerManager.isOpen = false
        }
    }

    // Tarjeta Modal Central
    Rectangle {
        id: modalCard
        anchors.centerIn: parent

        width: 580
        height: 260
        color: Theme.bg
        border.color: Theme.border
        border.width: 1
        radius: Theme.radiusLarge
        clip: true

        opacity: ColorPickerManager.isOpen ? 1.0 : 0.0
        scale: ColorPickerManager.isOpen ? 1.0 : 0.92

        Behavior on scale {
            NumberAnimation {
                duration: ColorPickerManager.isOpen ? 300 : 180
                easing.type: ColorPickerManager.isOpen ? Easing.OutBack : Easing.InQuad
                easing.overshoot: 1.15
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.anim.defaultEffects
            }
        }

        Shortcut {
            sequence: "Escape"
            enabled: ColorPickerManager.isOpen
            onActivated: ColorPickerManager.isOpen = false
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // =================================================================
            // CUERPO: Muestra del color y Formatos
            // =================================================================
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 14

                // Cuadro de Vista Previa del Color (140px fijo)
                Item {
                    Layout.preferredWidth: 140
                    Layout.fillHeight: true

                    Rectangle {
                        id: colorSwatch
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: hexBadge.top
                        anchors.bottomMargin: 8
                        radius: 10
                        color: ColorPickerManager.hexColor
                        border.color: Qt.darker(ColorPickerManager.hexColor, 1.2)
                        border.width: 1

                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            color: "transparent"
                            border.color: "#22ffffff"
                            border.width: 1
                        }
                    }

                    Rectangle {
                        id: hexBadge
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 26
                        radius: 6
                        color: Theme.bgSurface
                        border.color: Theme.border
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: ColorPickerManager.hexColor
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.text
                        }
                    }
                }

                // Lista de formatos con botones de copiar
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 6

                    component ColorFormatRow: Rectangle {
                        id: rowRoot
                        required property string label
                        required property string value
                        property bool justCopied: false

                        Layout.fillWidth: true
                        height: 36
                        radius: 7
                        clip: true
                        color: rowHover.containsMouse ? Theme.bgHover : Theme.bgSurface
                        border.color: rowHover.containsMouse ? Theme.borderHover : Theme.border
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 100 } }
                        Behavior on border.color { ColorAnimation { duration: 100 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 8
                            spacing: 8

                            Text {
                                text: rowRoot.label
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.bold: true
                                color: Theme.accent
                                Layout.preferredWidth: 38
                            }

                            Text {
                                text: rowRoot.value
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                color: Theme.text
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                Layout.preferredWidth: 76
                                Layout.preferredHeight: 24
                                Layout.alignment: Qt.AlignVCenter
                                radius: 5
                                clip: true
                                color: rowRoot.justCopied ? Theme.accent : (copyHover.containsMouse ? Theme.bgHover : "transparent")
                                border.color: rowRoot.justCopied ? Theme.accent : Theme.border
                                border.width: 1

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Text {
                                        text: rowRoot.justCopied ? "󰄬" : "󰆏"
                                        font.family: Theme.iconFontFamily
                                        font.pixelSize: 11
                                        color: rowRoot.justCopied ? "#ffffff" : (copyHover.containsMouse ? Theme.text : Theme.subtext)
                                    }

                                    Text {
                                        text: rowRoot.justCopied ? "Copiado" : "Copiar"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: rowRoot.justCopied ? "#ffffff" : (copyHover.containsMouse ? Theme.text : Theme.subtext)
                                    }
                                }

                                MouseArea {
                                    id: copyHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        ColorPickerManager.copyToClipboard(rowRoot.value);
                                        rowRoot.justCopied = true;
                                        copyTimer.restart();
                                    }
                                }

                                Timer {
                                    id: copyTimer
                                    interval: 1500
                                    onTriggered: rowRoot.justCopied = false
                                }
                            }
                        }

                        MouseArea {
                            id: rowHover
                            anchors.fill: parent
                            hoverEnabled: true
                            z: -1
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                ColorPickerManager.copyToClipboard(rowRoot.value);
                                rowRoot.justCopied = true;
                                copyTimer.restart();
                            }
                        }
                    }

                    ColorFormatRow {
                        label: "HEX"
                        value: ColorPickerManager.hexColor
                    }

                    ColorFormatRow {
                        label: "RGB"
                        value: ColorPickerManager.rgbColor
                    }

                    ColorFormatRow {
                        label: "HSL"
                        value: ColorPickerManager.hslColor
                    }

                    ColorFormatRow {
                        label: "HSV"
                        value: ColorPickerManager.hsvColor
                    }
                }
            }

            // Separador
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.border
            }

            // =================================================================
            // ACCIONES INFERIORES
            // =================================================================
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Botón: Seleccionar otro color
                Rectangle {
                    Layout.fillWidth: true
                    height: 34
                    radius: 7
                    color: pickHover.containsMouse ? Theme.accentHover : Theme.accent
                    Behavior on color { ColorAnimation { duration: 100 } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: "󰈊"
                            font.family: Theme.iconFontFamily
                            font.pixelSize: 13
                            color: "#ffffff"
                        }

                        Text {
                            text: "Seleccionar otro color"
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                            color: "#ffffff"
                        }
                    }

                    MouseArea {
                        id: pickHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ColorPickerManager.launchPicker()
                    }
                }

                // Botón: Cerrar
                Rectangle {
                    Layout.preferredWidth: 80
                    Layout.preferredHeight: 34
                    radius: 7
                    color: cancelHover.containsMouse ? Theme.bgHover : Theme.bgSurface
                    border.color: Theme.border
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        text: "Cerrar"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: cancelHover.containsMouse ? Theme.text : Theme.subtext
                    }

                    MouseArea {
                        id: cancelHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ColorPickerManager.isOpen = false
                    }
                }
            }
        }
    }
}
