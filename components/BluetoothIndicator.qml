import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root
    property string indicatorName: "bluetooth"
    implicitWidth: contentRow.implicitWidth + 14
    implicitHeight: 24

    property bool isPowered: false
    property bool isConnected: false
    property bool isScanning: false
    property string controllerName: ""
    property int connectedCount: 0
    property var devices: []
    property string rawBtOutput: ""

    property bool isHovered: false
    readonly property bool isPopoutActive: PopoutManager.activePopout === "bluetooth"

    Process {
        id: scanProc
        command: ["/home/demonc/Documents/Proyects/shell/scripts/get_bluetooth_info.py"]
        stdout: SplitParser {
            onRead: data => { root.rawBtOutput += data; }
        }
        onExited: {
            try {
                let info = JSON.parse(root.rawBtOutput.trim());
                root.isPowered = info.isPowered;
                root.isConnected = info.isConnected;
                root.controllerName = info.controllerName || "";
                root.connectedCount = info.connectedCount || 0;
                root.devices = info.devices || [];
            } catch (e) {}
            root.rawBtOutput = "";
            root.isScanning = false;
        }
    }

    Process {
        id: actionProc
        onExited: { root.rescan(); }
    }

    function togglePower() {
        actionProc.command = ["bluetoothctl", "power", root.isPowered ? "off" : "on"];
        actionProc.running = false;
        actionProc.running = true;
    }

    function connectDevice(mac) {
        actionProc.command = ["bluetoothctl", "connect", mac];
        actionProc.running = false;
        actionProc.running = true;
    }

    function disconnectDevice(mac) {
        actionProc.command = ["bluetoothctl", "disconnect", mac];
        actionProc.running = false;
        actionProc.running = true;
    }

    function removeDevice(mac) {
        actionProc.command = ["bluetoothctl", "remove", mac];
        actionProc.running = false;
        actionProc.running = true;
    }

    function rescan() {
        root.isScanning = true;
        root.rawBtOutput = "";
        scanProc.running = false;
        scanProc.running = true;
    }

    Timer {
        interval: 4000
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
                    if (root.isConnected) return "󰂱";
                    if (root.isPowered) return "󰂯";
                    return "󰂲";
                }
                color: root.isConnected ? Theme.primary : (root.isPowered ? Theme.text : Theme.overlay)
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }

            Text {
                visible: root.isConnected && root.connectedCount > 0
                text: root.connectedCount.toString()
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }
        }
    }
}
