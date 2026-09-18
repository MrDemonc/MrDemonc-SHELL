pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

QtObject {
    id: mgr
    property bool monitorsOpen: false
    property int selectedIndex: 0
    property var monitorInfo: ({monitors: [], count: 0, has_external: false, has_laptop: false})
    property string feedbackMessage: ""
    property bool feedbackError: false
    readonly property bool busy: applyProc.running
    property string topology: ""
    property bool pendingTopology: false
    property int autoAttempts: 0
    property bool automaticAction: false

    property var watchToggleProc: Process {
        command: ["sh", "-c", "STATE=\"${XDG_RUNTIME_DIR:-/tmp}/quickshell_monitors.toggle\"; while true; do if [ -f \"$STATE\" ]; then rm -f \"$STATE\"; echo 'TOGGLE'; fi; sleep 0.15; done"]
        running: true
        stdout: SplitParser {
            onRead: function(data) { if (String(data).trim() === "TOGGLE") mgr.toggle(); }
        }
    }

    // Los eventos dan respuesta rápida; el sondeo también ve salidas desactivadas.
    property var monitorEvents: Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (LockScreenManager.isLocked) return;
            if (event.name.startsWith("monitoradded") || event.name.startsWith("monitorremoved"))
                refreshDelay.restart();
        }
    }
    property var refreshDelay: Timer {
        interval: 600
        onTriggered: {
            if (LockScreenManager.isLocked) return;
            mgr.refresh();
        }
    }
    property var monitorPoll: Timer {
        interval: 3000
        running: !LockScreenManager.isLocked
        repeat: true
        triggeredOnStart: true
        onTriggered: mgr.refresh()
    }
    property var lockEvents: Connections {
        target: LockScreenManager
        function onIsLockedChanged() {
            if (!LockScreenManager.isLocked) {
                refreshDelay.restart();
            }
        }
    }

    property var fetchProc: Process {
        command: ["python3", Quickshell.shellDir + "/scripts/monitor_manager.py", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let parsed = JSON.parse(text);
                    if (!parsed.monitors) {
                        mgr.feedbackError = true;
                        mgr.feedbackMessage = parsed.message || "No se pudieron consultar las pantallas";
                        return;
                    }
                    let selected = mgr.currentMonitor ? mgr.currentMonitor.name : "";
                    let names = parsed.monitors.map(m => m.name).sort().join("|");
                    if (names !== mgr.topology) {
                        mgr.topology = names;
                        mgr.pendingTopology = true;
                        mgr.autoAttempts = 0;
                    }
                    // No reiniciar los campos que el usuario está editando en cada sondeo.
                    if (JSON.stringify(parsed) !== JSON.stringify(mgr.monitorInfo)) {
                        mgr.monitorInfo = parsed;
                        let index = parsed.monitors.findIndex(m => m.name === selected);
                        mgr.selectedIndex = index >= 0 ? index : 0;
                    }
                } catch (error) {
                    mgr.feedbackError = true;
                    mgr.feedbackMessage = "Respuesta de pantallas no válida";
                }
            }
        }
        onExited: mgr.applyPendingTopology()
    }

    property var applyProc: Process {
        property bool receivedResult: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let result = JSON.parse(text);
                    applyProc.receivedResult = true;
                    mgr.feedbackError = result.status === "error";
                    mgr.feedbackMessage = result.message || (mgr.feedbackError ? "No se pudo aplicar la configuración" : "Configuración aplicada");
                    if (mgr.automaticAction && !mgr.feedbackError) mgr.pendingTopology = false;
                } catch (error) {
                    mgr.feedbackError = true;
                    mgr.feedbackMessage = "No se pudo leer el resultado de la configuración";
                }
            }
        }
        onExited: function(code, status) {
            if (!receivedResult || code !== 0 || status !== 0) {
                mgr.feedbackError = true;
                if (!receivedResult) mgr.feedbackMessage = "No se pudo ejecutar la configuración de pantallas";
            }
            refreshDelay.restart();
        }
    }

    function applyPendingTopology() {
        if (LockScreenManager.isLocked) return;
        if (!pendingTopology || busy || autoAttempts >= 3 || monitorInfo.count === 0) return;
        autoAttempts++;
        automaticAction = true;
        runAction(["auto"]);
    }
    function runAction(args) {
        if (busy) return;
        feedbackError = false;
        feedbackMessage = "Aplicando configuración…";
        applyProc.receivedResult = false;
        applyProc.command = ["python3", Quickshell.shellDir + "/scripts/monitor_manager.py"].concat(args);
        applyProc.running = true;
    }
    function toggle() {
        monitorsOpen = !monitorsOpen;
        if (monitorsOpen) refresh();
    }
    function refresh() {
        if (!fetchProc.running && !busy) fetchProc.running = true;
    }
    function applyPreset(presetName) {
        if (busy) return;
        automaticAction = false;
        pendingTopology = false;
        runAction(["preset", presetName]);
    }
    function applySetting(output, enabled, mode, scale, pos, transform, mirror) {
        if (busy) return;
        automaticAction = false;
        pendingTopology = false;
        runAction(["set", "--output", output, enabled ? "--enable" : "--disable",
                   "--mode", mode || "preferred", "--scale", String(scale || 1),
                   "--transform", String(transform || 0)]);
    }
    readonly property var currentMonitor: monitorInfo.monitors.length > selectedIndex ? monitorInfo.monitors[selectedIndex] : null
}
