pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: mgr

    property bool isOpen: false
    property string activeTab: "network" // "network", "bluetooth", "audio", "display", "power", "bar", "apps"

    // -------------------------------------------------------------------------
    // 1. MONITOREO DE ACTIVACIÓN (CLI & KEYBIND)
    // -------------------------------------------------------------------------
    property var watchToggleProc: Process {
        command: ["sh", "-c", "STATE=\"${XDG_RUNTIME_DIR:-/tmp}/quickshell_control_center.toggle\"; TMP_STATE=\"/tmp/quickshell_control_center.toggle\"; while kill -0 $PPID 2>/dev/null; do CMD=\"\"; if [ -f \"$STATE\" ]; then CMD=$(cat \"$STATE\"); elif [ -f \"$TMP_STATE\" ]; then CMD=$(cat \"$TMP_STATE\"); fi; if [ -n \"$CMD\" ]; then rm -f \"$STATE\" \"$TMP_STATE\" 2>/dev/null; echo \"CMD:$CMD\"; fi; sleep 0.04; done"]
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
        cancelSudoAuth();
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
        refreshAbout();
        if (activeTab === "apps") {
            refreshPackages(false);
        }
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
        val = Math.max(0, Math.min(100, Math.round(val)));
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
        val = Math.max(0, Math.min(100, Math.round(val)));
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
    // 7. INFORMACIÓN DEL SISTEMA Y ACERCA DE (ABOUT)
    // -------------------------------------------------------------------------
    property string sysUser: Quickshell.env("USER") || ""
    property string sysHost: ""
    property string sysKernel: ""
    property string sysUptime: ""

    property var aboutData: ({
        "os_name": "Arch Linux",
        "kernel": "",
        "user": Quickshell.env("USER") || "usuario",
        "host": "",
        "uptime": "--",
        "model": "Equipo PC",
        "cpu": "Cargando procesador...",
        "gpu": "Gráficos Integrados",
        "ram_total": "--",
        "ram_used": "--",
        "ram_percent": 0,
        "disk_total": "--",
        "disk_free": "--",
        "disk_percent": 0,
        "wm": "Hyprland",
        "framework": "Quickshell",
        "shell_name": "MrDemonc-SHELL",
        "github_user": "MrDemonc",
        "github_url": "https://github.com/MrDemonc",
        "repo_url": "https://github.com/MrDemonc/MrDemonc-SHELL",
        "packages": 0
    })

    property string rawAboutOutput: ""
    property var aboutInfoProc: Process {
        command: ["python3", Quickshell.shellDir + "/scripts/get_about_info.py"]
        stdout: SplitParser {
            onRead: data => { mgr.rawAboutOutput += data; }
        }
        onExited: {
            try {
                let parsed = JSON.parse(mgr.rawAboutOutput.trim());
                if (parsed && typeof parsed === "object") {
                    mgr.aboutData = parsed;
                    if (parsed.user) mgr.sysUser = parsed.user;
                    if (parsed.host) mgr.sysHost = parsed.host;
                    if (parsed.kernel) mgr.sysKernel = parsed.kernel;
                    if (parsed.uptime) mgr.sysUptime = parsed.uptime;
                }
            } catch (e) {}
            mgr.rawAboutOutput = "";
        }
    }

    function refreshAbout() {
        if (!aboutInfoProc.running) {
            mgr.rawAboutOutput = "";
            aboutInfoProc.running = true;
        }
    }

    property var openUrlProc: Process {}
    function openExternalUrl(targetUrl) {
        if (!targetUrl || targetUrl.length === 0) return;
        openUrlProc.command = ["xdg-open", targetUrl];
        openUrlProc.running = false;
        openUrlProc.running = true;
    }

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
        refreshAbout();
    }

    // -------------------------------------------------------------------------
    // 8. GESTIÓN DE APLICACIONES Y PAQUETES (PACMAN Y AUR)
    // -------------------------------------------------------------------------
    property var installedPackages: []
    property int totalPackagesCount: 0
    property int pacmanPackagesCount: 0
    property int aurPackagesCount: 0
    property int updatesPackagesCount: 0
    property bool isPackagesLoading: false
    property string packagesSearchQuery: ""
    property string packagesFilter: "all" // "all", "pacman", "aur", "updates"
    property var filteredPackages: []
    property string rawPackagesOutput: ""

    property string activeUpdatingPkg: ""
    property string activeCurrentPkg: ""
    property int activeUpdatingProgress: -1
    property string activeUpdatingStatus: ""

    onPackagesSearchQueryChanged: filterPackages()
    onPackagesFilterChanged: filterPackages()

    onActiveTabChanged: {
        if (activeTab === "about") {
            refreshAbout();
        } else if (activeTab === "apps" && (!installedPackages || installedPackages.length === 0)) {
            refreshPackages(false);
        }
    }

    onIsOpenChanged: {
        if (isOpen) {
            refreshAbout();
            if (activeTab === "apps" && (!installedPackages || installedPackages.length === 0)) {
                refreshPackages(false);
            }
        }
    }

    property var packagesProc: Process {
        stdout: SplitParser {
            onRead: data => { mgr.rawPackagesOutput += data; }
        }
        onExited: {
            try {
                let info = JSON.parse(mgr.rawPackagesOutput.trim());
                if (info && info.packages) {
                    mgr.totalPackagesCount = info.total || 0;
                    mgr.pacmanPackagesCount = info.pacmanCount || 0;
                    mgr.aurPackagesCount = info.aurCount || 0;
                    mgr.updatesPackagesCount = info.updatesCount || 0;
                    mgr.installedPackages = info.packages || [];
                    mgr.filterPackages();
                }
            } catch (e) {
                console.log("Error parsing packages JSON:", e);
            }
            mgr.rawPackagesOutput = "";
            mgr.isPackagesLoading = false;
        }
    }

    function refreshPackages(force) {
        if (!packagesProc.running) {
            mgr.isPackagesLoading = true;
            mgr.rawPackagesOutput = "";
            let args = ["python3", Quickshell.shellDir + "/scripts/package_manager.py", "list"];
            if (force) args.push("--force");
            packagesProc.command = args;
            packagesProc.running = false;
            packagesProc.running = true;
        }
    }

    function filterPackages() {
        let q = packagesSearchQuery.trim().toLowerCase();
        let f = packagesFilter;
        let list = installedPackages || [];
        
        mgr.filteredPackages = list.filter(function(p) {
            if (!p) return false;
            if (f === "pacman" && p.source !== "pacman") return false;
            if (f === "aur" && p.source !== "aur") return false;
            if (f === "updates" && !p.hasUpdate) return false;
            
            if (q.length > 0) {
                let dName = (p.displayName || "").toLowerCase();
                let name = (p.name || "").toLowerCase();
                let desc = (p.description || "").toLowerCase();
                return dName.indexOf(q) !== -1 || name.indexOf(q) !== -1 || desc.indexOf(q) !== -1;
            }
            return true;
        });
    }

    // -------------------------------------------------------------------------
    // 8.1 AUTENTICACIÓN SUDO NATIVA (QUICKSHELL)
    // -------------------------------------------------------------------------
    property bool isAuthModalOpen: false
    property bool isAuthChecking: false
    property string authErrorMessage: ""
    property string authActionDescription: ""
    property var pendingSudoAction: null

    property string lastVerifiedPassword: ""

    property var sudoCheckProc: Process {
        command: ["sudo", "-n", "true"]
        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0) {
                // Ya se tiene sesión sudo activa en el kernel, ejecutar directamente
                let act = mgr.pendingSudoAction;
                mgr.pendingSudoAction = null;
                mgr.executeSudoAction(act, "");
            } else {
                // Requiere contraseña: abrir modal nativo de Quickshell
                mgr.isAuthChecking = false;
                mgr.authErrorMessage = "";
                mgr.isAuthModalOpen = true;
            }
        }
    }

    property Process sudoAuthProc: Process {
        property string passwordToVerify: ""
        command: ["python3", Quickshell.shellDir + "/scripts/package_manager.py", "auth"]
        onStarted: {
            write(passwordToVerify + "\n");
            mgr.lastVerifiedPassword = passwordToVerify;
            passwordToVerify = "";
            stdinEnabled = false;
        }
        onExited: function(exitCode, exitStatus) {
            authTimeoutTimer.stop();
            mgr.isAuthChecking = false;
            if (exitCode === 0) {
                mgr.isAuthModalOpen = false;
                mgr.authErrorMessage = "";
                let act = mgr.pendingSudoAction;
                let pwd = mgr.lastVerifiedPassword;
                mgr.pendingSudoAction = null;
                mgr.lastVerifiedPassword = "";
                mgr.executeSudoAction(act, pwd);
            } else {
                mgr.lastVerifiedPassword = "";
                mgr.authErrorMessage = "Contraseña incorrecta. Inténtalo de nuevo.";
            }
        }
    }

    property var authTimeoutTimer: Timer {
        interval: 10000
        repeat: false
        onTriggered: {
            if (mgr.isAuthChecking) {
                mgr.isAuthChecking = false;
                mgr.authErrorMessage = "Tiempo de espera agotado. Inténtalo de nuevo.";
                if (sudoAuthProc.running) {
                    sudoAuthProc.running = false;
                }
            }
        }
    }

    property Process packageActionProc: Process {
        property string passwordToPass: ""
        onStarted: {
            if (passwordToPass.length > 0) {
                write(passwordToPass + "\n");
                passwordToPass = "";
                stdinEnabled = false;
            }
        }
        stdout: SplitParser {
            onRead: data => {
                let line = String(data).trim();
                if (!line) return;
                if (line.indexOf("STATUS:") === 0) {
                    mgr.activeUpdatingStatus = line.substring(7).trim();
                } else if (line.indexOf("PROGRESS:") === 0) {
                    let p = parseInt(line.substring(9).trim());
                    if (!isNaN(p)) {
                        mgr.activeUpdatingProgress = Math.max(0, Math.min(100, p));
                    }
                } else if (line.indexOf("CURRENT_PKG:") === 0) {
                    mgr.activeCurrentPkg = line.substring(12).trim();
                } else if (line.indexOf("PKG:") === 0) {
                    mgr.activeUpdatingPkg = line.substring(4).trim();
                }
            }
        }
        onExited: function(exitCode, exitStatus) {
            passwordToPass = "";
            finishUpdateTimer.restart();
        }
    }

    property var finishUpdateTimer: Timer {
        interval: 1200
        repeat: false
        onTriggered: {
            mgr.activeUpdatingPkg = "";
            mgr.activeCurrentPkg = "";
            mgr.activeUpdatingProgress = -1;
            mgr.activeUpdatingStatus = "";
            mgr.refreshPackages(true);
        }
    }

    function requestSudoAction(actionObj) {
        if (!actionObj) return;
        mgr.pendingSudoAction = actionObj;
        mgr.authActionDescription = actionObj.desc || "completar la operación";
        mgr.authErrorMessage = "";
        mgr.isAuthChecking = false;

        sudoCheckProc.running = false;
        sudoCheckProc.running = true;
    }

    function verifySudoPassword(password) {
        if (!password || password.length === 0) {
            authErrorMessage = "Por favor ingresa tu contraseña.";
            return;
        }
        if (isAuthChecking) return;

        isAuthChecking = true;
        authErrorMessage = "";
        authTimeoutTimer.restart();
        sudoAuthProc.passwordToVerify = password;
        sudoAuthProc.stdinEnabled = true;
        sudoAuthProc.running = true;
    }

    function cancelSudoAuth() {
        authTimeoutTimer.stop();
        isAuthModalOpen = false;
        isAuthChecking = false;
        authErrorMessage = "";
        pendingSudoAction = null;
        lastVerifiedPassword = "";
        sudoAuthProc.passwordToVerify = "";
        mgr.activeUpdatingPkg = "";
        mgr.activeCurrentPkg = "";
        mgr.activeUpdatingProgress = -1;
        mgr.activeUpdatingStatus = "";
        if (sudoAuthProc.running) {
            sudoAuthProc.running = false;
        }
    }

    function executeSudoAction(act, pwd) {
        if (!act) return;
        let args = ["python3", Quickshell.shellDir + "/scripts/package_manager.py"];
        if (act.type === "update") {
            args.push("update", act.target);
            mgr.activeUpdatingPkg = act.target;
            mgr.activeCurrentPkg = act.target;
            mgr.activeUpdatingProgress = 5;
            mgr.activeUpdatingStatus = "Iniciando descarga...";
        } else if (act.type === "update-all") {
            args.push("update-all");
            mgr.activeUpdatingPkg = "all";
            mgr.activeCurrentPkg = "";
            mgr.activeUpdatingProgress = 5;
            mgr.activeUpdatingStatus = "Iniciando actualización general...";
        } else if (act.type === "remove") {
            args.push("remove", act.target);
            mgr.activeUpdatingPkg = act.target;
            mgr.activeCurrentPkg = act.target;
            mgr.activeUpdatingProgress = 5;
            mgr.activeUpdatingStatus = "Desinstalando...";
        }
        packageActionProc.passwordToPass = pwd || "";
        packageActionProc.stdinEnabled = !!(pwd && pwd.length > 0);
        packageActionProc.command = args;
        packageActionProc.running = false;
        packageActionProc.running = true;
    }

    function updatePackage(pkgName) {
        if (!pkgName) return;
        requestSudoAction({
            type: "update",
            target: pkgName,
            desc: "actualizar \"" + pkgName + "\""
        });
    }

    function updateAllPackages() {
        requestSudoAction({
            type: "update-all",
            target: "",
            desc: "actualizar todas las aplicaciones del sistema"
        });
    }

    function removePackage(pkgName) {
        if (!pkgName) return;
        requestSudoAction({
            type: "remove",
            target: pkgName,
            desc: "desinstalar \"" + pkgName + "\""
        });
    }
}
