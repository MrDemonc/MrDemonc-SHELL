pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: powerMgr

    property bool powerOpen: false
    property int selectedIndex: 0
    property var pendingAction: null

    property string username: "usuario"
    property string hostname: "archlinux"
    property string uptime: "0m"

    readonly property var actions: [
        {
            id: "poweroff",
            title: "Apagar",
            desc: "Apagar el sistema",
            icon: "󰐥",
            key: "1",
            letter: "P",
            color: Theme.danger,
            needsConfirm: true,
            confirmTitle: "¿Apagar el sistema por completo?",
            confirmDesc: "Se cerrarán todas las aplicaciones abiertas y el equipo se apagará de forma segura.",
            command: ["systemctl", "poweroff"]
        },
        {
            id: "reboot",
            title: "Reiniciar",
            desc: "Reiniciar equipo",
            icon: "󰜉",
            key: "2",
            letter: "R",
            color: Theme.warning,
            needsConfirm: true,
            confirmTitle: "¿Reiniciar el sistema operativo?",
            confirmDesc: "Se reiniciará el equipo de inmediato para cargar una nueva sesión.",
            command: ["systemctl", "reboot"]
        },
        {
            id: "suspend",
            title: "Suspender",
            desc: "Suspender a RAM",
            icon: "󰤄",
            key: "3",
            letter: "S",
            color: Theme.cyan,
            needsConfirm: false,
            confirmTitle: "¿Suspender el equipo?",
            confirmDesc: "El equipo entrará en modo de bajo consumo manteniendo las ventanas en memoria.",
            command: ["systemctl", "suspend"]
        },
        {
            id: "lock",
            title: "Bloquear",
            desc: "Bloquear pantalla",
            icon: "󰌾",
            key: "4",
            letter: "L",
            color: Theme.primary,
            needsConfirm: false,
            confirmTitle: "¿Bloquear pantalla?",
            confirmDesc: "Se activará la pantalla de bloqueo Hyprlock.",
            command: ["sh", "-c", "command -v hyprlock >/dev/null 2>&1 && hyprlock || notify-send 'Sistema' 'hyprlock no está instalado'"]
        },
        {
            id: "logout",
            title: "Cerrar Sesión",
            desc: "Salir de Hyprland",
            icon: "󰍃",
            key: "5",
            letter: "E",
            color: Theme.pink,
            needsConfirm: true,
            confirmTitle: "¿Cerrar sesión de Hyprland?",
            confirmDesc: "Se cerrará el entorno gráfico y volverás a la pantalla de inicio o consola.",
            command: ["hyprctl", "dispatch", "exit"]
        },
        {
            id: "hibernate",
            title: "Hibernar",
            desc: "Guardar en disco",
            icon: "󰤆",
            key: "6",
            letter: "H",
            color: Theme.overlay,
            needsConfirm: true,
            confirmTitle: "¿Hibernar el sistema?",
            confirmDesc: "Se guardará el estado de la memoria en disco y se apagará el equipo.",
            command: ["systemctl", "hibernate"]
        }
    ]

    // Observador para toggle SUPER + ESC o comando CLI
    property var watchToggleProc: Process {
        command: ["sh", "-c", "STATE=\"${XDG_RUNTIME_DIR:-/tmp}/quickshell_power.toggle\"; while true; do if [ -f \"$STATE\" ]; then rm -f \"$STATE\"; echo 'TOGGLE'; fi; sleep 0.15; done"]
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                if (String(data).indexOf("TOGGLE") !== -1) {
                    powerMgr.toggle();
                }
            }
        }
    }

    // Obtener información de usuario y uptime
    property var infoProc: Process {
        command: ["python3", "-c", "import os; u = os.getenv('USER') or 'usuario'; h = os.uname().nodename; f = open('/proc/uptime') if os.path.exists('/proc/uptime') else None; sec = float(f.readline().split()[0]) if f else 0; hrs = int(sec // 3600); mins = int((sec % 3600) // 60); up = f'{hrs}h {mins}m' if hrs > 0 else f'{mins}m'; print(f'{u};{h};{up}')"]
        running: false
        stdout: SplitParser {
            onRead: function(data) {
                try {
                    let parts = String(data).trim().split(";");
                    if (parts.length >= 3) {
                        powerMgr.username = parts[0];
                        powerMgr.hostname = parts[1];
                        powerMgr.uptime = parts[2];
                    }
                } catch (e) {}
            }
        }
    }

    property Process execProc: Process {}

    property real lastToggleTime: 0

    function toggle() {
        let now = Date.now();
        if (now - lastToggleTime < 300) return;
        lastToggleTime = now;

        powerOpen = !powerOpen;
        if (powerOpen) {
            selectedIndex = 0;
            pendingAction = null;
            refreshInfo();
        }
    }

    function open() {
        powerOpen = true;
        selectedIndex = 0;
        pendingAction = null;
        refreshInfo();
    }

    function close() {
        powerOpen = false;
        pendingAction = null;
    }

    function refreshInfo() {
        infoProc.running = false;
        infoProc.running = true;
    }

    function triggerAction(action) {
        if (!action) return;
        if (action.needsConfirm && pendingAction !== action) {
            pendingAction = action;
            return;
        }
        executeAction(action);
    }

    function executeAction(action) {
        if (!action) return;
        let cmd = action.command;
        powerOpen = false;
        pendingAction = null;
        execProc.command = cmd;
        execProc.running = true;
    }

    function cancelConfirm() {
        pendingAction = null;
    }
}
