import QtQuick
import QtQuick.Layouts
import "./"

Row {
    id: root
    spacing: 8
    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

    property var audioItem: null
    property var btItem: null
    property var netItem: null
    property var batItem: null

    function getItem(name) {
        if (name === "audio") return audioItem;
        if (name === "bluetooth") return btItem;
        if (name === "wifi") return netItem;
        if (name === "battery") return batItem;
        return null;
    }

    Repeater {
        id: rep
        model: PopoutManager.indicatorOrder

        Item {
            id: slot
            required property string modelData
            required property int index

            readonly property var targetItem: root.getItem(modelData)
            width: targetItem ? targetItem.implicitWidth : 30
            height: 24

            // Re-parent el elemento indicador al slot correspondiente
            Binding {
                target: slot.targetItem
                property: "parent"
                value: slot
            }
        }
    }
}
