import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: monitorModalWindow

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    WlrLayershell.namespace: "shell-monitors-modal"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: MonitorManager.monitorsOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    visible: MonitorManager.monitorsOpen || modalCard.opacity > 0.01

    onVisibleChanged: {
        if (visible && MonitorManager.monitorsOpen) {
            MonitorManager.refresh();
        }
    }

    // Fondo oscurecido (Scrim)
    Rectangle {
        id: scrim
        anchors.fill: parent
        color: "#000000"
        opacity: MonitorManager.monitorsOpen ? 0.65 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.anim.defaultEffects
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.anim.expressiveDefaultEffects
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: MonitorManager.monitorsOpen
            onClicked: MonitorManager.monitorsOpen = false
        }
    }

    // Tarjeta Modal Central Minimalista
    Rectangle {
        id: modalCard
        anchors.centerIn: parent

        implicitWidth: 700
        implicitHeight: 465
        color: Theme.bg
        border.color: Theme.border
        border.width: 1
        radius: Theme.radiusLarge
        clip: true

        opacity: MonitorManager.monitorsOpen ? 1.0 : 0.0
        scale: MonitorManager.monitorsOpen ? 1.0 : 0.92

        Behavior on scale {
            NumberAnimation {
                duration: MonitorManager.monitorsOpen ? 340 : 180
                easing.type: MonitorManager.monitorsOpen ? Easing.OutBack : Easing.InQuad
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
            enabled: MonitorManager.monitorsOpen
            onActivated: MonitorManager.monitorsOpen = false
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            // -----------------------------------------------------------------
            // 1. PERFILES RÁPIDOS (PRESETS)
            // -----------------------------------------------------------------
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // A. Extender
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 52
                    radius: 10
                    color: pExtMouse.containsMouse ? Theme.bgHover : Theme.bgSurface
                    border.color: Theme.border
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Text { text: "󰍺"; color: Theme.primary; font.family: Theme.iconFontFamily; font.pixelSize: 16 }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Extender"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 11; font.bold: true }
                            Text { text: "Ambas activas"; color: Theme.subtext; font.family: Theme.fontFamily; font.pixelSize: 9 }
                        }
                    }

                    MouseArea {
                        id: pExtMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MonitorManager.applyPreset("extend")
                    }
                }

                // B. Solo Externo
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 52
                    radius: 10
                    color: pExtOnlyMouse.containsMouse ? Theme.bgHover : Theme.bgSurface
                    border.color: Theme.primary
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Text { text: "󰍹"; color: Theme.primary; font.family: Theme.iconFontFamily; font.pixelSize: 16 }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Solo Externo"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 11; font.bold: true }
                            Text { text: "Apaga laptop"; color: Theme.subtext; font.family: Theme.fontFamily; font.pixelSize: 9 }
                        }
                    }

                    MouseArea {
                        id: pExtOnlyMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MonitorManager.applyPreset("external_only")
                    }
                }

                // C. Solo Laptop
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 52
                    radius: 10
                    color: pLapOnlyMouse.containsMouse ? Theme.bgHover : Theme.bgSurface
                    border.color: Theme.border
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Text { text: "󰌢"; color: Theme.cyan; font.family: Theme.iconFontFamily; font.pixelSize: 16 }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Solo Laptop"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 11; font.bold: true }
                            Text { text: "Apaga externo"; color: Theme.subtext; font.family: Theme.fontFamily; font.pixelSize: 9 }
                        }
                    }

                    MouseArea {
                        id: pLapOnlyMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MonitorManager.applyPreset("laptop_only")
                    }
                }

                // D. Duplicar
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 52
                    radius: 10
                    color: pMirrorMouse.containsMouse ? Theme.bgHover : Theme.bgSurface
                    border.color: Theme.border
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Text { text: "󰑑"; color: Theme.warning; font.family: Theme.iconFontFamily; font.pixelSize: 16 }
                        ColumnLayout {
                            spacing: 1
                            Text { text: "Duplicar"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 11; font.bold: true }
                            Text { text: "Espejo"; color: Theme.subtext; font.family: Theme.fontFamily; font.pixelSize: 9 }
                        }
                    }

                    MouseArea {
                        id: pMirrorMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MonitorManager.applyPreset("mirror")
                    }
                }
            }

            // -----------------------------------------------------------------
            // 3. SELECTOR DE MONITORES DETECTADOS (TABS)
            // -----------------------------------------------------------------
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: (MonitorManager.monitorInfo && MonitorManager.monitorInfo.monitors) ? MonitorManager.monitorInfo.monitors : []

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        readonly property bool isSelected: MonitorManager.selectedIndex === index
                        Layout.fillWidth: true
                        implicitHeight: 38
                        radius: 8
                        color: isSelected ? Theme.bgHover : "transparent"
                        border.color: isSelected ? Theme.primary : Theme.border
                        border.width: isSelected ? 1.5 : 1

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: modelData.is_laptop ? "󰌢" : "󰍹"
                                color: isSelected ? Theme.primary : Theme.subtext
                                font.family: Theme.iconFontFamily
                                font.pixelSize: 14
                            }

                            Text {
                                text: modelData.name + (modelData.disabled ? " (Apagado)" : "")
                                color: isSelected ? Theme.text : Theme.subtext
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.bold: isSelected
                            }

                            Rectangle {
                                implicitWidth: 8
                                implicitHeight: 8
                                radius: 4
                                color: modelData.disabled ? Theme.danger : Theme.success
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: MonitorManager.selectedIndex = index
                        }
                    }
                }
            }

            // -----------------------------------------------------------------
            // 4. PANEL DE CONTROL DEL MONITOR SELECCIONADO
            // -----------------------------------------------------------------
            Rectangle {
                id: monitorControlCard
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Theme.bgSurface
                radius: 12
                border.color: Theme.border
                border.width: 1

                property var mon: MonitorManager.currentMonitor
                property bool monEnabled: mon ? !mon.disabled : true
                property real monScale: mon ? (mon.scale || 1.0) : 1.0
                property string monMode: mon ? (mon.current_mode || "preferred") : "preferred"
                property int monTransform: mon ? (mon.transform || 0) : 0
                property string monPos: "auto"

                onMonChanged: {
                    if (mon) {
                        monEnabled = !mon.disabled;
                        monScale = mon.scale || 1.0;
                        monMode = mon.current_mode || "preferred";
                        monTransform = mon.transform || 0;
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    // Estado y Switch de Encendido / Apagado
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: monitorControlCard.mon ? (monitorControlCard.mon.name + " · " + monitorControlCard.mon.description) : "Pantalla"
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                font.bold: true
                            }

                            Text {
                                text: monitorControlCard.monEnabled ? "Pantalla activa y transmitiendo señal" : "Pantalla apagada y deshabilitada"
                                color: monitorControlCard.monEnabled ? Theme.success : Theme.overlay
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                            }
                        }

                        // Botón Toggle Activar/Desactivar
                        Rectangle {
                            implicitWidth: 90
                            implicitHeight: 28
                            radius: 14
                            color: monitorControlCard.monEnabled ? Theme.primary : Theme.bgHover
                            border.color: monitorControlCard.monEnabled ? Theme.primary : Theme.border
                            border.width: 1

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                Text {
                                    text: monitorControlCard.monEnabled ? "󰄲" : "󰅖"
                                    color: monitorControlCard.monEnabled ? Theme.bg : Theme.subtext
                                    font.family: Theme.iconFontFamily
                                    font.pixelSize: 12
                                }
                                Text {
                                    text: monitorControlCard.monEnabled ? "ACTIVO" : "APAGADO"
                                    color: monitorControlCard.monEnabled ? Theme.bg : Theme.subtext
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: monitorControlCard.monEnabled = !monitorControlCard.monEnabled
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: Theme.border
                        opacity: 0.6
                    }

                    // Selector de Escala HiDPI
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: "Escala de Pantalla (HiDPI)"
                            color: Theme.subtext
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Repeater {
                                model: [
                                    { label: "100%", value: 1.0 },
                                    { label: "125%", value: 1.25 },
                                    { label: "150%", value: 1.5 },
                                    { label: "175%", value: 1.75 },
                                    { label: "200%", value: 2.0 }
                                ]

                                delegate: Rectangle {
                                    required property var modelData
                                    readonly property bool isCurrent: Math.abs(monitorControlCard.monScale - modelData.value) < 0.05
                                    Layout.fillWidth: true
                                    implicitHeight: 32
                                    radius: 7
                                    color: isCurrent ? Theme.primary : (sMouse.containsMouse ? Theme.bgHover : Theme.bg)
                                    border.color: isCurrent ? Theme.primary : Theme.border
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        color: isCurrent ? Theme.bg : Theme.text
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        font.bold: isCurrent
                                    }

                                    MouseArea {
                                        id: sMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: monitorControlCard.monScale = modelData.value
                                    }
                                }
                            }
                        }
                    }

                    // Selector de Modos / Resolución
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "Resolución y Frecuencia"
                                color: Theme.subtext
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.bold: true
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: monitorControlCard.monMode
                                color: Theme.primary
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }

                        // Lista horizontal compacta de resoluciones disponibles
                        Flickable {
                            Layout.fillWidth: true
                            implicitHeight: 34
                            contentWidth: modesRow.width
                            clip: true

                            RowLayout {
                                id: modesRow
                                spacing: 6

                                Repeater {
                                    model: (monitorControlCard.mon && monitorControlCard.mon.available_modes) ? monitorControlCard.mon.available_modes.slice(0, 8) : ["preferred"]

                                    delegate: Rectangle {
                                        required property string modelData
                                        readonly property bool isModeSelected: monitorControlCard.monMode === modelData
                                        implicitWidth: mTxt.implicitWidth + 16
                                        implicitHeight: 30
                                        radius: 6
                                        color: isModeSelected ? Theme.primary : (mMouse.containsMouse ? Theme.bgHover : Theme.bg)
                                        border.color: isModeSelected ? Theme.primary : Theme.border
                                        border.width: 1

                                        Text {
                                            id: mTxt
                                            anchors.centerIn: parent
                                            text: modelData
                                            color: isModeSelected ? Theme.bg : Theme.text
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 10
                                            font.bold: isModeSelected
                                        }

                                        MouseArea {
                                            id: mMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: monitorControlCard.monMode = modelData
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Orientación y Rotación
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: "Orientación"
                            color: Theme.subtext
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Repeater {
                                model: [
                                    { label: "Normal (0°)", value: 0 },
                                    { label: "Vertical Izq (90°)", value: 1 },
                                    { label: "Invertido (180°)", value: 2 },
                                    { label: "Vertical Der (270°)", value: 3 }
                                ]

                                delegate: Rectangle {
                                    required property var modelData
                                    readonly property bool isCurrent: monitorControlCard.monTransform === modelData.value
                                    Layout.fillWidth: true
                                    implicitHeight: 28
                                    radius: 6
                                    color: isCurrent ? Theme.primary : (tMouse.containsMouse ? Theme.bgHover : Theme.bg)
                                    border.color: isCurrent ? Theme.primary : Theme.border
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        color: isCurrent ? Theme.bg : Theme.text
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.bold: isCurrent
                                    }

                                    MouseArea {
                                        id: tMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: monitorControlCard.monTransform = modelData.value
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // Fila de Acción Inferior
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: MonitorManager.feedbackMessage
                            color: Theme.primary
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            implicitWidth: 100
                            implicitHeight: 32
                            radius: 7
                            color: btnRefMouse.containsMouse ? Theme.bgHover : "transparent"
                            border.color: Theme.border
                            border.width: 1

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 5
                                Text { text: "󰑐"; color: Theme.cyan; font.family: Theme.iconFontFamily; font.pixelSize: 11 }
                                Text { text: "Refrescar"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 10; font.bold: true }
                            }

                            MouseArea {
                                id: btnRefMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: MonitorManager.refresh()
                            }
                        }

                        Rectangle {
                            implicitWidth: 140
                            implicitHeight: 32
                            radius: 7
                            color: Theme.primary
                            opacity: btnApplyMouse.containsMouse ? 0.88 : 1.0

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 5
                                Text { text: "󰄬"; color: Theme.bg; font.family: Theme.iconFontFamily; font.pixelSize: 12 }
                                Text { text: "Aplicar Cambios"; color: Theme.bg; font.family: Theme.fontFamily; font.pixelSize: 10; font.bold: true }
                            }

                            MouseArea {
                                id: btnApplyMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (monitorControlCard.mon) {
                                        MonitorManager.applySetting(
                                            monitorControlCard.mon.name,
                                            monitorControlCard.monEnabled,
                                            monitorControlCard.monMode,
                                            monitorControlCard.monScale,
                                            monitorControlCard.monPos,
                                            monitorControlCard.monTransform,
                                            "none"
                                        );
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
