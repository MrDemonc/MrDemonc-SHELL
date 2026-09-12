pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property string osdType: "volume" // "volume", "brightness", "mic"
    property int osdValue: 50
    property bool osdMuted: false
    property bool isOsdVisible: false

    property var osdServerProc: Process {
        command: [Quickshell.shellDir + "/scripts/osd_server.py"]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                let str = String(line).trim();
                if (!str || !str.startsWith("{")) return;
                try {
                    let msg = JSON.parse(str);
                    if (msg.status === "ready") return;

                    if (msg.type) {
                        root.osdType = msg.type;
                        root.osdValue = Math.max(0, Math.min(150, parseInt(msg.value) || 0));
                        root.osdMuted = !!msg.muted;
                        root.isOsdVisible = true;
                        hideTimer.restart();
                    }
                } catch (e) {
                    // Ignorar errores de parseo
                }
            }
        }
    }

    property var hideTimer: Timer {
        interval: 1800
        repeat: false
        onTriggered: {
            root.isOsdVisible = false;
        }
    }

    function showVolume(val, muted) {
        root.osdType = "volume";
        root.osdValue = Math.max(0, Math.min(150, Math.round(val)));
        root.osdMuted = !!muted;
        root.isOsdVisible = true;
        hideTimer.restart();
    }

    function showBrightness(val) {
        root.osdType = "brightness";
        root.osdValue = Math.max(0, Math.min(100, Math.round(val)));
        root.osdMuted = false;
        root.isOsdVisible = true;
        hideTimer.restart();
    }

    function showMic(val, muted) {
        root.osdType = "mic";
        root.osdValue = Math.max(0, Math.min(100, Math.round(val)));
        root.osdMuted = !!muted;
        root.isOsdVisible = true;
        hideTimer.restart();
    }
}
