pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: mgr

    property bool modalOpen: false
    property var searchResults: []
    property bool isSearching: false
    property string lastQuery: ""

    property var currentLocation: ({
        "auto": true,
        "name": "Ubicación actual",
        "label": "Ubicación actual (Automática)"
    })

    property string statusMessage: ""

    // Proceso para consultar la ubicación actual guardada
    property var getLocProc: Process {
        command: [Quickshell.shellDir + "/scripts/weather_manager.py", "get"]
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                try {
                    let str = String(data).trim();
                    if (str.length > 0 && str.startsWith("{")) {
                        mgr.currentLocation = JSON.parse(str);
                    }
                } catch (e) {}
            }
        }
    }

    // Proceso para buscar ciudades
    property var searchProc: Process {
        stdout: SplitParser {
            onRead: function(data) {
                mgr.isSearching = false;
                try {
                    let str = String(data).trim();
                    if (str.length > 0 && str.startsWith("[")) {
                        mgr.searchResults = JSON.parse(str);
                    }
                } catch (e) {
                    mgr.searchResults = [];
                }
            }
        }
    }

    // Proceso para guardar la ubicación elegida
    property var setLocProc: Process {
        stdout: SplitParser {
            onRead: function(data) {
                mgr.refreshCurrent();
            }
        }
    }

    function open() {
        modalOpen = true;
        searchResults = [];
        isSearching = false;
        lastQuery = "";
        statusMessage = "";
        refreshCurrent();
    }

    function close() {
        modalOpen = false;
    }

    function toggle() {
        if (modalOpen) close();
        else open();
    }

    function refreshCurrent() {
        getLocProc.running = false;
        getLocProc.command = [Quickshell.shellDir + "/scripts/weather_manager.py", "get"];
        getLocProc.running = true;
    }

    function search(query) {
        let q = String(query).trim();
        lastQuery = q;
        if (q.length < 2) {
            searchResults = [];
            isSearching = false;
            return;
        }
        isSearching = true;
        searchProc.running = false;
        searchProc.command = [Quickshell.shellDir + "/scripts/weather_manager.py", "search", q];
        searchProc.running = true;
    }

    function selectLocation(item) {
        if (!item) return;
        setLocProc.running = false;
        setLocProc.command = [
            Quickshell.shellDir + "/scripts/weather_manager.py",
            "set",
            item.name || "",
            item.country || "",
            item.admin1 || "",
            item.query || item.name || ""
        ];
        setLocProc.running = true;
        statusMessage = "Ubicación fijada a " + item.name;
        closeTimer.start();
    }

    function selectAutoLocation() {
        setLocProc.running = false;
        setLocProc.command = [Quickshell.shellDir + "/scripts/weather_manager.py", "auto"];
        setLocProc.running = true;
        statusMessage = "Detección automática por red/IP activada";
        closeTimer.start();
    }

    property var closeTimer: Timer {
        interval: 350
        repeat: false
        onTriggered: {
            mgr.close();
        }
    }
}
