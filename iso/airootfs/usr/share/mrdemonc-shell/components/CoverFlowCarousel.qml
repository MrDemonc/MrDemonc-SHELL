import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell

Item {
    id: carouselRoot
    anchors.fill: parent

    property var items: []
    property int currentIndex: 0
    property string mode: "themes" // "themes" o "wallpapers"

    signal itemActivated(int index, var item)
    signal closeRequested()
    signal switchModeRequested(string targetMode)
    signal openFolderRequested()

    readonly property var currentItem: (items && items.length > currentIndex && currentIndex >= 0) ? items[currentIndex] : null

    function selectAdjacent(dir) {
        if (!items || items.length === 0) return;
        let next = currentIndex + dir;
        if (next < 0) next = 0;
        if (next >= items.length) next = items.length - 1;
        currentIndex = next;
    }

    // Captura de teclado
    Item {
        id: keyHandler
        anchors.fill: parent
        focus: true

        Keys.onLeftPressed: carouselRoot.selectAdjacent(-1)
        Keys.onRightPressed: carouselRoot.selectAdjacent(1)
        Keys.onTabPressed: function(event) {
            if (event.modifiers & Qt.ShiftModifier) {
                carouselRoot.selectAdjacent(-1);
            } else {
                carouselRoot.selectAdjacent(1);
            }
            event.accepted = true;
        }
        Keys.onBacktabPressed: carouselRoot.selectAdjacent(-1)
        Keys.onReturnPressed: {
            if (carouselRoot.currentItem) {
                carouselRoot.itemActivated(carouselRoot.currentIndex, carouselRoot.currentItem);
            }
        }
        Keys.onSpacePressed: {
            if (carouselRoot.currentItem) {
                carouselRoot.itemActivated(carouselRoot.currentIndex, carouselRoot.currentItem);
            }
        }
        Keys.onEscapePressed: {
            carouselRoot.closeRequested();
        }

        Component.onCompleted: forceActiveFocus()
    }

    // Fondo oscurecido con click para cerrar
    Rectangle {
        id: scrim
        anchors.fill: parent
        color: "#000000"
        opacity: 0.78

        MouseArea {
            anchors.fill: parent
            onClicked: carouselRoot.closeRequested()
        }
    }

    // =========================================================================
    // 1. BARRA FLOTANTE SUPERIOR ESTILO PILL (idéntica a la imagen de referencia)
    // =========================================================================
    Rectangle {
        id: topPill
        anchors.top: parent.top
        anchors.topMargin: 36
        anchors.horizontalCenter: parent.horizontalCenter
        implicitHeight: 44
        implicitWidth: pillLayout.implicitWidth + 24
        radius: 22
        color: Theme.bgSurface
        border.color: Theme.border
        border.width: 1
        z: 3000

        RowLayout {
            id: pillLayout
            anchors.centerIn: parent
            spacing: 10

            // Nombre del item activo destacado
            Rectangle {
                implicitHeight: 28
                implicitWidth: nameText.implicitWidth + 20
                radius: 14
                color: Theme.bgHover
                border.color: Theme.primary
                border.width: 1

                Text {
                    id: nameText
                    anchors.centerIn: parent
                    text: carouselRoot.currentItem ? (carouselRoot.currentItem.name || carouselRoot.currentItem.id || "Predeterminado") : "Sin selección"
                    color: Theme.primary
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.bold: true
                }
            }

            // Pestaña Temas
            Rectangle {
                implicitHeight: 28
                implicitWidth: 32
                radius: 8
                color: carouselRoot.mode === "themes" ? Theme.primary : (themesTabMouse.containsMouse ? Theme.bgHover : "transparent")

                Text {
                    anchors.centerIn: parent
                    text: "󰔎"
                    color: carouselRoot.mode === "themes" ? Theme.bg : Theme.text
                    font.family: Theme.iconFontFamily
                    font.pixelSize: 14
                }

                MouseArea {
                    id: themesTabMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: carouselRoot.switchModeRequested("themes")
                }
            }

            // Pestaña Wallpapers
            Rectangle {
                implicitHeight: 28
                implicitWidth: 32
                radius: 8
                color: carouselRoot.mode === "wallpapers" ? Theme.primary : (wallTabMouse.containsMouse ? Theme.bgHover : "transparent")

                Text {
                    anchors.centerIn: parent
                    text: "󰸉"
                    color: carouselRoot.mode === "wallpapers" ? Theme.bg : Theme.text
                    font.family: Theme.iconFontFamily
                    font.pixelSize: 14
                }

                MouseArea {
                    id: wallTabMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: carouselRoot.switchModeRequested("wallpapers")
                }
            }

            // Botón Abrir Carpeta
            Rectangle {
                implicitHeight: 28
                implicitWidth: 32
                radius: 8
                color: folderMouse.containsMouse ? Theme.bgHover : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: ""
                    color: folderMouse.containsMouse ? Theme.primary : Theme.subtext
                    font.family: Theme.iconFontFamily
                    font.pixelSize: 13
                }

                MouseArea {
                    id: folderMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: carouselRoot.openFolderRequested()
                }
            }

            // Separador
            Rectangle {
                implicitWidth: 1
                implicitHeight: 18
                color: Theme.border
            }

            // Paleta de colores del tema activo
            Row {
                spacing: 6
                visible: carouselRoot.mode === "themes" && carouselRoot.currentItem

                Repeater {
                    model: [
                        carouselRoot.currentItem ? carouselRoot.currentItem.primary : "#88c0d0",
                        carouselRoot.currentItem ? carouselRoot.currentItem.cyan : "#81a1c1",
                        carouselRoot.currentItem ? carouselRoot.currentItem.success : "#a3be8c",
                        carouselRoot.currentItem ? carouselRoot.currentItem.warning : "#ebcb8b",
                        carouselRoot.currentItem ? carouselRoot.currentItem.danger : "#bf616a",
                        carouselRoot.currentItem ? carouselRoot.currentItem.pink : "#b48ead"
                    ]
                    delegate: Rectangle {
                        width: 14
                        height: 14
                        radius: 4
                        color: modelData || "transparent"
                        border.color: "#30ffffff"
                        border.width: 1
                    }
                }
            }

            // Botón Cerrar
            Rectangle {
                implicitHeight: 28
                implicitWidth: 28
                radius: 14
                color: closeMouse.containsMouse ? Theme.danger : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: closeMouse.containsMouse ? "#ffffff" : Theme.subtext
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.bold: true
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: carouselRoot.closeRequested()
                }
            }
        }
    }

    // =========================================================================
    // 2. CARRUSEL CON RECTÁNGULOS INCLINADOS Y GEOMETRÍA EXACTA DE OMARCHY
    // =========================================================================
    Item {
        id: carouselArea
        anchors.centerIn: parent
        width: Math.min(carouselRoot.width - 40, expandedWidth + 14 * (sliceWidth + sliceSpacing) + 40)
        height: expandedHeight + 70
        clip: false

        // Parámetros oficiales de escala Omarchy
        readonly property int expandedWidth: Math.min(768, Math.max(480, carouselRoot.width - 160))
        readonly property int expandedHeight: Math.round(expandedWidth * 475 / 768)
        readonly property int sliceWidth: 108
        readonly property int sliceHeight: Math.round(expandedHeight * 432 / 475)
        readonly property int sliceSpacing: -30
        readonly property int skewOffset: 28

        readonly property real itemStep: sliceWidth + sliceSpacing
        readonly property real previewX: (width - expandedWidth) / 2

        // Rueda del ratón para desplazamiento horizontal
        WheelHandler {
            target: carouselArea
            onWheel: event => {
                if (event.angleDelta.y < 0 || event.angleDelta.x > 0) {
                    carouselRoot.selectAdjacent(1);
                } else if (event.angleDelta.y > 0 || event.angleDelta.x < 0) {
                    carouselRoot.selectAdjacent(-1);
                }
            }
        }

        // Renderizado de las rebanadas inclinadas
        Repeater {
            model: carouselRoot.items.length

            delegate: Item {
                id: sliceItem
                required property int index

                readonly property var itemData: (carouselRoot.items && carouselRoot.items.length > index) ? carouselRoot.items[index] : null
                readonly property int relativeIndex: index - carouselRoot.currentIndex
                readonly property bool selected: relativeIndex === 0
                readonly property bool nearby: Math.abs(relativeIndex) <= 16

                visible: nearby

                // Posicionamiento horizontal según la fórmula matemática de Omarchy
                x: selected
                    ? carouselArea.previewX
                    : (relativeIndex < 0
                        ? carouselArea.previewX + relativeIndex * carouselArea.itemStep
                        : carouselArea.previewX + carouselArea.expandedWidth + carouselArea.sliceSpacing + (relativeIndex - 1) * carouselArea.itemStep)

                width: selected ? carouselArea.expandedWidth : carouselArea.sliceWidth
                height: selected ? carouselArea.expandedHeight : carouselArea.sliceHeight
                y: selected ? 0 : (carouselArea.expandedHeight - carouselArea.sliceHeight) / 2
                z: selected ? 100 : 50 - Math.min(Math.abs(relativeIndex), 40)

                Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                // Vértices del paralelogramo inclinado Omarchy
                readonly property real skAbs: Math.abs(carouselArea.skewOffset)
                readonly property real topLeft: carouselArea.skewOffset >= 0 ? skAbs : 0
                readonly property real topRight: carouselArea.skewOffset >= 0 ? width : width - skAbs
                readonly property real bottomRight: carouselArea.skewOffset >= 0 ? width - skAbs : width
                readonly property real bottomLeft: carouselArea.skewOffset >= 0 ? 0 : skAbs

                // Máscara geométrica del paralelogramo
                Item {
                    id: maskShape
                    anchors.fill: parent
                    visible: false
                    layer.enabled: true

                    Shape {
                        anchors.fill: parent
                        antialiasing: true
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            fillColor: "white"
                            strokeColor: "transparent"
                            startX: sliceItem.topLeft; startY: 0
                            PathLine { x: sliceItem.topRight; y: 0 }
                            PathLine { x: sliceItem.bottomRight; y: sliceItem.height }
                            PathLine { x: sliceItem.bottomLeft; y: sliceItem.height }
                            PathLine { x: sliceItem.topLeft; y: 0 }
                        }
                    }
                }

                // Contenido recortado con efecto MultiEffect
                Item {
                    anchors.fill: parent
                    layer.enabled: true
                    layer.smooth: true
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: maskShape
                        maskThresholdMin: 0.3
                        maskSpreadAtMin: 0.3
                    }

                    // Fondo de la rebanada
                    Rectangle {
                        anchors.fill: parent
                        color: Theme.bgSurface
                    }

                    // Imagen del wallpaper
                    Image {
                        id: sliceImage
                        anchors.fill: parent
                        source: {
                            if (!itemData) return "";
                            let p = itemData.wallpaperPath || itemData.path || "";
                            if (!p) return "";
                            return p.startsWith("/") ? ("file://" + p) : p;
                        }
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        smooth: true
                    }

                    // Atenuación de las imágenes en segundo plano (para elevar el elemento central)
                    Rectangle {
                        anchors.fill: parent
                        color: sliceItem.selected ? "transparent" : "#aa14161d"
                        Behavior on color { ColorAnimation { duration: 160 } }
                    }
                }

                // Resplandor exterior estilo Hyprland ventana activa
                Shape {
                    visible: sliceItem.selected
                    anchors.fill: parent
                    anchors.margins: -4
                    antialiasing: true
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        fillColor: "transparent"
                        strokeColor: Theme.cyan
                        strokeWidth: 2
                        startX: sliceItem.topLeft; startY: 0
                        PathLine { x: sliceItem.topRight + 8; y: 0 }
                        PathLine { x: sliceItem.bottomRight + 8; y: sliceItem.height + 8 }
                        PathLine { x: sliceItem.bottomLeft; y: sliceItem.height + 8 }
                        PathLine { x: sliceItem.topLeft; y: 0 }
                    }
                    opacity: 0.45
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                }

                // Marco principal estilo Hyprland (active_border 3px / inactive_border 1px)
                Shape {
                    anchors.fill: parent
                    antialiasing: true
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        fillColor: "transparent"
                        strokeColor: sliceItem.selected ? Theme.primary : "#35ffffff"
                        strokeWidth: sliceItem.selected ? 3 : 1
                        startX: sliceItem.topLeft; startY: 0
                        PathLine { x: sliceItem.topRight; y: 0 }
                        PathLine { x: sliceItem.bottomRight; y: sliceItem.height }
                        PathLine { x: sliceItem.bottomLeft; y: sliceItem.height }
                        PathLine { x: sliceItem.topLeft; y: 0 }
                    }
                }

                // Interacción ratón: click para seleccionar o aplicar
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (sliceItem.selected) {
                            carouselRoot.itemActivated(sliceItem.index, itemData);
                        } else {
                            carouselRoot.currentIndex = sliceItem.index;
                        }
                    }
                }
            }
        }

        // Título del elemento seleccionado debajo del carrusel (estilo Omarchy)
        ColumnLayout {
            anchors.top: carouselArea.top
            anchors.topMargin: carouselArea.expandedHeight + 16
            anchors.horizontalCenter: parent.horizontalCenter
            width: carouselArea.expandedWidth
            spacing: 3

            Text {
                text: carouselRoot.currentItem ? (carouselRoot.currentItem.name || carouselRoot.currentItem.id || "Predeterminado") : ""
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 15
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Text {
                text: {
                    if (!carouselRoot.currentItem) return "";
                    if (carouselRoot.mode === "themes") {
                        return carouselRoot.currentItem.author ? ("Tema por " + carouselRoot.currentItem.author) : "Tema de Quickshell";
                    } else {
                        return carouselRoot.currentItem.size ? (carouselRoot.currentItem.size + " • Fondo de pantalla") : "Fondo de pantalla";
                    }
                }
                color: Theme.subtext
                font.family: Theme.fontFamily
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }
    }
}
