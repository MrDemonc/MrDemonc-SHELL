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
    property string ssid: ""
    property int signalStrength: 0
    property string ipAddress: ""
    property string gateway: ""
    property string securityType: ""
    property var networks: []
    property bool isScanning: false

    property bool isHovered: false
    readonly property bool isPopoutActive: PopoutManager.activePopout === "wifi"

    property string rawWifiOutput: ""

    Process {
        id: scanProc
        command: ["/home/demonc/Documents/Proyects/shell/scripts/get_network_info.py"]
        stdout: SplitParser {
            onRead: data => { root.rawWifiOutput += data; }
        }
        onExited: {
            try {
                let info = JSON.parse(root.rawWifiOutput.trim());
                root.isConnected = info.isConnected;
                root.ssid = info.ssid;
                root.signalStrength = info.signalStrength;
                root.ipAddress = info.ipAddress;
                root.gateway = info.gateway;
                root.securityType = info.security;
                root.networks = info.networks || [];
            } catch (e) {}
            root.rawWifiOutput = "";
            root.isScanning = false;
        }
    }

    Process {
        id: connectProc
        onExited: { root.rescan(); }
    }

    function connectToNetwork(ssidName, password, isHidden) {
        root.isScanning = true;
        if (isHidden) {
            if (password && password.length > 0) {
                connectProc.command = ["nmcli", "dev", "wifi", "connect", ssidName, "password", password, "hidden", "yes"];
            } else {
                connectProc.command = ["nmcli", "dev", "wifi", "connect", ssidName, "hidden", "yes"];
            }
        } else {
            if (password && password.length > 0) {
                connectProc.command = ["nmcli", "dev", "wifi", "connect", ssidName, "password", password];
            } else {
                connectProc.command = ["nmcli", "dev", "wifi", "connect", ssidName];
            }
        }
        connectProc.running = false;
        connectProc.running = true;
    }

    function disconnectCurrent() {
        connectProc.command = ["sh", "-c", "nmcli dev disconnect $(nmcli -t -f DEVICE,TYPE dev | grep ':wifi$' | cut -d: -f1 | head -n1)"];
        connectProc.running = false;
        connectProc.running = true;
    }

    function rescan() {
        root.isScanning = true;
        root.rawWifiOutput = "";
        scanProc.running = false;
        scanProc.running = true;
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
                    if (root.signalStrength >= 75) return "󰤨";
                    if (root.signalStrength >= 50) return "󰤥";
                    if (root.signalStrength >= 25) return "󰤢";
                    return "󰤟";
                }
                color: root.isConnected ? Theme.cyan : Theme.overlay
                font.family: Theme.fontFamily
                font.pixelSize: 12
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
