pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: mgr

    property bool monitorsOpen: false
    property int selectedIndex: 0

    property var monitorInfo: ({
        "monitors": [],
        "count": 0,
        "laptop_count": 0,
        "external_count": 0,
        "has_external": false,
        "has_laptop": false
    })

    property string feedbackMessage: ""

    // Monitoreo del archivo de toggle para SUPER + SHIFT + S
    property var watchToggleProc: Process {
        command: ["sh", "-c", "STATE=\"${XDG_RUNTIME_DIR:-/tmp}/quickshell_monitors.toggle\"; while true; do if [ -f \"$STATE\" ]; then rm -f \"$STATE\"; echo 'TOGGLE'; fi; sleep 0.15; done"]
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                if (String(data).indexOf("TOGGLE") !== -1) {
                    mgr.toggle();
                }
            }
        }
    }

    // Proceso para obtener información de monitores
    property var fetchProc: Process {
        command: [Quickshell.shellDir + "/scripts/monitor_manager.py", "get"]
        stdout: SplitParser {
            onRead: function(data) {
                try {
                    let str = String(data).trim();
                    if (str.length > 0 && str.startsWith("{")) {
                        let parsed = JSON.parse(str);
                        mgr.monitorInfo = parsed;
                        if (mgr.selectedIndex >= parsed.monitors.length) {
                            mgr.selectedIndex = 0;
                        }
                    }
                } catch (e) {}
            }
        }
    }

    // Proceso para aplicar presets
    property var presetProc: Process {
        stdout: SplitParser {
            onRead: function(data) {
                mgr.refresh();
            }
        }
    }

    // Proceso para aplicar configuraciones individuales
    property var applyProc: Process {
        stdout: SplitParser {
            onRead: function(data) {
                mgr.refresh();
            }
        }
    }

    function toggle() {
        monitorsOpen = !monitorsOpen;
        if (monitorsOpen) {
            feedbackMessage = "";
            refresh();
        }
    }

    function refresh() {
        fetchProc.running = false;
        fetchProc.command = [Quickshell.shellDir + "/scripts/monitor_manager.py", "get"];
        fetchProc.running = true;
    }

    function applyPreset(presetName) {
        presetProc.running = false;
        presetProc.command = [Quickshell.shellDir + "/scripts/monitor_manager.py", "preset", presetName];
        presetProc.running = true;
        if (presetName === "external_only") {
            feedbackMessage = "Pantalla de laptop apagada. Usando monitor externo.";
        } else if (presetName === "laptop_only") {
            feedbackMessage = "Monitores externos desactivados. Usando pantalla de laptop.";
        } else if (presetName === "extend") {
            feedbackMessage = "Modo extendido activado en todas las pantallas.";
        } else if (presetName === "mirror") {
            feedbackMessage = "Modo duplicado (espejo) activado.";
        }
    }

    function applySetting(output, enabled, mode, scale, pos, transform, mirror) {
        let args = [
            Quickshell.shellDir + "/scripts/monitor_manager.py",
            "set",
            "--output", output,
            enabled ? "--enable" : "--disable",
            "--mode", mode ? mode : "preferred",
            "--scale", String(scale || 1.0),
            "--pos", pos ? pos : "auto",
            "--transform", String(transform || 0)
        ];
        if (mirror && mirror !== "none") {
            args.push("--mirror", mirror);
        }
        applyProc.running = false;
        applyProc.command = args;
        applyProc.running = true;
        feedbackMessage = "Configuración aplicada a " + output;
    }

    readonly property var currentMonitor: {
        if (monitorInfo && monitorInfo.monitors && monitorInfo.monitors.length > selectedIndex) {
            return monitorInfo.monitors[selectedIndex];
        }
        return null;
    }
}
