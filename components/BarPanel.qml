import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: barWindow

    anchors {
        top: PopoutManager.barPosition !== "bottom"
        bottom: PopoutManager.barPosition !== "top"
        left: PopoutManager.barPosition !== "right"
        right: PopoutManager.barPosition !== "left"
    }
    implicitHeight: PopoutManager.isVertical ? (barWindow.screen ? barWindow.screen.height : 800) : 26
    implicitWidth: PopoutManager.isVertical ? 38 : (barWindow.screen ? barWindow.screen.width : 1280)
    color: Theme.bg

    WlrLayershell.namespace: "shell-bar"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusiveZone: PopoutManager.isVertical ? 38 : 26
    exclusionMode: ExclusionMode.Auto

    onWidthChanged: console.log("BAR DIM: width=" + width + " height=" + height + " pos=" + PopoutManager.barPosition)
    onHeightChanged: console.log("BAR DIM: width=" + width + " height=" + height + " pos=" + PopoutManager.barPosition)

    function getScreenCoords(localX, localY) {
        let screenW = barWindow.screen ? barWindow.screen.width : 1280;
        let screenH = barWindow.screen ? barWindow.screen.height : 800;
        let sX = localX;
        let sY = localY;
        if (PopoutManager.barPosition === "bottom") {
            sY = (screenH - barWindow.height) + localY;
        } else if (PopoutManager.barPosition === "right") {
            sX = (screenW - barWindow.width) + localX;
        }
        return { x: sX, y: sY, w: screenW, h: screenH };
    }

    function calculateTargetEdge(screenX, screenY, screenW, screenH) {
        let dTop = Math.max(0, screenY);
        let dBottom = Math.max(0, screenH - screenY);
        let dLeft = Math.max(0, screenX);
        let dRight = Math.max(0, screenW - screenX);

        let minD = dTop;
        let edge = "top";

        if (dBottom < minD) {
            minD = dBottom;
            edge = "bottom";
        }
        if (dLeft < minD) {
            minD = dLeft;
            edge = "left";
        }
        if (dRight < minD) {
            minD = dRight;
            edge = "right";
        }
        return edge;
    }

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
        if (PopoutManager.isVertical) return 28;
        let m = getModule(name);
        return m ? Math.max(22, m.implicitWidth || m.width) : 30;
    }

    function getModuleHeight(name) {
        if (!PopoutManager.isVertical) return 24;
        if (name === "workspaces") {
            return wsComp ? Math.max(28, wsComp.implicitHeight) : 80;
        }
        return 28;
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

    function getSectionHeight(secList) {
        if (!secList || secList.length === 0) return 0;
        let h = 0;
        for (let i = 0; i < secList.length; i++) {
            h += getModuleHeight(secList[i]);
            if (i < secList.length - 1) h += 8;
        }
        return h;
    }

    function getSlotX(name) {
        if (PopoutManager.isVertical) {
            return (barWindow.width - getModuleWidth(name)) / 2;
        }
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

    function getSlotY(name) {
        if (!PopoutManager.isVertical) {
            return (barWindow.height - getModuleHeight(name)) / 2;
        }
        let sec = displaySections || {};
        let leftList = (sec && sec.left) ? sec.left : [];
        let centerList = (sec && sec.center) ? sec.center : [];
        let rightList = (sec && sec.right) ? sec.right : [];

        let leftIdx = leftList.indexOf(name);
        if (leftIdx !== -1) {
            let curY = 10;
            for (let i = 0; i < leftIdx; i++) {
                curY += getModuleHeight(leftList[i]) + 8;
            }
            return curY;
        }

        let centerIdx = centerList.indexOf(name);
        if (centerIdx !== -1) {
            let totalCenterH = getSectionHeight(centerList);
            let startY = (barWindow.height - totalCenterH) / 2;
            let curY = startY;
            for (let i = 0; i < centerIdx; i++) {
                curY += getModuleHeight(centerList[i]) + 8;
            }
            return curY;
        }

        let rightIdx = rightList.indexOf(name);
        if (rightIdx !== -1) {
            let totalRightH = getSectionHeight(rightList);
            let startY = barWindow.height - totalRightH - 10;
            let curY = startY;
            for (let i = 0; i < rightIdx; i++) {
                curY += getModuleHeight(rightList[i]) + 8;
            }
            return curY;
        }

        return 10;
    }

    property real dragCurrentX: 0
    property real dragCurrentY: 0

    function startModuleDrag(name, startCoord) {
        PopoutManager.isDraggingAny = true;
        PopoutManager.close();
        draggingModName = name;
        if (PopoutManager.isVertical) {
            dragCurrentY = startCoord;
        } else {
            dragCurrentX = startCoord;
        }
        displaySections = {
            "left": [...(currentSections.left || [])],
            "center": [...(currentSections.center || [])],
            "right": [...(currentSections.right || [])]
        };
    }

    function updateModuleDrag(name, newCoord) {
        if (draggingModName !== name) return;

        let isVert = PopoutManager.isVertical;
        let itemSize = isVert ? getModuleHeight(name) : getModuleWidth(name);
        let maxBound = isVert ? barContent.height : barContent.width;
        let clamped = Math.max(10, Math.min(maxBound - itemSize - 10, newCoord));
        if (isVert) {
            dragCurrentY = clamped;
        } else {
            dragCurrentX = clamped;
        }

        let dragCenter = clamped + itemSize / 2;

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

                let totalSize = 0;
                for (let j = 0; j < candSub.length; j++) {
                    totalSize += (isVert ? getModuleHeight(candSub[j]) : getModuleWidth(candSub[j])) + (j < candSub.length - 1 ? 8 : 0);
                }

                let secStart = 10;
                if (secId === "center") {
                    secStart = (maxBound - totalSize) / 2;
                } else if (secId === "right") {
                    secStart = maxBound - totalSize - 10;
                }

                let candItemCoord = secStart;
                for (let j = 0; j < k; j++) {
                    candItemCoord += (isVert ? getModuleHeight(candSub[j]) : getModuleWidth(candSub[j])) + 8;
                }

                let candCenter = candItemCoord + itemSize / 2;
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

        // 0. Área de arrastre de la barra en espacios vacíos
        MouseArea {
            id: barBgDragArea
            anchors.fill: parent
            z: 0
            hoverEnabled: true
            cursorShape: PopoutManager.isBarDragging ? Qt.ClosedHandCursor : Qt.ArrowCursor

            property real pressLocalX: 0
            property real pressLocalY: 0
            property bool isDraggingBar: false

            onPressed: mouse => {
                pressLocalX = mouse.x;
                pressLocalY = mouse.y;
                isDraggingBar = false;
            }

            onPositionChanged: mouse => {
                if (!pressed) return;
                let dist = Math.hypot(mouse.x - pressLocalX, mouse.y - pressLocalY);
                if (!isDraggingBar && dist > 15) {
                    isDraggingBar = true;
                    PopoutManager.isBarDragging = true;
                    PopoutManager.close();
                }
                if (isDraggingBar) {
                    let coords = barWindow.getScreenCoords(mouse.x, mouse.y);
                    let edge = barWindow.calculateTargetEdge(coords.x, coords.y, coords.w, coords.h);
                    PopoutManager.candidateBarPosition = edge;
                }
            }

            onReleased: {
                if (isDraggingBar) {
                    isDraggingBar = false;
                    PopoutManager.isBarDragging = false;
                    let edge = PopoutManager.candidateBarPosition;
                    PopoutManager.candidateBarPosition = "";
                    if (edge && edge !== PopoutManager.barPosition) {
                        PopoutManager.setBarPosition(edge);
                    }
                }
            }

            onCanceled: {
                if (isDraggingBar) {
                    isDraggingBar = false;
                    PopoutManager.isBarDragging = false;
                    PopoutManager.candidateBarPosition = "";
                }
            }
        }

        // 1. Módulo Workspaces
        Item {
            id: modWorkspaces
            property string modName: "workspaces"
            implicitWidth: PopoutManager.isVertical ? 28 : wsComp.implicitWidth
            width: implicitWidth
            implicitHeight: PopoutManager.isVertical ? wsComp.implicitHeight : 26
            height: implicitHeight

            readonly property bool isBeingDragged: barWindow.draggingModName === modName

            x: (!PopoutManager.isVertical && isBeingDragged) ? barWindow.dragCurrentX : barWindow.getSlotX(modName)
            y: (PopoutManager.isVertical && isBeingDragged) ? barWindow.dragCurrentY : barWindow.getSlotY(modName)

            Behavior on x {
                enabled: !PopoutManager.isVertical && !modWorkspaces.isBeingDragged
                NumberAnimation {
                    duration: Theme.anim.fastSpatial
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.anim.expressiveDefaultSpatial
                }
            }
            Behavior on y {
                enabled: PopoutManager.isVertical && !modWorkspaces.isBeingDragged
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
                anchors.centerIn: parent
                barWindowRef: barWindow
                barContentRef: barContent
            }
        }

        // 2. Módulo Clock
        Item {
            id: modClock
            property string modName: "clock"
            implicitWidth: PopoutManager.isVertical ? 28 : (clockComp.implicitWidth + 14)
            width: implicitWidth
            implicitHeight: PopoutManager.isVertical ? 28 : 26
            height: implicitHeight

            readonly property bool isBeingDragged: barWindow.draggingModName === modName

            x: (!PopoutManager.isVertical && isBeingDragged) ? barWindow.dragCurrentX : barWindow.getSlotX(modName)
            y: (PopoutManager.isVertical && isBeingDragged) ? barWindow.dragCurrentY : barWindow.getSlotY(modName)

            Behavior on x {
                enabled: !PopoutManager.isVertical && !modClock.isBeingDragged
                NumberAnimation {
                    duration: Theme.anim.fastSpatial
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.anim.expressiveDefaultSpatial
                }
            }
            Behavior on y {
                enabled: PopoutManager.isVertical && !modClock.isBeingDragged
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

                property real pressCoord: 0
                property real initialCoord: 0
                property bool isDraggingThis: false

                onPressed: mouse => {
                    let globalPt = mapToItem(barContent, mouse.x, mouse.y);
                    pressCoord = PopoutManager.isVertical ? globalPt.y : globalPt.x;
                    let m = modClock;
                    if (PopoutManager.isVertical) {
                        initialCoord = m ? m.y : barWindow.getSlotY("clock");
                    } else {
                        initialCoord = m ? m.x : barWindow.getSlotX("clock");
                    }
                    isDraggingThis = false;
                }

                onPositionChanged: mouse => {
                    if (!pressed) return;
                    let globalPt = mapToItem(barContent, mouse.x, mouse.y);
                    let curCoord = PopoutManager.isVertical ? globalPt.y : globalPt.x;
                    let delta = curCoord - pressCoord;
                    if (!isDraggingThis) {
                        if (Math.abs(delta) > 6) {
                            isDraggingThis = true;
                            barWindow.startModuleDrag("clock", initialCoord);
                        }
                    }
                    if (isDraggingThis) {
                        barWindow.updateModuleDrag("clock", initialCoord + delta);
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
            implicitWidth: PopoutManager.isVertical ? 28 : (audioRow.implicitWidth + 12)
            width: implicitWidth
            implicitHeight: PopoutManager.isVertical ? 28 : 24
            height: implicitHeight

            readonly property bool isBeingDragged: barWindow.draggingModName === modName
            readonly property bool isHovered: audioMouse.containsMouse && !PopoutManager.isDraggingAny && !audioMouse.pressed
            readonly property bool isActive: (audioIndicator && audioIndicator.isPopoutActive) || isHovered || isBeingDragged

            x: (!PopoutManager.isVertical && isBeingDragged) ? barWindow.dragCurrentX : barWindow.getSlotX(modName)
            y: (PopoutManager.isVertical && isBeingDragged) ? barWindow.dragCurrentY : barWindow.getSlotY(modName)

            Behavior on x {
                enabled: !PopoutManager.isVertical && !modAudio.isBeingDragged
                NumberAnimation {
                    duration: Theme.anim.fastSpatial
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.anim.expressiveDefaultSpatial
                }
            }
            Behavior on y {
                enabled: PopoutManager.isVertical && !modAudio.isBeingDragged
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
                    visible: !PopoutManager.isVertical
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

                property real pressCoord: 0
                property real initialCoord: 0
                property bool isDraggingThis: false

                onPressed: mouse => {
                    let globalPt = mapToItem(barContent, mouse.x, mouse.y);
                    pressCoord = PopoutManager.isVertical ? globalPt.y : globalPt.x;
                    let m = modAudio;
                    if (PopoutManager.isVertical) {
                        initialCoord = m ? m.y : barWindow.getSlotY("audio");
                    } else {
                        initialCoord = m ? m.x : barWindow.getSlotX("audio");
                    }
                    isDraggingThis = false;
                }

                onPositionChanged: mouse => {
                    if (!pressed) return;
                    let globalPt = mapToItem(barContent, mouse.x, mouse.y);
                    let curCoord = PopoutManager.isVertical ? globalPt.y : globalPt.x;
                    let delta = curCoord - pressCoord;
                    if (!isDraggingThis) {
                        if (Math.abs(delta) > 6) {
                            isDraggingThis = true;
                            barWindow.startModuleDrag("audio", initialCoord);
                        }
                    }
                    if (isDraggingThis) {
                        barWindow.updateModuleDrag("audio", initialCoord + delta);
                    }
                }

                onReleased: {
                    if (isDraggingThis) {
                        isDraggingThis = false;
                        barWindow.finishModuleDrag();
                    } else {
                        if (!PopoutManager.isDraggingAny) {
                            let centerCoord = PopoutManager.isVertical ? (modAudio.y + modAudio.height / 2) : (modAudio.x + modAudio.width / 2);
                            PopoutManager.toggle("audio", centerCoord);
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
            implicitWidth: PopoutManager.isVertical ? 28 : (btRow.implicitWidth + 12)
            width: implicitWidth
            implicitHeight: PopoutManager.isVertical ? 28 : 24
            height: implicitHeight

            readonly property bool isBeingDragged: barWindow.draggingModName === modName
            readonly property bool isHovered: btMouse.containsMouse && !PopoutManager.isDraggingAny && !btMouse.pressed
            readonly property bool isActive: (btIndicator && btIndicator.isPopoutActive) || isHovered || isBeingDragged

            x: (!PopoutManager.isVertical && isBeingDragged) ? barWindow.dragCurrentX : barWindow.getSlotX(modName)
            y: (PopoutManager.isVertical && isBeingDragged) ? barWindow.dragCurrentY : barWindow.getSlotY(modName)

            Behavior on x {
                enabled: !PopoutManager.isVertical && !modBluetooth.isBeingDragged
                NumberAnimation {
                    duration: Theme.anim.fastSpatial
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.anim.expressiveDefaultSpatial
                }
            }
            Behavior on y {
                enabled: PopoutManager.isVertical && !modBluetooth.isBeingDragged
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
                    visible: !PopoutManager.isVertical && btIndicator && btIndicator.isConnected && btIndicator.connectedCount > 0
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

                property real pressCoord: 0
                property real initialCoord: 0
                property bool isDraggingThis: false

                onPressed: mouse => {
                    let globalPt = mapToItem(barContent, mouse.x, mouse.y);
                    pressCoord = PopoutManager.isVertical ? globalPt.y : globalPt.x;
                    let m = modBluetooth;
                    if (PopoutManager.isVertical) {
                        initialCoord = m ? m.y : barWindow.getSlotY("bluetooth");
                    } else {
                        initialCoord = m ? m.x : barWindow.getSlotX("bluetooth");
                    }
                    isDraggingThis = false;
                }

                onPositionChanged: mouse => {
                    if (!pressed) return;
                    let globalPt = mapToItem(barContent, mouse.x, mouse.y);
                    let curCoord = PopoutManager.isVertical ? globalPt.y : globalPt.x;
                    let delta = curCoord - pressCoord;
                    if (!isDraggingThis) {
                        if (Math.abs(delta) > 6) {
                            isDraggingThis = true;
                            barWindow.startModuleDrag("bluetooth", initialCoord);
                        }
                    }
                    if (isDraggingThis) {
                        barWindow.updateModuleDrag("bluetooth", initialCoord + delta);
                    }
                }

                onReleased: {
                    if (isDraggingThis) {
                        isDraggingThis = false;
                        barWindow.finishModuleDrag();
                    } else {
                        if (!PopoutManager.isDraggingAny) {
                            let centerCoord = PopoutManager.isVertical ? (modBluetooth.y + modBluetooth.height / 2) : (modBluetooth.x + modBluetooth.width / 2);
                            PopoutManager.toggle("bluetooth", centerCoord);
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
            implicitWidth: PopoutManager.isVertical ? 28 : (wifiRow.implicitWidth + 12)
            width: implicitWidth
            implicitHeight: PopoutManager.isVertical ? 28 : 24
            height: implicitHeight

            readonly property bool isBeingDragged: barWindow.draggingModName === modName
            readonly property bool isHovered: wifiMouse.containsMouse && !PopoutManager.isDraggingAny && !wifiMouse.pressed
            readonly property bool isActive: (netIndicator && netIndicator.isPopoutActive) || isHovered || isBeingDragged

            x: (!PopoutManager.isVertical && isBeingDragged) ? barWindow.dragCurrentX : barWindow.getSlotX(modName)
            y: (PopoutManager.isVertical && isBeingDragged) ? barWindow.dragCurrentY : barWindow.getSlotY(modName)

            Behavior on x {
                enabled: !PopoutManager.isVertical && !modWifi.isBeingDragged
                NumberAnimation {
                    duration: Theme.anim.fastSpatial
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.anim.expressiveDefaultSpatial
                }
            }
            Behavior on y {
                enabled: PopoutManager.isVertical && !modWifi.isBeingDragged
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
                        if (netIndicator.isEthernet) return "󰈀";
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
                    visible: !PopoutManager.isVertical && netIndicator && netIndicator.isConnected && netIndicator.ssid.length > 0
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

                property real pressCoord: 0
                property real initialCoord: 0
                property bool isDraggingThis: false

                onPressed: mouse => {
                    let globalPt = mapToItem(barContent, mouse.x, mouse.y);
                    pressCoord = PopoutManager.isVertical ? globalPt.y : globalPt.x;
                    let m = modWifi;
                    if (PopoutManager.isVertical) {
                        initialCoord = m ? m.y : barWindow.getSlotY("wifi");
                    } else {
                        initialCoord = m ? m.x : barWindow.getSlotX("wifi");
                    }
                    isDraggingThis = false;
                }

                onPositionChanged: mouse => {
                    if (!pressed) return;
                    let globalPt = mapToItem(barContent, mouse.x, mouse.y);
                    let curCoord = PopoutManager.isVertical ? globalPt.y : globalPt.x;
                    let delta = curCoord - pressCoord;
                    if (!isDraggingThis) {
                        if (Math.abs(delta) > 6) {
                            isDraggingThis = true;
                            barWindow.startModuleDrag("wifi", initialCoord);
                        }
                    }
                    if (isDraggingThis) {
                        barWindow.updateModuleDrag("wifi", initialCoord + delta);
                    }
                }

                onReleased: {
                    if (isDraggingThis) {
                        isDraggingThis = false;
                        barWindow.finishModuleDrag();
                    } else {
                        if (!PopoutManager.isDraggingAny) {
                            let centerCoord = PopoutManager.isVertical ? (modWifi.y + modWifi.height / 2) : (modWifi.x + modWifi.width / 2);
                            PopoutManager.toggle("wifi", centerCoord);
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
            implicitWidth: PopoutManager.isVertical ? 28 : (batRow.implicitWidth + 12)
            width: implicitWidth
            implicitHeight: PopoutManager.isVertical ? 28 : 24
            height: implicitHeight

            readonly property bool isBeingDragged: barWindow.draggingModName === modName
            readonly property bool isHovered: batMouse.containsMouse && !PopoutManager.isDraggingAny && !batMouse.pressed
            readonly property bool isActive: (batIndicator && batIndicator.isPopoutActive) || isHovered || isBeingDragged

            x: (!PopoutManager.isVertical && isBeingDragged) ? barWindow.dragCurrentX : barWindow.getSlotX(modName)
            y: (PopoutManager.isVertical && isBeingDragged) ? barWindow.dragCurrentY : barWindow.getSlotY(modName)

            Behavior on x {
                enabled: !PopoutManager.isVertical && !modBattery.isBeingDragged
                NumberAnimation {
                    duration: Theme.anim.fastSpatial
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.anim.expressiveDefaultSpatial
                }
            }
            Behavior on y {
                enabled: PopoutManager.isVertical && !modBattery.isBeingDragged
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
                        if (!batIndicator.hasBattery) return "󰚥";
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
                        if (!batIndicator.hasBattery) return Theme.primary;
                        return batIndicator.percentage <= 20 && batIndicator.status !== "Charging" ? Theme.danger : (batIndicator.status === "Charging" ? Theme.success : Theme.primary);
                    }
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }
                Text {
                    visible: !PopoutManager.isVertical && batIndicator && batIndicator.showPercentage
                    text: {
                        if (!batIndicator) return "0%";
                        if (!batIndicator.hasBattery) return "AC";
                        return batIndicator.percentage + "%";
                    }
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

                property real pressCoord: 0
                property real initialCoord: 0
                property bool isDraggingThis: false

                onPressed: mouse => {
                    let globalPt = mapToItem(barContent, mouse.x, mouse.y);
                    pressCoord = PopoutManager.isVertical ? globalPt.y : globalPt.x;
                    let m = modBattery;
                    if (PopoutManager.isVertical) {
                        initialCoord = m ? m.y : barWindow.getSlotY("battery");
                    } else {
                        initialCoord = m ? m.x : barWindow.getSlotX("battery");
                    }
                    isDraggingThis = false;
                }

                onPositionChanged: mouse => {
                    if (!pressed) return;
                    let globalPt = mapToItem(barContent, mouse.x, mouse.y);
                    let curCoord = PopoutManager.isVertical ? globalPt.y : globalPt.x;
                    let delta = curCoord - pressCoord;
                    if (!isDraggingThis) {
                        if (Math.abs(delta) > 6) {
                            isDraggingThis = true;
                            barWindow.startModuleDrag("battery", initialCoord);
                        }
                    }
                    if (isDraggingThis) {
                        barWindow.updateModuleDrag("battery", initialCoord + delta);
                    }
                }

                onReleased: {
                    if (isDraggingThis) {
                        isDraggingThis = false;
                        barWindow.finishModuleDrag();
                    } else {
                        if (!PopoutManager.isDraggingAny) {
                            let centerCoord = PopoutManager.isVertical ? (modBattery.y + modBattery.height / 2) : (modBattery.x + modBattery.width / 2);
                            PopoutManager.toggle("battery", centerCoord);
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
