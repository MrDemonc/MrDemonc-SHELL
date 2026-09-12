pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool isRecording: false
    property bool modalOpen: false
    property string captureMode: "screen" // "screen" o "area"
    property bool recordSysAudio: true
    property bool recordMicAudio: false
    property int elapsedSeconds: 0
    property string recordTimeFormatted: "00:00"
    property string currentOutputFile: ""

    property var actionProc: Process {
        running: false
    }

    onElapsedSecondsChanged: {
        let mins = Math.floor(elapsedSeconds / 60);
        let secs = elapsedSeconds % 60;
        let mStr = String(mins).padStart(2, '0');
        let sStr = String(secs).padStart(2, '0');
        recordTimeFormatted = `${mStr}:${sStr}`;
    }

    Timer {
        interval: 1000
        running: root.isRecording
        repeat: true
        onTriggered: {
            root.elapsedSeconds += 1;
        }
    }

    function toggleModal() {
        if (isRecording) {
            stopRecording();
        } else {
            modalOpen = !modalOpen;
            console.log("RECORDER MANAGER: toggleModal called, modalOpen=" + modalOpen);
        }
    }

    function startRecording() {
        modalOpen = false;
        let sys = recordSysAudio ? 1 : 0;
        let mic = recordMicAudio ? 1 : 0;
        let cmd = `"$HOME/.local/bin/shell-recorder" start "${captureMode}" "${sys}" "${mic}" &`;
        actionProc.command = ["sh", "-c", cmd];
        actionProc.running = false;
        actionProc.running = true;
    }

    function stopRecording() {
        let cmd = '"$HOME/.local/bin/shell-recorder" stop &';
        actionProc.command = ["sh", "-c", cmd];
        actionProc.running = false;
        actionProc.running = true;
    }

    // 1. Escuchar eventos de cambio de estado (START / STOP)
    property var watchStateProc: Process {
        command: ["sh", "-c", "START=\"${XDG_RUNTIME_DIR:-/tmp}/quickshell_recorder.start\"; STOP=\"${XDG_RUNTIME_DIR:-/tmp}/quickshell_recorder.stop\"; while true; do if [ -f \"$START\" ]; then rm -f \"$START\"; echo 'START'; elif [ -f \"$STOP\" ]; then rm -f \"$STOP\"; echo 'STOP'; fi; sleep 0.15; done"]
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                let line = String(data).trim();
                console.log("RECORDER MANAGER STATE:", line);
                if (line.indexOf("START") !== -1) {
                    root.elapsedSeconds = 0;
                    root.isRecording = true;
                    root.modalOpen = false;
                } else if (line.indexOf("STOP") !== -1) {
                    root.isRecording = false;
                    root.elapsedSeconds = 0;
                }
            }
        }
    }

    // 2. Escuchar peticiones de Toggle por atajo de teclado
    property var watchToggleProc: Process {
        command: ["sh", "-c", "TOGGLE=\"${XDG_RUNTIME_DIR:-/tmp}/quickshell_recorder.toggle\"; while true; do if [ -f \"$TOGGLE\" ]; then rm -f \"$TOGGLE\"; echo 'TOGGLE'; fi; sleep 0.15; done"]
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                let line = String(data).trim();
                if (line.indexOf("TOGGLE") !== -1) {
                    root.toggleModal();
                }
            }
        }
    }
}
