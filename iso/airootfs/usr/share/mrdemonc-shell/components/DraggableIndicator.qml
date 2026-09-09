import QtQuick
import QtQuick.Layouts
import "./"

Item {
    id: root

    property string indicatorType: ""
    property int indexInBar: 0
    property var indicatorItem: null

    implicitWidth: indicatorItem ? indicatorItem.implicitWidth : 30
    implicitHeight: 24

    readonly property bool isDragging: dragArea.drag.active

    onIsDraggingChanged: {
        PopoutManager.isDraggingAny = isDragging;
        if (isDragging) {
            PopoutManager.close();
        }
    }

    // Contenedor visual animado al reordenar
    Item {
        id: visualContent
        width: root.width
        height: root.height

        Drag.active: dragArea.drag.active
        Drag.source: root
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2

        scale: root.isDragging ? 1.08 : 1.0
        opacity: root.isDragging ? 0.9 : 1.0
        z: root.isDragging ? 99 : 1

        Behavior on scale {
            NumberAnimation {
                duration: Theme.anim.fastSpatial
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.anim.expressiveFastSpatial
            }
        }
        Behavior on opacity {
            NumberAnimation { duration: Theme.anim.fastEffects }
        }

        children: [root.indicatorItem]

        MouseArea {
            id: dragArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: root.isDragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor
            drag.target: visualContent
            drag.axis: Drag.XAxis
            drag.minimumX: -300
            drag.maximumX: 300

            property bool pressAndHoldTriggered: false
            property real startGlobalX: 0

            onPressed: mouse => {
                pressAndHoldTriggered = false;
                startGlobalX = mapToGlobal(mouse.x, mouse.y).x;
            }

            onPressAndHold: {
                pressAndHoldTriggered = true;
                PopoutManager.close();
            }

            onPositionChanged: mouse => {
                if (drag.active) {
                    let globalX = mapToGlobal(mouse.x, mouse.y).x;
                    // Detectar si se cruza con elementos vecinos en el ListView/Row
                    let parentView = root.parent;
                    while (parentView && !parentView.count && parentView.parent) {
                        parentView = parentView.parent;
                    }
                    if (parentView && parentView.count) {
                        for (let i = 0; i < parentView.count; i++) {
                            if (i === root.indexInBar) continue;
                            let item = parentView.itemAtIndex ? parentView.itemAtIndex(i) : null;
                            if (item) {
                                let itemGlobalPos = item.mapToGlobal(0, 0);
                                let itemWidth = item.width;
                                if (globalX >= itemGlobalPos.x && globalX <= itemGlobalPos.x + itemWidth) {
                                    PopoutManager.moveIndicator(root.indexInBar, i);
                                    break;
                                }
                            }
                        }
                    }
                }
            }

            onReleased: {
                if (drag.active) {
                    visualContent.x = 0;
                    visualContent.y = 0;
                }
                pressAndHoldTriggered = false;
            }

            onEntered: {
                if (!dragArea.pressed && !PopoutManager.isDraggingAny) {
                    PopoutManager.open(root.indicatorType);
                }
            }

            onClicked: {
                if (!pressAndHoldTriggered) {
                    if (PopoutManager.activePopout === root.indicatorType) {
                        PopoutManager.close();
                    } else {
                        PopoutManager.open(root.indicatorType);
                    }
                }
            }

            onWheel: wheel => {
                if (root.indicatorType === "audio" && root.indicatorItem && root.indicatorItem.handleWheel) {
                    root.indicatorItem.handleWheel(wheel);
                }
            }
        }
    }
}
