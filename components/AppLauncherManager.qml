pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: appMgr

    property bool appLauncherOpen: false
    property string searchQuery: ""
    property var allApps: []
    property var filteredApps: []
    property var recentApps: []
    property int selectedIndex: 0

    // Monitoreo de toggle por atajo o comando CLI
    property var watchToggleProc: Process {
        command: ["sh", "-c", "STATE=\"${XDG_RUNTIME_DIR:-/tmp}/quickshell_app_launcher.toggle\"; while true; do if [ -f \"$STATE\" ]; then rm -f \"$STATE\"; echo 'TOGGLE'; fi; sleep 0.15; done"]
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                if (String(data).indexOf("TOGGLE") !== -1) {
                    appMgr.toggle();
                }
            }
        }
    }

    // Proceso para listar aplicaciones instaladas y recientes
    property Process listProc: Process {
        command: [Quickshell.shellDir + "/scripts/app_launcher.py", "list"]
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                try {
                    let parsed = JSON.parse(String(data).trim());
                    if (parsed && typeof parsed === "object" && !Array.isArray(parsed)) {
                        appMgr.allApps = parsed.apps || [];
                        appMgr.recentApps = parsed.recents || [];
                    } else if (Array.isArray(parsed)) {
                        appMgr.allApps = parsed;
                    }
                    appMgr.filterApps();
                } catch (e) {}
            }
        }
    }

    property Process launchProc: Process {}

    function toggle() {
        appLauncherOpen = !appLauncherOpen;
        if (appLauncherOpen) {
            searchQuery = "";
            selectedIndex = 0;
            refreshApps();
        }
    }

    function refreshApps() {
        listProc.running = false;
        listProc.running = true;
    }

    function filterApps() {
        let q = searchQuery.trim().toLowerCase();
        if (q === "") {
            filteredApps = [];
        } else {
            let res = [];
            for (let i = 0; i < allApps.length; i++) {
                let app = allApps[i];
                let nameMatch = (app.name || "").toLowerCase().indexOf(q) !== -1;
                let commentMatch = (app.comment || "").toLowerCase().indexOf(q) !== -1;
                let execMatch = (app.exec || "").toLowerCase().indexOf(q) !== -1;
                let genericMatch = (app.genericName || "").toLowerCase().indexOf(q) !== -1;
                if (nameMatch || commentMatch || execMatch || genericMatch) {
                    res.push(app);
                }
            }
            filteredApps = res;
        }
        selectedIndex = 0;
    }

    onSearchQueryChanged: {
        filterApps();
    }

    function launchCurrent() {
        let list = (searchQuery.trim() === "") ? recentApps : filteredApps;
        if (list && list.length > 0 && selectedIndex >= 0 && selectedIndex < list.length) {
            let app = list[selectedIndex];
            launchApp(app.exec, app.terminal, app.name);
            appLauncherOpen = false;
        } else if (searchQuery.trim() !== "") {
            // Permitir ejecutar comando personalizado directamente
            launchApp(searchQuery.trim(), false, searchQuery.trim());
            appLauncherOpen = false;
        }
    }

    function launchApp(execCmd, isTerminal, appName) {
        if (!execCmd) return;
        // Actualizar recentApps en memoria de inmediato para feedback instantáneo
        let id = appName || execCmd;
        let found = null;
        for (let i = 0; i < allApps.length; i++) {
            if (allApps[i].name === id || allApps[i].exec === id) {
                found = allApps[i];
                break;
            }
        }
        if (found) {
            let updated = [found];
            for (let j = 0; j < recentApps.length; j++) {
                if (recentApps[j].exec !== found.exec) {
                    updated.push(recentApps[j]);
                }
            }
            recentApps = updated.slice(0, 4);
        }

        launchProc.command = [Quickshell.shellDir + "/scripts/app_launcher.py", "launch", execCmd, isTerminal ? "true" : "false", id];
        launchProc.running = false;
        launchProc.running = true;
    }
}
