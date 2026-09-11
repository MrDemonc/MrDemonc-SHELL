import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: themeModalWindow

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    WlrLayershell.namespace: "shell-theme-modal"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: PopoutManager.themeModalOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    visible: PopoutManager.themeModalOpen

    onVisibleChanged: {
        if (visible) {
            Theme.refresh();
            for (let i = 0; i < Theme.availableThemes.length; i++) {
                if (Theme.availableThemes[i].isCurrent || Theme.availableThemes[i].id === Theme.activeThemeId) {
                    carousel.currentIndex = i;
                    break;
                }
            }
        }
    }

    CoverFlowCarousel {
        id: carousel
        anchors.fill: parent
        items: Theme.availableThemes
        mode: "themes"

        onItemActivated: function(idx, item) {
            if (item && item.id) {
                Theme.applyTheme(item.id);
            }
            PopoutManager.themeModalOpen = false;
        }

        onCloseRequested: {
            PopoutManager.themeModalOpen = false;
        }

        onSwitchModeRequested: function(target) {
            PopoutManager.themeModalOpen = false;
            if (target === "wallpapers") {
                WallpaperManager.wallpaperModalOpen = true;
            }
        }

        onOpenFolderRequested: {
            PopoutManager.themeModalOpen = false;
            WallpaperManager.openFolder();
        }
    }
}
