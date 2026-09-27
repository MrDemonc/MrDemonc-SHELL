pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool reminderOpen: false
    property var activeTimers: []
    property int nextId: 1

    property var actionProc: Process {
        running: false
    }

    // Monitoreo del archivo de señalización para atajos de teclado (SUPER + ALT + R)
    property var watchToggleProc: Process {
        command: ["sh", "-c", "STATE=\"${XDG_RUNTIME_DIR:-/tmp}/quickshell_reminder.toggle\"; while kill -0 $PPID 2>/dev/null; do if [ -f \"$STATE\" ]; then rm -f \"$STATE\"; echo 'TOGGLE'; fi; sleep 0.04; done"]
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                if (String(data).indexOf("TOGGLE") !== -1) {
                    root.toggle();
                }
            }
        }
    }

    function toggle() {
        reminderOpen = !reminderOpen;
    }

    function open() {
        reminderOpen = true;
    }

    function close() {
        reminderOpen = false;
    }

    function formatTime(seconds) {
        let sec = Math.max(0, Math.floor(seconds));
        let h = Math.floor(sec / 3600);
        let m = Math.floor((sec % 3600) / 60);
        let s = sec % 60;
        let sStr = String(s).padStart(2, '0');
        let mStr = String(m).padStart(2, '0');
        if (h > 0) {
            let hStr = String(h).padStart(2, '0');
            return `${hStr}:${mStr}:${sStr}`;
        }
        return `${mStr}:${sStr}`;
    }

    function addTimer(name, hours, minutes, seconds) {
        let total = (parseInt(hours) || 0) * 3600 + (parseInt(minutes) || 0) * 60 + (parseInt(seconds) || 0);
        if (total <= 0) return false;

        let cleanTitle = String(name || "").trim();
        if (cleanTitle.length === 0) {
            cleanTitle = "Temporizador (" + formatTime(total) + ")";
        }

        let newTimer = {
            id: nextId++,
            title: cleanTitle,
            totalSeconds: total,
            remainingSeconds: total,
            running: true,
            progress: 0.0,
            formatted: formatTime(total)
        };

        let copy = [];
        for (let i = 0; i < activeTimers.length; i++) {
            copy.push(activeTimers[i]);
        }
        copy.push(newTimer);
        activeTimers = copy;

        // Notificación de confirmación inicial
        let msgCmd = `notify-send -u low -a "Temporizador" -i "alarm-symbolic" "Temporizador iniciado" "${cleanTitle} - ${formatTime(total)}" &`;
        actionProc.command = ["sh", "-c", msgCmd];
        actionProc.running = false;
        actionProc.running = true;

        return true;
    }

    function deleteTimer(id) {
        let copy = [];
        for (let i = 0; i < activeTimers.length; i++) {
            if (activeTimers[i].id !== id) {
                copy.push(activeTimers[i]);
            }
        }
        activeTimers = copy;
    }

    function togglePause(id) {
        let copy = [];
        for (let i = 0; i < activeTimers.length; i++) {
            let t = activeTimers[i];
            if (t.id === id) {
                t.running = !t.running;
            }
            copy.push(t);
        }
        activeTimers = copy;
    }

    function addExtraTime(id, extraSec) {
        let copy = [];
        for (let i = 0; i < activeTimers.length; i++) {
            let t = activeTimers[i];
            if (t.id === id) {
                t.totalSeconds += extraSec;
                t.remainingSeconds += extraSec;
                t.formatted = formatTime(t.remainingSeconds);
            }
            copy.push(t);
        }
        activeTimers = copy;
    }

    function triggerAlarm(timer) {
        let title = String(timer.title || "Recordatorio").replace(/"/g, '\\"').replace(/\$/g, '\\$').replace(/`/g, '\\`');
        let soundCmd = "paplay /usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga 2>/dev/null || paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null || true";
        let notifCmd = `notify-send -u critical -a "Temporizador" -i "alarm-symbolic" "⏰ ¡Tiempo Finalizado!" "${title}" &`;
        let fullCmd = `${soundCmd} & ${notifCmd}`;

        let alertProc = Qt.createQmlObject('import Quickshell.Io; Process { running: false }', root);
        alertProc.command = ["sh", "-c", fullCmd];
        alertProc.running = true;
    }

    // Cronómetro de cuenta regresiva por segundo
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            if (root.activeTimers.length === 0) return;

            let updatedList = [];
            let finishedTimers = [];

            for (let i = 0; i < root.activeTimers.length; i++) {
                let t = root.activeTimers[i];
                if (t.running) {
                    t.remainingSeconds -= 1;
                    if (t.remainingSeconds <= 0) {
                        t.remainingSeconds = 0;
                        t.running = false;
                        finishedTimers.push(t);
                        continue; // Quitar automáticamente de la lista activa al terminar
                    }
                }
                let total = Math.max(1, t.totalSeconds);
                let rem = Math.max(0, t.remainingSeconds);
                t.progress = Math.min(1.0, Math.max(0.0, 1.0 - (rem / total)));
                t.formatted = root.formatTime(rem);
                updatedList.push(t);
            }

            root.activeTimers = updatedList;

            // Disparar alertas para temporizadores cumplidos
            for (let j = 0; j < finishedTimers.length; j++) {
                root.triggerAlarm(finishedTimers[j]);
            }
        }
    }
}
