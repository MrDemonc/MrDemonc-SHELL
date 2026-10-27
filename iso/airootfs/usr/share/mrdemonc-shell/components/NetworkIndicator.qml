import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root
    property string indicatorName: "wifi"
    implicitWidth: contentRow.implicitWidth + 14
    implicitHeight: 24

    property bool isConnected: false
    property bool isEthernet: false
    property string ssid: ""
    property int signalStrength: 0
    property string ipAddress: ""
    property string gateway: ""
    property string securityType: ""
    property var networks: []
    property bool isScanning: false
    property bool isManualScanning: false
    property bool isConnecting: false
    property string connectingToSsid: ""

    property bool isHovered: false
    readonly property bool isPopoutActive: PopoutManager.activePopout === "wifi"

    property string rawWifiOutput: ""

    Process {
        id: scanProc
        command: [Quickshell.shellDir + "/scripts/get_network_info.py"]
        stdout: SplitParser {
            onRead: data => { root.rawWifiOutput += data; }
        }
        onExited: {
            try {
                let info = JSON.parse(root.rawWifiOutput.trim());
                root.isConnected = info.isConnected;
                root.isEthernet = !!info.isEthernet;
                root.ssid = info.ssid;
                root.signalStrength = info.signalStrength;
                root.ipAddress = info.ipAddress;
                root.gateway = info.gateway;
                root.securityType = info.security;
                root.networks = info.networks || [];
            } catch (e) {}
            root.rawWifiOutput = "";
            root.isScanning = false;
            root.isManualScanning = false;
        }
    }

    Process {
        id: connectProc
        onExited: {
            root.isConnecting = false;
            root.connectingToSsid = "";
            root.rescan();
        }
    }

    function connectToNetwork(ssidName, password, isHidden) {
        if (!ssidName) return;
        root.isScanning = true;
        root.isConnecting = true;
        root.connectingToSsid = ssidName;

        let cmd;
        if (password && password.length > 0) {
            cmd = ["sh", "-c", 'SSID="$1"; PW="$2"; HIDDEN="$3"; if [ "$HIDDEN" = "true" ]; then nmcli dev wifi connect "$SSID" password "$PW" hidden yes; else nmcli dev wifi connect "$SSID" password "$PW"; fi', "sh", ssidName, password, isHidden ? "true" : "false"];
        } else {
            cmd = ["sh", "-c", 'SSID="$1"; nmcli connection up id "$SSID" 2>/dev/null || nmcli dev wifi connect "$SSID"', "sh", ssidName];
        }

        if (connectProc.running) {
            connectProc.running = false;
            Qt.callLater(function() {
                connectProc.command = cmd;
                connectProc.running = true;
            });
        } else {
            connectProc.command = cmd;
            connectProc.running = true;
        }
    }

    function disconnectCurrent() {
        let cmd = ["sh", "-c", "nmcli dev disconnect $(nmcli -t -f DEVICE,TYPE dev | grep ':wifi$' | cut -d: -f1 | head -n1)"];
        if (connectProc.running) {
            connectProc.running = false;
            Qt.callLater(function() {
                connectProc.command = cmd;
                connectProc.running = true;
            });
        } else {
            connectProc.command = cmd;
            connectProc.running = true;
        }
    }

    function rescan() {
        root.isScanning = true;
        root.rawWifiOutput = "";
        scanProc.running = false;
        scanProc.running = true;
    }

    function manualRescan() {
        root.isManualScanning = true;
        rescan();
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { root.rescan(); }
    }

    Rectangle {
        id: capsule
        anchors.fill: parent
        radius: 6
        color: (root.isPopoutActive || root.isHovered) ? Theme.bgHover : "transparent"

        Behavior on color { ColorAnimation { duration: 150 } }

        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: 5

            Text {
                text: {
                    if (!root.isConnected) return "󰤭";
                    if (root.isEthernet) return "󰈀";
                    if (root.signalStrength >= 75) return "󰤨";
                    if (root.signalStrength >= 50) return "󰤥";
                    if (root.signalStrength >= 25) return "󰤢";
                    return "󰤟";
                }
                color: root.isConnected ? Theme.cyan : Theme.overlay
                font.family: Theme.fontFamily
                font.pixelSize: 13
            }

            Text {
                visible: root.isConnected && root.ssid.length > 0
                text: root.ssid
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 11
                elide: Text.ElideRight
                Layout.maximumWidth: 100
            }
        }
    }
}
