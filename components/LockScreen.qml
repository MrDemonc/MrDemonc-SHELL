import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

WlSessionLock {
    id: sessionLockRoot

    locked: LockScreenManager.isLocked

    surface: Component {
        WlSessionLockSurface {
            id: lockSurface
            color: "#0a0c12"

            Item {
                id: lockContainer
                anchors.fill: parent
                focus: true

                // -------------------------------------------------------------
                // 0. ANIMACIÓN DE TRANSICIÓN AL BLOQUEAR Y DESBLOQUEAR
                // -------------------------------------------------------------
                property bool surfaceReady: false

                opacity: LockScreenManager.isUnlocking ? 0.0 : (surfaceReady ? 1.0 : 0.0)
                scale: LockScreenManager.isUnlocking ? 1.05 : (surfaceReady ? 1.0 : 1.02)
                transform: Translate {
                    y: LockScreenManager.isUnlocking ? -18 : (lockContainer.surfaceReady ? 0 : 14)
                    Behavior on y {
                        NumberAnimation {
                            duration: LockScreenManager.isUnlocking ? 240 : 340
                            easing.type: LockScreenManager.isUnlocking ? Easing.InQuad : Easing.OutCubic
                        }
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: LockScreenManager.isUnlocking ? 240 : 320
                        easing.type: LockScreenManager.isUnlocking ? Easing.InQuad : Easing.OutCubic
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: LockScreenManager.isUnlocking ? 240 : 360
                        easing.type: LockScreenManager.isUnlocking ? Easing.InQuad : Easing.OutCubic
                    }
                }

                // -------------------------------------------------------------
                // 1. FONDO CON DESENFOQUE Y WALLPAPER DE LA SHELL
                // -------------------------------------------------------------
                Image {
                    id: bgWallpaper
                    anchors.fill: parent
                    source: WallpaperManager.currentWallpaper ? (WallpaperManager.currentWallpaper.startsWith("file://") ? WallpaperManager.currentWallpaper : ("file://" + WallpaperManager.currentWallpaper)) : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                }

                // Capa de oscurecimiento y efecto frosted glass
                Rectangle {
                    anchors.fill: parent
                    color: "#0a0c12"
                    opacity: 0.72
                }

                // Malla de gradiente radial sutil para profundidad estética
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#25000000" }
                        GradientStop { position: 0.6; color: "#55000000" }
                        GradientStop { position: 1.0; color: "#95000000" }
                    }
                }

                // Clic en cualquier punto mantiene el foco siempre activo en el teclado
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        pwdInput.forceActiveFocus();
                    }
                }

                // -------------------------------------------------------------
                // 2. BARRA SUPERIOR DE WIDGETS E INFORMACIÓN DEL SISTEMA
                // -------------------------------------------------------------
                Item {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 56

                    // Píldora flotante izquierda: Info de Hardware (Hostname, CPU, RAM)
                    Rectangle {
                        anchors.left: parent.left
                        anchors.leftMargin: 28
                        anchors.verticalCenter: parent.verticalCenter
                        height: 32
                        implicitWidth: hwRow.implicitWidth + 24
                        radius: 16
                        color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.65)
                        border.color: Theme.border
                        border.width: 1

                        RowLayout {
                            id: hwRow
                            anchors.centerIn: parent
                            spacing: 12

                            // Hostname
                            RowLayout {
                                spacing: 4
                                Text {
                                    text: "󰌢"
                                    font.family: Theme.iconFontFamily
                                    font.pixelSize: 13
                                    color: Theme.accent
                                }
                                Text {
                                    text: LockScreenManager.sysData.user.hostname || "archlinux"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: Theme.text
                                }
                            }

                            // Separador
                            Rectangle { width: 1; height: 12; color: Theme.border }

                            // CPU
                            RowLayout {
                                spacing: 4
                                Text {
                                    text: "󰍛"
                                    font.family: Theme.iconFontFamily
                                    font.pixelSize: 13
                                    color: "#a3be8c"
                                }
                                Text {
                                    text: (LockScreenManager.sysData.cpu ? LockScreenManager.sysData.cpu.percent : 0) + "%"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    color: Theme.subtext
                                }
                            }

                            // Separador
                            Rectangle { width: 1; height: 12; color: Theme.border }

                            // RAM
                            RowLayout {
                                spacing: 4
                                Text {
                                    text: "󰘚"
                                    font.family: Theme.iconFontFamily
                                    font.pixelSize: 13
                                    color: "#ebcb8b"
                                }
                                Text {
                                    text: (LockScreenManager.sysData.ram ? LockScreenManager.sysData.ram.used_gb : 0) + " GB"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    color: Theme.subtext
                                }
                            }
                        }
                    }

                    // Píldora flotante derecha: Notificaciones, Audio y Batería
                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 28
                        anchors.verticalCenter: parent.verticalCenter
                        height: 32
                        implicitWidth: statusRow.implicitWidth + 24
                        radius: 16
                        color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.65)
                        border.color: Theme.border
                        border.width: 1

                        RowLayout {
                            id: statusRow
                            anchors.centerIn: parent
                            spacing: 12

                            // Notificaciones pendientes
                            RowLayout {
                                spacing: 4
                                Text {
                                    text: NotificationManager.unreadCount > 0 ? "󰂚" : "󰂜"
                                    font.family: Theme.iconFontFamily
                                    font.pixelSize: 13
                                    color: NotificationManager.unreadCount > 0 ? Theme.accent : Theme.overlay
                                }
                                Text {
                                    text: String(NotificationManager.unreadCount || NotificationManager.history.length || 0)
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: NotificationManager.unreadCount > 0 ? Theme.text : Theme.subtext
                                }
                            }

                            // Separador
                            Rectangle { width: 1; height: 12; color: Theme.border }

                            // Sonido / Volumen maestro
                            RowLayout {
                                spacing: 4
                                Text {
                                    text: LockScreenManager.audioMuted ? "󰝟" : (LockScreenManager.audioVolume > 50 ? "󰕾" : "󰖀")
                                    font.family: Theme.iconFontFamily
                                    font.pixelSize: 13
                                    color: LockScreenManager.audioMuted ? Theme.overlay : Theme.accent
                                }
                                Text {
                                    text: LockScreenManager.audioMuted ? "Silencio" : (LockScreenManager.audioVolume + "%")
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    color: Theme.subtext
                                }
                            }

                            // Batería (si el equipo dispone de ella)
                            RowLayout {
                                visible: LockScreenManager.hasBattery
                                spacing: 4

                                Rectangle { width: 1; height: 12; color: Theme.border }

                                Text {
                                    text: {
                                        let p = LockScreenManager.batteryPercent;
                                        let c = LockScreenManager.batteryStatus === "Charging";
                                        if (c) return "󰂄";
                                        if (p > 90) return "󰁹";
                                        if (p > 70) return "󰂀";
                                        if (p > 50) return "󰁾";
                                        if (p > 30) return "󰁼";
                                        if (p > 15) return "󰁺";
                                        return "󰂎";
                                    }
                                    font.family: Theme.iconFontFamily
                                    font.pixelSize: 14
                                    color: LockScreenManager.batteryPercent <= 20 ? "#bf616a" : "#a3be8c"
                                }
                                Text {
                                    text: LockScreenManager.batteryPercent + "%"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    color: Theme.subtext
                                }
                            }
                        }
                    }
                }

                // -------------------------------------------------------------
                // 3. SECCIÓN CENTRAL: RELOJ, FECHA, CLIMA, CAVA Y CONTRASEÑA
                // -------------------------------------------------------------
                ColumnLayout {
                    id: centerColumn
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -18
                    spacing: 18

                    // 1. Reloj, Fecha y Clima
                    ColumnLayout {
                        id: clockSection
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 6

                        // Gran Reloj Digital Estilizado
                        Text {
                            id: mainClock
                            Layout.alignment: Qt.AlignHCenter
                            text: {
                                let d = new Date();
                                let h = String(d.getHours()).padStart(2, '0');
                                let m = String(d.getMinutes()).padStart(2, '0');
                                return `${h}:${m}`;
                            }
                            font.family: Theme.fontFamily
                            font.pixelSize: 92
                            font.bold: true
                            color: "#ffffff"

                            Timer {
                                interval: 1000
                                running: LockScreenManager.isLocked
                                repeat: true
                                onTriggered: {
                                    let d = new Date();
                                    let h = String(d.getHours()).padStart(2, '0');
                                    let m = String(d.getMinutes()).padStart(2, '0');
                                    mainClock.text = `${h}:${m}`;
                                }
                            }
                        }

                        // Fecha completa en español
                        Text {
                            id: dateLabel
                            Layout.alignment: Qt.AlignHCenter
                            text: {
                                let d = new Date();
                                let days = ["Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"];
                                let months = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"];
                                return `${days[d.getDay()]}, ${d.getDate()} de ${months[d.getMonth()]} de ${d.getFullYear()}`;
                            }
                            font.family: Theme.fontFamily
                            font.pixelSize: 16
                            font.bold: true
                            color: Theme.subtext
                        }

                        // Píldora del Tiempo / Clima
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            implicitHeight: 28
                            implicitWidth: weatherRow.implicitWidth + 22
                            radius: 14
                            color: Qt.rgba(Theme.bgSurface.r, Theme.bgSurface.g, Theme.bgSurface.b, 0.6)
                            border.color: Theme.border
                            border.width: 1

                            RowLayout {
                                id: weatherRow
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: (LockScreenManager.sysData.weather && LockScreenManager.sysData.weather.icon) ? LockScreenManager.sysData.weather.icon : "󰖐"
                                    font.family: Theme.iconFontFamily
                                    font.pixelSize: 13
                                    color: Theme.accent
                                }

                                Text {
                                    text: (LockScreenManager.sysData.weather && LockScreenManager.sysData.weather.temp) ? LockScreenManager.sysData.weather.temp : "--°C"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: Theme.text
                                }

                                Text {
                                    text: "•"
                                    color: Theme.overlay
                                    font.pixelSize: 9
                                }

                                Text {
                                    text: (LockScreenManager.sysData.weather && LockScreenManager.sysData.weather.desc) ? LockScreenManager.sysData.weather.desc : "Clima local"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    color: Theme.subtext
                                }
                            }
                        }
                    }

                    // 2. Visualizador Cava (Reactivo al audio mientras se reproduce)
                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 160
                        Layout.preferredHeight: LockScreenManager.isMusicPlaying ? 22 : 0
                        visible: LockScreenManager.isMusicPlaying
                        opacity: LockScreenManager.isMusicPlaying ? 1.0 : 0.0

                        Behavior on opacity { NumberAnimation { duration: 250 } }
                        Behavior on Layout.preferredHeight { NumberAnimation { duration: 250 } }

                        Row {
                            anchors.centerIn: parent
                            spacing: 3

                            Repeater {
                                model: LockScreenManager.cavaBars.slice(0, 16)
                                delegate: Rectangle {
                                    width: 4
                                    height: Math.max(3, Math.min(20, modelData * 20))
                                    radius: 2
                                    color: Theme.accent
                                    opacity: 0.85
                                    anchors.verticalCenter: parent.verticalCenter
                                    Behavior on height { NumberAnimation { duration: 60 } }
                                }
                            }
                        }
                    }

                    // 3. Área de Contraseña Dinámica (Aparece solo al escribir / comprobando / error)
                    Item {
                        id: authArea
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredHeight: 74
                        Layout.preferredWidth: 500

                        property bool showInputBox: pwdInput.text.length > 0 || LockScreenManager.isChecking || LockScreenManager.authFailed

                        // El cuadro de contraseña (Pill dinámico que cambia de tamaño con animación)
                        Rectangle {
                            id: inputPill
                            anchors.top: parent.top
                            anchors.horizontalCenter: parent.horizontalCenter
                            height: 44
                            radius: 22

                            // Ancho dinámico adaptado a la longitud de la contraseña
                            property real targetWidth: Math.max(116, Math.min(420, Math.max(pwdInput.contentWidth, pwdInput.text.length * 15) + 86))
                            width: authArea.showInputBox ? targetWidth : 116

                            Behavior on width {
                                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                            }

                            color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.76)
                            border.color: LockScreenManager.authFailed ? "#bf616a" : (pwdInput.activeFocus ? Theme.accent : Theme.border)
                            border.width: LockScreenManager.authFailed ? 2 : 1.5
                            clip: true

                            // Animación de aparición / desaparición
                            opacity: authArea.showInputBox ? 1.0 : 0.0
                            scale: authArea.showInputBox ? 1.0 : 0.82

                            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
                            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }

                            transform: Translate { id: pillTranslate }

                            // Animación de sacudida (Shake Animation) al fallar autenticación
                            SequentialAnimation {
                                id: shakeAnim
                                running: LockScreenManager.authFailed
                                NumberAnimation { target: pillTranslate; property: "x"; from: 0; to: -14; duration: 40; easing.type: Easing.OutQuad }
                                NumberAnimation { target: pillTranslate; property: "x"; from: -14; to: 14; duration: 50; easing.type: Easing.InOutQuad }
                                NumberAnimation { target: pillTranslate; property: "x"; from: 14; to: -10; duration: 40; easing.type: Easing.InOutQuad }
                                NumberAnimation { target: pillTranslate; property: "x"; from: -10; to: 10; duration: 40; easing.type: Easing.InOutQuad }
                                NumberAnimation { target: pillTranslate; property: "x"; from: 10; to: 0; duration: 40; easing.type: Easing.OutQuad }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14
                                spacing: 8

                                // Icono de candado o spinner giratorio
                                Text {
                                    text: LockScreenManager.isChecking ? "󰑮" : (LockScreenManager.authFailed ? "󰅙" : "󰌾")
                                    font.family: Theme.iconFontFamily
                                    font.pixelSize: 15
                                    color: LockScreenManager.authFailed ? "#bf616a" : (pwdInput.activeFocus ? Theme.accent : Theme.overlay)

                                    RotationAnimation on rotation {
                                        running: LockScreenManager.isChecking
                                        loops: Animation.Infinite
                                        from: 0
                                        to: 360
                                        duration: 900
                                    }
                                }

                                // Entrada de texto de la contraseña
                                TextInput {
                                    id: pwdInput
                                    Layout.fillWidth: true
                                    echoMode: TextInput.Password
                                    passwordCharacter: "•"
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 18
                                    font.bold: true
                                    selectByMouse: true
                                    clip: true
                                    focus: true
                                    horizontalAlignment: TextInput.AlignHCenter
                                    verticalAlignment: TextInput.AlignVCenter

                                    Keys.onReturnPressed: {
                                        LockScreenManager.verifyPassword(pwdInput.text);
                                    }

                                    Keys.onEscapePressed: {
                                        pwdInput.text = "";
                                    }
                                }

                                // Botón o Flecha para enviar con ratón
                                Rectangle {
                                    width: 26
                                    height: 26
                                    radius: 13
                                    color: pwdInput.text.length > 0 ? Theme.accent : "transparent"
                                    visible: pwdInput.text.length > 0 || LockScreenManager.isChecking

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰁔"
                                        font.family: Theme.iconFontFamily
                                        font.pixelSize: 13
                                        color: "#ffffff"
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            LockScreenManager.verifyPassword(pwdInput.text);
                                        }
                                    }
                                }
                            }
                        }

                        // Indicador "Presiona Enter para desbloquear" y mensajes de estado
                        Item {
                            anchors.top: inputPill.bottom
                            anchors.topMargin: 10
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 320
                            height: 18

                            opacity: authArea.showInputBox ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

                            // Mensaje de estado (error o comprobando)
                            Text {
                                anchors.centerIn: parent
                                visible: LockScreenManager.statusMessage !== ""
                                text: LockScreenManager.statusMessage
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.bold: true
                                color: LockScreenManager.authFailed ? "#bf616a" : Theme.accent
                            }

                            // Indicador Enter con respiración animada
                            Text {
                                anchors.centerIn: parent
                                visible: LockScreenManager.statusMessage === ""
                                text: "󰌌  Presiona Enter para desbloquear"
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                color: Theme.overlay
                                opacity: 0.75

                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite
                                    NumberAnimation { from: 0.85; to: 0.35; duration: 1200; easing.type: Easing.InOutQuad }
                                    NumberAnimation { from: 0.35; to: 0.85; duration: 1200; easing.type: Easing.InOutQuad }
                                }
                            }
                        }
                    }
                }

                // Autoejecución al activarse el bloqueo para enfocar el campo de texto
                Component.onCompleted: {
                    surfaceReady = true;
                    pwdInput.forceActiveFocus();
                }

                Connections {
                    target: LockScreenManager
                    function onIsLockedChanged() {
                        if (LockScreenManager.isLocked) {
                            pwdInput.text = "";
                            pwdInput.forceActiveFocus();
                        }
                    }
                    function onAuthFailedChanged() {
                        if (LockScreenManager.authFailed) {
                            pwdInput.selectAll();
                            pwdInput.forceActiveFocus();
                        }
                    }
                }
            }
        }
    }
}
