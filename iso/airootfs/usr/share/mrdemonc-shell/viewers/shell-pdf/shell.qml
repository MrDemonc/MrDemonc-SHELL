import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "./components"

FloatingWindow {
    id: win

    title: currentFilename ? (currentFilename + " - Visor de PDF") : "Visor de PDF"
    color: Theme.bg
    visible: true

    implicitWidth: 880
    implicitHeight: 700

    property string currentPath: Quickshell.env("TARGET_FILE") || ""
    property string currentFilename: currentPath ? currentPath.split('/').pop() : ""
    property string renderDir: "/tmp/shell_pdf_" + Math.abs(currentPath.split('').reduce((a,b)=>{a=((a<<5)-a)+b.charCodeAt(0);return a&a},0))
    property int totalPages: 0
    property real pageWidth: 612
    property real pageHeight: 792
    property real zoomFactor: 1.0
    property bool isDarkMode: true
    property bool isFullscreen: false
    property bool controlsVisible: true
    property int currentPageVisible: 1

    property var readyMap: ({})
    property int renderVersion: 0

    function closeApp() {
        Quickshell.execDetached(["kill", "-9", String(Quickshell.processId)]);
    }

    function toggleFullscreen() {
        isFullscreen = !isFullscreen;
        win.fullscreen = isFullscreen;
    }

    function getPageSource(index) {
        let p = index + 1;
        if (readyMap[p]) {
            return "file://" + renderDir + "/page_" + p + ".png";
        }
        return "";
    }

    // Proceso unificado: Renderizador progresivo de PDF
    Process {
        id: renderProc
        command: [
            "python3",
            Quickshell.shellDir + "/scripts/pdf_render.py",
            win.currentPath,
            win.renderDir
        ]
        running: win.currentPath !== ""
        stdout: SplitParser {
            onRead: function(line) {
                try {
                    let str = String(line).trim();
                    if (str.length > 0 && str.startsWith("{")) {
                        let d = JSON.parse(str);
                        if (d.status === "info") {
                            win.totalPages = d.pages || 1;
                            win.pageWidth = d.w || 612;
                            win.pageHeight = d.h || 792;
                        } else if (d.status === "page") {
                            win.readyMap[d.page] = true;
                            win.renderVersion++;
                        }
                    }
                } catch(e) {}
            }
        }
    }

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

    // Captura global de teclado
    Item {
        anchors.fill: parent
        focus: true

        Keys.onPressed: function(event) {
            pingControls();
            if (event.key === Qt.Key_Escape || event.key === Qt.Key_Q) {
                closeApp();
                event.accepted = true;
            } else if (event.key === Qt.Key_PageDown || event.key === Qt.Key_Space || event.key === Qt.Key_J) {
                pdfListView.flick(0, -1800);
                event.accepted = true;
            } else if (event.key === Qt.Key_PageUp || event.key === Qt.Key_K) {
                pdfListView.flick(0, 1800);
                event.accepted = true;
            } else if (event.key === Qt.Key_Down) {
                pdfListView.flick(0, -600);
                event.accepted = true;
            } else if (event.key === Qt.Key_Up) {
                pdfListView.flick(0, 600);
                event.accepted = true;
            } else if (event.key === Qt.Key_Home) {
                pdfListView.positionViewAtBeginning();
                event.accepted = true;
            } else if (event.key === Qt.Key_End) {
                pdfListView.positionViewAtEnd();
                event.accepted = true;
            } else if (event.key === Qt.Key_Plus || event.key === Qt.Key_Equal) {
                zoomFactor = Math.min(3.0, zoomFactor * 1.25);
                event.accepted = true;
            } else if (event.key === Qt.Key_Minus || event.key === Qt.Key_Underscore) {
                zoomFactor = Math.max(0.25, zoomFactor / 1.25);
                event.accepted = true;
            } else if (event.key === Qt.Key_0) {
                zoomFactor = 1.0;
                event.accepted = true;
            } else if (event.key === Qt.Key_I || event.key === Qt.Key_D) {
                isDarkMode = !isDarkMode;
                event.accepted = true;
            } else if (event.key === Qt.Key_F11 || event.key === Qt.Key_F) {
                toggleFullscreen();
                event.accepted = true;
            }
        }
    }

    // VISTA DE DOCUMENTO CONTINUA VERTICAL (Desplazamiento fluido hacia abajo)
    ListView {
        id: pdfListView
        anchors.fill: parent
        orientation: ListView.Vertical
        spacing: 16
        topMargin: 20
        bottomMargin: 70
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        model: win.totalPages

        onContentYChanged: {
            pingControls();
            let idx = indexAt(width / 2, contentY + 140);
            if (idx >= 0) {
                win.currentPageVisible = idx + 1;
            }
        }

        delegate: Rectangle {
            id: pageCard
            anchors.horizontalCenter: parent.horizontalCenter

            // Ancho responsivo adaptado al zoom (hacia arriba y abajo con fidelidad)
            width: Math.max(200, (pdfListView.width - 64) * win.zoomFactor)
            height: (win.pageWidth > 0) ? (width * (win.pageHeight / win.pageWidth)) : (width * 1.414)

            radius: 4
            color: win.isDarkMode ? "#16181f" : "#ffffff"
            border.color: win.isDarkMode ? Theme.border : "#d0d7de"
            border.width: 1

            // Imagen de la página renderizada reactiva a renderVersion
            Image {
                id: pageImg
                anchors.fill: parent
                source: (win.renderVersion >= 0) ? win.getPageSource(index) : ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                cache: true
                smooth: true
                mipmap: true
            }

            // Indicador de carga sutil mientras la página se procesa
            Rectangle {
                anchors.centerIn: parent
                width: 36
                height: 36
                radius: 18
                color: Theme.bgHover
                visible: pageImg.status !== Image.Ready

                Text {
                    anchors.centerIn: parent
                    text: "󰑮"
                    color: Theme.primary
                    font.family: Theme.iconFontFamily
                    font.pixelSize: 15

                    RotationAnimation on rotation {
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 1000
                    }
                }
            }

            // Capa de modo lectura nocturno (suaviza contraste sin cegar)
            Rectangle {
                anchors.fill: parent
                color: "#12141a"
                opacity: win.isDarkMode ? 0.35 : 0.0
                Behavior on opacity { NumberAnimation { duration: 180 } }
            }
        }

        // Manejo de rueda de ratón para desplazamiento o zoom con Ctrl
        WheelHandler {
            target: pdfListView
            onWheel: function(event) {
                pingControls();
                if (event.modifiers & Qt.ControlModifier) {
                    let factor = event.angleDelta.y > 0 ? 1.2 : 0.833;
                    win.zoomFactor = Math.max(0.25, Math.min(3.0, win.zoomFactor * factor));
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            propagateComposedEvents: true
            onPositionChanged: pingControls()
            onPressed: function(mouse) { pingControls(); mouse.accepted = false; }
        }
    }

    // Top Badge: Nombre del documento y páginas
    Rectangle {
        id: topBadge
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 14
        implicitHeight: 28
        implicitWidth: topRow.implicitWidth + 24
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
                text: win.currentFilename || "Visor de PDF"
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
                text: win.totalPages > 0 ? (win.totalPages + " páginas") : "Cargando..."
                color: Theme.subtext
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }
        }
    }

    // Píldora de controles flotante minimalista (SIN BOTÓN DE CERRAR)
    Rectangle {
        id: controlPill
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 18
        implicitHeight: 38
        implicitWidth: pillLayout.implicitWidth + 20
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

            // Página Anterior (󰒮)
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
                    onClicked: {
                        pingControls();
                        let prevIdx = Math.max(0, win.currentPageVisible - 2);
                        pdfListView.positionViewAtIndex(prevIdx, ListView.Beginning);
                    }
                }
            }

            // Indicador de Página (Pág X / Y)
            Text {
                text: "Pág " + win.currentPageVisible + " / " + Math.max(1, win.totalPages)
                color: Theme.subtext
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.bold: true
                Layout.leftMargin: 4
                Layout.rightMargin: 4
            }

            // Página Siguiente (󰒭)
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
                    onClicked: {
                        pingControls();
                        let nextIdx = Math.min(win.totalPages - 1, win.currentPageVisible);
                        pdfListView.positionViewAtIndex(nextIdx, ListView.Beginning);
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
                        win.zoomFactor = Math.max(0.25, win.zoomFactor / 1.25);
                    }
                }
            }

            // Botón Reset / Fit
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
                        win.zoomFactor = Math.min(3.0, win.zoomFactor * 1.25);
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

            // Modo Oscuro / Lectura Nocturna (󰔎)
            Rectangle {
                implicitWidth: 30
                implicitHeight: 30
                radius: 15
                color: win.isDarkMode ? Theme.bgHover : (darkHover.containsMouse ? Theme.bgHover : "transparent")
                Text {
                    anchors.centerIn: parent
                    text: "󰔎"
                    color: win.isDarkMode ? Theme.primary : (darkHover.containsMouse ? Theme.primary : Theme.text)
                    font.family: Theme.iconFontFamily
                    font.pixelSize: 13
                }
                MouseArea {
                    id: darkHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        pingControls();
                        win.isDarkMode = !win.isDarkMode;
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
