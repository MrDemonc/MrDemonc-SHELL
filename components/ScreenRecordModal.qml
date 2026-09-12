import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: recordModalWindow

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    WlrLayershell.namespace: "shell-recorder-modal"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: ScreenRecordManager.modalOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    visible: ScreenRecordManager.modalOpen || modalCard.opacity > 0.01
    onVisibleChanged: console.log("RECORDER MODAL visible changed: " + visible)

    // Fondo oscurecido (scrim)
    Rectangle {
        id: scrim
        anchors.fill: parent
        color: "#000000"
        opacity: ScreenRecordManager.modalOpen ? 0.65 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.anim.defaultEffects
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.anim.expressiveDefaultEffects
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: ScreenRecordManager.modalOpen
            onClicked: ScreenRecordManager.modalOpen = false
        }
    }

    // Tarjeta Modal Central
    Rectangle {
        id: modalCard
        anchors.centerIn: parent

        width: 500
        height: 360
        implicitWidth: 500
        implicitHeight: 360
        color: Theme.bg
        border.color: Theme.border
        border.width: 1
        radius: Theme.radiusLarge
        clip: true

        opacity: ScreenRecordManager.modalOpen ? 1.0 : 0.0
        scale: ScreenRecordManager.modalOpen ? 1.0 : 0.92

        Behavior on scale {
            NumberAnimation {
                duration: ScreenRecordManager.modalOpen ? 320 : 180
                easing.type: ScreenRecordManager.modalOpen ? Easing.OutBack : Easing.InQuad
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
            enabled: ScreenRecordManager.modalOpen
            onActivated: ScreenRecordManager.modalOpen = false
        }

        Shortcut {
            sequence: "Return"
            enabled: ScreenRecordManager.modalOpen
            onActivated: ScreenRecordManager.startRecording()
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16

            // =================================================================
            // SELECCIÓN DE ÁREA (PANTALLA COMPLETA O REGIÓN)
            // =================================================================
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "MODO DE CAPTURA"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.bold: true
                    color: Theme.subtext
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    // Tarjeta: Pantalla Completa
                    Rectangle {
                        id: screenModeCard
                        Layout.fillWidth: true
                        height: 64
                        radius: 10
                        readonly property bool isSelected: ScreenRecordManager.captureMode === "screen"
                        color: isSelected ? Theme.accentBg : (screenHover.containsMouse ? Theme.bgHover : Theme.bgSubtle)
                        border.color: isSelected ? Theme.accent : Theme.border
                        border.width: isSelected ? 2 : 1

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 10

                            Text {
                                text: "󰹑"
                                font.family: Theme.iconFontFamily
                                font.pixelSize: 22
                                color: screenModeCard.isSelected ? Theme.accent : Theme.text
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    text: "Toda la pantalla"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: screenModeCard.isSelected ? Theme.accent : Theme.text
                                }

                                Text {
                                    text: "Captura el monitor completo"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: Theme.subtext
                                }
                            }
                        }

                        MouseArea {
                            id: screenHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ScreenRecordManager.captureMode = "screen"
                        }
                    }

                    // Tarjeta: Sección / Área
                    Rectangle {
                        id: areaModeCard
                        Layout.fillWidth: true
                        height: 64
                        radius: 10
                        readonly property bool isSelected: ScreenRecordManager.captureMode === "area"
                        color: isSelected ? Theme.accentBg : (areaHover.containsMouse ? Theme.bgHover : Theme.bgSubtle)
                        border.color: isSelected ? Theme.accent : Theme.border
                        border.width: isSelected ? 2 : 1

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 10

                            Text {
                                text: "󰒅"
                                font.family: Theme.iconFontFamily
                                font.pixelSize: 22
                                color: areaModeCard.isSelected ? Theme.accent : Theme.text
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    text: "Sección / Región"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: areaModeCard.isSelected ? Theme.accent : Theme.text
                                }

                                Text {
                                    text: "Seleccionar área con el ratón"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: Theme.subtext
                                }
                            }
                        }

                        MouseArea {
                            id: areaHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ScreenRecordManager.captureMode = "area"
                        }
                    }
                }
            }

            // =================================================================
            // 3. ENTRADAS DE AUDIO
            // =================================================================
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "OPCIONES DE AUDIO"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.bold: true
                    color: Theme.subtext
                }

                // Opción 1: Audio del Sistema
                Rectangle {
                    Layout.fillWidth: true
                    height: 48
                    radius: 8
                    color: sysAudioHover.containsMouse ? Theme.bgHover : Theme.bgSubtle
                    border.color: Theme.border
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        Text {
                            text: ScreenRecordManager.recordSysAudio ? "󰕾" : "󰖁"
                            font.family: Theme.iconFontFamily
                            font.pixelSize: 18
                            color: ScreenRecordManager.recordSysAudio ? Theme.text : Theme.subtext
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                text: "Audio del sistema"
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.bold: true
                                color: Theme.text
                            }

                            Text {
                                text: "Sonido de aplicaciones, vídeos y juegos"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: Theme.subtext
                            }
                        }

                        // Switch toggle
                        Rectangle {
                            width: 38
                            height: 20
                            radius: 10
                            color: ScreenRecordManager.recordSysAudio ? Theme.accent : Theme.border

                            Behavior on color { ColorAnimation { duration: 150 } }

                            Rectangle {
                                width: 16
                                height: 16
                                radius: 8
                                color: "#ffffff"
                                anchors.verticalCenter: parent.verticalCenter
                                x: ScreenRecordManager.recordSysAudio ? parent.width - width - 2 : 2

                                Behavior on x {
                                    NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: sysAudioHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ScreenRecordManager.recordSysAudio = !ScreenRecordManager.recordSysAudio
                    }
                }

                // Opción 2: Micrófono
                Rectangle {
                    Layout.fillWidth: true
                    height: 48
                    radius: 8
                    color: micAudioHover.containsMouse ? Theme.bgHover : Theme.bgSubtle
                    border.color: Theme.border
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        Text {
                            text: ScreenRecordManager.recordMicAudio ? "󰍬" : "󰍭"
                            font.family: Theme.iconFontFamily
                            font.pixelSize: 18
                            color: ScreenRecordManager.recordMicAudio ? Theme.text : Theme.subtext
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                text: "Micrófono"
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.bold: true
                                color: Theme.text
                            }

                            Text {
                                text: "Grabar tu voz o fuentes de entrada externas"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: Theme.subtext
                            }
                        }

                        // Switch toggle
                        Rectangle {
                            width: 38
                            height: 20
                            radius: 10
                            color: ScreenRecordManager.recordMicAudio ? Theme.accent : Theme.border

                            Behavior on color { ColorAnimation { duration: 150 } }

                            Rectangle {
                                width: 16
                                height: 16
                                radius: 8
                                color: "#ffffff"
                                anchors.verticalCenter: parent.verticalCenter
                                x: ScreenRecordManager.recordMicAudio ? parent.width - width - 2 : 2

                                Behavior on x {
                                    NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: micAudioHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ScreenRecordManager.recordMicAudio = !ScreenRecordManager.recordMicAudio
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
            // 4. ACCIONES INFERIORES
            // =================================================================
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // Botón Iniciar Grabación (Rojo / Destacado)
                Rectangle {
                    Layout.fillWidth: true
                    height: 38
                    radius: 8
                    color: startRecHover.containsMouse ? "#dc2626" : "#ef4444"
                    Behavior on color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: "󰑋"
                            font.family: Theme.iconFontFamily
                            font.pixelSize: 14
                            color: "#ffffff"
                        }

                        Text {
                            text: "Iniciar Grabación"
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.bold: true
                            color: "#ffffff"
                        }
                    }

                    MouseArea {
                        id: startRecHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ScreenRecordManager.startRecording()
                    }
                }

                // Botón Cancelar
                Rectangle {
                    Layout.preferredWidth: 90
                    Layout.preferredHeight: 38
                    radius: 8
                    color: cancelRecHover.containsMouse ? Theme.bgHover : Theme.bgSubtle
                    border.color: Theme.border
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: "Cancelar"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: cancelRecHover.containsMouse ? Theme.text : Theme.subtext
                    }

                    MouseArea {
                        id: cancelRecHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ScreenRecordManager.modalOpen = false
                    }
                }
            }
        }
    }
}
