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

    // Monitoreo de archivo para alternar el selector de wallpapers por CLI / atajo
    property var watchToggleProc: Process {
        command: ["sh", "-c", "STATE=\"${XDG_RUNTIME_DIR:-/tmp}/quickshell_wallpaper_picker.toggle\"; while true; do if [ -f \"$STATE\" ]; then rm -f \"$STATE\"; echo 'TOGGLE'; fi; sleep 0.15; done"]
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                if (String(data).indexOf("TOGGLE") !== -1) {
                    wallMgr.wallpaperModalOpen = !wallMgr.wallpaperModalOpen;
                    if (wallMgr.wallpaperModalOpen) {
                        wallMgr.refreshList();
                    }
                }
            }
        }
    }

    // Proceso para obtener el wallpaper actual
    property Process getCurProc: Process {
        command: ["/home/demonc/Documents/Proyects/shell/scripts/wallpaper_manager.py", "get"]
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
        command: ["/home/demonc/Documents/Proyects/shell/scripts/wallpaper_manager.py", "list"]
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
        command: ["/home/demonc/Documents/Proyects/shell/scripts/wallpaper_manager.py", "open_dir"]
    }

    function setWallpaper(path) {
        if (!path) return;
        currentWallpaper = path;
        setProc.command = ["/home/demonc/Documents/Proyects/shell/scripts/wallpaper_manager.py", "set", path];
        setProc.running = false;
        setProc.running = true;
    }

    function openFolder() {
        openFolderProc.running = false;
        openFolderProc.running = true;
    }

    function refreshList() {
        listProc.running = false;
        listProc.running = true;
        getCurProc.running = false;
        getCurProc.running = true;
    }
}
