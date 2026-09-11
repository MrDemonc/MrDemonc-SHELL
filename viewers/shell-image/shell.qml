import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "./components"

FloatingWindow {
    id: win

    title: currentFilename ? (currentFilename + " - Visor de Imágenes") : "Visor de Imágenes"
    color: Theme.bg
    visible: true

    implicitWidth: 920
    implicitHeight: 620

    property string currentPath: Quickshell.env("TARGET_FILE") || ""
    property string currentFilename: currentPath ? currentPath.split('/').pop() : ""
    property var imageList: []
    property int currentIndex: 0
    property real zoomFactor: 1.0
    property real imgRotation: 0
    property bool isFullscreen: false
    property bool controlsVisible: true

    function closeApp() {
        Quickshell.execDetached(["kill", "-9", String(Quickshell.processId)]);
    }

    function toggleFullscreen() {
        isFullscreen = !isFullscreen;
        if (isFullscreen) {
            win.fullscreen = true;
        } else {
            win.fullscreen = false;
        }
    }

    function prevImage() {
        if (imageList.length > 1) {
            currentIndex = (currentIndex - 1 + imageList.length) % imageList.length;
            currentPath = imageList[currentIndex];
            zoomFactor = 1.0;
            imgRotation = 0;
        }
    }

    function nextImage() {
        if (imageList.length > 1) {
            currentIndex = (currentIndex + 1) % imageList.length;
            currentPath = imageList[currentIndex];
            zoomFactor = 1.0;
            imgRotation = 0;
        }
    }

    // Cargar lista de imágenes en el mismo directorio
    Process {
        id: dirScanner
        command: [
            "python3", "-c",
            "import os, sys, json\np = sys.argv[1]\nd = os.path.dirname(os.path.abspath(p)) if p else os.getcwd()\nexts = ('.png','.jpg','.jpeg','.webp','.svg','.gif','.bmp','.avif','.ico')\nfiles = sorted([os.path.join(d, f) for f in os.listdir(d) if f.lower().endswith(exts) and not f.startswith('.')])\nprint(json.dumps(files))",
            win.currentPath
        ]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                try {
                    let files = JSON.parse(String(line).trim());
                    if (Array.isArray(files) && files.length > 0) {
                        win.imageList = files;
                        let idx = files.indexOf(win.currentPath);
                        win.currentIndex = (idx !== -1) ? idx : 0;
                    }
                } catch(e) {}
            }
        }
    }

    // Timer de auto-ocultado para controles minimalistas
    Timer {
        id: autoHideTimer
        interval: 2500
        running: true
        repeat: false
        onTriggered: {
            if (!pillMouseArea.containsMouse) {
                win.controlsVisible = false;
            }
        }
    }

    function pingControls() {
        win.controlsVisible = true;
        autoHideTimer.restart();
    }

    // Captura global de eventos de teclado
    Item {
        anchors.fill: parent
        focus: true

        Keys.onPressed: function(event) {
            pingControls();
            if (event.key === Qt.Key_Escape || event.key === Qt.Key_Q) {
                closeApp();
                event.accepted = true;
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
                prevImage();
                event.accepted = true;
            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
                nextImage();
                event.accepted = true;
            } else if (event.key === Qt.Key_Plus || event.key === Qt.Key_Equal) {
                zoomFactor = Math.min(8.0, zoomFactor * 1.25);
                event.accepted = true;
            } else if (event.key === Qt.Key_Minus || event.key === Qt.Key_Underscore) {
                zoomFactor = Math.max(0.15, zoomFactor / 1.25);
                event.accepted = true;
            } else if (event.key === Qt.Key_0) {
                zoomFactor = 1.0;
                imgRotation = 0;
                event.accepted = true;
            } else if (event.key === Qt.Key_R) {
                imgRotation = (imgRotation + 90) % 360;
                event.accepted = true;
            } else if (event.key === Qt.Key_F11 || event.key === Qt.Key_F) {
                toggleFullscreen();
                event.accepted = true;
            }
        }
    }

    property real baseFitScale: {
        if (mainImage.sourceSize.width <= 0 || mainImage.sourceSize.height <= 0 || flick.width <= 0 || flick.height <= 0) return 1.0;
        return Math.min(flick.width / mainImage.sourceSize.width, flick.height / mainImage.sourceSize.height);
    }

    // Área principal de visualización con Flickable y Zoom nativo
    Flickable {
        id: flick
        anchors.fill: parent
        clip: true

        contentWidth: Math.max(width, imageWrapper.width)
        contentHeight: Math.max(height, imageWrapper.height)
        boundsBehavior: Flickable.StopAtBounds

        Item {
            id: imageWrapper
            width: Math.max(flick.width, mainImage.width)
            height: Math.max(flick.height, mainImage.height)

            Image {
                id: mainImage
                anchors.centerIn: parent
                source: win.currentPath ? ("file://" + win.currentPath) : ""
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
                asynchronous: true
                cache: true

                width: Math.max(20, (sourceSize.width > 0 ? (sourceSize.width * win.baseFitScale) : flick.width) * win.zoomFactor)
                height: Math.max(20, (sourceSize.height > 0 ? (sourceSize.height * win.baseFitScale) : flick.height) * win.zoomFactor)

                rotation: win.imgRotation
                Behavior on rotation { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            }
        }

        // Manejador de rueda del ratón para Zoom fluido centrado
        WheelHandler {
            target: flick
            onWheel: function(event) {
                pingControls();
                let factor = event.angleDelta.y > 0 ? 1.2 : 0.833;
                let nextZoom = Math.max(0.1, Math.min(10.0, win.zoomFactor * factor));
                if (Math.abs(nextZoom - 1.0) < 0.05) {
                    nextZoom = 1.0;
                }
                win.zoomFactor = nextZoom;
            }
        }

        // MouseArea para detectar movimiento y doble clic
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: win.zoomFactor > 1.0 ? Qt.OpenHandCursor : Qt.ArrowCursor
            onPositionChanged: pingControls()
            onDoubleClicked: {
                if (win.zoomFactor !== 1.0) {
                    win.zoomFactor = 1.0;
                } else {
                    win.zoomFactor = 2.0;
                }
            }
            onPressed: pingControls()
        }
    }

    // Top Badge: Nombre y resolución (área superior limpia)
    Rectangle {
        id: topBadge
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 14
        implicitHeight: 28
        implicitWidth: topRow.implicitWidth + 20
        radius: 14
        color: Theme.bgSurface
        border.color: Theme.border
        border.width: 1
        opacity: win.controlsVisible ? 0.90 : 0.0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        RowLayout {
            id: topRow
            anchors.centerIn: parent
            spacing: 8

            Text {
                text: win.currentFilename || "Sin imagen"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.bold: true
                elide: Text.ElideMiddle
                Layout.maximumWidth: 350
            }

            Text {
                text: "•"
                color: Theme.border
                font.pixelSize: 10
            }

            Text {
                text: mainImage.sourceSize.width > 0 ? (mainImage.sourceSize.width + "×" + mainImage.sourceSize.height) : "--"
                color: Theme.subtext
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }
        }
    }

    // Barra de controles flotante minimalista (SIN BOTÓN DE CERRAR)
    Rectangle {
        id: controlPill
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 18
        implicitHeight: 38
        implicitWidth: pillLayout.implicitWidth + 16
        radius: 19
        color: Theme.bgSurface
        border.color: Theme.border
        border.width: 1
        opacity: win.controlsVisible ? 0.94 : 0.0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        MouseArea {
            id: pillMouseArea
            anchors.fill: parent
            hoverEnabled: true
            onEntered: pingControls()
            onPositionChanged: pingControls()
        }

        RowLayout {
            id: pillLayout
            anchors.centerIn: parent
            spacing: 4

            // Botón Anterior (󰒮)
            Rectangle {
                implicitWidth: 30
                implicitHeight: 30
                radius: 15
                color: prevHover.containsMouse ? Theme.bgHover : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "󰒮"
                    color: prevHover.containsMouse ? Theme.primary : Theme.text
                    font.family: Theme.iconFontFamily
                    font.pixelSize: 13
                }
                MouseArea {
                    id: prevHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { pingControls(); prevImage(); }
                }
            }

            // Indicador de imagen (X / Total)
            Text {
                text: (win.currentIndex + 1) + " / " + Math.max(1, win.imageList.length)
                color: Theme.subtext
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.bold: true
                Layout.leftMargin: 4
                Layout.rightMargin: 4
            }

            // Botón Siguiente (󰒭)
            Rectangle {
                implicitWidth: 30
                implicitHeight: 30
                radius: 15
                color: nextHover.containsMouse ? Theme.bgHover : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "󰒭"
                    color: nextHover.containsMouse ? Theme.primary : Theme.text
                    font.family: Theme.iconFontFamily
                    font.pixelSize: 13
                }
                MouseArea {
                    id: nextHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { pingControls(); nextImage(); }
                }
            }

            // Separador
            Rectangle {
                implicitWidth: 1
                implicitHeight: 18
                color: Theme.border
                Layout.leftMargin: 2
                Layout.rightMargin: 2
            }

            // Zoom Out (󰍊)
            Rectangle {
                implicitWidth: 30
                implicitHeight: 30
                radius: 15
                color: zOutHover.containsMouse ? Theme.bgHover : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "󰍊"
                    color: zOutHover.containsMouse ? Theme.primary : Theme.text
                    font.family: Theme.iconFontFamily
                    font.pixelSize: 13
                }
                MouseArea {
                    id: zOutHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        pingControls();
                        win.zoomFactor = Math.max(0.15, win.zoomFactor / 1.25);
                    }
                }
            }

            // Botón / Label Zoom (Ajustar / 100%)
            Rectangle {
                implicitWidth: 62
                implicitHeight: 26
                radius: 13
                color: zFitHover.containsMouse ? Theme.bgHover : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: win.zoomFactor === 1.0 ? "Ajustar" : (Math.round(win.zoomFactor * 100) + "%")
                    color: Theme.primary
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.bold: true
                }
                MouseArea {
                    id: zFitHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        pingControls();
                        win.zoomFactor = 1.0;
                    }
                }
            }

            // Zoom In (󰍉)
            Rectangle {
                implicitWidth: 30
                implicitHeight: 30
                radius: 15
                color: zInHover.containsMouse ? Theme.bgHover : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "󰍉"
                    color: zInHover.containsMouse ? Theme.primary : Theme.text
                    font.family: Theme.iconFontFamily
                    font.pixelSize: 13
                }
                MouseArea {
                    id: zInHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        pingControls();
                        win.zoomFactor = Math.min(8.0, win.zoomFactor * 1.25);
                    }
                }
            }

            // Separador
            Rectangle {
                implicitWidth: 1
                implicitHeight: 18
                color: Theme.border
                Layout.leftMargin: 2
                Layout.rightMargin: 2
            }

            // Rotar (󰑓)
            Rectangle {
                implicitWidth: 30
                implicitHeight: 30
                radius: 15
                color: rotHover.containsMouse ? Theme.bgHover : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "󰑓"
                    color: rotHover.containsMouse ? Theme.primary : Theme.text
                    font.family: Theme.iconFontFamily
                    font.pixelSize: 13
                }
                MouseArea {
                    id: rotHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        pingControls();
                        win.imgRotation = (win.imgRotation + 90) % 360;
                    }
                }
            }

            // Pantalla Completa (󰊓)
            Rectangle {
                implicitWidth: 30
                implicitHeight: 30
                radius: 15
                color: fsHover.containsMouse ? Theme.bgHover : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: win.isFullscreen ? "󰊔" : "󰊓"
                    color: fsHover.containsMouse ? Theme.primary : Theme.text
                    font.family: Theme.iconFontFamily
                    font.pixelSize: 13
                }
                MouseArea {
                    id: fsHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        pingControls();
                        toggleFullscreen();
                    }
                }
            }
        }
    }
}
