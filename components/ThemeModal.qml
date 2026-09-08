import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: themeModalWindow

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    WlrLayershell.namespace: "shell-theme-modal"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: PopoutManager.themeModalOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    visible: PopoutManager.themeModalOpen || modalCard.scale > 0.01

    onVisibleChanged: {
        if (visible) {
            keyCatcher.forceActiveFocus();
            for (let i = 0; i < Theme.availableThemes.length; i++) {
                if (Theme.availableThemes[i].isCurrent || Theme.availableThemes[i].id === Theme.activeThemeId) {
                    Theme.previewIndex = i;
                    themeListView.positionViewAtIndex(i, ListView.Center);
                    break;
                }
            }
        }
    }

    // Fondo oscurecido con transición suave
    Rectangle {
        id: scrim
        anchors.fill: parent
        color: "#000000"
        opacity: PopoutManager.themeModalOpen ? 0.65 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.anim.defaultEffects
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.anim.expressiveDefaultEffects
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: PopoutManager.themeModalOpen = false
        }
    }

    // Tarjeta Modal Minimalista con expansión circular y rebote
    Rectangle {
        id: modalCard
        anchors.centerIn: parent
        implicitWidth: 640
        implicitHeight: 420
        color: Theme.bg
        border.color: Theme.border
        border.width: 1
        clip: true

        opacity: PopoutManager.themeModalOpen ? 1.0 : 0.0
        scale: PopoutManager.themeModalOpen ? 1.0 : 0.0
        radius: PopoutManager.themeModalOpen ? 16 : 320

        Behavior on scale {
            NumberAnimation {
                duration: PopoutManager.themeModalOpen ? 420 : 220
                easing.type: PopoutManager.themeModalOpen ? Easing.OutBack : Easing.InQuad
                easing.overshoot: 1.4
            }
        }

        Behavior on radius {
            NumberAnimation {
                duration: PopoutManager.themeModalOpen ? 420 : 220
                easing.type: PopoutManager.themeModalOpen ? Easing.OutBack : Easing.InQuad
                easing.overshoot: 1.4
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: PopoutManager.themeModalOpen ? 180 : 200
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            // Header Minimalista: Solo Título (sin X de cerrar)
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Temas"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                    font.bold: true
                }
            }

            // Split Horizontal: Lista a la izquierda, Preview a la derecha
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 20

                // 1. Panel Izquierdo: Lista limpia sin contenedor/borde exterior
                Item {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 220

                    ListView {
                        id: themeListView
                        anchors.fill: parent
                        clip: true
                        spacing: 4
                        model: Theme.availableThemes
                        currentIndex: Theme.previewIndex

                        delegate: Item {
                            id: itemDelegate
                            required property var modelData
                            required property int index
                            width: themeListView.width
                            implicitHeight: 40

                            readonly property bool isSelected: Theme.previewIndex === index
                            readonly property bool isCurrent: modelData.isCurrent || modelData.id === Theme.activeThemeId

                            // Animación de entrada fluida escalonada
                            opacity: PopoutManager.themeModalOpen ? 1.0 : 0.0
                            transform: Translate {
                                x: PopoutManager.themeModalOpen ? 0 : -10
                                Behavior on x {
                                    NumberAnimation {
                                        duration: Theme.anim.fastSpatial + (index * 15)
                                        easing.type: Easing.BezierSpline
                                        easing.bezierCurve: Theme.anim.expressiveDefaultSpatial
                                    }
                                }
                            }

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: Theme.anim.defaultEffects + (index * 12)
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 4
                                anchors.rightMargin: 8
                                spacing: 8

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    // Nombre Grande del Tema (sin fondo ni borde)
                                    Text {
                                        text: modelData.name || modelData.id
                                        color: isCurrent ? Theme.primary : (isSelected ? Theme.text : Theme.overlay)
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 13
                                        font.bold: isCurrent || isSelected
                                        elide: Text.ElideRight

                                        Behavior on color { ColorAnimation { duration: 120 } }
                                    }

                                    Text {
                                        text: modelData.isDark ? "Oscuro" : "Claro"
                                        color: Theme.overlay
                                        opacity: 0.7
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 9
                                    }
                                }

                                // Indicador a la derecha: Visto si es el tema activo, punto si está enfocado/navegando (sin ser el activo)
                                Item {
                                    implicitWidth: 16
                                    implicitHeight: 16

                                    // Visto solo para el tema activo
                                    Text {
                                        anchors.centerIn: parent
                                        visible: isCurrent
                                        text: "󰄬"
                                        color: Theme.primary
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 13
                                    }

                                    // Punto sutil solo cuando está seleccionado al navegar (y no es el tema activo)
                                    Rectangle {
                                        anchors.centerIn: parent
                                        visible: !isCurrent && (isSelected || itemMouse.containsMouse)
                                        width: 5
                                        height: 5
                                        radius: 2.5
                                        color: Theme.primary
                                        opacity: 0.8
                                    }
                                }
                            }

                            MouseArea {
                                id: itemMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Theme.previewIndex = index;
                                    Theme.setTheme(modelData.id);
                                }
                            }
                        }
                    }
                }

                // 2. Panel Derecho: Previsualización Minimalista sincronizada globalmente
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 12
                    color: Theme.previewThemeData ? (Theme.previewThemeData.bg || Theme.bgSurface) : Theme.bgSurface
                    border.color: Theme.previewThemeData ? (Theme.previewThemeData.border || Theme.border) : Theme.border
                    border.width: 1
                    clip: true

                    Behavior on color { ColorAnimation { duration: 180 } }
                    Behavior on border.color { ColorAnimation { duration: 180 } }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 16

                        // Título Grande del Tema Seleccionado
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: Theme.previewThemeData ? (Theme.previewThemeData.name || "") : ""
                                color: Theme.previewThemeData ? (Theme.previewThemeData.primary || Theme.primary) : Theme.primary
                                font.family: Theme.fontFamily
                                font.pixelSize: 18
                                font.bold: true
                            }

                            Item { Layout.fillWidth: true }

                            Rectangle {
                                implicitWidth: modeText.implicitWidth + 12
                                implicitHeight: 20
                                radius: 5
                                color: Theme.previewThemeData ? (Theme.previewThemeData.bgSurface || Theme.bgHover) : Theme.bgHover

                                Text {
                                    id: modeText
                                    anchors.centerIn: parent
                                    text: Theme.previewThemeData ? (Theme.previewThemeData.isDark ? "󰖔 Oscuro" : "󰖙 Claro") : ""
                                    color: Theme.previewThemeData ? (Theme.previewThemeData.text || Theme.text) : Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                }
                            }
                        }

                        // Mockup Mini de la Barra Superior
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 28
                            radius: 6
                            color: Theme.previewThemeData ? (Theme.previewThemeData.bgSurface || Theme.bgSurface) : Theme.bgSurface
                            border.color: Theme.previewThemeData ? (Theme.previewThemeData.border || Theme.border) : Theme.border
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 6

                                Text {
                                    text: "1  2  3"
                                    color: Theme.previewThemeData ? (Theme.previewThemeData.text || Theme.text) : Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: "󰕾 80%  󰤨  󰁹 95%"
                                    color: Theme.previewThemeData ? (Theme.previewThemeData.primary || Theme.primary) : Theme.primary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                }
                            }
                        }

                        // Muestras de la Paleta de Colores
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Repeater {
                                model: Theme.previewThemeData ? [
                                    Theme.previewThemeData.primary,
                                    Theme.previewThemeData.cyan,
                                    Theme.previewThemeData.success,
                                    Theme.previewThemeData.warning,
                                    Theme.previewThemeData.danger,
                                    Theme.previewThemeData.pink
                                ] : []

                                Rectangle {
                                    required property var modelData
                                    implicitWidth: 26
                                    implicitHeight: 26
                                    radius: 7
                                    color: modelData || "transparent"
                                    border.color: "#22000000"
                                    border.width: 1

                                    scale: swatchMouse.containsMouse ? 1.15 : 1.0
                                    Behavior on scale { NumberAnimation { duration: 100 } }

                                    MouseArea {
                                        id: swatchMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                    }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }

                        // Botón de Aplicar Tema
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 34
                            radius: 8
                            color: (Theme.previewThemeData && Theme.previewThemeData.id === Theme.activeThemeId) ? (Theme.previewThemeData.primary || Theme.primary) : (applyMouse.containsMouse ? Theme.bgHover : Theme.bgSurface)
                            border.color: Theme.previewThemeData ? (Theme.previewThemeData.primary || Theme.primary) : Theme.primary
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: (Theme.previewThemeData && Theme.previewThemeData.id === Theme.activeThemeId) ? "󰄬 Tema Aplicado" : "Aplicar este Tema (Enter)"
                                color: (Theme.previewThemeData && Theme.previewThemeData.id === Theme.activeThemeId) ? (Theme.isDark ? "#11111b" : "#ffffff") : (Theme.previewThemeData ? (Theme.previewThemeData.primary || Theme.primary) : Theme.primary)
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.bold: true
                            }

                            MouseArea {
                                id: applyMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (Theme.previewThemeData) {
                                        Theme.setTheme(Theme.previewThemeData.id);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Receptor de eventos de teclado
    Item {
        id: keyCatcher
        anchors.fill: parent
        focus: PopoutManager.themeModalOpen

        Keys.onEscapePressed: {
            PopoutManager.themeModalOpen = false;
        }

        Keys.onUpPressed: {
            if (Theme.availableThemes && Theme.availableThemes.length > 0) {
                Theme.previewIndex = (Theme.previewIndex - 1 + Theme.availableThemes.length) % Theme.availableThemes.length;
                themeListView.positionViewAtIndex(Theme.previewIndex, ListView.Contain);
            }
        }

        Keys.onDownPressed: {
            if (Theme.availableThemes && Theme.availableThemes.length > 0) {
                Theme.previewIndex = (Theme.previewIndex + 1) % Theme.availableThemes.length;
                themeListView.positionViewAtIndex(Theme.previewIndex, ListView.Contain);
            }
        }

        Keys.onLeftPressed: {
            if (Theme.availableThemes && Theme.availableThemes.length > 0) {
                Theme.previewIndex = (Theme.previewIndex - 1 + Theme.availableThemes.length) % Theme.availableThemes.length;
                themeListView.positionViewAtIndex(Theme.previewIndex, ListView.Contain);
            }
        }

        Keys.onRightPressed: {
            if (Theme.availableThemes && Theme.availableThemes.length > 0) {
                Theme.previewIndex = (Theme.previewIndex + 1) % Theme.availableThemes.length;
                themeListView.positionViewAtIndex(Theme.previewIndex, ListView.Contain);
            }
        }

        Keys.onReturnPressed: {
            if (Theme.previewThemeData) {
                Theme.setTheme(Theme.previewThemeData.id);
            }
        }

        Keys.onSpacePressed: {
            if (Theme.previewThemeData) {
                Theme.setTheme(Theme.previewThemeData.id);
            }
        }
    }
}
