import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property var audioRef: null
    property bool showAppMixer: false
    property bool showDevicePicker: false

    implicitWidth: 320
    implicitHeight: layout.implicitHeight + 20

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        // 1. Header: Título + Botón de Silencio Rápido
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "󰕾  SONIDO Y AUDIO"
                color: Theme.primary
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            // Botón selector de dispositivo de salida
            Rectangle {
                implicitWidth: 28
                implicitHeight: 28
                radius: 7
                color: (root.showDevicePicker || devPickerMouse.containsMouse) ? Theme.bgHover : Theme.bgSurface
                border.color: root.showDevicePicker ? Theme.primary : "transparent"
                border.width: 1

                Behavior on color { ColorAnimation { duration: Theme.anim.fastEffects } }

                Text {
                    anchors.centerIn: parent
                    text: "󰓃"
                    color: root.showDevicePicker ? Theme.primary : Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }

                MouseArea {
                    id: devPickerMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.showDevicePicker = !root.showDevicePicker;
                    }
                }
            }

            // Botón Mute / Desmutear
            Rectangle {
                implicitWidth: 28
                implicitHeight: 28
                radius: 7
                color: (audioRef && audioRef.masterMuted) ? Theme.danger : (muteMouse.containsMouse ? Theme.bgHover : Theme.bgSurface)

                Behavior on color { ColorAnimation { duration: Theme.anim.fastEffects } }

                Text {
                    anchors.centerIn: parent
                    text: (audioRef && audioRef.masterMuted) ? "󰝟" : "󰕾"
                    color: (audioRef && audioRef.masterMuted) ? (Theme.isDark ? "#11111b" : "#ffffff") : Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }

                MouseArea {
                    id: muteMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (audioRef) audioRef.toggleMasterMute();
                    }
                }
            }
        }

        // 2. Selector de Dispositivos de Salida (Desplegable)
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: root.showDevicePicker ? Math.min(84, ((audioRef && audioRef.sinks) ? audioRef.sinks.length * 28 + 8 : 36)) : 0
            visible: implicitHeight > 0
            clip: true
            radius: 8
            color: Theme.bgSurface
            border.color: Theme.border
            border.width: 1

            Behavior on implicitHeight {
                NumberAnimation {
                    duration: Theme.anim.fastEffects
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.anim.expressiveFastEffects
                }
            }

            ListView {
                anchors.fill: parent
                anchors.margins: 4
                clip: true
                spacing: 2
                model: audioRef ? audioRef.sinks : []

                delegate: Rectangle {
                    required property var modelData
                    width: parent ? parent.width : 290
                    implicitHeight: 26
                    radius: 6
                    color: modelData.isDefault ? Theme.bgHover : (sinkMouse.containsMouse ? Theme.bg : "transparent")
                    border.color: modelData.isDefault ? Theme.primary : "transparent"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 6

                        Text {
                            text: modelData.isDefault ? "󰄬" : "󰓃"
                            color: modelData.isDefault ? Theme.primary : Theme.overlay
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.description || modelData.name
                            color: modelData.isDefault ? Theme.primary : Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: sinkMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (audioRef) audioRef.setDefaultSink(modelData.name);
                        }
                    }
                }
            }
        }

        // 3. Slider de Volumen Principal (Master)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "VOLUMEN GENERAL"
                    color: Theme.overlay
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: audioRef ? (audioRef.masterMuted ? "Silenciado" : (audioRef.masterVolume + "%")) : "0%"
                    color: (audioRef && audioRef.masterMuted) ? Theme.danger : Theme.primary
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.bold: true
                }
            }

            Rectangle {
                id: masterTrack
                Layout.fillWidth: true
                implicitHeight: 20
                radius: 7
                color: Theme.bgSurface
                clip: true

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: audioRef ? (parent.width * (Math.min(100, audioRef.masterVolume) / 100)) : 0
                    radius: 7
                    color: (audioRef && audioRef.masterMuted) ? Theme.overlay : Theme.primary

                    Behavior on width {
                        enabled: !masterMouse.drag.active
                        NumberAnimation {
                            duration: 120
                            easing.type: Easing.OutQuad
                        }
                    }
                }

                MouseArea {
                    id: masterMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    function updateVol(mouseX) {
                        let pct = Math.max(0, Math.min(100, Math.round((mouseX / width) * 100)));
                        if (audioRef) audioRef.setMasterVolume(pct);
                    }

                    onPressed: mouse => updateVol(mouse.x)
                    onPositionChanged: mouse => {
                        if (pressed) updateVol(mouse.x);
                    }
                }
            }
        }

        // 4. Slider de Micrófono
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "MICRÓFONO"
                    color: Theme.overlay
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: audioRef ? (audioRef.sourceMuted ? "Silenciado" : (audioRef.sourceVolume + "%")) : "0%"
                    color: (audioRef && audioRef.sourceMuted) ? Theme.danger : Theme.cyan
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.bold: true
                }
            }

            Rectangle {
                id: sourceTrack
                Layout.fillWidth: true
                implicitHeight: 20
                radius: 7
                color: Theme.bgSurface
                clip: true

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: audioRef ? (parent.width * (Math.min(100, audioRef.sourceVolume) / 100)) : 0
                    radius: 7
                    color: (audioRef && audioRef.sourceMuted) ? Theme.overlay : Theme.cyan

                    Behavior on width {
                        enabled: !sourceMouse.drag.active
                        NumberAnimation {
                            duration: 120
                            easing.type: Easing.OutQuad
                        }
                    }
                }

                MouseArea {
                    id: sourceMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    function updateMic(mouseX) {
                        let pct = Math.max(0, Math.min(100, Math.round((mouseX / width) * 100)));
                        if (audioRef) audioRef.setMicVolume(pct);
                    }

                    onPressed: mouse => updateMic(mouse.x)
                    onPositionChanged: mouse => {
                        if (pressed) updateMic(mouse.x);
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Theme.border
        }

        // 5. Botón Colapsable: Mezclador de Aplicaciones
        Rectangle {
            id: toggleAppsBtn
            Layout.fillWidth: true
            implicitHeight: 28
            radius: 7
            color: toggleAppsMouse.containsMouse ? Theme.bgHover : Theme.bgSurface

            Behavior on color { ColorAnimation { duration: Theme.anim.fastEffects } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 6

                Text {
                    text: root.showAppMixer ? "󰅃" : "󰅀"
                    color: Theme.primary
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }

                Text {
                    text: "MEZCLADOR DE APLICACIONES"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    font.bold: true
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: (audioRef && audioRef.apps) ? (audioRef.apps.length + " apps") : "0 apps"
                    color: Theme.overlay
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                }
            }

            MouseArea {
                id: toggleAppsMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.showAppMixer = !root.showAppMixer;
                }
            }
        }

        // 6. Lista de Aplicaciones con control de volumen individual
        Item {
            id: appMixerContainer
            Layout.fillWidth: true
            implicitHeight: {
                if (!root.showAppMixer) return 0;
                let appCount = (audioRef && audioRef.apps) ? audioRef.apps.length : 0;
                return appCount === 0 ? 44 : Math.min(180, appCount * 46 + 6);
            }
            visible: implicitHeight > 0
            clip: true

            Behavior on implicitHeight {
                NumberAnimation {
                    duration: Theme.anim.fastEffects
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.anim.expressiveFastEffects
                }
            }

            Text {
                anchors.centerIn: parent
                visible: !audioRef || !audioRef.apps || audioRef.apps.length === 0
                text: "No hay apps reproduciendo audio"
                color: Theme.overlay
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }

            ListView {
                id: appListView
                anchors.fill: parent
                clip: true
                spacing: 6
                model: (audioRef && audioRef.apps) ? audioRef.apps : []

                delegate: Rectangle {
                    required property var modelData
                    width: appListView.width
                    implicitHeight: 40
                    radius: 7
                    color: Theme.bgSurface
                    border.color: Theme.border
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 5
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                Layout.fillWidth: true
                                text: modelData.name || "Aplicación"
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: modelData.volume + "%"
                                color: Theme.primary
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                            }
                        }

                        // Slider de la aplicación
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 12
                            radius: 4
                            color: Theme.bg
                            clip: true

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width * (Math.min(100, modelData.volume) / 100)
                                radius: 4
                                color: Theme.primary
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                function updateAppVol(mx) {
                                    let pct = Math.max(0, Math.min(100, Math.round((mx / width) * 100)));
                                    if (audioRef) audioRef.setAppVolume(modelData.id, pct);
                                }
                                onPressed: mouse => updateAppVol(mouse.x)
                                onPositionChanged: mouse => {
                                    if (pressed) updateAppVol(mouse.x);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
