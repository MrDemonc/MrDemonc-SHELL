import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root
    property string indicatorName: "audio"
    implicitWidth: contentRow.implicitWidth + 14
    implicitHeight: 24

    property int masterVolume: 50
    property bool masterMuted: false
    property int micVolume: 100
    property bool micMuted: false
    property var sinks: []
    property var apps: []
    property string rawAudioOutput: ""

    // Métricas para popup y hover
    property bool isHovered: false
    readonly property bool isPopoutActive: PopoutManager.activePopout === "audio"

    Process {
        id: scanProc
        command: ["/home/demonc/Documents/Proyects/shell/scripts/get_audio_info.py"]
        stdout: SplitParser {
            onRead: data => { root.rawAudioOutput += data; }
        }
        onExited: {
            try {
                let info = JSON.parse(root.rawAudioOutput.trim());
                root.masterVolume = info.masterVolume || 0;
                root.masterMuted = !!info.masterMuted;
                root.micVolume = info.micVolume || 0;
                root.micMuted = !!info.micMuted;
                root.sinks = info.sinks || [];
                root.apps = info.apps || [];
            } catch (e) {}
            root.rawAudioOutput = "";
        }
    }

    Process {
        id: actionProc
        onExited: { root.rescan(); }
    }

    function setMasterVolume(val) {
        val = Math.max(0, Math.min(150, Math.round(val)));
        root.masterVolume = val;
        actionProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (val / 100.0).toFixed(2)];
        actionProc.running = false;
        actionProc.running = true;
    }

    function toggleMasterMute() {
        root.masterMuted = !root.masterMuted;
        actionProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"];
        actionProc.running = false;
        actionProc.running = true;
    }

    function setMicVolume(val) {
        val = Math.max(0, Math.min(100, Math.round(val)));
        root.micVolume = val;
        actionProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", (val / 100.0).toFixed(2)];
        actionProc.running = false;
        actionProc.running = true;
    }

    function toggleMicMute() {
        root.micMuted = !root.micMuted;
        actionProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"];
        actionProc.running = false;
        actionProc.running = true;
    }

    function setDefaultSink(sinkName) {
        actionProc.command = ["pactl", "set-default-sink", sinkName];
        actionProc.running = false;
        actionProc.running = true;
    }

    function setAppVolume(index, val) {
        val = Math.max(0, Math.min(150, Math.round(val)));
        actionProc.command = ["pactl", "set-sink-input-volume", index.toString(), val.toString() + "%"];
        actionProc.running = false;
        actionProc.running = true;
    }

    function toggleAppMute(index) {
        actionProc.command = ["pactl", "set-sink-input-mute", index.toString(), "toggle"];
        actionProc.running = false;
        actionProc.running = true;
    }

    function rescan() {
        root.rawAudioOutput = "";
        scanProc.running = false;
        scanProc.running = true;
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { root.rescan(); }
    }

    Rectangle {
        id: capsule
        anchors.fill: parent
        radius: 6
        color: (root.isPopoutActive || root.isHovered) ? Theme.bgHover : "transparent"

        Behavior on color { ColorAnimation { duration: 150 } }

        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: 5

            Text {
                text: {
                    if (root.masterMuted || root.masterVolume === 0) return "󰝟";
                    if (root.masterVolume >= 65) return "󰕾";
                    if (root.masterVolume >= 30) return "󰖀";
                    return "󰕿";
                }
                color: root.masterMuted ? Theme.danger : Theme.primary
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }

            Text {
                text: root.masterMuted ? "Mute" : (root.masterVolume + "%")
                color: root.masterMuted ? Theme.overlay : Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }
        }
    }
}
