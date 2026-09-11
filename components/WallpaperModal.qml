import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: wallpaperModalWindow

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    WlrLayershell.namespace: "shell-wallpaper-modal"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WallpaperManager.wallpaperModalOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    visible: WallpaperManager.wallpaperModalOpen

    onVisibleChanged: {
        if (visible) {
            WallpaperManager.refreshList();
            for (let i = 0; i < WallpaperManager.availableWallpapers.length; i++) {
                if (WallpaperManager.availableWallpapers[i].path === WallpaperManager.currentWallpaper) {
                    carousel.currentIndex = i;
                    break;
                }
            }
        }
    }

    CoverFlowCarousel {
        id: carousel
        anchors.fill: parent
        items: WallpaperManager.availableWallpapers
        mode: "wallpapers"

        onItemActivated: function(idx, item) {
            if (item && item.path) {
                WallpaperManager.setWallpaper(item.path);
            }
            WallpaperManager.wallpaperModalOpen = false;
        }

        onCloseRequested: {
            WallpaperManager.wallpaperModalOpen = false;
        }

        onSwitchModeRequested: function(target) {
            WallpaperManager.wallpaperModalOpen = false;
            if (target === "themes") {
                PopoutManager.themeModalOpen = true;
            }
        }

        onOpenFolderRequested: {
            WallpaperManager.wallpaperModalOpen = false;
            WallpaperManager.openFolder();
        }
    }
}
