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

    Process {
        id: batProc
        command: ["sh", "-c", "printf 'CAP:%s\nSTAT:%s\nCYC:%s\nFULL:%s\nDES:%s\nPROF:%s\nPOW:%s\nVOLT:%s\n' \"$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null)\" \"$(cat /sys/class/power_supply/BAT0/status 2>/dev/null)\" \"$(cat /sys/class/power_supply/BAT0/cycle_count 2>/dev/null)\" \"$(cat /sys/class/power_supply/BAT0/energy_full 2>/dev/null || cat /sys/class/power_supply/BAT0/charge_full 2>/dev/null)\" \"$(cat /sys/class/power_supply/BAT0/energy_full_design 2>/dev/null || cat /sys/class/power_supply/BAT0/charge_full_design 2>/dev/null)\" \"$(powerprofilesctl get 2>/dev/null || echo balanced)\" \"$(cat /sys/class/power_supply/BAT0/power_now 2>/dev/null || cat /sys/class/power_supply/BAT0/current_now 2>/dev/null)\" \"$(cat /sys/class/power_supply/BAT0/voltage_now 2>/dev/null)\""]
        running: true
        stdout: SplitParser {
            onRead: data => {
                let lines = data.split("\n");
                for (let i = 0; i < lines.length; i++) {
                    let line = lines[i].trim();
                    if (line.startsWith("CAP:")) {
                        let cap = parseInt(line.substring(4).trim());
                        if (!isNaN(cap)) root.percentage = cap;
                    } else if (line.startsWith("STAT:")) {
                        root.status = line.substring(5).trim() || "Discharging";
                    } else if (line.startsWith("CYC:")) {
                        let c = parseInt(line.substring(4).trim());
                        if (!isNaN(c)) root.cycleCount = c;
                    } else if (line.startsWith("FULL:")) {
                        let f = parseFloat(line.substring(5).trim());
                        if (!isNaN(f) && f > 0) root._full = f;
                    } else if (line.startsWith("DES:")) {
                        let d = parseFloat(line.substring(4).trim());
                        if (!isNaN(d) && d > 0) root._design = d;
                    } else if (line.startsWith("PROF:")) {
                        root.currentProfile = line.substring(5).trim() || "balanced";
                    } else if (line.startsWith("POW:")) {
                        let p = parseFloat(line.substring(4).trim());
                        if (!isNaN(p) && p > 0) {
                            root.powerRate = (p / 1000000.0).toFixed(1) + " W";
                        }
                    } else if (line.startsWith("VOLT:")) {
                        let v = parseFloat(line.substring(5).trim());
                        if (!isNaN(v) && v > 0) {
                            root.voltage = (v / 1000000.0).toFixed(1) + " V";
                        }
                    }
                }
                if (root._full > 0 && root._design > 0) {
                    let h = Math.min(100, Math.round((root._full / root._design) * 100));
                    root.health = h + "%";
                }
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
                    if (root.status === "Charging") return "󰂄";
                    if (root.percentage >= 90) return "󰁹";
                    if (root.percentage >= 70) return "󰂀";
                    if (root.percentage >= 50) return "󰁾";
                    if (root.percentage >= 30) return "󰁼";
                    if (root.percentage >= 10) return "󰁺";
                    return "󰂎";
                }
                color: root.percentage <= 20 && root.status !== "Charging" ? Theme.danger : (root.status === "Charging" ? Theme.success : Theme.primary)
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }

            Text {
                visible: root.showPercentage
                text: root.percentage + "%"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }
        }
    }
}
