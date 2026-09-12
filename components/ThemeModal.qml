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

    function syncCurrentIndex() {
        if (!Theme.availableThemes || Theme.availableThemes.length === 0) return;
        let targetId = Theme.activeThemeId;
        for (let i = 0; i < Theme.availableThemes.length; i++) {
            if (Theme.availableThemes[i].id === targetId) {
                carousel.currentIndex = i;
                return;
            }
        }
        for (let j = 0; j < Theme.availableThemes.length; j++) {
            if (Theme.availableThemes[j].isCurrent) {
                carousel.currentIndex = j;
                return;
            }
        }
    }

    onVisibleChanged: {
        console.log("THEME MODAL onVisibleChanged:", visible, "activeThemeId:", Theme.activeThemeId, "currentIndex:", carousel.currentIndex);
        if (visible) {
            syncCurrentIndex();
            Theme.refresh();
        }
    }

    Connections {
        target: Theme
        function onAvailableThemesChanged() {
            if (themeModalWindow.visible) {
                themeModalWindow.syncCurrentIndex();
            }
        }
        function onActiveThemeIdChanged() {
            if (themeModalWindow.visible) {
                themeModalWindow.syncCurrentIndex();
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
                carousel.currentIndex = idx;
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
