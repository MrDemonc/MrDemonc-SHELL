import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: netSpeedModalWindow

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    WlrLayershell.namespace: "shell-network-speed-modal"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    visible: NetworkSpeedManager.modalOpen || modalCard.opacity > 0.01

    // Fondo oscurecido (scrim)
    Rectangle {
        id: scrim
        anchors.fill: parent
        color: "#000000"
        opacity: NetworkSpeedManager.modalOpen ? 0.65 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.anim.defaultEffects
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.anim.expressiveDefaultEffects
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: NetworkSpeedManager.modalOpen
            onClicked: NetworkSpeedManager.close()
        }
    }

    // Tarjeta Modal Central
    Rectangle {
        id: modalCard
        anchors.centerIn: parent

        implicitWidth: 840
        implicitHeight: 580
        color: Theme.bg
        border.color: Theme.border
        border.width: 1
        radius: Theme.radiusLarge
        clip: true

        opacity: NetworkSpeedManager.modalOpen ? 1.0 : 0.0
        scale: NetworkSpeedManager.modalOpen ? 1.0 : 0.92

        Behavior on scale {
            NumberAnimation {
                duration: NetworkSpeedManager.modalOpen ? 340 : 180
                easing.type: NetworkSpeedManager.modalOpen ? Easing.OutBack : Easing.InQuad
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
            enabled: NetworkSpeedManager.modalOpen
            onActivated: NetworkSpeedManager.close()
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            // =========================================================
            // 1. FILA DE MÉTRICAS DEL TEST (3 Tarjetas)
            // =========================================================
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Tarjeta Descarga
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 88
                    radius: 12
                    color: Theme.bgSurface
                    border.color: Theme.border
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 4

                        RowLayout {
                            spacing: 6
                            Text {
                                text: "󰇚"
                                color: Theme.cyan
                                font.family: Theme.iconFontFamily
                                font.pixelSize: 13
                            }
                            Text {
                                text: "VELOCIDAD DE DESCARGA"
                                color: Theme.overlay
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                                font.letterSpacing: 0.8
                            }
                        }

                        Text {
                            text: (NetworkSpeedManager.speedTestRunning && NetworkSpeedManager.speedTestPhase === "download") ?
                                  NetworkSpeedManager.testDownloadStr :
                                  (NetworkSpeedManager.testDownload > 0 ? NetworkSpeedManager.testDownloadStr : "--")
                            color: Theme.cyan
                            font.family: Theme.fontFamily
                            font.pixelSize: 22
                            font.bold: true
                        }

                        Text {
                            text: (NetworkSpeedManager.speedTestRunning && NetworkSpeedManager.speedTestPhase === "download") ?
                                  "Midiendo en tiempo real..." :
                                  (NetworkSpeedManager.testDownload > 0 ? `Pico: ${NetworkSpeedManager.testPeakDownload.toFixed(1)} Mbps` : "En espera de prueba")
                            color: Theme.subtext
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }
                    }
                }

                // Tarjeta Subida
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 88
                    radius: 12
                    color: Theme.bgSurface
                    border.color: Theme.border
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 4

                        RowLayout {
                            spacing: 6
                            Text {
                                text: "󰕒"
                                color: Theme.pink
                                font.family: Theme.iconFontFamily
                                font.pixelSize: 13
                            }
                            Text {
                                text: "VELOCIDAD DE SUBIDA"
                                color: Theme.overlay
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                                font.letterSpacing: 0.8
                            }
                        }

                        Text {
                            text: (NetworkSpeedManager.speedTestRunning && NetworkSpeedManager.speedTestPhase === "upload") ?
                                  NetworkSpeedManager.testUploadStr :
                                  (NetworkSpeedManager.testUpload > 0 ? NetworkSpeedManager.testUploadStr : "--")
                            color: Theme.pink
                            font.family: Theme.fontFamily
                            font.pixelSize: 22
                            font.bold: true
                        }

                        Text {
                            text: (NetworkSpeedManager.speedTestRunning && NetworkSpeedManager.speedTestPhase === "upload") ?
                                  "Midiendo en tiempo real..." :
                                  (NetworkSpeedManager.testUpload > 0 ? `Pico: ${NetworkSpeedManager.testPeakUpload.toFixed(1)} Mbps` : "En espera de prueba")
                            color: Theme.subtext
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }
                    }
                }

                // Tarjeta Latencia & Señal
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 88
                    radius: 12
                    color: Theme.bgSurface
                    border.color: Theme.border
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 4

                        RowLayout {
                            spacing: 6
                            Text {
                                text: "󱘖"
                                color: Theme.primary
                                font.family: Theme.iconFontFamily
                                font.pixelSize: 13
                            }
                            Text {
                                text: "LATENCIA & SEÑAL"
                                color: Theme.overlay
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                                font.letterSpacing: 0.8
                            }
                        }

                        Text {
                            text: NetworkSpeedManager.testPing > 0 ? `${NetworkSpeedManager.testPing} ms` :
                                  (NetworkSpeedManager.netData.ping > 0 ? `${NetworkSpeedManager.netData.ping} ms` : "-- ms")
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 22
                            font.bold: true
                        }

                        Text {
                            text: NetworkSpeedManager.netData.type === "wifi" ?
                                  `Señal: ${NetworkSpeedManager.netData.signal}% • ${NetworkSpeedManager.netData.freq || 'Wi-Fi'}` :
                                  "Conexión cableada Ethernet"
                            color: Theme.subtext
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }
                    }
                }
            }

            // =========================================================
            // 2. GRÁFICO DE PRUEBA DE VELOCIDAD (CANVAS 2D)
            // =========================================================
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
                    spacing: 8

                    // Leyenda del Gráfico
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Text {
                            text: "Curva del Test de Velocidad (Mbps)"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                        }

                        Item { Layout.fillWidth: true }

                        // Leyenda Descarga
                        RowLayout {
                            spacing: 5
                            Rectangle {
                                implicitWidth: 10
                                implicitHeight: 10
                                radius: 5
                                color: Theme.cyan
                            }
                            Text {
                                text: `Descarga: ${NetworkSpeedManager.testDownloadStr}`
                                color: Theme.subtext
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }

                        // Leyenda Subida
                        RowLayout {
                            spacing: 5
                            Rectangle {
                                implicitWidth: 10
                                implicitHeight: 10
                                radius: 5
                                color: Theme.pink
                            }
                            Text {
                                text: `Subida: ${NetworkSpeedManager.testUploadStr}`
                                color: Theme.subtext
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }
                    }

                    // Lienzo de Dibujo de Curvas
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Canvas {
                            id: chartCanvas
                            anchors.fill: parent
                            antialiasing: true

                            Connections {
                                target: NetworkSpeedManager
                                function onTestDownloadHistoryChanged() { chartCanvas.requestPaint(); }
                                function onTestUploadHistoryChanged() { chartCanvas.requestPaint(); }
                                function onSpeedTestPhaseChanged() { chartCanvas.requestPaint(); }
                            }

                            onPaint: {
                                let ctx = getContext("2d");
                                ctx.reset();
                                let w = width;
                                let h = height;

                                ctx.clearRect(0, 0, w, h);

                                let dl = NetworkSpeedManager.testDownloadHistory;
                                let ul = NetworkSpeedManager.testUploadHistory;
                                let maxSpeed = Math.max(NetworkSpeedManager.testMaxObservedSpeed, 20.0);

                                // Líneas guía horizontales
                                ctx.strokeStyle = Theme.border;
                                ctx.lineWidth = 1;
                                ctx.setLineDash([3, 3]);

                                for (let i = 1; i <= 3; i++) {
                                    let y = (h / 4) * i;
                                    ctx.beginPath();
                                    ctx.moveTo(35, y);
                                    ctx.lineTo(w - 10, y);
                                    ctx.stroke();

                                    // Etiqueta de velocidad
                                    ctx.fillStyle = Theme.overlay;
                                    ctx.font = "9px sans-serif";
                                    let speedMark = ((4 - i) / 4 * maxSpeed).toFixed(0) + "M";
                                    ctx.fillText(speedMark, 4, y + 3);
                                }
                                ctx.setLineDash([]);

                                let startX = 38;
                                let bottomY = h - 8;
                                let usableWidth = w - 48;
                                let expectedPoints = 25;
                                let maxPoints = Math.max(expectedPoints, dl.length, ul.length);
                                let stepX = usableWidth / Math.max(maxPoints - 1, 1);

                                if (dl.length === 0 && ul.length === 0) {
                                    // Mensaje en espera de test
                                    ctx.fillStyle = Theme.overlay;
                                    ctx.font = "12px sans-serif";
                                    ctx.textAlign = "center";
                                    ctx.fillText("Presiona 'Iniciar Test de Velocidad' para registrar las curvas de red", w / 2, h / 2);
                                    ctx.textAlign = "start";
                                    return;
                                }

                                // 1. Área y Curva de Descarga (Cyan)
                                if (dl.length > 0) {
                                    ctx.beginPath();
                                    for (let i = 0; i < dl.length; i++) {
                                        let x = startX + i * stepX;
                                        let val = Math.min(dl[i], maxSpeed);
                                        let y = bottomY - (val / maxSpeed) * (bottomY - 14);
                                        if (i === 0) ctx.moveTo(x, y);
                                        else ctx.lineTo(x, y);
                                    }
                                    ctx.strokeStyle = Theme.cyan;
                                    ctx.lineWidth = 2.4;
                                    ctx.stroke();

                                    ctx.lineTo(startX + (dl.length - 1) * stepX, bottomY);
                                    ctx.lineTo(startX, bottomY);
                                    ctx.closePath();
                                    let dlGrad = ctx.createLinearGradient(0, 0, 0, bottomY);
                                    dlGrad.addColorStop(0, Theme.cyan + "40");
                                    dlGrad.addColorStop(1, Theme.cyan + "04");
                                    ctx.fillStyle = dlGrad;
                                    ctx.fill();

                                    if (NetworkSpeedManager.speedTestRunning && NetworkSpeedManager.speedTestPhase === "download") {
                                        let lastIdx = dl.length - 1;
                                        let lx = startX + lastIdx * stepX;
                                        let lval = Math.min(dl[lastIdx], maxSpeed);
                                        let ly = bottomY - (lval / maxSpeed) * (bottomY - 14);
                                        ctx.beginPath();
                                        ctx.arc(lx, ly, 4, 0, 2 * Math.PI);
                                        ctx.fillStyle = Theme.cyan;
                                        ctx.fill();
                                    }
                                }

                                // 2. Área y Curva de Subida (Pink)
                                if (ul.length > 0) {
                                    ctx.beginPath();
                                    for (let i = 0; i < ul.length; i++) {
                                        let x = startX + i * stepX;
                                        let val = Math.min(ul[i], maxSpeed);
                                        let y = bottomY - (val / maxSpeed) * (bottomY - 14);
                                        if (i === 0) ctx.moveTo(x, y);
                                        else ctx.lineTo(x, y);
                                    }
                                    ctx.strokeStyle = Theme.pink;
                                    ctx.lineWidth = 2.0;
                                    ctx.stroke();

                                    ctx.lineTo(startX + (ul.length - 1) * stepX, bottomY);
                                    ctx.lineTo(startX, bottomY);
                                    ctx.closePath();
                                    let ulGrad = ctx.createLinearGradient(0, 0, 0, bottomY);
                                    ulGrad.addColorStop(0, Theme.pink + "30");
                                    ulGrad.addColorStop(1, Theme.pink + "04");
                                    ctx.fillStyle = ulGrad;
                                    ctx.fill();

                                    if (NetworkSpeedManager.speedTestRunning && NetworkSpeedManager.speedTestPhase === "upload") {
                                        let lastIdx = ul.length - 1;
                                        let lx = startX + lastIdx * stepX;
                                        let lval = Math.min(ul[lastIdx], maxSpeed);
                                        let ly = bottomY - (lval / maxSpeed) * (bottomY - 14);
                                        ctx.beginPath();
                                        ctx.arc(lx, ly, 4, 0, 2 * Math.PI);
                                        ctx.fillStyle = Theme.pink;
                                        ctx.fill();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // =========================================================
            // 4. PARTE INFERIOR: Parámetros de Red + Test de Velocidad
            // =========================================================
            RowLayout {
                Layout.fillWidth: true
                implicitHeight: 140
                spacing: 12

                // Tarjeta Información Detallada de Red
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 12
                    color: Theme.bgSurface
                    border.color: Theme.border
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        Text {
                            text: "DETALLES DE LA INTERFAZ Y CONEXIÓN"
                            color: Theme.overlay
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                            font.letterSpacing: 0.8
                        }

                        GridLayout {
                            columns: 3
                            rowSpacing: 6
                            columnSpacing: 14
                            Layout.fillWidth: true

                            // Interfaz
                            ColumnLayout {
                                spacing: 1
                                Text { text: "Interfaz"; color: Theme.overlay; font.pixelSize: 9; font.bold: true }
                                Text { text: NetworkSpeedManager.netData.interface; color: Theme.text; font.pixelSize: 11; font.bold: true }
                            }

                            // IPv4
                            ColumnLayout {
                                spacing: 1
                                Text { text: "Dirección IPv4"; color: Theme.overlay; font.pixelSize: 9; font.bold: true }
                                Text { text: NetworkSpeedManager.netData.ip || "--"; color: Theme.text; font.pixelSize: 11 }
                            }

                            // Gateway
                            ColumnLayout {
                                spacing: 1
                                Text { text: "Puerta de Enlace"; color: Theme.overlay; font.pixelSize: 9; font.bold: true }
                                Text { text: NetworkSpeedManager.netData.gateway || "--"; color: Theme.text; font.pixelSize: 11 }
                            }

                            // SSID / Red
                            ColumnLayout {
                                spacing: 1
                                Text { text: "Nombre de Red"; color: Theme.overlay; font.pixelSize: 9; font.bold: true }
                                Text { text: NetworkSpeedManager.netData.ssid || "--"; color: Theme.text; font.pixelSize: 11; elide: Text.ElideRight; Layout.maximumWidth: 140 }
                            }

                            // DNS
                            ColumnLayout {
                                spacing: 1
                                Text { text: "Servidor DNS"; color: Theme.overlay; font.pixelSize: 9; font.bold: true }
                                Text { text: NetworkSpeedManager.netData.dns || "--"; color: Theme.text; font.pixelSize: 11 }
                            }

                            // MAC
                            ColumnLayout {
                                spacing: 1
                                Text { text: "Dirección MAC"; color: Theme.overlay; font.pixelSize: 9; font.bold: true }
                                Text { text: NetworkSpeedManager.netData.mac || "--"; color: Theme.text; font.pixelSize: 11 }
                            }
                        }
                    }
                }

                // Tarjeta Benchmark SpeedTest
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 12
                    color: Theme.bgSurface
                    border.color: Theme.border
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "TEST DE VELOCIDAD BENCHMARK"
                                color: Theme.overlay
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                                font.letterSpacing: 0.8
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                visible: NetworkSpeedManager.speedTestPhase === "done"
                                implicitHeight: 18
                                implicitWidth: doneTxt.implicitWidth + 10
                                radius: 9
                                color: Theme.success
                                opacity: 0.2
                                Text {
                                    id: doneTxt
                                    anchors.centerIn: parent
                                    text: "Completado"
                                    color: Theme.success
                                    font.pixelSize: 9
                                    font.bold: true
                                }
                            }
                        }

                        // Estado Inactivo (Botón Iniciar)
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: !NetworkSpeedManager.speedTestRunning && NetworkSpeedManager.speedTestPhase !== "done"

                            Rectangle {
                                anchors.centerIn: parent
                                implicitWidth: Math.max(260, startBtnRow.implicitWidth + 40)
                                implicitHeight: 40
                                radius: 10
                                color: startTestMouse.containsMouse ? Theme.primary : Theme.bgHover
                                border.color: Theme.primary
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: 150 } }

                                RowLayout {
                                    id: startBtnRow
                                    anchors.centerIn: parent
                                    spacing: 8

                                    Text {
                                        text: "󰓅"
                                        color: startTestMouse.containsMouse ? (Theme.isDark ? "#11111b" : "#ffffff") : Theme.primary
                                        font.family: Theme.iconFontFamily
                                        font.pixelSize: 14
                                    }

                                    Text {
                                        text: "Iniciar Test de Velocidad"
                                        color: startTestMouse.containsMouse ? (Theme.isDark ? "#11111b" : "#ffffff") : Theme.text
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12
                                        font.bold: true
                                    }
                                }

                                MouseArea {
                                    id: startTestMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: NetworkSpeedManager.startSpeedTest()
                                }
                            }
                        }

                        // Estado Ejecutando (Barra de progreso + mensaje)
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: NetworkSpeedManager.speedTestRunning
                            spacing: 6

                            Text {
                                text: NetworkSpeedManager.speedTestMessage || "Ejecutando test..."
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.bold: true
                            }

                            // Barra de progreso animada
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 8
                                radius: 4
                                color: Theme.bgHover

                                Rectangle {
                                    height: parent.height
                                    width: parent.width * Math.max(0.05, Math.min(1.0, NetworkSpeedManager.speedTestProgress))
                                    radius: 4
                                    color: Theme.primary

                                    Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }
                                }
                            }

                            Text {
                                text: NetworkSpeedManager.speedTestPhase === "download" ? "Midiendo tasa de bajada..." :
                                      (NetworkSpeedManager.speedTestPhase === "upload" ? "Midiendo tasa de subida..." : "Comprobando servidor...")
                                color: Theme.subtext
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                            }
                        }

                        // Estado Completado (Resultados + Botón Repetir)
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: !NetworkSpeedManager.speedTestRunning && NetworkSpeedManager.speedTestPhase === "done"
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                // Resultado Ping
                                ColumnLayout {
                                    spacing: 1
                                    Text { text: "Ping"; color: Theme.overlay; font.pixelSize: 9; font.bold: true }
                                    Text { text: `${NetworkSpeedManager.testPing} ms`; color: Theme.text; font.pixelSize: 12; font.bold: true }
                                }

                                // Resultado Descarga
                                ColumnLayout {
                                    spacing: 1
                                    Text { text: "Descarga"; color: Theme.cyan; font.pixelSize: 9; font.bold: true }
                                    Text { text: NetworkSpeedManager.testDownloadStr; color: Theme.cyan; font.pixelSize: 13; font.bold: true }
                                }

                                // Resultado Subida
                                ColumnLayout {
                                    spacing: 1
                                    Text { text: "Subida"; color: Theme.pink; font.pixelSize: 9; font.bold: true }
                                    Text { text: NetworkSpeedManager.testUploadStr; color: Theme.pink; font.pixelSize: 13; font.bold: true }
                                }

                                Item { Layout.fillWidth: true }

                                // Botón Repetir
                                Rectangle {
                                    implicitWidth: 32
                                    implicitHeight: 32
                                    radius: 8
                                    color: repeatMouse.containsMouse ? Theme.bgHover : "transparent"
                                    border.color: Theme.border
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰑐"
                                        color: Theme.primary
                                        font.family: Theme.iconFontFamily
                                        font.pixelSize: 14
                                    }

                                    MouseArea {
                                        id: repeatMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: NetworkSpeedManager.startSpeedTest()
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
