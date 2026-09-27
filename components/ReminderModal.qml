import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: reminderModalWindow

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    WlrLayershell.namespace: "shell-reminder-modal"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: ReminderManager.reminderOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    visible: ReminderManager.reminderOpen || modalCard.opacity > 0.01

    // Fondo oscurecido (scrim)
    Rectangle {
        id: scrim
        anchors.fill: parent
        color: "#000000"
        opacity: ReminderManager.reminderOpen ? 0.65 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.anim.defaultEffects
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.anim.expressiveDefaultEffects
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: ReminderManager.reminderOpen
            onClicked: ReminderManager.reminderOpen = false
        }
    }

    // Atajo Escape para cerrar la ventana
    Shortcut {
        sequence: "Escape"
        enabled: ReminderManager.reminderOpen
        onActivated: ReminderManager.reminderOpen = false
    }

    // Tarjeta Modal Central
    Rectangle {
        id: modalCard
        anchors.centerIn: parent
        width: 580
        height: 620
        radius: Theme.radiusLarge
        color: Theme.bg
        border.color: Theme.border
        border.width: 1
        clip: true

        opacity: ReminderManager.reminderOpen ? 1.0 : 0.0
        scale: ReminderManager.reminderOpen ? 1.0 : 0.94

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.anim.defaultEffects
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.anim.expressiveDefaultEffects
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: Theme.anim.defaultSpatial
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.anim.expressiveDefaultSpatial
            }
        }

        // Resplandor superior sutil
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 120
            radius: Theme.radiusLarge
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            // 1. ENCABEZADO
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    implicitWidth: 42
                    implicitHeight: 42
                    radius: 12
                    color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.16)
                    border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.40)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "󰔛"
                        color: Theme.primary
                        font.family: Theme.fontFamily
                        font.pixelSize: 22
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Recordatorios y Temporizador"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                        font.bold: true
                    }

                    Text {
                        text: "Configura alertas con cuenta regresiva para tus actividades"
                        color: Theme.overlay
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }
                }

                // Botón Cerrar
                Rectangle {
                    implicitWidth: 32
                    implicitHeight: 32
                    radius: 8
                    color: closeArea.containsMouse ? Theme.bgHover : Theme.bgSurface
                    border.color: Theme.border
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        color: closeArea.containsMouse ? Theme.red : Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ReminderManager.reminderOpen = false
                    }
                }
            }

            // 2. FORMULARIO DE NUEVO RECORDATORIO
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: formCol.implicitHeight + 24
                radius: Theme.radiusMedium
                color: Theme.bgSurface
                border.color: Theme.border
                border.width: 1

                ColumnLayout {
                    id: formCol
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    // Entrada de Texto del Recordatorio
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 38
                        radius: 8
                        color: Theme.bg
                        border.color: titleInput.activeFocus ? Theme.primary : Theme.border
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            Text {
                                text: "󰄞"
                                color: Theme.overlay
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                            }

                            TextInput {
                                id: titleInput
                                Layout.fillWidth: true
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                clip: true
                                selectByMouse: true

                                Text {
                                    anchors.fill: parent
                                    text: "Título o nota (ej. Revisar horno, descansar, reunión...)"
                                    color: Theme.overlay
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    visible: !titleInput.text && !titleInput.activeFocus
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }
                    }

                    // Botones de presets rápidos
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: [
                                { label: "1 min", h: 0, m: 1, s: 0 },
                                { label: "5 min", h: 0, m: 5, s: 0 },
                                { label: "10 min", h: 0, m: 10, s: 0 },
                                { label: "15 min", h: 0, m: 15, s: 0 },
                                { label: "25 min 󰄉", h: 0, m: 25, s: 0 },
                                { label: "30 min", h: 0, m: 30, s: 0 },
                                { label: "1 hora", h: 1, m: 0, s: 0 }
                            ]

                            delegate: Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 28
                                radius: 6
                                color: presetMouse.containsMouse ? Theme.bgHover : Theme.bg
                                border.color: (hoursSpin.value === modelData.h && minsSpin.value === modelData.m && secsSpin.value === modelData.s) ? Theme.primary : Theme.border
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: (hoursSpin.value === modelData.h && minsSpin.value === modelData.m && secsSpin.value === modelData.s) ? Theme.primary : Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.bold: (hoursSpin.value === modelData.h && minsSpin.value === modelData.m && secsSpin.value === modelData.s)
                                }

                                MouseArea {
                                    id: presetMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        hoursSpin.value = modelData.h;
                                        minsSpin.value = modelData.m;
                                        secsSpin.value = modelData.s;
                                    }
                                }
                            }
                        }
                    }

                    // Selector numérico manual: Horas, Minutos, Segundos + Botón Iniciar
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        // Horas
                        ColumnLayout {
                            spacing: 2
                            Text {
                                text: "HORAS"
                                color: Theme.overlay
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                font.bold: true
                            }
                            SpinBox {
                                id: hoursSpin
                                from: 0
                                to: 23
                                value: 0
                                editable: true
                                implicitWidth: 84
                                implicitHeight: 34
                                textFromValue: function(val, loc) { return String(val).padStart(2, '0'); }
                                valueFromText: function(txt, loc) { return parseInt(txt) || 0; }

                                contentItem: TextInput {
                                    text: hoursSpin.textFromValue(hoursSpin.value, hoursSpin.locale)
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: Theme.text
                                    horizontalAlignment: Qt.AlignHCenter
                                    verticalAlignment: Qt.AlignVCenter
                                    readOnly: !hoursSpin.editable
                                    validator: hoursSpin.validator
                                    inputMethodHints: Qt.ImhDigitsOnly
                                }

                                background: Rectangle {
                                    color: Theme.bg
                                    border.color: hoursSpin.activeFocus ? Theme.primary : Theme.border
                                    border.width: 1
                                    radius: 6
                                }

                                up.indicator: Rectangle {
                                    x: hoursSpin.mirrored ? 0 : hoursSpin.width - width
                                    height: hoursSpin.height
                                    implicitWidth: 24
                                    implicitHeight: 24
                                    color: hoursSpin.up.pressed ? Theme.bgHover : "transparent"

                                    Text {
                                        text: "+"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: Theme.text
                                        anchors.centerIn: parent
                                    }
                                }

                                down.indicator: Rectangle {
                                    x: hoursSpin.mirrored ? hoursSpin.width - width : 0
                                    height: hoursSpin.height
                                    implicitWidth: 24
                                    implicitHeight: 24
                                    color: hoursSpin.down.pressed ? Theme.bgHover : "transparent"

                                    Text {
                                        text: "-"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: Theme.text
                                        anchors.centerIn: parent
                                    }
                                }
                            }
                        }

                        // Minutos
                        ColumnLayout {
                            spacing: 2
                            Text {
                                text: "MINUTOS"
                                color: Theme.overlay
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                font.bold: true
                            }
                            SpinBox {
                                id: minsSpin
                                from: 0
                                to: 59
                                value: 5
                                editable: true
                                implicitWidth: 84
                                implicitHeight: 34
                                textFromValue: function(val, loc) { return String(val).padStart(2, '0'); }
                                valueFromText: function(txt, loc) { return parseInt(txt) || 0; }

                                contentItem: TextInput {
                                    text: minsSpin.textFromValue(minsSpin.value, minsSpin.locale)
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: Theme.text
                                    horizontalAlignment: Qt.AlignHCenter
                                    verticalAlignment: Qt.AlignVCenter
                                    readOnly: !minsSpin.editable
                                    validator: minsSpin.validator
                                    inputMethodHints: Qt.ImhDigitsOnly
                                }

                                background: Rectangle {
                                    color: Theme.bg
                                    border.color: minsSpin.activeFocus ? Theme.primary : Theme.border
                                    border.width: 1
                                    radius: 6
                                }

                                up.indicator: Rectangle {
                                    x: minsSpin.mirrored ? 0 : minsSpin.width - width
                                    height: minsSpin.height
                                    implicitWidth: 24
                                    implicitHeight: 24
                                    color: minsSpin.up.pressed ? Theme.bgHover : "transparent"

                                    Text {
                                        text: "+"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: Theme.text
                                        anchors.centerIn: parent
                                    }
                                }

                                down.indicator: Rectangle {
                                    x: minsSpin.mirrored ? minsSpin.width - width : 0
                                    height: minsSpin.height
                                    implicitWidth: 24
                                    implicitHeight: 24
                                    color: minsSpin.down.pressed ? Theme.bgHover : "transparent"

                                    Text {
                                        text: "-"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: Theme.text
                                        anchors.centerIn: parent
                                    }
                                }
                            }
                        }

                        // Segundos
                        ColumnLayout {
                            spacing: 2
                            Text {
                                text: "SEGUNDOS"
                                color: Theme.overlay
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                font.bold: true
                            }
                            SpinBox {
                                id: secsSpin
                                from: 0
                                to: 59
                                value: 0
                                editable: true
                                implicitWidth: 84
                                implicitHeight: 34
                                textFromValue: function(val, loc) { return String(val).padStart(2, '0'); }
                                valueFromText: function(txt, loc) { return parseInt(txt) || 0; }

                                contentItem: TextInput {
                                    text: secsSpin.textFromValue(secsSpin.value, secsSpin.locale)
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: Theme.text
                                    horizontalAlignment: Qt.AlignHCenter
                                    verticalAlignment: Qt.AlignVCenter
                                    readOnly: !secsSpin.editable
                                    validator: secsSpin.validator
                                    inputMethodHints: Qt.ImhDigitsOnly
                                }

                                background: Rectangle {
                                    color: Theme.bg
                                    border.color: secsSpin.activeFocus ? Theme.primary : Theme.border
                                    border.width: 1
                                    radius: 6
                                }

                                up.indicator: Rectangle {
                                    x: secsSpin.mirrored ? 0 : secsSpin.width - width
                                    height: secsSpin.height
                                    implicitWidth: 24
                                    implicitHeight: 24
                                    color: secsSpin.up.pressed ? Theme.bgHover : "transparent"

                                    Text {
                                        text: "+"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: Theme.text
                                        anchors.centerIn: parent
                                    }
                                }

                                down.indicator: Rectangle {
                                    x: secsSpin.mirrored ? secsSpin.width - width : 0
                                    height: secsSpin.height
                                    implicitWidth: 24
                                    implicitHeight: 24
                                    color: secsSpin.down.pressed ? Theme.bgHover : "transparent"

                                    Text {
                                        text: "-"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: Theme.text
                                        anchors.centerIn: parent
                                    }
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Botón de Inicio
                        Rectangle {
                            Layout.alignment: Qt.AlignBottom
                            implicitWidth: 160
                            implicitHeight: 34
                            radius: 8
                            color: startMouse.containsMouse ? Qt.darker(Theme.primary, 1.1) : Theme.primary

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: "󰔛"
                                    color: Theme.bg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 15
                                    font.bold: true
                                }

                                Text {
                                    text: "Iniciar Temporizador"
                                    color: Theme.bg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                id: startMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    let ok = ReminderManager.addTimer(titleInput.text, hoursSpin.value, minsSpin.value, secsSpin.value);
                                    if (ok) {
                                        titleInput.text = "";
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // 3. SECCIÓN TEMPORIZADORES EN CURSO
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "TEMPORIZADORES EN CURSO"
                    color: Theme.overlay
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.bold: true
                }

                Rectangle {
                    implicitWidth: countTxt.implicitWidth + 10
                    implicitHeight: 18
                    radius: 9
                    color: ReminderManager.activeTimers.length > 0 ? Theme.primary : Theme.bgSurface
                    border.color: ReminderManager.activeTimers.length > 0 ? Theme.primary : Theme.border
                    border.width: 1

                    Text {
                        id: countTxt
                        anchors.centerIn: parent
                        text: String(ReminderManager.activeTimers.length)
                        color: ReminderManager.activeTimers.length > 0 ? Theme.bg : Theme.overlay
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.bold: true
                    }
                }
            }

            // Lista de Temporizadores Activos
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Theme.radiusMedium
                color: Theme.bgSurface
                border.color: Theme.border
                border.width: 1
                clip: true

                // Vista vacía
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    visible: ReminderManager.activeTimers.length === 0

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "󱎫"
                        color: Theme.overlay
                        font.family: Theme.fontFamily
                        font.pixelSize: 38
                        opacity: 0.5
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "No hay temporizadores activos"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.bold: true
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Usa el formulario superior para programar un temporizador o alarma"
                        color: Theme.overlay
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }
                }

                // Lista de temporizadores
                ListView {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8
                    model: ReminderManager.activeTimers
                    clip: true
                    visible: ReminderManager.activeTimers.length > 0

                    delegate: Rectangle {
                        width: ListView.view.width
                        implicitHeight: 64
                        radius: 8
                        color: Theme.bg
                        border.color: modelData.remainingSeconds <= 0 ? Theme.red : (modelData.running ? Theme.primary : Theme.border)
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 6

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                // Estado icono
                                Text {
                                    text: modelData.remainingSeconds <= 0 ? "⏰" : (modelData.running ? "󱎫" : "󰏤")
                                    color: modelData.remainingSeconds <= 0 ? Theme.red : (modelData.running ? Theme.primary : Theme.overlay)
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 14
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.title
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

                                // Tiempo restante grande
                                Text {
                                    text: modelData.formatted
                                    color: modelData.remainingSeconds <= 0 ? Theme.red : (modelData.running ? Theme.cyan : Theme.overlay)
                                    font.family: Theme.fontFamilyMono || "monospace"
                                    font.pixelSize: 14
                                    font.bold: true
                                }

                                // Botón Pausa / Reanudar
                                Rectangle {
                                    implicitWidth: 26
                                    implicitHeight: 26
                                    radius: 6
                                    color: pauseMouse.containsMouse ? Theme.bgHover : Theme.bgSurface
                                    border.color: Theme.border
                                    border.width: 1
                                    visible: modelData.remainingSeconds > 0

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.running ? "󰏤" : "󰐊"
                                        color: modelData.running ? Theme.text : Theme.green
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12
                                    }

                                    MouseArea {
                                        id: pauseMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: ReminderManager.togglePause(modelData.id)
                                    }
                                }

                                // Botón +1 min
                                Rectangle {
                                    implicitWidth: 32
                                    implicitHeight: 26
                                    radius: 6
                                    color: plusMouse.containsMouse ? Theme.bgHover : Theme.bgSurface
                                    border.color: Theme.border
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "+1m"
                                        color: Theme.text
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 9
                                        font.bold: true
                                    }

                                    MouseArea {
                                        id: plusMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: ReminderManager.addExtraTime(modelData.id, 60)
                                    }
                                }

                                // Botón Eliminar / Cancelar
                                Rectangle {
                                    implicitWidth: 26
                                    implicitHeight: 26
                                    radius: 6
                                    color: delMouse.containsMouse ? Theme.bgHover : Theme.bgSurface
                                    border.color: Theme.border
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅖"
                                        color: delMouse.containsMouse ? Theme.red : Theme.overlay
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12
                                    }

                                    MouseArea {
                                        id: delMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: ReminderManager.deleteTimer(modelData.id)
                                    }
                                }
                            }

                            // Barra de Progreso
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 4
                                radius: 2
                                color: Theme.bgSurface
                                clip: true

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: parent.width * (modelData.progress || 0.0)
                                    radius: 2
                                    color: modelData.remainingSeconds <= 0 ? Theme.red : (modelData.running ? Theme.primary : Theme.overlay)

                                    Behavior on width {
                                        NumberAnimation { duration: 300 }
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
