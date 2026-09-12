pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property bool isOpen: false
    property string appId: ""
    property string appTitle: ""
    property string appIcon: ""
    property real targetX: 0
    property real targetY: 0
    property var currentSniItem: null
    property var options: []

    property var execProc: Process {
        running: false
    }

    property var watchMenuProc: Process {
        command: ["sh", "-c", "STATE=\"${XDG_RUNTIME_DIR:-/tmp}/quickshell_tray_menu.toggle\"; while true; do if [ -f \"$STATE\" ]; then T=$(cat \"$STATE\"); rm -f \"$STATE\"; echo \"MENU:$T\"; fi; sleep 0.15; done"]
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                let str = String(data).trim();
                if (str.indexOf("MENU:") === 0) {
                    let parts = str.substring(5).trim().split(" ");
                    if (parts[0] === "close") {
                        root.closeMenu();
                        return;
                    }
                    let app = parts[0] || "telegram";
                    let x = parseFloat(parts[1]) || 980;
                    let y = parseFloat(parts[2]) || 15;
                    root.openMenu(app, x, y);
                }
            }
        }
    }

    function runCommand(cmd) {
        if (!cmd) return;
        execProc.command = ["sh", "-c", cmd];
        execProc.running = false;
        execProc.running = true;
    }

    function openMenu(id, screenX, screenY, extraItem) {
        appId = id;
        targetX = screenX;
        targetY = screenY;
        currentSniItem = extraItem || null;

        let opts = [];

        if (id === "telegram") {
            appTitle = "Telegram";
            appIcon = "";
            opts = [
                {
                    icon: "󰈈",
                    label: "Abrir Telegram",
                    action: function() {
                        runCommand("hyprctl dispatch focuswindow TelegramDesktop 2>/dev/null || gtk-launch org.telegram.desktop.desktop 2>/dev/null || telegram-desktop 2>/dev/null || Telegram 2>/dev/null &");
                    }
                },
                {
                    icon: "󰂚",
                    label: "Notificaciones",
                    action: function() {
                        runCommand("notify-send 'Telegram' 'Notificaciones de Telegram activas' -i telegram 2>/dev/null");
                    }
                },
                {
                    isSeparator: true
                },
                {
                    icon: "󰈆",
                    label: "Cerrar Telegram",
                    isDanger: true,
                    action: function() {
                        runCommand("pkill -i telegram-desktop || pkill -x Telegram || pkill -i telegram");
                    }
                }
            ];
        } else if (id === "discord") {
            appTitle = "Discord";
            appIcon = "󰙯";
            opts = [
                {
                    icon: "󰈈",
                    label: "Abrir Discord",
                    action: function() {
                        runCommand("hyprctl dispatch focuswindow discord 2>/dev/null || gtk-launch discord.desktop 2>/dev/null || discord 2>/dev/null || webcord 2>/dev/null &");
                    }
                },
                {
                    icon: "󰍬",
                    label: "Silenciar audio",
                    action: function() {
                        runCommand("notify-send 'Discord' 'Comando de silenciar ejecutado' -i discord 2>/dev/null");
                    }
                },
                {
                    isSeparator: true
                },
                {
                    icon: "󰈆",
                    label: "Cerrar Discord",
                    isDanger: true,
                    action: function() {
                        runCommand("pkill -i discord || pkill -i webcord");
                    }
                }
            ];
        } else if (id === "spotify") {
            appTitle = "Spotify";
            appIcon = "󰓇";
            opts = [
                {
                    icon: "󰈈",
                    label: "Abrir Spotify",
                    action: function() {
                        runCommand("hyprctl dispatch focuswindow spotify 2>/dev/null || gtk-launch spotify.desktop 2>/dev/null || spotify 2>/dev/null &");
                    }
                },
                {
                    icon: "󰐊",
                    label: "Reproducir / Pausa",
                    action: function() {
                        runCommand("playerctl -p spotify play-pause 2>/dev/null || playerctl play-pause 2>/dev/null");
                    }
                },
                {
                    icon: "󰒭",
                    label: "Siguiente pista",
                    action: function() {
                        runCommand("playerctl -p spotify next 2>/dev/null || playerctl next 2>/dev/null");
                    }
                },
                {
                    icon: "󰒮",
                    label: "Pista anterior",
                    action: function() {
                        runCommand("playerctl -p spotify previous 2>/dev/null || playerctl previous 2>/dev/null");
                    }
                },
                {
                    isSeparator: true
                },
                {
                    icon: "󰈆",
                    label: "Cerrar Spotify",
                    isDanger: true,
                    action: function() {
                        runCommand("pkill -i spotify");
                    }
                }
            ];
        } else if (id === "steam") {
            appTitle = "Steam";
            appIcon = "󰓓";
            opts = [
                {
                    icon: "󰈈",
                    label: "Abrir Steam",
                    action: function() {
                        runCommand("hyprctl dispatch focuswindow steam 2>/dev/null || gtk-launch steam.desktop 2>/dev/null || steam 2>/dev/null &");
                    }
                },
                {
                    icon: "󰊴",
                    label: "Biblioteca de Juegos",
                    action: function() {
                        runCommand("steam steam://open/games 2>/dev/null &");
                    }
                },
                {
                    icon: "󰻂",
                    label: "Amigos y Chat",
                    action: function() {
                        runCommand("steam steam://open/friends 2>/dev/null &");
                    }
                },
                {
                    isSeparator: true
                },
                {
                    icon: "󰈆",
                    label: "Cerrar Steam",
                    isDanger: true,
                    action: function() {
                        runCommand("steam -shutdown 2>/dev/null || pkill -x steam");
                    }
                }
            ];
        } else if (extraItem) {
            let it = extraItem;
            let title = it.title || it.id || "Aplicación";
            appTitle = title;
            appIcon = "󰅁";
            opts = [
                {
                    icon: "󰈈",
                    label: "Abrir / Activar",
                    action: function() {
                        if (it && typeof it.activate === "function") it.activate();
                    }
                },
                {
                    icon: "󰍜",
                    label: "Menú contextual",
                    action: function() {
                        if (it && typeof it.secondaryActivate === "function") it.secondaryActivate();
                    }
                },
                {
                    isSeparator: true
                },
                {
                    icon: "󰈆",
                    label: "Cerrar",
                    isDanger: true,
                    action: function() {
                        if (it && typeof it.secondaryActivate === "function") it.secondaryActivate();
                    }
                }
            ];
        }

        options = opts;
        isOpen = true;
    }

    function closeMenu() {
        isOpen = false;
    }
}
