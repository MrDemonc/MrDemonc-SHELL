pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: mgr

    property bool isOpen: false
    property string activeTab: "network" // "network", "bluetooth", "audio", "display", "power", "bar", "system"

    // -------------------------------------------------------------------------
    // 1. MONITOREO DE ACTIVACIÓN (CLI & KEYBIND)
    // -------------------------------------------------------------------------
    property var watchToggleProc: Process {
        command: ["sh", "-c", "STATE=\"${XDG_RUNTIME_DIR:-/tmp}/quickshell_control_center.toggle\"; TMP_STATE=\"/tmp/quickshell_control_center.toggle\"; while true; do CMD=\"\"; if [ -f \"$STATE\" ]; then CMD=$(cat \"$STATE\"); elif [ -f \"$TMP_STATE\" ]; then CMD=$(cat \"$TMP_STATE\"); fi; if [ -n \"$CMD\" ]; then rm -f \"$STATE\" \"$TMP_STATE\" 2>/dev/null; echo \"CMD:$CMD\"; fi; sleep 0.15; done"]
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                let s = String(data).trim();
                console.log("CONTROL CENTER TOGGLE RECEIVED:", s);
                if (s.indexOf("CMD:") === 0) {
                    let cmd = s.substring(4).trim();
                    if (cmd.indexOf("TAB:") === 0) {
                        let targetTab = cmd.substring(4).trim();
                        mgr.open(targetTab);
                    } else if (cmd === "OPEN") {
                        mgr.open();
                    } else if (cmd === "CLOSE") {
                        mgr.close();
                    } else {
                        mgr.toggle();
                    }
                }
            }
        }
    }

    function toggle(tab) {
        console.log("CONTROL CENTER toggle() called, currently isOpen=", isOpen);
        if (isOpen) {
            if (tab && tab !== activeTab) {
                activeTab = tab;
            } else {
                close();
            }
        } else {
            open(tab);
        }
    }

    function open(tab) {
        console.log("CONTROL CENTER open() called, tab=", tab);
        if (tab && tab.length > 0) {
            activeTab = tab;
        } else {
            activeTab = "network";
        }
        isOpen = true;
        refreshAll();
    }

    function close() {
        console.log("CONTROL CENTER close() called");
        isOpen = false;
    }

    // Auto-refresco mientras el centro de control está abierto
    property var pollTimer: Timer {
        interval: 2500
        repeat: true
        running: mgr.isOpen
        onTriggered: mgr.refreshAll()
    }

    function refreshAll() {
        refreshNetwork();
        refreshBluetooth();
        refreshAudio();
        refreshDisplay();
        refreshBattery();
        refreshSystem();
    }

    // -------------------------------------------------------------------------
    // 2. RED Y WI-FI
    // -------------------------------------------------------------------------
    property bool wifiEnabled: true
    property bool isNetworkConnected: false
    property bool isEthernet: false
    property string currentSsid: ""
    property int signalStrength: 0
    property string ipAddress: ""
    property string gateway: ""
    property string securityType: ""
    property var networksList: []
    property bool isNetworkScanning: false

    property string rawNetworkOutput: ""
    property var netScanProc: Process {
        command: [Quickshell.shellDir + "/scripts/get_network_info.py"]
        stdout: SplitParser {
            onRead: data => { mgr.rawNetworkOutput += data; }
        }
        onExited: {
            try {
                let info = JSON.parse(mgr.rawNetworkOutput.trim());
                mgr.isNetworkConnected = !!info.isConnected;
                mgr.isEthernet = !!info.isEthernet;
                mgr.currentSsid = info.ssid || "";
                mgr.signalStrength = info.signalStrength || 0;
                mgr.ipAddress = info.ipAddress || "";
                mgr.gateway = info.gateway || "";
                mgr.securityType = info.security || "";
                mgr.networksList = info.networks || [];
            } catch (e) {}
            mgr.rawNetworkOutput = "";
            mgr.isNetworkScanning = false;
        }
    }

    property var netWifiStatusProc: Process {
        command: ["nmcli", "-t", "-f", "WIFI", "g"]
        stdout: SplitParser {
            onRead: data => {
                let s = String(data).trim().toLowerCase();
                mgr.wifiEnabled = (s === "enabled" || s === "habilitado");
            }
        }
    }

    property var netActionProc: Process {
        onExited: {
            mgr.refreshNetwork();
        }
    }

    function refreshNetwork() {
        if (!netScanProc.running) {
            mgr.rawNetworkOutput = "";
            netScanProc.running = true;
        }
        if (!netWifiStatusProc.running) {
            netWifiStatusProc.running = true;
        }
    }

    function toggleWifi() {
        let nextState = !wifiEnabled ? "on" : "off";
        wifiEnabled = !wifiEnabled;
        netActionProc.command = ["nmcli", "radio", "wifi", nextState];
        netActionProc.running = false;
        netActionProc.running = true;
    }

    function rescanWifi() {
        isNetworkScanning = true;
        netActionProc.command = ["nmcli", "dev", "wifi", "rescan"];
        netActionProc.running = false;
        netActionProc.running = true;
    }

    function connectWifi(ssidName, password, isHidden) {
        isNetworkScanning = true;
        let args = ["nmcli", "dev", "wifi", "connect", ssidName];
        if (password && password.length > 0) {
            args.push("password", password);
        }
        if (isHidden) {
            args.push("hidden", "yes");
        }
        netActionProc.command = args;
        netActionProc.running = false;
        netActionProc.running = true;
    }

    function disconnectWifi() {
        netActionProc.command = ["sh", "-c", "nmcli dev disconnect $(nmcli -t -f DEVICE,TYPE dev | grep ':wifi$' | cut -d: -f1 | head -n1)"];
        netActionProc.running = false;
        netActionProc.running = true;
    }

    // -------------------------------------------------------------------------
    // 3. BLUETOOTH
    // -------------------------------------------------------------------------
    property bool btPowered: false
    property bool btConnected: false
    property bool btScanning: false
    property bool btHasAdapter: false
    property string btController: ""
    property int btConnectedCount: 0
    property var btDevices: []

    property string rawBtOutput: ""
    property var btScanProc: Process {
        command: [Quickshell.shellDir + "/scripts/get_bluetooth_info.py"]
        stdout: SplitParser {
            onRead: data => { mgr.rawBtOutput += data; }
        }
        onExited: {
            try {
                let info = JSON.parse(mgr.rawBtOutput.trim());
                mgr.btPowered = !!info.isPowered;
                mgr.btConnected = (info.connectedCount > 0) || !!info.isConnected;
                mgr.btHasAdapter = !!info.hasAdapter;
                mgr.btController = info.controllerName || "";
                mgr.btConnectedCount = info.connectedCount || 0;
                mgr.btDevices = info.devices || [];
            } catch (e) {}
            mgr.rawBtOutput = "";
            mgr.btScanning = false;
        }
    }

    property var btActionProc: Process {
        onExited: {
            mgr.refreshBluetooth();
        }
    }

    function refreshBluetooth() {
        if (!btScanProc.running) {
            mgr.rawBtOutput = "";
            btScanProc.running = true;
        }
    }

    function toggleBtPower() {
        mgr.btPowered = !mgr.btPowered;
        let cmd = mgr.btPowered ? "rfkill unblock bluetooth 2>/dev/null; bluetoothctl power on" : "bluetoothctl power off";
        btActionProc.command = ["sh", "-c", cmd];
        btActionProc.running = false;
        btActionProc.running = true;
    }

    function connectBt(mac) {
        btActionProc.command = ["bluetoothctl", "connect", mac];
        btActionProc.running = false;
        btActionProc.running = true;
    }

    function disconnectBt(mac) {
        btActionProc.command = ["bluetoothctl", "disconnect", mac];
        btActionProc.running = false;
        btActionProc.running = true;
    }

    function removeBt(mac) {
        btActionProc.command = ["bluetoothctl", "remove", mac];
        btActionProc.running = false;
        btActionProc.running = true;
    }

    // -------------------------------------------------------------------------
    // 4. AUDIO & SONIDO
    // -------------------------------------------------------------------------
    property int masterVolume: 50
    property bool masterMuted: false
    property int micVolume: 100
    property bool micMuted: false
    property var audioSinks: []
    property var audioApps: []

    property string rawAudioOutput: ""
    property var audioScanProc: Process {
        command: [Quickshell.shellDir + "/scripts/get_audio_info.py"]
        stdout: SplitParser {
            onRead: data => { mgr.rawAudioOutput += data; }
        }
        onExited: {
            try {
                let info = JSON.parse(mgr.rawAudioOutput.trim());
                mgr.masterVolume = info.masterVolume !== undefined ? info.masterVolume : 50;
                mgr.masterMuted = !!info.masterMuted;
                mgr.micVolume = info.micVolume !== undefined ? info.micVolume : 100;
                mgr.micMuted = !!info.micMuted;
                mgr.audioSinks = info.sinks || [];
                mgr.audioApps = info.apps || [];
            } catch (e) {}
            mgr.rawAudioOutput = "";
        }
    }

    property var audioActionProc: Process {
        onExited: {
            mgr.refreshAudio();
        }
    }

    function refreshAudio() {
        if (!audioScanProc.running) {
            mgr.rawAudioOutput = "";
            audioScanProc.running = true;
        }
    }

    function setMasterVolume(val) {
        val = Math.max(0, Math.min(150, Math.round(val)));
        mgr.masterVolume = val;
        audioActionProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (val / 100.0).toFixed(2)];
        audioActionProc.running = false;
        audioActionProc.running = true;
    }

    function toggleMasterMute() {
        mgr.masterMuted = !mgr.masterMuted;
        audioActionProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"];
        audioActionProc.running = false;
        audioActionProc.running = true;
    }

    function setMicVolume(val) {
        val = Math.max(0, Math.min(100, Math.round(val)));
        mgr.micVolume = val;
        audioActionProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", (val / 100.0).toFixed(2)];
        audioActionProc.running = false;
        audioActionProc.running = true;
    }

    function toggleMicMute() {
        mgr.micMuted = !mgr.micMuted;
        audioActionProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"];
        audioActionProc.running = false;
        audioActionProc.running = true;
    }

    function setDefaultSink(sinkName) {
        audioActionProc.command = ["pactl", "set-default-sink", sinkName];
        audioActionProc.running = false;
        audioActionProc.running = true;
    }

    function setAppVolume(index, val) {
        val = Math.max(0, Math.min(150, Math.round(val)));
        audioActionProc.command = ["pactl", "set-sink-input-volume", index.toString(), val.toString() + "%"];
        audioActionProc.running = false;
        audioActionProc.running = true;
    }

    function toggleAppMute(index) {
        audioActionProc.command = ["pactl", "set-sink-input-mute", index.toString(), "toggle"];
        audioActionProc.running = false;
        audioActionProc.running = true;
    }

    // -------------------------------------------------------------------------
    // 5. PANTALLA & LUZ NOCTURNA
    // -------------------------------------------------------------------------
    property int brightness: 100
    property bool nightLightEnabled: false
    property int nightLightTemp: 4000

    property var brightnessProc: Process {
        command: ["brightnessctl", "-m"]
        stdout: SplitParser {
            onRead: data => {
                let line = String(data).trim();
                let parts = line.split(",");
                if (parts.length >= 4) {
                    let pctStr = parts[3].replace("%", "").trim();
                    let val = parseInt(pctStr);
                    if (!isNaN(val)) {
                        mgr.brightness = val;
                    }
                }
            }
        }
    }

    property var setBrightnessProc: Process {}

    function setBrightness(val) {
        val = Math.max(5, Math.min(100, Math.round(val)));
        mgr.brightness = val;
        setBrightnessProc.command = ["brightnessctl", "s", val.toString() + "%"];
        setBrightnessProc.running = false;
        setBrightnessProc.running = true;
    }

    property var nightLightProc: Process {
        command: [Quickshell.shellDir + "/scripts/nightlight.py", "get"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    let s = String(data).trim();
                    if (!s) return;
                    let info = JSON.parse(s);
                    if (info && typeof info.enabled === "boolean") {
                        mgr.nightLightEnabled = info.enabled;
                    }
                    if (info && info.temperature) {
                        mgr.nightLightTemp = info.temperature;
                    }
                } catch (e) {}
            }
        }
    }

    property var setNightLightProc: Process {
        onExited: {
            mgr.refreshNightLight();
        }
    }

    property int _pendingNightLightTemp: 4000
    property var nightLightDebounceTimer: Timer {
        interval: 90
        repeat: false
        onTriggered: {
            setNightLightProc.command = [Quickshell.shellDir + "/scripts/nightlight.py", "set", mgr._pendingNightLightTemp.toString()];
            setNightLightProc.running = false;
            setNightLightProc.running = true;
        }
    }

    function refreshDisplay() {
        if (!brightnessProc.running) brightnessProc.running = true;
        refreshNightLight();
    }

    function refreshNightLight() {
        if (!nightLightProc.running) nightLightProc.running = true;
    }

    function toggleNightLight() {
        mgr.nightLightEnabled = !mgr.nightLightEnabled;
        setNightLightProc.command = [Quickshell.shellDir + "/scripts/nightlight.py", "toggle"];
        setNightLightProc.running = false;
        setNightLightProc.running = true;
    }

    function setNightLightTemp(val) {
        val = Math.max(2500, Math.min(6500, Math.round(val)));
        mgr.nightLightTemp = val;
        mgr._pendingNightLightTemp = val;
        nightLightDebounceTimer.restart();
    }

    // -------------------------------------------------------------------------
    // 6. BATERÍA & ENERGÍA
    // -------------------------------------------------------------------------
    property bool hasBattery: false
    property int batteryPercentage: 100
    property string batteryStatus: "AC"
    property int batteryCycleCount: 0
    property string batteryHealth: "100%"
    property string batteryPowerRate: "0.0 W"
    property string currentPowerProfile: "balanced"

    property string rawBatOutput: ""
    property var batScanProc: Process {
        command: [Quickshell.shellDir + "/scripts/get_battery_info.py"]
        stdout: SplitParser {
            onRead: data => { mgr.rawBatOutput += data; }
        }
        onExited: {
            try {
                let info = JSON.parse(mgr.rawBatOutput.trim());
                mgr.hasBattery = !!info.hasBattery;
                mgr.batteryPercentage = info.percentage !== undefined ? info.percentage : 100;
                mgr.batteryStatus = info.status || "AC";
                mgr.batteryCycleCount = info.cycleCount || 0;
                mgr.batteryHealth = info.health || "100%";
                mgr.batteryPowerRate = info.powerRate || "0.0 W";
                mgr.currentPowerProfile = info.profile || "balanced";
            } catch (e) {}
            mgr.rawBatOutput = "";
        }
    }

    property var setProfileProc: Process {
        onExited: {
            mgr.refreshBattery();
        }
    }

    function refreshBattery() {
        if (!batScanProc.running) {
            mgr.rawBatOutput = "";
            batScanProc.running = true;
        }
    }

    function setPowerProfile(profile) {
        mgr.currentPowerProfile = profile;
        setProfileProc.command = [Quickshell.shellDir + "/scripts/power_profile.py", "set", profile];
        setProfileProc.running = false;
        setProfileProc.running = true;
    }

    // -------------------------------------------------------------------------
    // 7. INFORMACIÓN DEL SISTEMA
    // -------------------------------------------------------------------------
    property string sysUser: ""
    property string sysHost: ""
    property string sysKernel: ""
    property string sysUptime: ""

    property var sysInfoProc: Process {
        command: ["sh", "-c", "echo \"USER:$(whoami)\"; echo \"HOST:$(uname -n)\"; echo \"KERNEL:$(uname -r)\"; echo \"UPTIME:$(uptime -p 2>/dev/null || uptime | sed 's/.*up \\([^,]*\\), .*/\\1/')\""]
        stdout: SplitParser {
            onRead: data => {
                let lines = String(data).trim().split("\n");
                for (let i = 0; i < lines.length; i++) {
                    let l = lines[i];
                    if (l.indexOf("USER:") === 0) mgr.sysUser = l.substring(5).trim();
                    else if (l.indexOf("HOST:") === 0) mgr.sysHost = l.substring(5).trim();
                    else if (l.indexOf("KERNEL:") === 0) mgr.sysKernel = l.substring(7).trim();
                    else if (l.indexOf("UPTIME:") === 0) mgr.sysUptime = l.substring(7).trim();
                }
            }
        }
    }

    function refreshSystem() {
        if (!sysInfoProc.running) sysInfoProc.running = true;
    }
}
