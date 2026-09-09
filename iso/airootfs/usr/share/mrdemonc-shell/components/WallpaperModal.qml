import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: wallpaperModalWindow

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    WlrLayershell.namespace: "shell-wallpaper-modal"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WallpaperManager.wallpaperModalOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    visible: WallpaperManager.wallpaperModalOpen || modalCard.scale > 0.01

    onVisibleChanged: {
        if (visible) {
            keyCatcher.forceActiveFocus();
            WallpaperManager.refreshList();
            for (let i = 0; i < WallpaperManager.availableWallpapers.length; i++) {
                if (WallpaperManager.availableWallpapers[i].path === WallpaperManager.currentWallpaper) {
                    WallpaperManager.previewIndex = i;
                    wallpaperListView.positionViewAtIndex(i, ListView.Center);
                    break;
                }
            }
        }
    }

    function applyCurrentSelection() {
        if (WallpaperManager.previewWallpaperData) {
            WallpaperManager.setWallpaper(WallpaperManager.previewWallpaperData.path);
            WallpaperManager.wallpaperModalOpen = false;
        }
    }

    function openExplorerAndClose() {
        WallpaperManager.wallpaperModalOpen = false;
        WallpaperManager.openFolder();
    }

    // Fondo oscurecido con transición suave
    Rectangle {
        id: scrim
        anchors.fill: parent
        color: "#000000"
        opacity: WallpaperManager.wallpaperModalOpen ? 0.65 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.anim.defaultEffects
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.anim.expressiveDefaultEffects
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: WallpaperManager.wallpaperModalOpen = false
        }
    }

    // Tarjeta Modal Minimalista con expansión circular y rebote
    Rectangle {
        id: modalCard
        anchors.centerIn: parent
        implicitWidth: 660
        implicitHeight: 440
        color: Theme.bg
        border.color: Theme.border
        border.width: 1
        clip: true

        opacity: WallpaperManager.wallpaperModalOpen ? 1.0 : 0.0
        scale: WallpaperManager.wallpaperModalOpen ? 1.0 : 0.0
        radius: WallpaperManager.wallpaperModalOpen ? 16 : 330

        Behavior on scale {
            NumberAnimation {
                duration: WallpaperManager.wallpaperModalOpen ? 420 : 220
                easing.type: WallpaperManager.wallpaperModalOpen ? Easing.OutBack : Easing.InQuad
                easing.overshoot: 1.4
            }
        }

        Behavior on radius {
            NumberAnimation {
                duration: WallpaperManager.wallpaperModalOpen ? 420 : 220
                easing.type: WallpaperManager.wallpaperModalOpen ? Easing.OutBack : Easing.InQuad
                easing.overshoot: 1.4
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: WallpaperManager.wallpaperModalOpen ? 180 : 200
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            // Header Minimalista con atajo [i] para abrir explorador
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Fondos de Pantalla"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                    font.bold: true
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    implicitWidth: folderHintText.implicitWidth + 12
                    implicitHeight: 22
                    radius: 6
                    color: folderMouse.containsMouse ? Theme.bgHover : Theme.bgSurface
                    border.color: Theme.border
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        id: folderHintText
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            text: "󰉋 [i] Abrir Carpeta"
                            color: folderMouse.containsMouse ? Theme.primary : Theme.overlay
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }

                    MouseArea {
                        id: folderMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: wallpaperModalWindow.openExplorerAndClose()
                    }
                }
            }

            // Split Horizontal: Lista a la izquierda, Preview grande a la derecha
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 20

                // 1. Panel Izquierdo: Lista limpia de fondos
                Item {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 230

                    ListView {
                        id: wallpaperListView
                        anchors.fill: parent
                        clip: true
                        spacing: 4
                        model: WallpaperManager.availableWallpapers
                        currentIndex: WallpaperManager.previewIndex

                        delegate: Item {
                            id: itemDelegate
                            required property var modelData
                            required property int index
                            width: wallpaperListView.width
                            implicitHeight: 40

                            readonly property bool isSelected: WallpaperManager.previewIndex === index
                            readonly property bool isCurrent: modelData.path === WallpaperManager.currentWallpaper

                            // Animación de entrada
                            opacity: WallpaperManager.wallpaperModalOpen ? 1.0 : 0.0
                            transform: Translate {
                                x: WallpaperManager.wallpaperModalOpen ? 0 : -10
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

                                    Text {
                                        text: modelData.name || modelData.fileName
                                        color: isCurrent ? Theme.primary : (isSelected ? Theme.text : Theme.overlay)
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 13
                                        font.bold: isCurrent || isSelected
                                        elide: Text.ElideRight

                                        Behavior on color { ColorAnimation { duration: 120 } }
                                    }

                                    Text {
                                        text: modelData.fileName
                                        color: Theme.overlay
                                        opacity: 0.6
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 9
                                        elide: Text.ElideRight
                                    }
                                }

                                // Indicador a la derecha: Visto si está activo, punto si está seleccionado
                                Item {
                                    implicitWidth: 16
                                    implicitHeight: 16

                                    // Visto solo para el wallpaper activo
                                    Text {
                                        anchors.centerIn: parent
                                        visible: isCurrent
                                        text: "󰄬"
                                        color: Theme.primary
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 13
                                    }

                                    // Punto sutil cuando navega con teclado o ratón
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
                                    WallpaperManager.previewIndex = index;
                                    wallpaperModalWindow.applyCurrentSelection();
                                }
                            }
                        }
                    }
                }

                // 2. Panel Derecho: Preview del Wallpaper seleccionado sincronizado entre pantallas
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 12
                    color: Theme.bgSurface
                    border.color: Theme.border
                    border.width: 1
                    clip: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        // Marco de imagen
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 8
                            color: "#000000"
                            clip: true

                            Image {
                                id: previewImage
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                source: WallpaperManager.previewWallpaperData ? ("file://" + WallpaperManager.previewWallpaperData.path) : ""
                                asynchronous: true
                                cache: false
                                smooth: true
                            }
                        }

                        // Información inferior
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                Layout.fillWidth: true
                                text: WallpaperManager.previewWallpaperData ? WallpaperManager.previewWallpaperData.name : "Sin selección"
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: (WallpaperManager.previewWallpaperData && WallpaperManager.previewWallpaperData.path === WallpaperManager.currentWallpaper) ? "󰄬 Activo" : "Enter para aplicar"
                                color: (WallpaperManager.previewWallpaperData && WallpaperManager.previewWallpaperData.path === WallpaperManager.currentWallpaper) ? Theme.primary : Theme.overlay
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
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
        focus: WallpaperManager.wallpaperModalOpen

        Keys.onEscapePressed: {
            WallpaperManager.wallpaperModalOpen = false;
        }

        // Tecla "i" o "I" para abrir el explorador de archivos y cerrar el modal
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_I) {
                wallpaperModalWindow.openExplorerAndClose();
                event.accepted = true;
            }
        }

        Keys.onUpPressed: {
            if (WallpaperManager.availableWallpapers && WallpaperManager.availableWallpapers.length > 0) {
                WallpaperManager.previewIndex = (WallpaperManager.previewIndex - 1 + WallpaperManager.availableWallpapers.length) % WallpaperManager.availableWallpapers.length;
                wallpaperListView.positionViewAtIndex(WallpaperManager.previewIndex, ListView.Contain);
            }
        }

        Keys.onDownPressed: {
            if (WallpaperManager.availableWallpapers && WallpaperManager.availableWallpapers.length > 0) {
                WallpaperManager.previewIndex = (WallpaperManager.previewIndex + 1) % WallpaperManager.availableWallpapers.length;
                wallpaperListView.positionViewAtIndex(WallpaperManager.previewIndex, ListView.Contain);
            }
        }

        Keys.onReturnPressed: {
            wallpaperModalWindow.applyCurrentSelection();
        }

        Keys.onSpacePressed: {
            wallpaperModalWindow.applyCurrentSelection();
        }
    }
}
