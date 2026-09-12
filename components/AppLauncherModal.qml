import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: appLauncherWindow

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    WlrLayershell.namespace: "shell-app-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: AppLauncherManager.appLauncherOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    visible: AppLauncherManager.appLauncherOpen || modalCard.scale > 0.01

    onVisibleChanged: {
        if (visible && AppLauncherManager.appLauncherOpen) {
            searchInput.text = "";
            searchInput.forceActiveFocus();
            AppLauncherManager.refreshApps();
        }
    }

    // Fondo oscurecido con transición suave
    Rectangle {
        id: scrim
        anchors.fill: parent
        color: "#000000"
        opacity: AppLauncherManager.appLauncherOpen ? 0.65 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.anim.defaultEffects
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.anim.expressiveDefaultEffects
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: AppLauncherManager.appLauncherOpen = false
        }
    }

    // Tarjeta Modal con tamaño inicial minimizado y expansión dinámica al buscar
    Rectangle {
        id: modalCard
        anchors.centerIn: parent

        readonly property bool hasSearch: AppLauncherManager.searchQuery.trim().length > 0
        readonly property int targetHeight: {
            if (!hasSearch) {
                let recCount = AppLauncherManager.recentApps ? AppLauncherManager.recentApps.length : 0;
                return recCount > 0 ? (95 + recCount * 50) : 74;
            }
            let count = AppLauncherManager.filteredApps ? AppLauncherManager.filteredApps.length : 0;
            if (count === 0) return 130;
            return Math.min(480, 95 + Math.min(count, 7) * 50);
        }

        implicitWidth: 540
        implicitHeight: targetHeight
        color: Theme.bg
        border.color: Theme.border
        border.width: 1
        clip: true

        opacity: AppLauncherManager.appLauncherOpen ? 1.0 : 0.0
        scale: AppLauncherManager.appLauncherOpen ? 1.0 : 0.0
        radius: AppLauncherManager.appLauncherOpen ? 16 : 270

        // Animación de aparición circular y rebote
        Behavior on scale {
            NumberAnimation {
                duration: AppLauncherManager.appLauncherOpen ? 420 : 220
                easing.type: AppLauncherManager.appLauncherOpen ? Easing.OutBack : Easing.InQuad
                easing.overshoot: 1.35
            }
        }

        Behavior on radius {
            NumberAnimation {
                duration: AppLauncherManager.appLauncherOpen ? 420 : 220
                easing.type: AppLauncherManager.appLauncherOpen ? Easing.OutBack : Easing.InQuad
                easing.overshoot: 1.35
            }
        }

        // Animación fluida al estirarse / contraerse según las búsquedas
        Behavior on implicitHeight {
            NumberAnimation {
                duration: Theme.anim.fastSpatial
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.anim.expressiveDefaultSpatial
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: AppLauncherManager.appLauncherOpen ? 180 : 200
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            // 1. Buscador Limpio (sin contenedor ni caja anidada)
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                spacing: 12

                Text {
                    text: "󰍉"
                    color: searchInput.activeFocus ? Theme.accent : Theme.overlay
                    font.family: Theme.iconFontFamily
                    font.pixelSize: 18
                    Layout.alignment: Qt.AlignVCenter
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    selectByMouse: true
                    clip: true

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !searchInput.text && !searchInput.inputMethodComposing
                        text: "Buscar aplicaciones..."
                        color: Theme.overlay
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                    }

                    onTextChanged: {
                        AppLauncherManager.searchQuery = text;
                    }

                    Keys.onEscapePressed: {
                        AppLauncherManager.appLauncherOpen = false;
                    }

                    Keys.onUpPressed: {
                        let activeList = modalCard.hasSearch ? AppLauncherManager.filteredApps : AppLauncherManager.recentApps;
                        if (activeList && activeList.length > 0) {
                            AppLauncherManager.selectedIndex = (AppLauncherManager.selectedIndex - 1 + activeList.length) % activeList.length;
                            appListView.positionViewAtIndex(AppLauncherManager.selectedIndex, ListView.Contain);
                        }
                    }

                    Keys.onDownPressed: {
                        let activeList = modalCard.hasSearch ? AppLauncherManager.filteredApps : AppLauncherManager.recentApps;
                        if (activeList && activeList.length > 0) {
                            AppLauncherManager.selectedIndex = (AppLauncherManager.selectedIndex + 1) % activeList.length;
                            appListView.positionViewAtIndex(AppLauncherManager.selectedIndex, ListView.Contain);
                        }
                    }

                    Keys.onReturnPressed: {
                        AppLauncherManager.launchCurrent();
                    }
                }

                // Contador de resultados cuando hay búsqueda
                Text {
                    visible: modalCard.hasSearch
                    text: AppLauncherManager.filteredApps ? AppLauncherManager.filteredApps.length : "0"
                    color: Theme.overlay
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            // Separador horizontal sutil
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.border
            }

            // Contenedor de Lista (Recientes o Resultados filtrados)
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ListView {
                    id: appListView
                    anchors.fill: parent
                    clip: true
                    spacing: 4
                    model: modalCard.hasSearch ? AppLauncherManager.filteredApps : AppLauncherManager.recentApps
                    currentIndex: AppLauncherManager.selectedIndex

                    delegate: Item {
                        id: appDelegate
                        required property var modelData
                        required property int index
                        width: appListView.width
                        implicitHeight: 46

                        readonly property bool isSelected: AppLauncherManager.selectedIndex === index

                        // Fondo sutil al seleccionar o hover
                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: isSelected ? Theme.bgHover : (appMouse.containsMouse ? Theme.bgSurface : "transparent")
                            opacity: isSelected ? 0.85 : 1.0

                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        // Contenedor de Icono con posición y dimensiones fijas
                        Item {
                            id: iconBox
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            width: 28
                            height: 28

                            Image {
                                id: appIcon
                                anchors.fill: parent
                                source: modelData.iconPath ? ("file://" + modelData.iconPath) : ""
                                sourceSize.width: 28
                                sourceSize.height: 28
                                asynchronous: true
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                visible: modelData.iconPath !== ""
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: 6
                                color: Theme.bgHover
                                visible: !modelData.iconPath || modelData.iconPath === ""

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰣆"
                                    color: Theme.primary
                                    font.family: Theme.iconFontFamily
                                    font.pixelSize: 13
                                }
                            }
                        }

                        // Indicador de selección: Punto sutil al navegar
                        Rectangle {
                            id: selDot
                            anchors.right: parent.right
                            anchors.rightMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            visible: isSelected || appMouse.containsMouse
                            width: 5
                            height: 5
                            radius: 2.5
                            color: Theme.primary
                            opacity: 0.9
                        }

                        // Columna de Textos perfectamente anclada y alineada a la izquierda
                        Column {
                            anchors.left: iconBox.right
                            anchors.leftMargin: 12
                            anchors.right: selDot.left
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Text {
                                width: parent.width
                                text: modelData.name || ""
                                color: isSelected ? Theme.primary : Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                font.bold: isSelected
                                elide: Text.ElideRight

                                Behavior on color { ColorAnimation { duration: 120 } }
                            }

                            Text {
                                width: parent.width
                                text: modelData.comment || modelData.genericName || modelData.exec || ""
                                color: Theme.overlay
                                opacity: 0.75
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: appMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                AppLauncherManager.selectedIndex = index;
                                AppLauncherManager.launchApp(modelData.exec, modelData.terminal, modelData.name);
                                AppLauncherManager.appLauncherOpen = false;
                            }
                        }
                    }

                    // Mensaje cuando no hay resultados para la búsqueda
                    Item {
                        anchors.fill: parent
                        visible: modalCard.hasSearch && (!AppLauncherManager.filteredApps || AppLauncherManager.filteredApps.length === 0)

                        Text {
                            anchors.centerIn: parent
                            text: "No se encontraron aplicaciones"
                            color: Theme.overlay
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }
}
