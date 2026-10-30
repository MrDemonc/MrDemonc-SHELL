import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

PanelWindow {
    id: deskWindow

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    margins {
        top: PopoutManager.barPosition === "top" ? 30 : 8
        bottom: PopoutManager.barPosition === "bottom" ? 30 : 8
        left: PopoutManager.barPosition === "left" ? 30 : 8
        right: PopoutManager.barPosition === "right" ? 30 : 8
    }

    color: "transparent"

    WlrLayershell.namespace: "shell-desktop"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    visible: DesktopManager.enabled

    property string selectedId: ""
    property bool contextMenuOpen: false
    property real menuX: 0
    property real menuY: 0
    property var contextTargetItem: null

    // Clic en fondo vacío del escritorio: deseleccionar y cerrar menú contextual
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                deskWindow.contextTargetItem = null;
                deskWindow.menuX = Math.min(deskWindow.width - 210, mouse.x);
                deskWindow.menuY = Math.min(deskWindow.height - 150, mouse.y);
                deskWindow.contextMenuOpen = true;
            } else {
                deskWindow.selectedId = "";
                deskWindow.contextMenuOpen = false;
            }
        }
    }

    // Contenedor de iconos en cuadrícula fluida (Top to Bottom, en columnas de izquierda a derecha)
    Item {
        anchors.fill: parent
        anchors.margins: 14

        Flow {
            id: flowLayout
            anchors.fill: parent
            flow: Flow.TopToBottom
            spacing: 10

            Repeater {
                model: DesktopManager.desktopItems

                delegate: Rectangle {
                    id: iconCard
                    readonly property var itemData: modelData
                    readonly property bool isSelected: deskWindow.selectedId === itemData.id
                    readonly property bool isHovered: itemMouse.containsMouse

                    width: Math.max(78, DesktopManager.iconSize + 32)
                    height: DesktopManager.iconSize + 48
                    radius: Theme.radiusSmall

                    color: isSelected ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.28) :
                           (isHovered ? Qt.rgba(Theme.bgSurface.r, Theme.bgSurface.g, Theme.bgSurface.b, 0.45) : "transparent")
                    border.color: isSelected ? Theme.primary : (isHovered ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3) : "transparent")
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 4

                        // Icono
                        Item {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: DesktopManager.iconSize
                            Layout.preferredHeight: DesktopManager.iconSize

                            Image {
                                id: imgIcon
                                anchors.centerIn: parent
                                width: DesktopManager.iconSize
                                height: DesktopManager.iconSize
                                sourceSize: Qt.size(DesktopManager.iconSize, DesktopManager.iconSize)
                                source: itemData.icon ? ("file://" + itemData.icon) : ""
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                asynchronous: true
                                visible: status === Image.Ready
                            }

                            // Fallback glyph si la imagen no carga o no existe
                            Text {
                                anchors.centerIn: parent
                                visible: imgIcon.status !== Image.Ready
                                text: {
                                    if (itemData.type === "trash") return "󰩹";
                                    if (itemData.type === "drive") return "󰋊";
                                    if (itemData.type === "folder") return "󰉋";
                                    return "󰏖";
                                }
                                color: Theme.primary
                                font.family: Theme.iconFontFamily
                                font.pixelSize: Math.round(DesktopManager.iconSize * 0.72)
                            }
                        }

                        // Etiqueta de texto con fondo sutil para máxima legibilidad sobre cualquier fondo
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: textLabel.contentHeight + 4
                            radius: 4
                            color: iconCard.isSelected ? Theme.primary : Qt.rgba(0, 0, 0, 0.45)

                            Text {
                                id: textLabel
                                anchors.centerIn: parent
                                width: parent.width - 6
                                text: itemData.name || ""
                                color: "#ffffff"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideMiddle
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                            }
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                        onClicked: function(mouse) {
                            if (mouse.button === Qt.RightButton) {
                                deskWindow.selectedId = itemData.id;
                                deskWindow.contextTargetItem = itemData;
                                deskWindow.menuX = Math.min(deskWindow.width - 210, mouse.x + iconCard.x + 14);
                                deskWindow.menuY = Math.min(deskWindow.height - 180, mouse.y + iconCard.y + 14);
                                deskWindow.contextMenuOpen = true;
                            } else {
                                deskWindow.contextMenuOpen = false;
                                deskWindow.selectedId = itemData.id;
                            }
                        }

                        onDoubleClicked: function(mouse) {
                            if (mouse.button === Qt.LeftButton) {
                                deskWindow.contextMenuOpen = false;
                                DesktopManager.launchItem(itemData);
                            }
                        }
                    }
                }
            }
        }
    }

    // =========================================================
    // MENÚ CONTEXTUAL DEL ESCRITORIO / ICONOS
    // =========================================================
    Rectangle {
        id: menuCard
        visible: deskWindow.contextMenuOpen
        x: deskWindow.menuX
        y: deskWindow.menuY
        width: 200
        height: menuCol.implicitHeight + 12
        radius: Theme.radiusSmall
        color: Theme.bgSurface
        border.color: Theme.border
        border.width: 1
        z: 99

        ColumnLayout {
            id: menuCol
            anchors.fill: parent
            anchors.margins: 6
            spacing: 2

            // Si se hizo clic en un elemento concreto
            Repeater {
                model: deskWindow.contextTargetItem ? [
                    { id: "open", label: "Abrir", icon: "󰅩" },
                    ...(deskWindow.contextTargetItem.type === "trash" ? [{ id: "empty_trash", label: "Vaciar papelera", icon: "󰩹" }] : []),
                    ...(deskWindow.contextTargetItem.type === "drive" ? [{ id: "unmount", label: "Expulsar dispositivo", icon: "󰚥" }] : []),
                    ...(deskWindow.contextTargetItem.type === "folder" ? [{ id: "open_terminal", label: "Abrir en Terminal", icon: "󰞷" }] : []),
                    ...(deskWindow.contextTargetItem.type === "app" && deskWindow.contextTargetItem.id.indexOf("app_") === 0 ? [{ id: "remove_shortcut", label: "Quitar acceso directo", icon: "󰅖" }] : [])
                ] : [
                    { id: "open_terminal_desk", label: "Abrir Terminal aquí", icon: "󰞷" },
                    { id: "open_files_desk", label: "Abrir Archivos", icon: "󰉋" }
                ]

                delegate: Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 28
                    radius: Theme.radiusSmall - 2
                    color: itemMouseArea.containsMouse ? Theme.bgHover : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        Text {
                            text: modelData.icon
                            color: Theme.primary
                            font.family: Theme.iconFontFamily
                            font.pixelSize: 12
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.label
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: itemMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            deskWindow.contextMenuOpen = false;
                            let action = modelData.id;
                            let target = deskWindow.contextTargetItem;

                            if (action === "open" && target) {
                                DesktopManager.launchItem(target);
                            } else if (action === "empty_trash") {
                                DesktopManager.emptyTrash();
                            } else if (action === "unmount" && target) {
                                DesktopManager.unmountDrive(target.path);
                            } else if (action === "open_terminal" && target) {
                                DesktopManager.launchItem({ exec: "kitty --directory \"" + target.path + "\"", terminal: false });
                            } else if (action === "remove_shortcut" && target) {
                                let appId = target.id.substring(4);
                                DesktopManager.toggleApp(appId);
                            } else if (action === "open_terminal_desk") {
                                DesktopManager.launchItem({ exec: "kitty", terminal: false });
                            } else if (action === "open_files_desk") {
                                DesktopManager.launchItem({ exec: "nautilus", terminal: false });
                            }
                        }
                    }
                }
            }

            // Separador
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 2
                Layout.bottomMargin: 2
                height: 1
                color: Theme.border
            }

            // Opción fija: Configuración de Escritorio
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 28
                radius: Theme.radiusSmall - 2
                color: configMouseArea.containsMouse ? Theme.bgHover : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8

                    Text {
                        text: "󰒓"
                        color: Theme.primary
                        font.family: Theme.iconFontFamily
                        font.pixelSize: 12
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Ajustes del Escritorio..."
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.bold: true
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: configMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        deskWindow.contextMenuOpen = false;
                        ControlCenterManager.open("desktop");
                    }
                }
            }
        }
    }
}
