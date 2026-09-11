import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import Quickshell
import Quickshell.Io
import "./components"

FloatingWindow {
    id: win

    title: currentFilename ? (currentFilename + " - Reproductor de Video") : "Reproductor de Video"
    color: Theme.bg
    visible: true

    implicitWidth: 960
    implicitHeight: 580

    property string currentPath: Quickshell.env("TARGET_FILE") || ""
    property string currentFilename: currentPath ? currentPath.split('/').pop() : ""
    property bool isFullscreen: false
    property bool isLoop: false
    property bool controlsVisible: true
    property bool userSeeking: false

    function closeApp() {
        player.stop();
        Quickshell.execDetached(["kill", "-9", String(Quickshell.processId)]);
    }

    function toggleFullscreen() {
        isFullscreen = !isFullscreen;
        win.fullscreen = isFullscreen;
    }

    function togglePlay() {
        if (player.playbackState === MediaPlayer.PlayingState) {
            player.pause();
        } else {
            player.play();
        }
    }

    function seekRelative(deltaMs) {
        let target = Math.max(0, Math.min(player.duration, player.position + deltaMs));
        player.setPosition(target);
    }

    function formatTime(ms) {
        if (isNaN(ms) || ms <= 0) return "00:00";
        let totalSeconds = Math.floor(ms / 1000);
        let s = totalSeconds % 60;
        let m = Math.floor(totalSeconds / 60) % 60;
        let h = Math.floor(totalSeconds / 3600);
        let sStr = s < 10 ? ("0" + s) : String(s);
        let mStr = m < 10 ? ("0" + m) : String(m);
        if (h > 0) {
            return h + ":" + mStr + ":" + sStr;
        }
        return mStr + ":" + sStr;
    }

    Timer {
        id: autoHideTimer
        interval: 2500
        running: true
        repeat: false
        onTriggered: {
            if (player.playbackState === MediaPlayer.PlayingState && !pillMouseArea.containsMouse) {
                win.controlsVisible = false;
            }
        }
    }

    function pingControls() {
        win.controlsVisible = true;
        autoHideTimer.restart();
    }

    // Motor Multimedia
    AudioOutput {
        id: audioOut
        volume: 1.0
        muted: false
    }

    MediaPlayer {
        id: player
        audioOutput: audioOut
        videoOutput: videoOut
        source: win.currentPath ? ("file://" + win.currentPath) : ""
        loops: win.isLoop ? MediaPlayer.Infinite : 1

        Component.onCompleted: {
            if (win.currentPath) {
                player.play();
            }
        }

        onPlaybackStateChanged: {
            if (player.playbackState !== MediaPlayer.PlayingState) {
                win.controlsVisible = true;
            } else {
                pingControls();
            }
        }
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
            } else if (event.key === Qt.Key_Space) {
                togglePlay();
                event.accepted = true;
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_J) {
                seekRelative(-5000);
                event.accepted = true;
            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
                seekRelative(5000);
                event.accepted = true;
            } else if (event.key === Qt.Key_Up) {
                audioOut.volume = Math.min(1.0, audioOut.volume + 0.05);
                event.accepted = true;
            } else if (event.key === Qt.Key_Down) {
                audioOut.volume = Math.max(0.0, audioOut.volume - 0.05);
                event.accepted = true;
            } else if (event.key === Qt.Key_M) {
                audioOut.muted = !audioOut.muted;
                event.accepted = true;
            } else if (event.key === Qt.Key_F11 || event.key === Qt.Key_F) {
                toggleFullscreen();
                event.accepted = true;
            }
        }
    }

    // Lienzo de Video único (Sin barras por defecto)
    VideoOutput {
        id: videoOut
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectFit

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onPositionChanged: pingControls()
            onClicked: {
                pingControls();
                togglePlay();
            }
            onDoubleClicked: {
                pingControls();
                toggleFullscreen();
            }
        }
    }

    // Top Badge: Título del Video
    Rectangle {
        id: topBadge
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 14
        implicitHeight: 28
        implicitWidth: titleText.implicitWidth + 24
        radius: 14
        color: Theme.bgSurface
        border.color: Theme.border
        border.width: 1
        opacity: win.controlsVisible ? 0.90 : 0.0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Text {
            id: titleText
            anchors.centerIn: parent
            text: win.currentFilename || "Reproductor de Video"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 11
            font.bold: true
            elide: Text.ElideMiddle
            maximumLineCount: 1
        }
    }

    // Píldora de controles flotante minimalista (UNA SOLA BARRA, SIN BOTÓN DE CERRAR)
    Rectangle {
        id: controlPill
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 18
        implicitHeight: 40
        implicitWidth: Math.min(win.width - 40, pillLayout.implicitWidth + 24)
        radius: 20
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
            spacing: 8

            // Botón Play / Pause (󰐊 / 󰏤)
            Rectangle {
                implicitWidth: 32
                implicitHeight: 32
                radius: 16
                color: playHover.containsMouse ? Theme.bgHover : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: player.playbackState === MediaPlayer.PlayingState ? "󰏤" : "󰐊"
                    color: playHover.containsMouse ? Theme.primary : Theme.text
                    font.family: Theme.iconFontFamily
                    font.pixelSize: 14
                }
                MouseArea {
                    id: playHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { pingControls(); togglePlay(); }
                }
            }

            // Retroceder 10s (󰒮)
            Rectangle {
                implicitWidth: 28
                implicitHeight: 28
                radius: 14
                color: rwdHover.containsMouse ? Theme.bgHover : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "󰒮"
                    color: rwdHover.containsMouse ? Theme.primary : Theme.subtext
                    font.family: Theme.iconFontFamily
                    font.pixelSize: 12
                }
                MouseArea {
                    id: rwdHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { pingControls(); seekRelative(-10000); }
                }
            }

            // Tiempo actual
            Text {
                text: formatTime(player.position)
                color: Theme.subtext
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.bold: true
            }

            // Barra deslizante de progreso (Seek Bar Custom)
            Item {
                id: seekTrack
                implicitWidth: 240
                implicitHeight: 18
                Layout.fillWidth: true

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width
                    height: 4
                    radius: 2
                    color: Theme.bgHover

                    Rectangle {
                        height: parent.height
                        radius: 2
                        width: player.duration > 0 ? (parent.width * Math.max(0, Math.min(1.0, player.position / player.duration))) : 0
                        color: Theme.primary
                    }
                }

                // Perilla indicadora
                Rectangle {
                    width: 10
                    height: 10
                    radius: 5
                    color: Theme.primary
                    border.color: Theme.text
                    border.width: 1.5
                    anchors.verticalCenter: parent.verticalCenter
                    x: player.duration > 0 ? Math.max(0, Math.min(seekTrack.width - width, (seekTrack.width * (player.position / player.duration)) - width/2)) : 0
                    visible: seekMouse.containsMouse || userSeeking
                }

                MouseArea {
                    id: seekMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    function updateSeek(mouseX) {
                        if (player.duration > 0) {
                            let ratio = Math.max(0, Math.min(1.0, mouseX / width));
                            player.setPosition(Math.round(ratio * player.duration));
                        }
                    }

                    onPressed: function(mouse) {
                        pingControls();
                        win.userSeeking = true;
                        updateSeek(mouse.x);
                    }
                    onPositionChanged: function(mouse) {
                        pingControls();
                        if (pressed) {
                            updateSeek(mouse.x);
                        }
                    }
                    onReleased: {
                        win.userSeeking = false;
                    }
                }
            }

            // Tiempo total
            Text {
                text: formatTime(player.duration)
                color: Theme.subtext
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.bold: true
            }

            // Adelantar 10s (󰒭)
            Rectangle {
                implicitWidth: 28
                implicitHeight: 28
                radius: 14
                color: fwdHover.containsMouse ? Theme.bgHover : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "󰒭"
                    color: fwdHover.containsMouse ? Theme.primary : Theme.subtext
                    font.family: Theme.iconFontFamily
                    font.pixelSize: 12
                }
                MouseArea {
                    id: fwdHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { pingControls(); seekRelative(10000); }
                }
            }

            // Separador
            Rectangle {
                implicitWidth: 1
                implicitHeight: 18
                color: Theme.border
            }

            // Silenciar / Volumen (󰕾 / 󰖁)
            Rectangle {
                implicitWidth: 28
                implicitHeight: 28
                radius: 14
                color: volHover.containsMouse ? Theme.bgHover : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: audioOut.muted || audioOut.volume <= 0 ? "󰖁" : "󰕾"
                    color: volHover.containsMouse ? Theme.primary : Theme.text
                    font.family: Theme.iconFontFamily
                    font.pixelSize: 13
                }
                MouseArea {
                    id: volHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        pingControls();
                        audioOut.muted = !audioOut.muted;
                    }
                }
            }

            // Control deslizante de volumen
            Item {
                implicitWidth: 60
                implicitHeight: 18

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width
                    height: 4
                    radius: 2
                    color: Theme.bgHover

                    Rectangle {
                        height: parent.height
                        radius: 2
                        width: parent.width * (audioOut.muted ? 0 : audioOut.volume)
                        color: Theme.primary
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPositionChanged: function(mouse) {
                        pingControls();
                        if (pressed) {
                            let ratio = Math.max(0, Math.min(1.0, mouse.x / width));
                            audioOut.volume = ratio;
                            if (audioOut.muted && ratio > 0) audioOut.muted = false;
                        }
                    }
                    onPressed: function(mouse) {
                        pingControls();
                        let ratio = Math.max(0, Math.min(1.0, mouse.x / width));
                        audioOut.volume = ratio;
                        if (audioOut.muted && ratio > 0) audioOut.muted = false;
                    }
                }
            }

            // Separador
            Rectangle {
                implicitWidth: 1
                implicitHeight: 18
                color: Theme.border
            }

            // Bucle continuo (󰑖)
            Rectangle {
                implicitWidth: 28
                implicitHeight: 28
                radius: 14
                color: win.isLoop ? Theme.bgHover : (loopHover.containsMouse ? Theme.bgHover : "transparent")
                Text {
                    anchors.centerIn: parent
                    text: "󰑖"
                    color: win.isLoop ? Theme.primary : (loopHover.containsMouse ? Theme.primary : Theme.subtext)
                    font.family: Theme.iconFontFamily
                    font.pixelSize: 12
                }
                MouseArea {
                    id: loopHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        pingControls();
                        win.isLoop = !win.isLoop;
                    }
                }
            }

            // Pantalla Completa (󰊓)
            Rectangle {
                implicitWidth: 28
                implicitHeight: 28
                radius: 14
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
