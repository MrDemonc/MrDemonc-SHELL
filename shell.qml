import Quickshell
import QtQuick
import "./components"

ShellRoot {
    id: rootShell

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

    // 4. Modal flotante central de selección de temas
    Variants {
        model: Quickshell.screens

        delegate: Component {
            ThemeModal {
                required property var modelData
                screen: modelData
            }
        }
    }

    // 5. Modal flotante central de selección de fondos de pantalla (Wallpapers)
    Variants {
        model: Quickshell.screens

        delegate: Component {
            WallpaperModal {
                required property var modelData
                screen: modelData
            }
        }
    }

    // 6. Modal flotante de Búsqueda y Lanzador de Aplicaciones
    Variants {
        model: Quickshell.screens

        delegate: Component {
            AppLauncherModal {
                required property var modelData
                screen: modelData
            }
        }
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

    // 8. Modal flotante de Atajos de Teclado y Comandos del Sistema (SUPER + K)
    Variants {
        model: Quickshell.screens

        delegate: Component {
            KeybindsModal {
                required property var modelData
                screen: modelData
            }
        }
    }

    // 9. Modal flotante de Configuración de Pantallas y Monitores (SUPER + SHIFT + S)
    Variants {
        model: Quickshell.screens

        delegate: Component {
            MonitorModal {
                required property var modelData
                screen: modelData
            }
        }
    }

    // 10. Modal flotante de Selección y Búsqueda de Ubicación del Clima
    Variants {
        model: Quickshell.screens

        delegate: Component {
            WeatherLocationModal {
                required property var modelData
                screen: modelData
            }
        }
    }
}
