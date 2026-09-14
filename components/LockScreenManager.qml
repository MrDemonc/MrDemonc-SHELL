pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: lockMgr

    property bool isLocked: false
    property bool isChecking: false
    property bool authFailed: false
    property int failAttempts: 0
    property string statusMessage: ""

    // Información del sistema compartida para la pantalla de bloqueo
    property var sysData: ({
        user: { username: "usuario", hostname: "archlinux", uptime: "0m", avatar: "" },
        weather: { city: "Ubicación actual", temp: "--°C", desc: "Clima", icon: "󰖐" },
        cpu: { percent: 0 },
        ram: { used_gb: 0, total_gb: 0, percent: 0 }
    })

    // Monitor de información del sistema (CPU, RAM, Usuario, Clima)
    Process {
        id: sysInfoProc
        command: [Quickshell.shellDir + "/scripts/get_system_info.py", "--daemon"]
        running: lockMgr.isLocked
        stdout: SplitParser {
            onRead: function(line) {
                try {
                    let str = String(line).trim();
                    if (str.length > 0 && str.startsWith("{")) {
                        lockMgr.sysData = JSON.parse(str);
                    }
                } catch (e) {}
            }
        }
    }

    // Información de batería
    property int batteryPercent: 100
    property string batteryStatus: "AC"
    property bool hasBattery: false

    Process {
        id: batProc
        command: [Quickshell.shellDir + "/scripts/get_battery_info.py"]
        running: lockMgr.isLocked
        stdout: SplitParser {
            onRead: function(data) {
                try {
                    let info = JSON.parse(String(data).trim());
                    lockMgr.hasBattery = !!info.hasBattery;
                    lockMgr.batteryPercent = info.percentage !== undefined ? info.percentage : 100;
                    lockMgr.batteryStatus = info.status || "AC";
                } catch (e) {}
            }
        }
    }

    // Información de audio
    property int audioVolume: 50
    property bool audioMuted: false

    Process {
        id: audioProc
        command: [Quickshell.shellDir + "/scripts/get_audio_info.py"]
        running: lockMgr.isLocked
        stdout: SplitParser {
            onRead: function(data) {
                try {
                    let info = JSON.parse(String(data).trim());
                    lockMgr.audioVolume = info.masterVolume || 0;
                    lockMgr.audioMuted = !!info.masterMuted;
                } catch (e) {}
            }
        }
    }

    // Cava en vivo para música cuando se reproduce sonido
    property bool isMusicPlaying: false
    property var cavaBars: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]

    Process {
        id: cavaProc
        command: [Quickshell.shellDir + "/scripts/cava_stream.py"]
        running: lockMgr.isLocked
        stdout: SplitParser {
            onRead: function(line) {
                try {
                    let str = String(line).trim();
                    if (str.length > 0 && str.startsWith("{")) {
                        let parsed = JSON.parse(str);
                        lockMgr.isMusicPlaying = !!parsed.playing;
                        if (parsed.bars && parsed.bars.length > 0) {
                            lockMgr.cavaBars = parsed.bars;
                        }
                    }
                } catch (e) {}
            }
        }
    }

    property bool isUnlocking: false

    // Proceso de autenticación con PAM
    property Process authProc: Process {
        onExited: function(exitCode, exitStatus) {
            lockMgr.isChecking = false;
            if (exitCode === 0) {
                lockMgr.unlock(false);
            } else {
                lockMgr.authFailed = true;
                lockMgr.failAttempts += 1;
                lockMgr.statusMessage = "Contraseña incorrecta";
                failedResetTimer.restart();
            }
        }
    }

    Timer {
        id: failedResetTimer
        interval: 2200
        onTriggered: {
            lockMgr.authFailed = false;
            lockMgr.statusMessage = "";
        }
    }

    Timer {
        id: finishUnlockTimer
        interval: 280
        repeat: false
        onTriggered: {
            lockMgr.finishUnlock();
        }
    }

    // Temporizador para apagar la pantalla tras 5 segundos de bloquearse
    Timer {
        id: dpmsOffTimer
        interval: 5000
        repeat: false
        onTriggered: {
            if (lockMgr.isLocked) {
                dpmsOffProc.running = false;
                dpmsOffProc.running = true;
            }
        }
    }

    Process {
        id: dpmsOffProc
        command: ["hyprctl", "dispatch", "dpms", "off"]
    }

    Process {
        id: dpmsOnProc
        command: ["hyprctl", "dispatch", "dpms", "on"]
    }

    function wakeScreen() {
        dpmsOnProc.running = false;
        dpmsOnProc.running = true;
        if (isLocked) {
            dpmsOffTimer.restart();
        }
    }

    Process {
        id: markLockedProc
        command: ["sh", "-c", "touch \"${XDG_RUNTIME_DIR:-/tmp}/quickshell_lock.active\""]
    }

    Process {
        id: markUnlockedProc
        command: ["sh", "-c", "rm -f \"${XDG_RUNTIME_DIR:-/tmp}/quickshell_lock.active\""]
    }

    Component.onCompleted: {
        markUnlockedProc.running = false;
        markUnlockedProc.running = true;
    }

    function finishUnlock() {
        dpmsOffTimer.stop();
        dpmsOnProc.running = false;
        dpmsOnProc.running = true;
        finishUnlockTimer.stop();
        isLocked = false;
        isUnlocking = false;
        authFailed = false;
        isChecking = false;
        statusMessage = "";
        failAttempts = 0;
        markUnlockedProc.running = false;
        markUnlockedProc.running = true;
    }

    function lock() {
        finishUnlockTimer.stop();
        isUnlocking = false;
        authFailed = false;
        isChecking = false;
        statusMessage = "";
        isLocked = true;
        markLockedProc.running = false;
        markLockedProc.running = true;
        // Refrescar batería y audio
        batProc.running = false; batProc.running = true;
        audioProc.running = false; audioProc.running = true;
        // Iniciar temporizador de 5 segundos para apagar la pantalla
        dpmsOffTimer.restart();
    }

    function unlock(immediate) {
        if (immediate) {
            finishUnlock();
            return;
        }
        isUnlocking = true;
        finishUnlockTimer.restart();
    }

    function verifyPassword(pwd) {
        if (isChecking) return;
        if (!pwd || pwd.length === 0) {
            authFailed = true;
            statusMessage = "Introduce la contraseña";
            failedResetTimer.restart();
            return;
        }
        isChecking = true;
        authFailed = false;
        statusMessage = "Comprobando...";
        let escaped = pwd.replace(/'/g, "'\\''");
        authProc.command = ["sh", "-c", `printf '%s' '${escaped}' | "${Quickshell.shellDir}/scripts/auth_check.py"`];
        authProc.running = false;
        authProc.running = true;
    }

    // Escuchar peticiones de bloqueo y desbloqueo por FIFO runtime (<1ms) y archivo de respaldo
    property var watchLockProc: Process {
        command: ["sh", "-c", "FIFO=\"${XDG_RUNTIME_DIR:-/tmp}/quickshell_lock.fifo\"; LOCK=\"${XDG_RUNTIME_DIR:-/tmp}/quickshell_lock.toggle\"; rm -f \"$FIFO\"; mkfifo \"$FIFO\"; ( while true; do if [ -f \"$LOCK\" ]; then VAL=$(cat \"$LOCK\" 2>/dev/null); rm -f \"$LOCK\"; if [ -p \"$FIFO\" ]; then if [ \"$VAL\" = \"UNLOCK\" ]; then echo 'UNLOCK' > \"$FIFO\" 2>/dev/null || true; else echo 'LOCK' > \"$FIFO\" 2>/dev/null || true; fi; fi; fi; sleep 0.05; done ) & BG_PID=$!; trap 'kill $BG_PID 2>/dev/null; rm -f \"$FIFO\"' EXIT; while true; do if read -r line < \"$FIFO\"; then echo \"$line\"; fi; done"]
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                let str = String(data).trim();
                if (str.indexOf("UNLOCK") !== -1) {
                    lockMgr.unlock(false);
                } else if (str.indexOf("LOCK") !== -1) {
                    lockMgr.lock();
                }
            }
        }
    }
}
