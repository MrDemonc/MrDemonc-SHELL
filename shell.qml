import Quickshell
import QtQuick
import Quickshell.Hyprland
import "./components"

ShellRoot {
    id: rootShell

    // Asegurar inicialización inmediata de singletons con procesos en segundo plano
    property var _recMgr: ScreenRecordManager
    property var _pickerMgr: ColorPickerManager
    property var _caffMgr: CaffeineManager
    property var _lockMgr: LockScreenManager
    property var _osdMgr: OsdManager
    property var _powerMgr: PowerManager
    property var _monitorMgr: MonitorManager
    property var _keybindsMgr: KeybindsManager
    property var _controlCenterMgr: ControlCenterManager
    property var _calendarMgr: CalendarManager

    // Pantalla activa / enfocada actualmente por Hyprland (con fallback seguro a la primera pantalla disponible)
    readonly property var focusedScreen: {
        let focusedName = (Hyprland.focusedMonitor && Hyprland.focusedMonitor.name) ? Hyprland.focusedMonitor.name : "";
        if (focusedName !== "") {
            for (let i = 0; i < Quickshell.screens.length; i++) {
                if (Quickshell.screens[i].name === focusedName) {
                    return Quickshell.screens[i];
                }
            }
        }
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }

    // 1. Fondo de pantalla integrado por pantalla
    Variants {
        model: Quickshell.screens

        delegate: Component {
            WallpaperWindow {
                required property var modelData
                screen: modelData
            }
        }
    }

    // 2. Barra superior física fija (26px) instanciada en cada pantalla activa
    Variants {
        model: Quickshell.screens

        delegate: Component {
            BarPanel {
                required property var modelData
                screen: modelData
            }
        }
    }

    // 3.0 Scrim transparente para cerrar popout al hacer clic fuera
    Variants {
        model: Quickshell.screens

        delegate: Component {
            PopoutScrim {
                required property var modelData
                screen: modelData
            }
        }
    }

    // 3. Overlay desplegable fluido (Liquid Popout)
    Variants {
        model: Quickshell.screens

        delegate: Component {
            PopoutPanel {
                required property var modelData
                screen: modelData
            }
        }
    }

    // 4. Modal flotante central de selección de temas (Enfocado en pantalla activa)
    ThemeModal {
        screen: rootShell.focusedScreen
    }

    // 5. Modal flotante central de selección de fondos de pantalla (Enfocado en pantalla activa)
    WallpaperModal {
        screen: rootShell.focusedScreen
    }

    // 6. Modal flotante de Búsqueda y Lanzador de Aplicaciones (Enfocado en pantalla activa)
    AppLauncherModal {
        screen: rootShell.focusedScreen
    }

    // 7. Guía visual de acoplamiento de la barra al arrastrar
    Variants {
        model: Quickshell.screens

        delegate: Component {
            BarDockGuide {
                required property var modelData
                screen: modelData
            }
        }
    }

    // 7.1 Menú contextual para mover la barra
    Variants {
        model: Quickshell.screens

        delegate: Component {
            BarContextMenu {
                required property var modelData
                screen: modelData
            }
        }
    }

    // 8. Modal flotante de Atajos de Teclado y Comandos del Sistema (SUPER + K)
    KeybindsModal {
        screen: rootShell.focusedScreen
    }

    // 9. Modal flotante de Configuración de Pantallas y Monitores (SUPER + SHIFT + S)
    MonitorModal {
        screen: rootShell.focusedScreen
    }

    // 10. Modal flotante de Selección y Búsqueda de Ubicación del Clima
    WeatherLocationModal {
        screen: rootShell.focusedScreen
    }

    // 11. Modal flotante de Menú de Energía y Apagado (SUPER + ESC)
    PowerModal {
        screen: rootShell.focusedScreen
    }

    // 12. Banners flotantes de Notificaciones (Toasts emergentes en pantalla activa)
    NotificationPopups {
        screen: rootShell.focusedScreen
    }

    // 13. Panel lateral del Centro de Notificaciones (SUPER + N en pantalla activa)
    NotificationSidebar {
        screen: rootShell.focusedScreen
    }

    // 14. Menú contextual emergente para apps del Tray (Clic derecho)
    Variants {
        model: Quickshell.screens

        delegate: Component {
            TrayContextMenu {
                required property var modelData
                screen: modelData
            }
        }
    }

    // 15. Modal flotante de Grabación de Pantalla (SUPER + SHIFT + R)
    ScreenRecordModal {
        screen: rootShell.focusedScreen
    }

    // 16. Modal flotante de Cuentagotas / Selector de Color (SUPER + SHIFT + P)
    ColorPickerModal {
        screen: rootShell.focusedScreen
    }

    // 17. Pantalla de Bloqueo Nativa Quickshell (SUPER + L / Inactividad)
    LockScreen {}

    // 18. Indicador OSD de Volumen y Brillo (en pantalla activa)
    OsdModal {
        screen: rootShell.focusedScreen
    }

    // 19. Centro de Control Flotante del Sistema (SUPER + I en pantalla activa)
    ControlCenterModal {
        screen: rootShell.focusedScreen
    }

    // 20. Modal flotante de Calendario y Reloj (SUPER + ALT en pantalla activa)
    CalendarModal {
        screen: rootShell.focusedScreen
    }
}
