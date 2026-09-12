pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

QtObject {
    id: notifMgr

    property bool sidebarOpen: false
    property bool silenced: false
    property string sidebarPosition: "right" // "right" o "left"
    property var activePopups: []
    property var history: []
    property int unreadCount: 0

    // Servidor DBus nativo de Quickshell para org.freedesktop.Notifications
    property var server: NotificationServer {
        id: notifServer
        actionsSupported: true
        imageSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        keepOnReload: true

        onNotification: function(notif) {
            notifMgr.handleIncomingNotification(notif);
        }
    }

    // Proceso para reproducir sonido notification.mp3
    property var playSoundProc: Process {
        command: ["sh", "-c", "SOUND=\"/home/$USER/Descargas/notification.mp3\"; [ -f \"$SOUND\" ] || SOUND=\"" + Quickshell.shellDir + "/assets/sounds/notification.mp3\"; pw-play \"$SOUND\" 2>/dev/null || paplay \"$SOUND\" 2>/dev/null || mpv --no-video --volume=85 \"$SOUND\" 2>/dev/null"]
        running: false
    }

    // Proceso para copiar texto al portapapeles con wl-copy
    property var copyProc: Process {
        running: false
    }

    // Proceso de carga de configuración
    property var loadSettingsProc: Process {
        command: ["python3", "-c", "import os, json; f = os.path.expanduser('~/.config/quickshell/notifications_settings.json'); print(open(f).read() if os.path.isfile(f) else '{}')"]
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                try {
                    let parsed = JSON.parse(String(data).trim());
                    if (parsed.silenced !== undefined) notifMgr.silenced = parsed.silenced;
                } catch(e) {}
            }
        }
    }

    // Proceso para guardar configuración
    property var saveSettingsProc: Process {
        running: false
    }

    // Observador para atajo SUPER + N o comandos CLI
    property var watchToggleProc: Process {
        command: ["sh", "-c", "STATE=\"${XDG_RUNTIME_DIR:-/tmp}/quickshell_notifications.toggle\"; while true; do if [ -f \"$STATE\" ]; then CMD=$(cat \"$STATE\" 2>/dev/null); rm -f \"$STATE\"; echo \"${CMD:-TOGGLE}\"; fi; sleep 0.15; done"]
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                let s = String(data).trim();
                if (s.indexOf("DND") !== -1) {
                    notifMgr.toggleSilenced();
                } else if (s.indexOf("CLEAR") !== -1) {
                    notifMgr.clearAll();
                } else if (s.indexOf("TOGGLE") !== -1) {
                    notifMgr.toggleSidebar();
                }
            }
        }
    }

    function handleIncomingNotification(notif) {
        if (!notif) return;

        let now = new Date();
        let timeStr = ("0" + now.getHours()).slice(-2) + ":" + ("0" + now.getMinutes()).slice(-2);
        let id = notif.id || Date.now();
        let appName = notif.appName && notif.appName.trim() !== "" ? notif.appName : "Sistema";
        let summary = notif.summary || "";
        let body = notif.body || "";
        let appIcon = notif.appIcon || notif.image || "";

        let actionsList = [];
        if (notif.actions) {
            for (let i = 0; i < notif.actions.length; i++) {
                let act = notif.actions[i];
                if (act && act.identifier && act.identifier !== "default") {
                    actionsList.push({
                        id: act.identifier,
                        text: act.text || act.identifier,
                        actionObj: act
                    });
                }
            }
        }

        let item = {
            id: id,
            appName: appName,
            appIcon: appIcon,
            summary: summary,
            body: body,
            time: timeStr,
            timestamp: Date.now(),
            actions: actionsList
        };

        // 1. Reproducir sonido si no está silenciado
        if (!silenced) {
            playSoundProc.running = false;
            playSoundProc.running = true;
        }

        // 2. Si no está en silencio y el panel lateral está cerrado, mostrar popup flotante
        if (!silenced && !sidebarOpen) {
            let pList = [...activePopups];
            pList.push(item);
            if (pList.length > 4) pList.shift();
            activePopups = pList;
        }

        // 3. Registrar en el historial
        let hList = [item, ...history];
        if (hList.length > 50) hList.pop();
        history = hList;
        unreadCount = unreadCount + 1;
    }

    property Process launchAppProc: Process {}

    function copyContent(text) {
        if (!text) return;
        copyProc.command = ["wl-copy", text];
        copyProc.running = false;
        copyProc.running = true;
    }

    function openNotification(item) {
        if (!item) return;
        dismissPopup(item.id);

        let app = (item.appName || "").trim().toLowerCase();
        if (app === "telegram") app = "telegram-desktop";
        if (app === "discord") app = "discord";
        if (app && app !== "sistema") {
            launchAppProc.command = ["sh", "-c", "gtk-launch " + app + " 2>/dev/null || hyprctl dispatch exec " + app + " 2>/dev/null || true"];
            launchAppProc.running = false;
            launchAppProc.running = true;
        }
    }

    function dismissPopup(id) {
        let pList = [];
        for (let i = 0; i < activePopups.length; i++) {
            if (activePopups[i].id !== id) {
                pList.push(activePopups[i]);
            }
        }
        activePopups = pList;
    }

    function deleteHistoryItem(id) {
        let hList = [];
        for (let i = 0; i < history.length; i++) {
            if (history[i].id !== id) {
                hList.push(history[i]);
            }
        }
        history = hList;
        if (unreadCount > history.length) unreadCount = history.length;
    }

    function clearAll() {
        history = [];
        activePopups = [];
        unreadCount = 0;
    }

    function toggleSilenced() {
        silenced = !silenced;
        saveSettings();
    }

    function toggleSidebar() {
        sidebarOpen = !sidebarOpen;
        if (sidebarOpen) {
            unreadCount = 0;
            activePopups = [];
        }
    }

    function saveSettings() {
        let jsonStr = JSON.stringify({
            silenced: silenced,
            sidebarPosition: "right"
        });
        saveSettingsProc.command = ["python3", "-c", "import os, sys; os.makedirs(os.path.expanduser('~/.config/quickshell'), exist_ok=True); open(os.path.expanduser('~/.config/quickshell/notifications_settings.json'), 'w').write(sys.argv[1])", jsonStr];
        saveSettingsProc.running = false;
        saveSettingsProc.running = true;
    }
}
