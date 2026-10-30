pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: deskMgr

    property bool enabled: true
    property int iconSize: 48
    property bool showFolders: true
    property bool showTrash: true
    property bool showDrives: true
    property var selectedApps: []

    property var desktopItems: []
    property var availableApps: []
    property string appsSearchQuery: ""
    property var filteredAvailableApps: []

    // Monitoreo de cambios para recargar el escritorio de forma instantánea
    property var watchReloadProc: Process {
        command: ["sh", "-c", "STATE=\"${XDG_RUNTIME_DIR:-/tmp}/quickshell_desktop.reload\"; while kill -0 $PPID 2>/dev/null; do if [ -f \"$STATE\" ]; then rm -f \"$STATE\"; echo 'RELOAD'; fi; sleep 0.05; done"]
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                if (String(data).indexOf("RELOAD") !== -1) {
                    deskMgr.refreshAll();
                }
            }
        }
    }

    // Proceso para obtener configuración actual
    property Process settingsProc: Process {
        command: [Quickshell.shellDir + "/scripts/desktop_manager.py", "get_settings"]
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                try {
                    let parsed = JSON.parse(String(data).trim());
                    if (parsed && typeof parsed === "object") {
                        if (parsed.enabled !== undefined) deskMgr.enabled = Boolean(parsed.enabled);
                        if (parsed.iconSize !== undefined) deskMgr.iconSize = Number(parsed.iconSize);
                        if (parsed.showFolders !== undefined) deskMgr.showFolders = Boolean(parsed.showFolders);
                        if (parsed.showTrash !== undefined) deskMgr.showTrash = Boolean(parsed.showTrash);
                        if (parsed.showDrives !== undefined) deskMgr.showDrives = Boolean(parsed.showDrives);
                        if (Array.isArray(parsed.selectedApps)) deskMgr.selectedApps = parsed.selectedApps;
                    }
                } catch (e) {}
            }
        }
    }

    // Proceso para listar elementos mostrados en el escritorio
    property string rawItemsOutput: ""
    property Process itemsProc: Process {
        command: [Quickshell.shellDir + "/scripts/desktop_manager.py", "list_items"]
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                deskMgr.rawItemsOutput += data;
            }
        }
        onExited: {
            try {
                let parsed = JSON.parse(deskMgr.rawItemsOutput.trim());
                if (Array.isArray(parsed)) {
                    deskMgr.desktopItems = parsed;
                }
            } catch (e) {}
            deskMgr.rawItemsOutput = "";
        }
    }

    // Proceso para listar aplicaciones disponibles
    property string rawAppsOutput: ""
    property Process appsProc: Process {
        command: [Quickshell.shellDir + "/scripts/desktop_manager.py", "list_apps"]
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                deskMgr.rawAppsOutput += data;
            }
        }
        onExited: {
            try {
                let parsed = JSON.parse(deskMgr.rawAppsOutput.trim());
                if (Array.isArray(parsed)) {
                    deskMgr.availableApps = parsed;
                    deskMgr.filterApps();
                }
            } catch (e) {}
            deskMgr.rawAppsOutput = "";
        }
    }

    // Polling periódico ligero para detectar cambios en papelera, discos o archivos en escritorio
    property var pollTimer: Timer {
        interval: 4000
        repeat: true
        running: true
        onTriggered: {
            deskMgr.refreshItems();
        }
    }

    function refreshSettings() {
        settingsProc.running = false;
        settingsProc.running = true;
    }

    function refreshItems() {
        rawItemsOutput = "";
        itemsProc.running = false;
        itemsProc.running = true;
    }

    function refreshApps() {
        rawAppsOutput = "";
        appsProc.running = false;
        appsProc.running = true;
    }

    function refreshAll() {
        refreshSettings();
        refreshItems();
        refreshApps();
    }

    function setSetting(key, val) {
        if (key === "enabled") enabled = val;
        else if (key === "iconSize") iconSize = val;
        else if (key === "showFolders") showFolders = val;
        else if (key === "showTrash") showTrash = val;
        else if (key === "showDrives") showDrives = val;

        let proc = Qt.createQmlObject('import Quickshell.Io; Process {}', deskMgr);
        proc.command = [Quickshell.shellDir + "/scripts/desktop_manager.py", "set_setting", String(key), String(val)];
        proc.onExited.connect(function() {
            deskMgr.refreshItems();
            proc.destroy();
        });
        proc.running = true;
    }

    function toggleApp(desktopId) {
        let proc = Qt.createQmlObject('import Quickshell.Io; Process {}', deskMgr);
        proc.command = [Quickshell.shellDir + "/scripts/desktop_manager.py", "toggle_app", String(desktopId)];
        proc.onExited.connect(function() {
            deskMgr.refreshAll();
            proc.destroy();
        });
        proc.running = true;
    }

    function launchItem(item) {
        if (!item) return;
        let execCmd = item.exec || "";
        let isTerm = Boolean(item.terminal);

        let proc = Qt.createQmlObject('import Quickshell.Io; Process {}', deskMgr);
        proc.command = [Quickshell.shellDir + "/scripts/desktop_manager.py", "launch", execCmd, isTerm ? "true" : "false"];
        proc.onExited.connect(function() {
            proc.destroy();
        });
        proc.running = true;
    }

    function emptyTrash() {
        let proc = Qt.createQmlObject('import Quickshell.Io; Process {}', deskMgr);
        proc.command = [Quickshell.shellDir + "/scripts/desktop_manager.py", "empty_trash"];
        proc.onExited.connect(function() {
            deskMgr.refreshItems();
            proc.destroy();
        });
        proc.running = true;
    }

    function unmountDrive(mountPath) {
        let proc = Qt.createQmlObject('import Quickshell.Io; Process {}', deskMgr);
        proc.command = [Quickshell.shellDir + "/scripts/desktop_manager.py", "unmount_drive", String(mountPath)];
        proc.onExited.connect(function() {
            deskMgr.refreshItems();
            proc.destroy();
        });
        proc.running = true;
    }

    function filterApps() {
        let q = (appsSearchQuery || "").trim().toLowerCase();
        let all = availableApps || [];
        if (!q) {
            filteredAvailableApps = all;
            return;
        }
        let res = [];
        for (let i = 0; i < all.length; i++) {
            let app = all[i];
            let name = (app.name || "").toLowerCase();
            let cat = (app.categories || "").toLowerCase();
            let id = (app.id || "").toLowerCase();
            if (name.indexOf(q) !== -1 || cat.indexOf(q) !== -1 || id.indexOf(q) !== -1) {
                res.push(app);
            }
        }
        filteredAvailableApps = res;
    }

    onAppsSearchQueryChanged: {
        filterApps();
    }
}
