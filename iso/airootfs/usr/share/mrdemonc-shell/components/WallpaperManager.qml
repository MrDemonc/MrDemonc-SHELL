pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: wallMgr

    property bool wallpaperModalOpen: false
    property string currentWallpaper: ""
    property var availableWallpapers: []
    property int previewIndex: 0
    readonly property var previewWallpaperData: {
        if (availableWallpapers && availableWallpapers.length > 0) {
            return availableWallpapers[Math.max(0, Math.min(availableWallpapers.length - 1, previewIndex))];
        }
        return null;
    }

    // Monitoreo de archivo para alternar el selector de wallpapers o recargar por cambio de tema
    property var watchToggleProc: Process {
        command: ["sh", "-c", "STATE=\"${XDG_RUNTIME_DIR:-/tmp}/quickshell_wallpaper_picker.toggle\"; WP_RELOAD=\"${XDG_RUNTIME_DIR:-/tmp}/quickshell_wallpaper_reload.toggle\"; while kill -0 $PPID 2>/dev/null; do if [ -f \"$STATE\" ]; then rm -f \"$STATE\"; echo 'TOGGLE'; fi; if [ -f \"$WP_RELOAD\" ]; then rm -f \"$WP_RELOAD\"; echo 'RELOAD'; fi; sleep 0.04; done"]
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                let s = String(data);
                if (s.indexOf("TOGGLE") !== -1) {
                    wallMgr.wallpaperModalOpen = !wallMgr.wallpaperModalOpen;
                    if (wallMgr.wallpaperModalOpen) {
                        wallMgr.refreshList();
                    }
                }
                if (s.indexOf("RELOAD") !== -1) {
                    wallMgr.refreshList();
                }
            }
        }
    }

    // Proceso para obtener el wallpaper actual
    property Process getCurProc: Process {
        command: [Quickshell.shellDir + "/scripts/wallpaper_manager.py", "get"]
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                try {
                    let parsed = JSON.parse(String(data).trim());
                    if (parsed && parsed.path) {
                        wallMgr.currentWallpaper = parsed.path;
                    }
                } catch (e) {}
            }
        }
    }

    // Proceso para listar los wallpapers disponibles en ~/Pictures/Wallpapers
    property Process listProc: Process {
        command: [Quickshell.shellDir + "/scripts/wallpaper_manager.py", "list"]
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                try {
                    let list = JSON.parse(String(data).trim());
                    if (Array.isArray(list)) {
                        wallMgr.availableWallpapers = list;
                    }
                } catch (e) {}
            }
        }
    }

    property Process setProc: Process {
        command: []
        onExited: {
            wallMgr.getCurProc.running = false;
            wallMgr.getCurProc.running = true;
            wallMgr.listProc.running = false;
            wallMgr.listProc.running = true;
        }
    }

    property Process openFolderProc: Process {
        command: [Quickshell.shellDir + "/scripts/wallpaper_manager.py", "open_dir"]
    }

    function setWallpaper(path) {
        if (!path) return;
        currentWallpaper = path;
        let cmd = [Quickshell.shellDir + "/scripts/wallpaper_manager.py", "set", path];
        if (setProc.running) {
            setProc.running = false;
            Qt.callLater(function() {
                setProc.command = cmd;
                setProc.running = true;
            });
        } else {
            setProc.command = cmd;
            setProc.running = true;
        }
    }

    function openFolder() {
        if (openFolderProc.running) {
            openFolderProc.running = false;
            Qt.callLater(function() { openFolderProc.running = true; });
        } else {
            openFolderProc.running = true;
        }
    }

    function refreshList() {
        if (listProc.running) {
            listProc.running = false;
            Qt.callLater(function() { listProc.running = true; });
        } else {
            listProc.running = true;
        }
        if (getCurProc.running) {
            getCurProc.running = false;
            Qt.callLater(function() { getCurProc.running = true; });
        } else {
            getCurProc.running = true;
        }
    }
}
