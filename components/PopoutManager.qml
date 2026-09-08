pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: popoutMgr

    property string activePopout: ""
    property string lastActivePopout: ""
    property real popoutCenter: 0
    readonly property bool hasPopout: activePopout !== ""
    property bool isDraggingAny: false
    property bool themeModalOpen: false

    // Monitoreo de archivo para abrir el selector de temas por comando CLI
    property var watchToggleProc: Process {
        command: ["sh", "-c", "STATE=\"${XDG_RUNTIME_DIR:-/tmp}/quickshell_theme_picker.toggle\"; while true; do if [ -f \"$STATE\" ]; then rm -f \"$STATE\"; echo 'TOGGLE'; fi; sleep 0.15; done"]
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                if (String(data).indexOf("TOGGLE") !== -1) {
                    popoutMgr.themeModalOpen = !popoutMgr.themeModalOpen;
                }
            }
        }
    }

    // Monitoreo de popouts por comando CLI / atajo
    property var watchPopoutProc: Process {
        command: ["sh", "-c", "STATE=\"${XDG_RUNTIME_DIR:-/tmp}/quickshell_popout.toggle\"; while true; do if [ -f \"$STATE\" ]; then T=$(cat \"$STATE\"); rm -f \"$STATE\"; echo \"POPOUT:$T\"; fi; sleep 0.15; done"]
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                let str = String(data).trim();
                if (str.indexOf("POPOUT:") === 0) {
                    let target = str.substring(7).trim();
                    popoutMgr.toggle(target);
                }
            }
        }
    }

    // Orden de los indicadores en la barra
    property var indicatorOrder: ["audio", "bluetooth", "wifi", "battery"]

    // Proceso de Carga y Guardado de Orden
    property var loadOrderProc: Process {
        command: [Quickshell.shellDir + "/scripts/manage_order.py", "get"]
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                try {
                    let parsed = JSON.parse(String(data).trim());
                    if (parsed.order && Array.isArray(parsed.order)) {
                        popoutMgr.indicatorOrder = parsed.order;
                    }
                } catch (e) {}
            }
        }
    }

    property var saveOrderProc: Process {}

    function open(name, centerX) {
        if (!isDraggingAny) {
            activePopout = name;
            lastActivePopout = name;
            if (centerX !== undefined && centerX > 0) {
                popoutCenter = centerX;
            } else {
                popoutCenter = 1750;
            }
        }
    }

    function close() {
        activePopout = "";
    }

    function toggle(name, centerX) {
        if (!name || name === "close" || activePopout === name) {
            close();
        } else {
            open(name, centerX);
        }
    }

    // Configuración de las 3 secciones principales de la barra: left, center, right
    property var barSections: ({
        "left": ["workspaces"],
        "center": ["clock"],
        "right": ["audio", "bluetooth", "wifi", "battery"]
    })

    property var loadSectionsProc: Process {
        command: [Quickshell.shellDir + "/scripts/manage_order.py", "get_sections"]
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                try {
                    let parsed = JSON.parse(String(data).trim());
                    if (parsed.sections && typeof parsed.sections === "object") {
                        popoutMgr.barSections = parsed.sections;
                    }
                } catch (e) {}
            }
        }
    }

    property var saveSectionsProc: Process {}

    function setSections(newSec) {
        if (!newSec || typeof newSec !== "object") return;
        barSections = Object.assign({}, newSec);
        saveSectionsProc.command = [Quickshell.shellDir + "/scripts/manage_order.py", "save_sections", JSON.stringify(newSec)];
        saveSectionsProc.running = false;
        saveSectionsProc.running = true;
    }

    // Posición dinámica de la barra: "top", "bottom", "left", "right"
    property string barPosition: "top"
    readonly property bool isVertical: barPosition === "left" || barPosition === "right"
    property bool isBarDragging: false
    property string candidateBarPosition: ""

    property var loadPositionProc: Process {
        command: [Quickshell.shellDir + "/scripts/manage_order.py", "get_position"]
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                try {
                    let parsed = JSON.parse(String(data).trim());
                    if (parsed.position && ["top", "bottom", "left", "right"].indexOf(parsed.position) !== -1) {
                        popoutMgr.barPosition = parsed.position;
                    }
                } catch (e) {}
            }
        }
    }

    // Monitoreo de cambio de posición de la barra por comando CLI
    property var watchPositionProc: Process {
        command: ["sh", "-c", "STATE=\"${XDG_RUNTIME_DIR:-/tmp}/quickshell_bar_position.set\"; while true; do if [ -f \"$STATE\" ]; then POS=$(cat \"$STATE\"); rm -f \"$STATE\"; echo \"POS:$POS\"; fi; sleep 0.15; done"]
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                let str = String(data).trim();
                if (str.indexOf("POS:") === 0) {
                    let target = str.substring(4).trim();
                    if (["top", "bottom", "left", "right"].indexOf(target) !== -1) {
                        popoutMgr.barPosition = target;
                    }
                }
            }
        }
    }

    property var savePositionProc: Process {}

    function setBarPosition(newPos) {
        if (!newPos || ["top", "bottom", "left", "right"].indexOf(newPos) === -1) return;
        if (barPosition === newPos) return;
        close();
        barPosition = newPos;
        savePositionProc.command = [Quickshell.shellDir + "/scripts/manage_order.py", "save_position", newPos];
        savePositionProc.running = false;
        savePositionProc.running = true;
    }
}
