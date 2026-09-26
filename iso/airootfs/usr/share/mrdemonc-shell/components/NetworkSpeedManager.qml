pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: mgr

    property bool modalOpen: false

    property var netData: ({
        "interface": "wlo1",
        "type": "wifi",
        "ssid": "Buscando red...",
        "signal": 0,
        "freq": "",
        "ip": "--",
        "gateway": "--",
        "dns": "--",
        "mac": "--",
        "ping": 0.0,
        "rx_bps": 0,
        "tx_bps": 0,
        "rx_mbps": 0.0,
        "tx_mbps": 0.0,
        "rx_str": "0 bps",
        "tx_str": "0 bps",
        "total_rx_mb": 0.0,
        "total_tx_mb": 0.0
    })

    // Historial de 30 muestras en tiempo real para los gráficos
    property var downloadHistory: []
    property var uploadHistory: []
    property real maxObservedSpeed: 10.0
    property real peakDownload: 0.0
    property real peakUpload: 0.0

    // Estado del benchmark SpeedTest
    property bool speedTestRunning: false
    property string speedTestPhase: "idle" // "idle", "ping", "download", "upload", "done"
    property real speedTestProgress: 0.0
    property string speedTestMessage: ""
    property real testPing: 0.0
    property real testDownload: 0.0
    property real testUpload: 0.0
    property real testPeakDownload: 0.0
    property real testPeakUpload: 0.0
    property string testDownloadStr: "--"
    property string testUploadStr: "--"

    // Curvas específicas para el gráfico del Test de Velocidad
    property var testDownloadHistory: []
    property var testUploadHistory: []
    property real testMaxObservedSpeed: 20.0

    Component.onCompleted: {
        // Inicializar buffers con ceros
        let dl = [];
        let ul = [];
        for (let i = 0; i < 30; i++) {
            dl.push(0);
            ul.push(0);
        }
        downloadHistory = dl;
        uploadHistory = ul;
    }

    // Monitor en tiempo real (daemon a 1s)
    property var monitorProc: Process {
        id: monProc
        command: ["python3", Quickshell.shellDir + "/scripts/network_monitor.py"]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                try {
                    let str = String(line).trim();
                    if (str.length > 0 && str.startsWith("{")) {
                        let parsed = JSON.parse(str);
                        mgr.netData = parsed;

                        let rx = parsed.rx_mbps || 0.0;
                        let tx = parsed.tx_mbps || 0.0;

                        if (rx > mgr.peakDownload) mgr.peakDownload = rx;
                        if (tx > mgr.peakUpload) mgr.peakUpload = tx;

                        let dl = mgr.downloadHistory.slice();
                        let ul = mgr.uploadHistory.slice();

                        dl.push(rx);
                        ul.push(tx);

                        if (dl.length > 30) dl.shift();
                        if (ul.length > 30) ul.shift();

                        mgr.downloadHistory = dl;
                        mgr.uploadHistory = ul;

                        let currentMax = 5.0;
                        for (let i = 0; i < dl.length; i++) {
                            if (dl[i] > currentMax) currentMax = dl[i];
                            if (ul[i] > currentMax) currentMax = ul[i];
                        }
                        mgr.maxObservedSpeed = Math.ceil(currentMax * 1.15);
                    }
                } catch (e) {}
            }
        }
    }

    // Proceso del Benchmark de Velocidad
    property var speedTestProc: Process {
        id: stProc
        command: ["python3", Quickshell.shellDir + "/scripts/network_monitor.py", "--speedtest"]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                try {
                    let str = String(line).trim();
                    if (str.length > 0 && str.startsWith("{")) {
                        let parsed = JSON.parse(str);
                        if (parsed.phase) {
                            mgr.speedTestPhase = parsed.phase;
                        }
                        if (parsed.progress !== undefined) {
                            mgr.speedTestProgress = parsed.progress;
                        }
                        if (parsed.message) {
                            mgr.speedTestMessage = parsed.message;
                        }
                        if (parsed.ping !== undefined) {
                            mgr.testPing = parsed.ping;
                        }

                        // Muestra de descarga en tiempo real durante el test
                        if (parsed.phase === "download" && parsed.speed !== undefined) {
                            let spd = parsed.speed;
                            let dl = mgr.testDownloadHistory.slice();
                            dl.push(spd);
                            mgr.testDownloadHistory = dl;
                            mgr.testDownload = spd;
                            mgr.testDownloadStr = parsed.download_str || (spd.toFixed(1) + " Mbps");
                            if (spd > mgr.testPeakDownload) mgr.testPeakDownload = spd;
                            if (spd * 1.15 > mgr.testMaxObservedSpeed) mgr.testMaxObservedSpeed = Math.ceil(spd * 1.15);
                        }

                        // Muestra de subida en tiempo real durante el test
                        if (parsed.phase === "upload" && parsed.speed !== undefined) {
                            let spd = parsed.speed;
                            let ul = mgr.testUploadHistory.slice();
                            ul.push(spd);
                            mgr.testUploadHistory = ul;
                            mgr.testUpload = spd;
                            mgr.testUploadStr = parsed.upload_str || (spd.toFixed(1) + " Mbps");
                            if (spd > mgr.testPeakUpload) mgr.testPeakUpload = spd;
                            if (spd * 1.15 > mgr.testMaxObservedSpeed) mgr.testMaxObservedSpeed = Math.ceil(spd * 1.15);
                        }

                        if (parsed.phase === "download_done") {
                            if (parsed.download_mbps !== undefined) mgr.testDownload = parsed.download_mbps;
                            if (parsed.download_str !== undefined) mgr.testDownloadStr = parsed.download_str;
                        }

                        if (parsed.phase === "upload_done") {
                            if (parsed.upload_mbps !== undefined) mgr.testUpload = parsed.upload_mbps;
                            if (parsed.upload_str !== undefined) mgr.testUploadStr = parsed.upload_str;
                        }

                        if (parsed.phase === "done") {
                            if (parsed.ping !== undefined) mgr.testPing = parsed.ping;
                            if (parsed.download_mbps !== undefined) mgr.testDownload = parsed.download_mbps;
                            if (parsed.upload_mbps !== undefined) mgr.testUpload = parsed.upload_mbps;
                            if (parsed.download_str !== undefined) mgr.testDownloadStr = parsed.download_str;
                            if (parsed.upload_str !== undefined) mgr.testUploadStr = parsed.upload_str;
                            mgr.speedTestRunning = false;
                        }
                    }
                } catch (e) {}
            }
        }
        onExited: function(code) {
            mgr.speedTestRunning = false;
        }
    }

    // IPC Toggle
    property var watchToggleProc: Process {
        command: ["sh", "-c", "STATE=\"${XDG_RUNTIME_DIR:-/tmp}/quickshell_network_speed.toggle\"; while true; do if [ -f \"$STATE\" ]; then rm -f \"$STATE\"; echo 'TOGGLE'; fi; sleep 0.15; done"]
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                if (String(data).indexOf("TOGGLE") !== -1) {
                    mgr.toggle();
                }
            }
        }
    }

    function open() {
        modalOpen = true;
    }

    function close() {
        modalOpen = false;
    }

    function toggle() {
        modalOpen = !modalOpen;
    }

    function startSpeedTest() {
        if (speedTestRunning) return;
        speedTestRunning = true;
        speedTestPhase = "ping";
        speedTestProgress = 0.05;
        speedTestMessage = "Midiendo latencia de red...";
        testPing = 0.0;
        testDownload = 0.0;
        testUpload = 0.0;
        testPeakDownload = 0.0;
        testPeakUpload = 0.0;
        testDownloadStr = "--";
        testUploadStr = "--";
        testDownloadHistory = [];
        testUploadHistory = [];
        testMaxObservedSpeed = 20.0;
        speedTestProc.running = false;
        speedTestProc.running = true;
    }
}
