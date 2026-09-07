import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: barWindow

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 26
    color: Theme.bg

    WlrLayershell.namespace: "shell-bar"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Auto

    property var currentSections: PopoutManager.barSections
    property var displaySections: {
        let cur = PopoutManager.barSections;
        return {
            "left": (cur && cur.left) ? [...cur.left] : ["workspaces"],
            "center": (cur && cur.center) ? [...cur.center] : ["clock"],
            "right": (cur && cur.right) ? [...cur.right] : ["audio", "bluetooth", "wifi", "battery"]
        };
    }
    property string draggingModName: ""

    onCurrentSectionsChanged: {
        if (draggingModName === "") {
            let cur = currentSections;
            displaySections = {
                "left": (cur && cur.left) ? [...cur.left] : ["workspaces"],
                "center": (cur && cur.center) ? [...cur.center] : ["clock"],
                "right": (cur && cur.right) ? [...cur.right] : ["audio", "bluetooth", "wifi", "battery"]
            };
        }
    }

    function getModule(name) {
        if (name === "workspaces") return modWorkspaces;
        if (name === "clock") return modClock;
        if (name === "audio") return modAudio;
        if (name === "bluetooth") return modBluetooth;
        if (name === "wifi") return modWifi;
        if (name === "battery") return modBattery;
        return null;
    }

    function getModuleWidth(name) {
        let m = getModule(name);
        return m ? Math.max(22, m.implicitWidth || m.width) : 30;
    }

    function getSectionWidth(secList) {
        if (!secList || secList.length === 0) return 0;
        let w = 0;
        for (let i = 0; i < secList.length; i++) {
            w += getModuleWidth(secList[i]);
            if (i < secList.length - 1) w += 8;
        }
        return w;
    }

    function getSlotX(name) {
        let sec = displaySections || {};
        let leftList = (sec && sec.left) ? sec.left : [];
        let centerList = (sec && sec.center) ? sec.center : [];
        let rightList = (sec && sec.right) ? sec.right : [];

        let leftIdx = leftList.indexOf(name);
        if (leftIdx !== -1) {
            let curX = 10;
            for (let i = 0; i < leftIdx; i++) {
                curX += getModuleWidth(leftList[i]) + 8;
            }
            return curX;
        }

        let centerIdx = centerList.indexOf(name);
        if (centerIdx !== -1) {
            let totalCenterW = getSectionWidth(centerList);
            let startX = (barWindow.width - totalCenterW) / 2;
            let curX = startX;
            for (let i = 0; i < centerIdx; i++) {
                curX += getModuleWidth(centerList[i]) + 8;
            }
            return curX;
        }

        let rightIdx = rightList.indexOf(name);
        if (rightIdx !== -1) {
            let totalRightW = getSectionWidth(rightList);
            let startX = barWindow.width - totalRightW - 10;
            let curX = startX;
            for (let i = 0; i < rightIdx; i++) {
                curX += getModuleWidth(rightList[i]) + 8;
            }
            return curX;
        }

        return 10;
    }

    property real dragCurrentX: 0

    function startModuleDrag(name, startX) {
        PopoutManager.isDraggingAny = true;
        PopoutManager.close();
        draggingModName = name;
        dragCurrentX = startX;
        displaySections = {
            "left": [...(currentSections.left || [])],
            "center": [...(currentSections.center || [])],
            "right": [...(currentSections.right || [])]
        };
    }

    function updateModuleDrag(name, newX) {
        if (draggingModName !== name) return;

        let itemW = getModuleWidth(name);
        let clampedX = Math.max(10, Math.min(barContent.width - itemW - 10, newX));
        dragCurrentX = clampedX;

        let dragCenter = clampedX + itemW / 2;

        let baseLeft = (currentSections.left || []).filter(n => n !== name);
        let baseCenter = (currentSections.center || []).filter(n => n !== name);
        let baseRight = (currentSections.right || []).filter(n => n !== name);

        let bestSec = "left";
        let bestSlot = 0;
        let minDistance = 999999;

        let sectionsList = [
            { id: "left", items: baseLeft },
            { id: "center", items: baseCenter },
            { id: "right", items: baseRight }
        ];

        for (let s = 0; s < sectionsList.length; s++) {
            let secId = sectionsList[s].id;
            let secItems = sectionsList[s].items;

            for (let k = 0; k <= secItems.length; k++) {
                let candSub = [...secItems];
                candSub.splice(k, 0, name);

                let totalW = 0;
                for (let j = 0; j < candSub.length; j++) {
                    totalW += getModuleWidth(candSub[j]) + (j < candSub.length - 1 ? 8 : 0);
                }

                let secStartX = 10;
                if (secId === "center") {
                    secStartX = (barContent.width - totalW) / 2;
                } else if (secId === "right") {
                    secStartX = barContent.width - totalW - 10;
                }

                let candItemX = secStartX;
                for (let j = 0; j < k; j++) {
                    candItemX += getModuleWidth(candSub[j]) + 8;
                }

                let candCenter = candItemX + itemW / 2;
                let dist = Math.abs(dragCenter - candCenter);
                if (dist < minDistance) {
                    minDistance = dist;
                    bestSec = secId;
                    bestSlot = k;
                }
            }
        }

        let newLeft = [...baseLeft];
        let newCenter = [...baseCenter];
        let newRight = [...baseRight];

        if (bestSec === "left") {
            newLeft.splice(bestSlot, 0, name);
        } else if (bestSec === "center") {
            newCenter.splice(bestSlot, 0, name);
        } else {
            newRight.splice(bestSlot, 0, name);
        }

        let newSections = {
            "left": newLeft,
            "center": newCenter,
            "right": newRight
        };

        let curStr = JSON.stringify(displaySections);
        let newStr = JSON.stringify(newSections);
        if (curStr !== newStr) {
            displaySections = newSections;
        }
    }

    function finishModuleDrag() {
        if (draggingModName !== "") {
            let finalSec = {
                "left": [...(displaySections.left || [])],
                "center": [...(displaySections.center || [])],
                "right": [...(displaySections.right || [])]
            };
            draggingModName = "";
            PopoutManager.isDraggingAny = false;
            PopoutManager.setSections(finalSec);
        } else {
            PopoutManager.isDraggingAny = false;
        }
    }

    Item {
        id: barContent
        anchors.fill: parent

        // 1. Módulo Workspaces
        Item {
            id: modWorkspaces
            property string modName: "workspaces"
            implicitWidth: wsComp.implicitWidth
            width: implicitWidth
            height: 26
            anchors.verticalCenter: parent.verticalCenter

            readonly property bool isBeingDragged: barWindow.draggingModName === modName

            x: isBeingDragged ? barWindow.dragCurrentX : barWindow.getSlotX(modName)

            Behavior on x {
                enabled: !modWorkspaces.isBeingDragged
                NumberAnimation {
                    duration: Theme.anim.fastSpatial
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.anim.expressiveDefaultSpatial
                }
            }

            z: isBeingDragged ? 9999 : 1
            scale: isBeingDragged ? 1.08 : 1.0
            opacity: isBeingDragged ? 0.92 : 1.0

            Behavior on scale {
                NumberAnimation { duration: 150; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.expressiveFastSpatial }
            }

            Workspaces {
                id: wsComp
                anchors.verticalCenter: parent.verticalCenter
                barWindowRef: barWindow
                barContentRef: barContent
            }
        }

        // 2. Módulo Clock
        Item {
            id: modClock
            property string modName: "clock"
            implicitWidth: clockComp.implicitWidth + 14
            width: implicitWidth
            height: 26
            anchors.verticalCenter: parent.verticalCenter

            readonly property bool isBeingDragged: barWindow.draggingModName === modName

            x: isBeingDragged ? barWindow.dragCurrentX : barWindow.getSlotX(modName)

            Behavior on x {
                enabled: !modClock.isBeingDragged
                NumberAnimation {
                    duration: Theme.anim.fastSpatial
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.anim.expressiveDefaultSpatial
                }
            }

            z: isBeingDragged ? 9999 : 1
            scale: isBeingDragged ? 1.08 : 1.0
            opacity: isBeingDragged ? 0.92 : 1.0

            Behavior on scale {
                NumberAnimation { duration: 150; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.expressiveFastSpatial }
            }

            Rectangle {
                anchors.fill: parent
                radius: 6
                color: clockMouse.containsMouse ? Theme.bgHover : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            Clock {
                id: clockComp
                anchors.centerIn: parent
            }

            MouseArea {
                id: clockMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: isDraggingThis ? Qt.ClosedHandCursor : Qt.PointingHandCursor

                property real pressGlobalX: 0
                property real initialModuleX: 0
                property bool isDraggingThis: false

                onPressed: mouse => {
                    let globalPt = mapToItem(barContent, mouse.x, mouse.y);
                    pressGlobalX = globalPt.x;
                    let m = modClock;
                    initialModuleX = m ? m.x : barWindow.getSlotX("clock");
                    isDraggingThis = false;
                }

                onPositionChanged: mouse => {
                    if (!pressed) return;
                    let globalPt = mapToItem(barContent, mouse.x, mouse.y);
                    let delta = globalPt.x - pressGlobalX;
                    if (!isDraggingThis) {
                        if (Math.abs(delta) > 6) {
                            isDraggingThis = true;
                            barWindow.startModuleDrag("clock", initialModuleX);
                        }
                    }
                    if (isDraggingThis) {
                        barWindow.updateModuleDrag("clock", initialModuleX + delta);
                    }
                }

                onReleased: {
                    if (isDraggingThis) {
                        isDraggingThis = false;
                        barWindow.finishModuleDrag();
                    }
                }

                onCanceled: {
                    if (isDraggingThis) {
                        isDraggingThis = false;
                        barWindow.finishModuleDrag();
                    }
                }
            }
        }

        // 3. Módulo Audio
        Item {
            id: modAudio
            property string modName: "audio"
            implicitWidth: audioRow.implicitWidth + 12
            width: implicitWidth
            height: 24
            anchors.verticalCenter: parent.verticalCenter

            readonly property bool isBeingDragged: barWindow.draggingModName === modName
            readonly property bool isHovered: audioMouse.containsMouse && !PopoutManager.isDraggingAny && !audioMouse.pressed
            readonly property bool isActive: (audioIndicator && audioIndicator.isPopoutActive) || isHovered || isBeingDragged

            x: isBeingDragged ? barWindow.dragCurrentX : barWindow.getSlotX(modName)

            Behavior on x {
                enabled: !modAudio.isBeingDragged
                NumberAnimation {
                    duration: Theme.anim.fastSpatial
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.anim.expressiveDefaultSpatial
                }
            }

            z: isBeingDragged ? 9999 : 1
            scale: isBeingDragged ? 1.15 : 1.0
            opacity: isBeingDragged ? 0.92 : 1.0

            Behavior on scale {
                NumberAnimation { duration: Theme.anim.fastSpatial; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.expressiveFastSpatial }
            }

            Rectangle {
                anchors.fill: parent
                radius: 6
                color: modAudio.isActive ? Theme.bgHover : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            RowLayout {
                id: audioRow
                anchors.centerIn: parent
                spacing: 5

                Text {
                    text: {
                        if (!audioIndicator || audioIndicator.masterMuted || audioIndicator.masterVolume === 0) return "󰝟";
                        if (audioIndicator.masterVolume >= 65) return "󰕾";
                        if (audioIndicator.masterVolume >= 30) return "󰖀";
                        return "󰕿";
                    }
                    color: (audioIndicator && audioIndicator.masterMuted) ? Theme.danger : Theme.primary
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }
                Text {
                    text: audioIndicator ? (audioIndicator.masterMuted ? "Mute" : (audioIndicator.masterVolume + "%")) : ""
                    color: (audioIndicator && audioIndicator.masterMuted) ? Theme.overlay : Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }
            }

            MouseArea {
                id: audioMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: isDraggingThis ? Qt.ClosedHandCursor : Qt.PointingHandCursor

                property real pressGlobalX: 0
                property real initialModuleX: 0
                property bool isDraggingThis: false

                onPressed: mouse => {
                    let globalPt = mapToItem(barContent, mouse.x, mouse.y);
                    pressGlobalX = globalPt.x;
                    let m = modAudio;
                    initialModuleX = m ? m.x : barWindow.getSlotX("audio");
                    isDraggingThis = false;
                }

                onPositionChanged: mouse => {
                    if (!pressed) return;
                    let globalPt = mapToItem(barContent, mouse.x, mouse.y);
                    let delta = globalPt.x - pressGlobalX;
                    if (!isDraggingThis) {
                        if (Math.abs(delta) > 6) {
                            isDraggingThis = true;
                            barWindow.startModuleDrag("audio", initialModuleX);
                        }
                    }
                    if (isDraggingThis) {
                        barWindow.updateModuleDrag("audio", initialModuleX + delta);
                    }
                }

                onReleased: {
                    if (isDraggingThis) {
                        isDraggingThis = false;
                        barWindow.finishModuleDrag();
                    } else {
                        if (!PopoutManager.isDraggingAny) {
                            PopoutManager.toggle("audio", modAudio.x + modAudio.width / 2);
                        }
                    }
                }

                onCanceled: {
                    if (isDraggingThis) {
                        isDraggingThis = false;
                        barWindow.finishModuleDrag();
                    }
                }

                onWheel: wheel => {
                    if (audioIndicator && !pressed && !isDraggingThis) {
                        if (wheel.angleDelta.y > 0) {
                            audioIndicator.setMasterVolume(audioIndicator.masterVolume + 5);
                        } else if (wheel.angleDelta.y < 0) {
                            audioIndicator.setMasterVolume(audioIndicator.masterVolume - 5);
                        }
                    }
                }
            }
        }

        // 4. Módulo Bluetooth
        Item {
            id: modBluetooth
            property string modName: "bluetooth"
            implicitWidth: btRow.implicitWidth + 12
            width: implicitWidth
            height: 24
            anchors.verticalCenter: parent.verticalCenter

            readonly property bool isBeingDragged: barWindow.draggingModName === modName
            readonly property bool isHovered: btMouse.containsMouse && !PopoutManager.isDraggingAny && !btMouse.pressed
            readonly property bool isActive: (btIndicator && btIndicator.isPopoutActive) || isHovered || isBeingDragged

            x: isBeingDragged ? barWindow.dragCurrentX : barWindow.getSlotX(modName)

            Behavior on x {
                enabled: !modBluetooth.isBeingDragged
                NumberAnimation {
                    duration: Theme.anim.fastSpatial
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.anim.expressiveDefaultSpatial
                }
            }

            z: isBeingDragged ? 9999 : 1
            scale: isBeingDragged ? 1.15 : 1.0
            opacity: isBeingDragged ? 0.92 : 1.0

            Behavior on scale {
                NumberAnimation { duration: Theme.anim.fastSpatial; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.expressiveFastSpatial }
            }

            Rectangle {
                anchors.fill: parent
                radius: 6
                color: modBluetooth.isActive ? Theme.bgHover : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            RowLayout {
                id: btRow
                anchors.centerIn: parent
                spacing: 5

                Text {
                    text: {
                        if (!btIndicator) return "󰂲";
                        if (btIndicator.isConnected) return "󰂱";
                        if (btIndicator.isPowered) return "󰂯";
                        return "󰂲";
                    }
                    color: (btIndicator && btIndicator.isConnected) ? Theme.primary : ((btIndicator && btIndicator.isPowered) ? Theme.text : Theme.overlay)
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }
                Text {
                    visible: btIndicator && btIndicator.isConnected && btIndicator.connectedCount > 0
                    text: btIndicator ? btIndicator.connectedCount.toString() : ""
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }
            }

            MouseArea {
                id: btMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: isDraggingThis ? Qt.ClosedHandCursor : Qt.PointingHandCursor

                property real pressGlobalX: 0
                property real initialModuleX: 0
                property bool isDraggingThis: false

                onPressed: mouse => {
                    let globalPt = mapToItem(barContent, mouse.x, mouse.y);
                    pressGlobalX = globalPt.x;
                    let m = modBluetooth;
                    initialModuleX = m ? m.x : barWindow.getSlotX("bluetooth");
                    isDraggingThis = false;
                }

                onPositionChanged: mouse => {
                    if (!pressed) return;
                    let globalPt = mapToItem(barContent, mouse.x, mouse.y);
                    let delta = globalPt.x - pressGlobalX;
                    if (!isDraggingThis) {
                        if (Math.abs(delta) > 6) {
                            isDraggingThis = true;
                            barWindow.startModuleDrag("bluetooth", initialModuleX);
                        }
                    }
                    if (isDraggingThis) {
                        barWindow.updateModuleDrag("bluetooth", initialModuleX + delta);
                    }
                }

                onReleased: {
                    if (isDraggingThis) {
                        isDraggingThis = false;
                        barWindow.finishModuleDrag();
                    } else {
                        if (!PopoutManager.isDraggingAny) {
                            PopoutManager.toggle("bluetooth", modBluetooth.x + modBluetooth.width / 2);
                        }
                    }
                }

                onCanceled: {
                    if (isDraggingThis) {
                        isDraggingThis = false;
                        barWindow.finishModuleDrag();
                    }
                }
            }
        }

        // 5. Módulo Wi-Fi
        Item {
            id: modWifi
            property string modName: "wifi"
            implicitWidth: wifiRow.implicitWidth + 12
            width: implicitWidth
            height: 24
            anchors.verticalCenter: parent.verticalCenter

            readonly property bool isBeingDragged: barWindow.draggingModName === modName
            readonly property bool isHovered: wifiMouse.containsMouse && !PopoutManager.isDraggingAny && !wifiMouse.pressed
            readonly property bool isActive: (netIndicator && netIndicator.isPopoutActive) || isHovered || isBeingDragged

            x: isBeingDragged ? barWindow.dragCurrentX : barWindow.getSlotX(modName)

            Behavior on x {
                enabled: !modWifi.isBeingDragged
                NumberAnimation {
                    duration: Theme.anim.fastSpatial
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.anim.expressiveDefaultSpatial
                }
            }

            z: isBeingDragged ? 9999 : 1
            scale: isBeingDragged ? 1.15 : 1.0
            opacity: isBeingDragged ? 0.92 : 1.0

            Behavior on scale {
                NumberAnimation { duration: Theme.anim.fastSpatial; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.expressiveFastSpatial }
            }

            Rectangle {
                anchors.fill: parent
                radius: 6
                color: modWifi.isActive ? Theme.bgHover : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            RowLayout {
                id: wifiRow
                anchors.centerIn: parent
                spacing: 5

                Text {
                    text: {
                        if (!netIndicator || !netIndicator.isConnected) return "󰤭";
                        if (netIndicator.signalStrength >= 75) return "󰤨";
                        if (netIndicator.signalStrength >= 50) return "󰤥";
                        if (netIndicator.signalStrength >= 25) return "󰤢";
                        return "󰤟";
                    }
                    color: (netIndicator && netIndicator.isConnected) ? Theme.cyan : Theme.overlay
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }
                Text {
                    visible: netIndicator && netIndicator.isConnected && netIndicator.ssid.length > 0
                    text: netIndicator ? netIndicator.ssid : ""
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    Layout.maximumWidth: 100
                }
            }

            MouseArea {
                id: wifiMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: isDraggingThis ? Qt.ClosedHandCursor : Qt.PointingHandCursor

                property real pressGlobalX: 0
                property real initialModuleX: 0
                property bool isDraggingThis: false

                onPressed: mouse => {
                    let globalPt = mapToItem(barContent, mouse.x, mouse.y);
                    pressGlobalX = globalPt.x;
                    let m = modWifi;
                    initialModuleX = m ? m.x : barWindow.getSlotX("wifi");
                    isDraggingThis = false;
                }

                onPositionChanged: mouse => {
                    if (!pressed) return;
                    let globalPt = mapToItem(barContent, mouse.x, mouse.y);
                    let delta = globalPt.x - pressGlobalX;
                    if (!isDraggingThis) {
                        if (Math.abs(delta) > 6) {
                            isDraggingThis = true;
                            barWindow.startModuleDrag("wifi", initialModuleX);
                        }
                    }
                    if (isDraggingThis) {
                        barWindow.updateModuleDrag("wifi", initialModuleX + delta);
                    }
                }

                onReleased: {
                    if (isDraggingThis) {
                        isDraggingThis = false;
                        barWindow.finishModuleDrag();
                    } else {
                        if (!PopoutManager.isDraggingAny) {
                            PopoutManager.toggle("wifi", modWifi.x + modWifi.width / 2);
                        }
                    }
                }

                onCanceled: {
                    if (isDraggingThis) {
                        isDraggingThis = false;
                        barWindow.finishModuleDrag();
                    }
                }
            }
        }

        // 6. Módulo Batería
        Item {
            id: modBattery
            property string modName: "battery"
            implicitWidth: batRow.implicitWidth + 12
            width: implicitWidth
            height: 24
            anchors.verticalCenter: parent.verticalCenter

            readonly property bool isBeingDragged: barWindow.draggingModName === modName
            readonly property bool isHovered: batMouse.containsMouse && !PopoutManager.isDraggingAny && !batMouse.pressed
            readonly property bool isActive: (batIndicator && batIndicator.isPopoutActive) || isHovered || isBeingDragged

            x: isBeingDragged ? barWindow.dragCurrentX : barWindow.getSlotX(modName)

            Behavior on x {
                enabled: !modBattery.isBeingDragged
                NumberAnimation {
                    duration: Theme.anim.fastSpatial
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.anim.expressiveDefaultSpatial
                }
            }

            z: isBeingDragged ? 9999 : 1
            scale: isBeingDragged ? 1.15 : 1.0
            opacity: isBeingDragged ? 0.92 : 1.0

            Behavior on scale {
                NumberAnimation { duration: Theme.anim.fastSpatial; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.expressiveFastSpatial }
            }

            Rectangle {
                anchors.fill: parent
                radius: 6
                color: modBattery.isActive ? Theme.bgHover : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            RowLayout {
                id: batRow
                anchors.centerIn: parent
                spacing: 5

                Text {
                    text: {
                        if (!batIndicator) return "󰁹";
                        if (batIndicator.status === "Charging") return "󰂄";
                        if (batIndicator.percentage >= 90) return "󰁹";
                        if (batIndicator.percentage >= 70) return "󰂀";
                        if (batIndicator.percentage >= 50) return "󰁾";
                        if (batIndicator.percentage >= 30) return "󰁼";
                        if (batIndicator.percentage >= 10) return "󰁺";
                        return "󰂎";
                    }
                    color: {
                        if (!batIndicator) return Theme.primary;
                        return batIndicator.percentage <= 20 && batIndicator.status !== "Charging" ? Theme.danger : (batIndicator.status === "Charging" ? Theme.success : Theme.primary);
                    }
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }
                Text {
                    visible: batIndicator && batIndicator.showPercentage
                    text: batIndicator ? (batIndicator.percentage + "%") : "0%"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }
            }

            MouseArea {
                id: batMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: isDraggingThis ? Qt.ClosedHandCursor : Qt.PointingHandCursor

                property real pressGlobalX: 0
                property real initialModuleX: 0
                property bool isDraggingThis: false

                onPressed: mouse => {
                    let globalPt = mapToItem(barContent, mouse.x, mouse.y);
                    pressGlobalX = globalPt.x;
                    let m = modBattery;
                    initialModuleX = m ? m.x : barWindow.getSlotX("battery");
                    isDraggingThis = false;
                }

                onPositionChanged: mouse => {
                    if (!pressed) return;
                    let globalPt = mapToItem(barContent, mouse.x, mouse.y);
                    let delta = globalPt.x - pressGlobalX;
                    if (!isDraggingThis) {
                        if (Math.abs(delta) > 6) {
                            isDraggingThis = true;
                            barWindow.startModuleDrag("battery", initialModuleX);
                        }
                    }
                    if (isDraggingThis) {
                        barWindow.updateModuleDrag("battery", initialModuleX + delta);
                    }
                }

                onReleased: {
                    if (isDraggingThis) {
                        isDraggingThis = false;
                        barWindow.finishModuleDrag();
                    } else {
                        if (!PopoutManager.isDraggingAny) {
                            PopoutManager.toggle("battery", modBattery.x + modBattery.width / 2);
                        }
                    }
                }

                onCanceled: {
                    if (isDraggingThis) {
                        isDraggingThis = false;
                        barWindow.finishModuleDrag();
                    }
                }
            }
        }

        // Instancias de fondo para lógica y servicios
        Item {
            visible: false
            AudioIndicator { id: audioIndicator }
            BluetoothIndicator { id: btIndicator }
            NetworkIndicator { id: netIndicator }
            BatteryIndicator { id: batIndicator }
        }
    }
}
