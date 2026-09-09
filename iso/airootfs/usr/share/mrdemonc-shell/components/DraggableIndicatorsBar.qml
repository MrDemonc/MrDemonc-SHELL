import QtQuick
import QtQuick.Layouts
import "./"

Item {
    id: root

    property var audioRef: null
    property var btRef: null
    property var netRef: null
    property var batRef: null

    property var barWindowRef: null
    property var dragTargetProxy: null
    property var barContentRef: null

    readonly property int spacing: 6

    property var currentOrder: PopoutManager.indicatorOrder
    property var displayOrder: [...currentOrder]

    property string draggingItemName: ""

    onCurrentOrderChanged: {
        if (!dragArea.drag.active && draggingItemName === "") {
            displayOrder = [...currentOrder];
        }
    }

    implicitHeight: 24
    height: 24
    Layout.preferredHeight: 24
    implicitWidth: getItemWidth("battery") + getItemWidth("wifi") + getItemWidth("bluetooth") + getItemWidth("audio") + 3 * spacing
    width: implicitWidth
    Layout.preferredWidth: implicitWidth

    function getItem(name) {
        if (name === "audio") return itemAudio;
        if (name === "bluetooth") return itemBt;
        if (name === "wifi") return itemWifi;
        if (name === "battery") return itemBat;
        return null;
    }

    function getItemWidth(name) {
        let it = getItem(name);
        return it ? Math.max(22, it.implicitWidth) : 26;
    }

    function getSlotX(name) {
        let idx = displayOrder.indexOf(name);
        if (idx <= 0) return 0;
        let x = 0;
        for (let i = 0; i < idx; i++) {
            x += getItemWidth(displayOrder[i]) + spacing;
        }
        return x;
    }

    function findItemAt(posX) {
        if (displayOrder.length === 0) return "";
        let curX = 0;
        for (let i = 0; i < displayOrder.length; i++) {
            let name = displayOrder[i];
            let w = getItemWidth(name);
            let nextBoundary = curX + w + (i < displayOrder.length - 1 ? spacing : 0);
            if (posX < nextBoundary || i === displayOrder.length - 1) {
                return name;
            }
            curX = nextBoundary;
        }
        return displayOrder[0];
    }

    // Proxy de arrastre para el motor C++ nativo de Qt Quick
    Item {
        id: dragProxy
        height: 24
        width: root.draggingItemName !== "" ? root.getItemWidth(root.draggingItemName) : 24
        y: 0

        onXChanged: {
            if (dragArea.drag.active && root.draggingItemName !== "") {
                let itemW = width;
                let dragCenter = x + itemW / 2;

                let otherItems = PopoutManager.indicatorOrder.filter(n => n !== root.draggingItemName);
                let bestSlot = 0;
                let minDistance = 999999;

                for (let k = 0; k <= otherItems.length; k++) {
                    let candX = 0;
                    for (let j = 0; j < k; j++) {
                        candX += root.getItemWidth(otherItems[j]) + root.spacing;
                    }
                    let candCenter = candX + itemW / 2;
                    let dist = Math.abs(dragCenter - candCenter);
                    if (dist < minDistance) {
                        minDistance = dist;
                        bestSlot = k;
                    }
                }

                let newDisplay = [...otherItems];
                newDisplay.splice(bestSlot, 0, root.draggingItemName);

                if (newDisplay.join(",") !== root.displayOrder.join(",")) {
                    root.displayOrder = newDisplay;
                }
            }
        }
    }

    // --- INDICADORES FIJOS (Se deslizan fluidamente mediante su propiedad 'x') ---

    // 1. Batería
    Item {
        id: itemBat
        property string itemName: "battery"
        readonly property bool isBeingDragged: root.draggingItemName === itemName && dragArea.drag.active
        readonly property bool isHovered: dragArea.hoveredName === itemName && !PopoutManager.isDraggingAny && !dragArea.pressed
        readonly property bool isActive: (root.batRef && root.batRef.isPopoutActive) || isHovered || isBeingDragged

        implicitWidth: batRow.implicitWidth + 12
        implicitHeight: 24
        height: 24
        y: 0
        z: isBeingDragged ? 999 : 1
        scale: isBeingDragged ? 1.15 : 1.0
        opacity: isBeingDragged ? 0.92 : 1.0

        Behavior on scale {
            NumberAnimation {
                duration: Theme.anim.fastSpatial
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.anim.expressiveFastSpatial
            }
        }

        x: isBeingDragged ? dragProxy.x : root.getSlotX(itemName)
        Behavior on x {
            enabled: !itemBat.isBeingDragged
            NumberAnimation {
                duration: Theme.anim.fastSpatial
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.anim.expressiveDefaultSpatial
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 6
            color: itemBat.isActive ? Theme.bgHover : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        RowLayout {
            id: batRow
            anchors.centerIn: parent
            spacing: 5

            Text {
                text: {
                    if (!root.batRef) return "󰁹";
                    if (root.batRef.status === "Charging") return "󰂄";
                    if (root.batRef.percentage >= 90) return "󰁹";
                    if (root.batRef.percentage >= 70) return "󰂀";
                    if (root.batRef.percentage >= 50) return "󰁾";
                    if (root.batRef.percentage >= 30) return "󰁼";
                    if (root.batRef.percentage >= 10) return "󰁺";
                    return "󰂎";
                }
                color: {
                    if (!root.batRef) return Theme.primary;
                    return root.batRef.percentage <= 20 && root.batRef.status !== "Charging" ? Theme.danger : (root.batRef.status === "Charging" ? Theme.success : Theme.primary);
                }
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }
            Text {
                visible: root.batRef && root.batRef.showPercentage
                text: root.batRef ? (root.batRef.percentage + "%") : "0%"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }
        }
    }

    // 2. Wi-Fi
    Item {
        id: itemWifi
        property string itemName: "wifi"
        readonly property bool isBeingDragged: root.draggingItemName === itemName && dragArea.drag.active
        readonly property bool isHovered: dragArea.hoveredName === itemName && !PopoutManager.isDraggingAny && !dragArea.pressed
        readonly property bool isActive: (root.netRef && root.netRef.isPopoutActive) || isHovered || isBeingDragged

        implicitWidth: wifiRow.implicitWidth + 12
        implicitHeight: 24
        height: 24
        y: 0
        z: isBeingDragged ? 999 : 1
        scale: isBeingDragged ? 1.15 : 1.0
        opacity: isBeingDragged ? 0.92 : 1.0

        Behavior on scale {
            NumberAnimation {
                duration: Theme.anim.fastSpatial
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.anim.expressiveFastSpatial
            }
        }

        x: isBeingDragged ? dragProxy.x : root.getSlotX(itemName)
        Behavior on x {
            enabled: !itemWifi.isBeingDragged
            NumberAnimation {
                duration: Theme.anim.fastSpatial
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.anim.expressiveDefaultSpatial
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 6
            color: itemWifi.isActive ? Theme.bgHover : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        RowLayout {
            id: wifiRow
            anchors.centerIn: parent
            spacing: 5

            Text {
                text: {
                    if (!root.netRef || !root.netRef.isConnected) return "󰤭";
                    if (root.netRef.signalStrength >= 75) return "󰤨";
                    if (root.netRef.signalStrength >= 50) return "󰤥";
                    if (root.netRef.signalStrength >= 25) return "󰤢";
                    return "󰤟";
                }
                color: (root.netRef && root.netRef.isConnected) ? Theme.cyan : Theme.overlay
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }
            Text {
                visible: root.netRef && root.netRef.isConnected && root.netRef.ssid.length > 0
                text: root.netRef ? root.netRef.ssid : ""
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 11
                elide: Text.ElideRight
                Layout.maximumWidth: 100
            }
        }
    }

    // 3. Bluetooth
    Item {
        id: itemBt
        property string itemName: "bluetooth"
        readonly property bool isBeingDragged: root.draggingItemName === itemName && dragArea.drag.active
        readonly property bool isHovered: dragArea.hoveredName === itemName && !PopoutManager.isDraggingAny && !dragArea.pressed
        readonly property bool isActive: (root.btRef && root.btRef.isPopoutActive) || isHovered || isBeingDragged

        implicitWidth: btRow.implicitWidth + 12
        implicitHeight: 24
        height: 24
        y: 0
        z: isBeingDragged ? 999 : 1
        scale: isBeingDragged ? 1.15 : 1.0
        opacity: isBeingDragged ? 0.92 : 1.0

        Behavior on scale {
            NumberAnimation {
                duration: Theme.anim.fastSpatial
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.anim.expressiveFastSpatial
            }
        }

        x: isBeingDragged ? dragProxy.x : root.getSlotX(itemName)
        Behavior on x {
            enabled: !itemBt.isBeingDragged
            NumberAnimation {
                duration: Theme.anim.fastSpatial
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.anim.expressiveDefaultSpatial
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 6
            color: itemBt.isActive ? Theme.bgHover : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        RowLayout {
            id: btRow
            anchors.centerIn: parent
            spacing: 5

            Text {
                text: {
                    if (!root.btRef) return "󰂲";
                    if (root.btRef.isConnected) return "󰂱";
                    if (root.btRef.isPowered) return "󰂯";
                    return "󰂲";
                }
                color: (root.btRef && root.btRef.isConnected) ? Theme.primary : ((root.btRef && root.btRef.isPowered) ? Theme.text : Theme.overlay)
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }
            Text {
                visible: root.btRef && root.btRef.isConnected && root.btRef.connectedCount > 0
                text: root.btRef ? root.btRef.connectedCount.toString() : ""
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }
        }
    }

    // 4. Audio
    Item {
        id: itemAudio
        property string itemName: "audio"
        readonly property bool isBeingDragged: root.draggingItemName === itemName && dragArea.drag.active
        readonly property bool isHovered: dragArea.hoveredName === itemName && !PopoutManager.isDraggingAny && !dragArea.pressed
        readonly property bool isActive: (root.audioRef && root.audioRef.isPopoutActive) || isHovered || isBeingDragged

        implicitWidth: audioRow.implicitWidth + 12
        implicitHeight: 24
        height: 24
        y: 0
        z: isBeingDragged ? 999 : 1
        scale: isBeingDragged ? 1.15 : 1.0
        opacity: isBeingDragged ? 0.92 : 1.0

        Behavior on scale {
            NumberAnimation {
                duration: Theme.anim.fastSpatial
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.anim.expressiveFastSpatial
            }
        }

        x: isBeingDragged ? dragProxy.x : root.getSlotX(itemName)
        Behavior on x {
            enabled: !itemAudio.isBeingDragged
            NumberAnimation {
                duration: Theme.anim.fastSpatial
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.anim.expressiveDefaultSpatial
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 6
            color: itemAudio.isActive ? Theme.bgHover : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        RowLayout {
            id: audioRow
            anchors.centerIn: parent
            spacing: 5

            Text {
                text: {
                    if (!root.audioRef || root.audioRef.masterMuted || root.audioRef.masterVolume === 0) return "󰝟";
                    if (root.audioRef.masterVolume >= 65) return "󰕾";
                    if (root.audioRef.masterVolume >= 30) return "󰖀";
                    return "󰕿";
                }
                color: (root.audioRef && root.audioRef.masterMuted) ? Theme.danger : Theme.primary
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }
            Text {
                text: root.audioRef ? (root.audioRef.masterMuted ? "Mute" : (root.audioRef.masterVolume + "%")) : ""
                color: (root.audioRef && root.audioRef.masterMuted) ? Theme.overlay : Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }
        }
    }

    // --- SENSOR GLOBAL DE ARRASTRE Y HOVER ---
    MouseArea {
        id: dragArea
        anchors.fill: parent
        z: 10000
        hoverEnabled: true
        cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.ArrowCursor

        property string hoveredName: ""
        property string pendingOpenName: ""

        drag.target: dragProxy
        drag.axis: Drag.XAxis
        drag.minimumX: 0
        drag.maximumX: Math.max(0, root.implicitWidth - (root.draggingItemName !== "" ? root.getItemWidth(root.draggingItemName) : 24))

        Timer {
            id: hoverTimer
            interval: 120
            repeat: false
            onTriggered: {
                if (!dragArea.pressed && !dragArea.drag.active && !PopoutManager.isDraggingAny && dragArea.pendingOpenName !== "") {
                    PopoutManager.open(dragArea.pendingOpenName);
                }
            }
        }

        onPressed: mouse => {
            hoverTimer.stop();
            pendingOpenName = "";
            hoveredName = "";
            let hit = root.findItemAt(mouse.x);
            root.draggingItemName = hit;
            dragProxy.x = root.getSlotX(hit);
            root.displayOrder = [...PopoutManager.indicatorOrder];
            PopoutManager.isDraggingAny = true;
            PopoutManager.close();
        }

        onPositionChanged: mouse => {
            if (drag.active || pressed) {
                hoverTimer.stop();
                pendingOpenName = "";
                hoveredName = "";
                PopoutManager.isDraggingAny = true;
                PopoutManager.close();
            } else {
                if (!PopoutManager.isDraggingAny && !pressed) {
                    let hit = root.findItemAt(mouse.x);
                    if (hit !== "") {
                        if (hoveredName !== hit) {
                            hoveredName = hit;
                            pendingOpenName = hit;
                            hoverTimer.restart();
                        }
                    } else {
                        hoveredName = "";
                        pendingOpenName = "";
                        hoverTimer.stop();
                    }
                }
            }
        }

        onReleased: {
            hoverTimer.stop();
            pendingOpenName = "";
            hoveredName = "";
            if (root.draggingItemName !== "") {
                let finalOrder = [...root.displayOrder];
                root.draggingItemName = "";
                PopoutManager.isDraggingAny = false;
                PopoutManager.setOrder(finalOrder);
            } else {
                PopoutManager.isDraggingAny = false;
            }
        }

        onCanceled: {
            hoverTimer.stop();
            pendingOpenName = "";
            hoveredName = "";
            if (root.draggingItemName !== "") {
                let finalOrder = [...root.displayOrder];
                root.draggingItemName = "";
                PopoutManager.isDraggingAny = false;
                PopoutManager.setOrder(finalOrder);
            } else {
                PopoutManager.isDraggingAny = false;
            }
        }

        onExited: {
            if (!pressed && !drag.active) {
                hoverTimer.stop();
                pendingOpenName = "";
                hoveredName = "";
                PopoutManager.isDraggingAny = false;
            }
        }

        onWheel: wheel => {
            if (hoveredName === "audio" && root.audioRef && !pressed && !drag.active) {
                if (wheel.angleDelta.y > 0) {
                    root.audioRef.setMasterVolume(root.audioRef.masterVolume + 5);
                } else if (wheel.angleDelta.y < 0) {
                    root.audioRef.setMasterVolume(root.audioRef.masterVolume - 5);
                }
            }
        }
    }
}

