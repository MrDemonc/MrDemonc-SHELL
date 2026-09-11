import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: keybindsModalWindow

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    WlrLayershell.namespace: "shell-keybinds-modal"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: KeybindsManager.keybindsOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    visible: KeybindsManager.keybindsOpen || modalCard.opacity > 0.01

    onVisibleChanged: {
        if (visible && KeybindsManager.keybindsOpen) {
            searchInput.text = "";
            KeybindsManager.searchQuery = "";
            KeybindsManager.selectedCategory = "all";
            searchInput.forceActiveFocus();
        }
    }

    // Fondo oscurecido (scrim)
    Rectangle {
        id: scrim
        anchors.fill: parent
        color: "#000000"
        opacity: KeybindsManager.keybindsOpen ? 0.65 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.anim.defaultEffects
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.anim.expressiveDefaultEffects
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: KeybindsManager.keybindsOpen
            onClicked: KeybindsManager.keybindsOpen = false
        }
    }

    // Tarjeta Modal Central Minimalista
    Rectangle {
        id: modalCard
        anchors.centerIn: parent

        implicitWidth: 680
        implicitHeight: 490
        color: Theme.bg
        border.color: Theme.border
        border.width: 1
        radius: Theme.radiusLarge
        clip: true

        opacity: KeybindsManager.keybindsOpen ? 1.0 : 0.0
        scale: KeybindsManager.keybindsOpen ? 1.0 : 0.90

        Behavior on scale {
            NumberAnimation {
                duration: KeybindsManager.keybindsOpen ? 340 : 180
                easing.type: KeybindsManager.keybindsOpen ? Easing.OutBack : Easing.InQuad
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
            enabled: KeybindsManager.keybindsOpen
            onActivated: KeybindsManager.keybindsOpen = false
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // =================================================================
            // 1. BUSCADOR EN TIEMPO REAL
            // =================================================================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 42
                radius: 10
                color: Theme.bgSurface
                border.color: searchInput.activeFocus ? Theme.primary : Theme.border
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Text {
                        text: "󰍉"
                        font.family: Theme.iconFontFamily
                        font.pixelSize: 16
                        color: searchInput.activeFocus ? Theme.primary : Theme.overlay
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        color: Theme.text
                        selectByMouse: true

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !searchInput.text && !searchInput.inputMethodComposing
                            text: "Buscar atajo de teclado..."
                            color: Theme.overlay
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                        }

                        onTextChanged: {
                            KeybindsManager.searchQuery = text;
                        }

                        Keys.onEscapePressed: {
                            if (text.length > 0) {
                                text = "";
                            } else {
                                KeybindsManager.keybindsOpen = false;
                            }
                        }
                    }

                    // Contador de resultados
                    Text {
                        text: KeybindsManager.filteredKeybinds.length + " atajos"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: Theme.overlay
                    }
                }
            }

            // =================================================================
            // 2. BARRA DE FILTROS POR CATEGORÍA
            // =================================================================
            Flickable {
                Layout.fillWidth: true
                implicitHeight: 32
                contentWidth: categoryRow.implicitWidth
                contentHeight: 32
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                RowLayout {
                    id: categoryRow
                    spacing: 6

                    Repeater {
                        model: KeybindsManager.categories
                        delegate: Rectangle {
                            required property var modelData
                            implicitHeight: 30
                            implicitWidth: catRow.implicitWidth + 18
                            radius: 8
                            readonly property bool isSelected: KeybindsManager.selectedCategory === modelData.id
                            color: isSelected ? Theme.primary : (catMouse.containsMouse ? Theme.bgHover : Theme.bgSurface)
                            border.color: isSelected ? Theme.primary : Theme.border
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 120 } }

                            RowLayout {
                                id: catRow
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: modelData.icon
                                    font.family: Theme.iconFontFamily
                                    font.pixelSize: 12
                                    color: parent.parent.isSelected ? Theme.bgSurface : Theme.text
                                }

                                Text {
                                    text: modelData.name
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.bold: parent.parent.isSelected
                                    color: parent.parent.isSelected ? Theme.bgSurface : Theme.text
                                }
                            }

                            MouseArea {
                                id: catMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: KeybindsManager.selectedCategory = modelData.id
                            }
                        }
                    }
                }
            }

            // =================================================================
            // 3. LISTA MINIMALISTA DE ATAJOS DE TECLADO
            // =================================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Theme.bgSurface
                border.color: Theme.border
                border.width: 1
                radius: 12
                clip: true

                ListView {
                    id: keybindsListView
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6
                    clip: true
                    model: KeybindsManager.filteredKeybinds

                    delegate: Rectangle {
                        required property var modelData
                        width: keybindsListView.width
                        implicitHeight: 38
                        radius: 8
                        color: rowMouse.containsMouse ? Theme.bgHover : Theme.bg
                        border.color: rowMouse.containsMouse ? Theme.primary : Theme.border
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 12

                            // Título de la Acción
                            Text {
                                text: modelData ? modelData.title : ""
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                font.bold: true
                                color: Theme.text
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            // Columna de Teclas (Key Caps estilo KBD)
                            RowLayout {
                                spacing: 4

                                Repeater {
                                    model: modelData ? modelData.keys : []
                                    delegate: RowLayout {
                                        required property var modelData
                                        required property int index
                                        spacing: 4

                                        // Signo '+' entre teclas
                                        Text {
                                            visible: index > 0
                                            text: "+"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: Theme.overlay
                                        }

                                        // Key Cap
                                        Rectangle {
                                            implicitWidth: Math.max(26, keyTxt.implicitWidth + 12)
                                            implicitHeight: 24
                                            radius: 6
                                            color: Theme.bgSurface
                                            border.color: Theme.primary
                                            border.width: 1.2

                                            Text {
                                                id: keyTxt
                                                anchors.centerIn: parent
                                                text: modelData
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: Theme.primary
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                        }
                    }

                    // Mensaje cuando no hay resultados de búsqueda
                    ColumnLayout {
                        anchors.centerIn: parent
                        visible: KeybindsManager.filteredKeybinds.length === 0
                        spacing: 8

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "󰌌"
                            font.family: Theme.iconFontFamily
                            font.pixelSize: 36
                            color: Theme.overlay
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "No se encontraron atajos para \"" + KeybindsManager.searchQuery + "\""
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            color: Theme.overlay
                        }
                    }
                }
            }
        }
    }
}
