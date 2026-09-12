pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property bool isActive: false

    property var actionProc: Process {
        running: false
    }

    function toggle() {
        isActive = !isActive;
        console.log("CAFFEINE MANAGER: toggle called, now isActive=" + isActive);
        let cmd = "";
        if (isActive) {
            cmd = "pkill -STOP hypridle 2>/dev/null; notify-send 'Modo Cafeína' 'Activado: Se evita la suspensión y el bloqueo de pantalla' -u normal -t 3000 2>/dev/null";
        } else {
            cmd = "pkill -CONT hypridle 2>/dev/null; notify-send 'Modo Cafeína' 'Desactivado: Suspensión por inactividad reactivada' -u low -t 3000 2>/dev/null";
        }
        actionProc.command = ["sh", "-c", cmd];
        actionProc.running = false;
        actionProc.running = true;
    }

    property var watchToggleProc: Process {
        command: ["sh", "-c", "STATE=\"${XDG_RUNTIME_DIR:-/tmp}/quickshell_caffeine.toggle\"; while true; do if [ -f \"$STATE\" ]; then rm -f \"$STATE\"; echo 'TOGGLE'; fi; sleep 0.15; done"]
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                console.log("CAFFEINE MANAGER: received data=" + String(data).trim());
                if (String(data).indexOf("TOGGLE") !== -1) {
                    root.toggle();
                }
            }
        }
    }
}
