import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: calendarModalWindow

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    WlrLayershell.namespace: "shell-calendar-modal"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    visible: CalendarManager.calendarOpen || modalCard.opacity > 0.01

    onVisibleChanged: {
        if (visible && CalendarManager.calendarOpen) {
            CalendarManager.updateDaysModel();
        }
    }

    // Fondo oscurecido (scrim)
    Rectangle {
        id: scrim
        anchors.fill: parent
        color: "#000000"
        opacity: CalendarManager.calendarOpen ? 0.65 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.anim.defaultEffects
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.anim.expressiveDefaultEffects
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: CalendarManager.calendarOpen
            onClicked: CalendarManager.close()
        }
    }

    // Tarjeta Modal Central
    Rectangle {
        id: modalCard
        anchors.centerIn: parent

        implicitWidth: 760
        implicitHeight: 510
        color: Theme.bg
        border.color: Theme.border
        border.width: 1
        radius: Theme.radiusLarge
        clip: true

        opacity: CalendarManager.calendarOpen ? 1.0 : 0.0
        scale: CalendarManager.calendarOpen ? 1.0 : 0.92

        Behavior on scale {
            NumberAnimation {
                duration: CalendarManager.calendarOpen ? 340 : 180
                easing.type: CalendarManager.calendarOpen ? Easing.OutBack : Easing.InQuad
                easing.overshoot: 1.15
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.anim.defaultEffects
            }
        }

        // Atajo Escape para cerrar la ventana
        Shortcut {
            sequence: "Escape"
            enabled: CalendarManager.calendarOpen
            onActivated: CalendarManager.close()
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // =========================================================
            // COLUMNA IZQUIERDA: Reloj, Día de Hoy y Tarjeta de Fecha
            // =========================================================
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 290
                color: Theme.bgSurface
                border.color: Theme.border
                border.width: 0

                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1
                    color: Theme.border
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 22
                    spacing: 16

                    // Badge de encabezado
                    Rectangle {
                        implicitHeight: 26
                        implicitWidth: badgeRow.implicitWidth + 16
                        radius: 13
                        color: Theme.bgHover
                        border.color: Theme.primary
                        border.width: 1

                        RowLayout {
                            id: badgeRow
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: "󰸗"
                                color: Theme.primary
                                font.family: Theme.iconFontFamily
                                font.pixelSize: 13
                            }

                            Text {
                                text: "CALENDARIO"
                                color: Theme.primary
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.bold: true
                                font.letterSpacing: 1.2
                            }
                        }
                    }

                    // Reloj digital en vivo
                    ColumnLayout {
                        spacing: 2

                        Text {
                            text: CalendarManager.liveTimeStr
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 36
                            font.bold: true
                        }

                        Text {
                            text: CalendarManager.todayDayName
                            color: Theme.primary
                            font.family: Theme.fontFamily
                            font.pixelSize: 20
                            font.bold: true
                        }

                        Text {
                            text: `${CalendarManager.todayDate.getDate()} de ${CalendarManager.todayMonthName} de ${CalendarManager.todayDate.getFullYear()}`
                            color: Theme.subtext
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                        }
                    }

                    // Badges de Semana y Día del año
                    RowLayout {
                        spacing: 8

                        Rectangle {
                            implicitHeight: 24
                            implicitWidth: weekTxt.implicitWidth + 12
                            radius: 6
                            color: Theme.bgHover
                            border.color: Theme.border
                            border.width: 1

                            Text {
                                id: weekTxt
                                anchors.centerIn: parent
                                text: `Semana ${CalendarManager.weekNumber}`
                                color: Theme.subtext
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.bold: true
                            }
                        }

                        Rectangle {
                            implicitHeight: 24
                            implicitWidth: dayYearTxt.implicitWidth + 12
                            radius: 6
                            color: Theme.bgHover
                            border.color: Theme.border
                            border.width: 1

                            Text {
                                id: dayYearTxt
                                anchors.centerIn: parent
                                text: `Día ${CalendarManager.dayOfYear} de 365`
                                color: Theme.subtext
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.bold: true
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // Tarjeta de Día Seleccionado
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: selDayCol.implicitHeight + 20
                        radius: 12
                        color: Theme.bg
                        border.color: Theme.border
                        border.width: 1

                        ColumnLayout {
                            id: selDayCol
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 6

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: "FECHA SELECCIONADA"
                                    color: Theme.overlay
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.bold: true
                                    font.letterSpacing: 0.8
                                    Layout.fillWidth: true
                                }

                                Rectangle {
                                    implicitHeight: 18
                                    implicitWidth: diffTxt.implicitWidth + 10
                                    radius: 9
                                    color: Theme.primary
                                    opacity: 0.2

                                    Text {
                                        id: diffTxt
                                        anchors.centerIn: parent
                                        text: CalendarManager.getDaysDiffText(CalendarManager.selectedDate)
                                        color: Theme.primary
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.bold: true
                                    }
                                }
                            }

                            Text {
                                text: CalendarManager.selectedFormattedDate
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                font.bold: true
                                wrapMode: Text.Wrap
                                Layout.fillWidth: true
                            }
                        }
                    }

                    // Botón para volver a Hoy
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 38
                        radius: 10
                        color: todayBtnMouse.containsMouse ? Theme.primary : Theme.bgHover
                        border.color: Theme.primary
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: "󰥔"
                                color: todayBtnMouse.containsMouse ? Theme.bgSurface : Theme.primary
                                font.family: Theme.iconFontFamily
                                font.pixelSize: 14
                            }

                            Text {
                                text: "Ir a la fecha actual"
                                color: todayBtnMouse.containsMouse ? Theme.bgSurface : Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.bold: true
                            }
                        }

                        MouseArea {
                            id: todayBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: CalendarManager.goToToday()
                        }
                    }
                }
            }

            // =========================================================
            // COLUMNA DERECHA: Cuadrícula Mensual Navegable
            // =========================================================
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 22
                    spacing: 14

                    // Encabezado de Navegación de Mes y Año
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        // Título del Mes y Año
                        Text {
                            text: CalendarManager.viewedMonthYearStr
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 20
                            font.bold: true
                            Layout.fillWidth: true
                        }

                        // Botón Mes Anterior
                        Rectangle {
                            implicitWidth: 32
                            implicitHeight: 32
                            radius: 8
                            color: prevMonthMouse.containsMouse ? Theme.bgHover : "transparent"
                            border.color: Theme.border
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "󰅁"
                                color: Theme.text
                                font.family: Theme.iconFontFamily
                                font.pixelSize: 16
                            }

                            MouseArea {
                                id: prevMonthMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: CalendarManager.prevMonth()
                            }
                        }

                        // Botón Mes Siguiente
                        Rectangle {
                            implicitWidth: 32
                            implicitHeight: 32
                            radius: 8
                            color: nextMonthMouse.containsMouse ? Theme.bgHover : "transparent"
                            border.color: Theme.border
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "󰅂"
                                color: Theme.text
                                font.family: Theme.iconFontFamily
                                font.pixelSize: 16
                            }

                            MouseArea {
                                id: nextMonthMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: CalendarManager.nextMonth()
                            }
                        }

                        // Botón Año Anterior
                        Rectangle {
                            implicitWidth: 32
                            implicitHeight: 32
                            radius: 8
                            color: prevYearMouse.containsMouse ? Theme.bgHover : "transparent"
                            border.color: Theme.border
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "«"
                                color: Theme.subtext
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                                font.bold: true
                            }

                            MouseArea {
                                id: prevYearMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: CalendarManager.prevYear()
                            }
                        }

                        // Botón Año Siguiente
                        Rectangle {
                            implicitWidth: 32
                            implicitHeight: 32
                            radius: 8
                            color: nextYearMouse.containsMouse ? Theme.bgHover : "transparent"
                            border.color: Theme.border
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "»"
                                color: Theme.subtext
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                                font.bold: true
                            }

                            MouseArea {
                                id: nextYearMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: CalendarManager.nextYear()
                            }
                        }

                        // Botón Cerrar (✕)
                        Rectangle {
                            implicitWidth: 32
                            implicitHeight: 32
                            radius: 8
                            color: closeMouse.containsMouse ? Theme.danger : "transparent"
                            border.color: closeMouse.containsMouse ? Theme.danger : Theme.border
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 120 } }

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                color: closeMouse.containsMouse ? "#ffffff" : Theme.subtext
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                font.bold: true
                            }

                            MouseArea {
                                id: closeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: CalendarManager.close()
                            }
                        }
                    }

                    // Fila de Días de la Semana (Lun a Dom)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Repeater {
                            model: CalendarManager.dayNamesShort

                            Item {
                                Layout.fillWidth: true
                                implicitHeight: 26

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: (index === 5 || index === 6) ? Theme.primary : Theme.overlay
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                            }
                        }
                    }

                    // Cuadrícula 7x6 (42 Días)
                    Item {
                        id: gridContainer
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Grid {
                            id: daysGrid
                            anchors.fill: parent
                            columns: 7
                            rowSpacing: 4
                            columnSpacing: 4

                            readonly property real cellWidth: (width - 6 * columnSpacing) / 7
                            readonly property real cellHeight: (height - 5 * rowSpacing) / 6

                            Repeater {
                                model: CalendarManager.daysModel

                                Rectangle {
                                    id: dayCell
                                    width: daysGrid.cellWidth
                                    height: daysGrid.cellHeight
                                    radius: 10

                                    readonly property bool isToday: modelData.isToday
                                    readonly property bool isSelected: modelData.isSelected
                                    readonly property bool isCurrentMonth: modelData.isCurrentMonth
                                    readonly property bool isWeekend: modelData.isWeekend

                                    // Colores de fondo dinámicos según el estado
                                    color: {
                                        if (isToday) return Theme.primary;
                                        if (isSelected) return Theme.bgHover;
                                        if (cellMouse.containsMouse) return Theme.bgHover;
                                        return "transparent";
                                    }

                                    border.color: {
                                        if (isToday) return Theme.primary;
                                        if (isSelected) return Theme.primary;
                                        if (cellMouse.containsMouse) return Theme.border;
                                        return "transparent";
                                    }
                                    border.width: (isSelected && !isToday) ? 1.5 : 1

                                    Behavior on color { ColorAnimation { duration: 120 } }
                                    Behavior on scale { NumberAnimation { duration: 100 } }
                                    scale: cellMouse.pressed ? 0.94 : (cellMouse.containsMouse ? 1.05 : 1.0)

                                    // Indicador numérico del día
                                    Text {
                                        anchors.centerIn: parent
                                        text: String(modelData.dayNumber)
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 13
                                        font.bold: dayCell.isToday || dayCell.isSelected

                                        color: {
                                            if (dayCell.isToday) return Theme.bgSurface;
                                            if (!dayCell.isCurrentMonth) return Theme.overlay;
                                            if (dayCell.isSelected) return Theme.primary;
                                            if (dayCell.isWeekend) return Theme.primary;
                                            return Theme.text;
                                        }

                                        opacity: dayCell.isCurrentMonth ? 1.0 : 0.35
                                    }

                                    // Pequeño punto para indicar el día de hoy si no está seleccionado
                                    Rectangle {
                                        visible: dayCell.isToday && dayCell.isSelected
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: 3
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 4
                                        height: 4
                                        radius: 2
                                        color: Theme.bgSurface
                                    }

                                    MouseArea {
                                        id: cellMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: CalendarManager.selectDay(modelData.date)
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
