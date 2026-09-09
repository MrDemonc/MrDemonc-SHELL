import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root
    property string indicatorName: "battery"
    implicitWidth: contentRow.implicitWidth + 14
    implicitHeight: 24

    property int percentage: 0
    property string status: "Discharging"
    property int cycleCount: 0
    property string health: "100%"
    property string currentProfile: "balanced"
    property string powerRate: "0.0 W"
    property string voltage: "0.0 V"
    property bool showPercentage: true

    property bool isHovered: false
    readonly property bool isPopoutActive: PopoutManager.activePopout === "battery"

    property bool hasBattery: false

    Process {
        id: batProc
        command: [Quickshell.shellDir + "/scripts/get_battery_info.py"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                try {
                    let info = JSON.parse(String(data).trim());
                    root.hasBattery = !!info.hasBattery;
                    root.percentage = (info.percentage !== undefined && info.percentage !== null) ? info.percentage : 100;
                    root.status = info.status || "AC";
                    root.cycleCount = info.cycleCount || 0;
                    root.health = info.health || "100%";
                    root.powerRate = info.powerRate || "0.0 W";
                    root.voltage = info.voltage || "0.0 V";
                    root.currentProfile = info.profile || "balanced";
                } catch (e) {}
            }
        }
    }

    property real _full: 0
    property real _design: 0

    Process {
        id: setProfileProc
    }

    function togglePercentage() {
        root.showPercentage = !root.showPercentage;
    }

    function setProfile(profile) {
        root.currentProfile = profile;
        setProfileProc.command = ["powerprofilesctl", "set", profile];
        setProfileProc.running = false;
        setProfileProc.running = true;
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            batProc.running = false;
            batProc.running = true;
        }
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
                    if (!root.hasBattery) return "󰚥";
                    if (root.status === "Charging") return "󰂄";
                    if (root.percentage >= 90) return "󰁹";
                    if (root.percentage >= 70) return "󰂀";
                    if (root.percentage >= 50) return "󰁾";
                    if (root.percentage >= 30) return "󰁼";
                    if (root.percentage >= 10) return "󰁺";
                    return "󰂎";
                }
                color: {
                    if (!root.hasBattery) return Theme.primary;
                    return root.percentage <= 20 && root.status !== "Charging" ? Theme.danger : (root.status === "Charging" ? Theme.success : Theme.primary);
                }
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }

            Text {
                visible: root.showPercentage
                text: root.hasBattery ? (root.percentage + "%") : "AC"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }
        }
    }
}
