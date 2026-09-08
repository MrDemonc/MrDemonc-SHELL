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

    // Proceso para listar aplicaciones instaladas
    property Process listProc: Process {
        command: [Quickshell.shellDir + "/scripts/app_launcher.py", "list"]
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                try {
                    let list = JSON.parse(String(data).trim());
                    if (Array.isArray(list)) {
                        appMgr.allApps = list;
                        appMgr.filterApps();
                    }
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
        if (filteredApps && filteredApps.length > 0 && selectedIndex >= 0 && selectedIndex < filteredApps.length) {
            let app = filteredApps[selectedIndex];
            launchApp(app.exec, app.terminal);
            appLauncherOpen = false;
        } else if (searchQuery.trim() !== "") {
            // Permitir ejecutar comando personalizado directamente
            launchApp(searchQuery.trim(), false);
            appLauncherOpen = false;
        }
    }

    function launchApp(execCmd, isTerminal) {
        launchProc.command = [Quickshell.shellDir + "/scripts/app_launcher.py", "launch", execCmd, isTerminal ? "true" : "false"];
        launchProc.running = false;
        launchProc.running = true;
    }
}
