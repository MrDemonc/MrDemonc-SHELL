#!/usr/bin/env python3
import os
import json
import sys

THEMES_DIR = os.path.expanduser("~/.config/quickshell/themes")
CONFIG_FILE = os.path.expanduser("~/.config/quickshell/current_theme.json")

BUILTIN_THEMES = {
    "catppuccin-mocha": {
        "name": "Catppuccin Mocha",
        "description": "Paleta relajante pastel de alto contraste para la noche",
        "author": "Catppuccin Org",
        "isDark": True,
        "bg": "#1e1e2e",
        "bgSurface": "#181825",
        "bgHover": "#313244",
        "border": "#45475a",
        "text": "#cdd6f4",
        "subtext": "#a6adc8",
        "overlay": "#6c7086",
        "primary": "#89b4fa",
        "success": "#a6e3a1",
        "warning": "#f9e2af",
        "danger": "#f38ba8",
        "cyan": "#89dceb",
        "pink": "#f5c2e7"
    },
    "catppuccin-latte": {
        "name": "Catppuccin Latte",
        "description": "Edición diurna cálida y limpia de Catppuccin",
        "author": "Catppuccin Org",
        "isDark": False,
        "bg": "#eff1f5",
        "bgSurface": "#e6e9ef",
        "bgHover": "#ccd0da",
        "border": "#bcc0cc",
        "text": "#4c4f69",
        "subtext": "#6c6f85",
        "overlay": "#9ca0b0",
        "primary": "#1e66f5",
        "success": "#40a02b",
        "warning": "#df8e1d",
        "danger": "#d20f39",
        "cyan": "#04a5e5",
        "pink": "#ea76cb"
    },
    "tokyo-night": {
        "name": "Tokyo Night",
        "description": "Inspirado en las luces de neón del centro de Tokio",
        "author": "Enkelt",
        "isDark": True,
        "bg": "#1a1b26",
        "bgSurface": "#16161e",
        "bgHover": "#292e42",
        "border": "#3b4261",
        "text": "#c0caf5",
        "subtext": "#a9b1d6",
        "overlay": "#565f89",
        "primary": "#7aa2f7",
        "success": "#9ece6a",
        "warning": "#e0af68",
        "danger": "#f7768e",
        "cyan": "#7dcfff",
        "pink": "#bb9af7"
    },
    "tokyo-night-light": {
        "name": "Tokyo Night Light",
        "description": "Variante diurna de Tokio con tonos azules y plata",
        "author": "Enkelt",
        "isDark": False,
        "bg": "#e1e2e7",
        "bgSurface": "#d5d6db",
        "bgHover": "#cfc9c2",
        "border": "#b4b5b9",
        "text": "#3760bf",
        "subtext": "#6172b0",
        "overlay": "#8990b3",
        "primary": "#2e7de9",
        "success": "#587539",
        "warning": "#8c6c3e",
        "danger": "#f52a65",
        "cyan": "#007197",
        "pink": "#9854f1"
    },
    "nord": {
        "name": "Nord",
        "description": "Paleta ártica elegante basada en tonos fríos nórdicos",
        "author": "Arctic Ice Studio",
        "isDark": True,
        "bg": "#2e3440",
        "bgSurface": "#242933",
        "bgHover": "#3b4252",
        "border": "#434c5e",
        "text": "#eceff4",
        "subtext": "#e5e9f0",
        "overlay": "#7b88a1",
        "primary": "#88c0d0",
        "success": "#a3be8c",
        "warning": "#ebcb8b",
        "danger": "#bf616a",
        "cyan": "#81a1c1",
        "pink": "#b48ead"
    },
    "nord-light": {
        "name": "Nord Light",
        "description": "La serenidad de la nieve y el hielo nórdico en modo claro",
        "author": "Arctic Ice Studio",
        "isDark": False,
        "bg": "#eceff4",
        "bgSurface": "#e5e9f0",
        "bgHover": "#d8dee9",
        "border": "#c8d0de",
        "text": "#2e3440",
        "subtext": "#3b4252",
        "overlay": "#7b88a1",
        "primary": "#5e81ac",
        "success": "#4c566a",
        "warning": "#d08770",
        "danger": "#bf616a",
        "cyan": "#88c0d0",
        "pink": "#b48ead"
    },
    "gruvbox-dark": {
        "name": "Gruvbox Dark",
        "description": "Tono retro cálido con contraste suave y acentos tierra",
        "author": "morhetz",
        "isDark": True,
        "bg": "#282828",
        "bgSurface": "#1d2021",
        "bgHover": "#3c3836",
        "border": "#504945",
        "text": "#ebdbb2",
        "subtext": "#d5c4a1",
        "overlay": "#928374",
        "primary": "#d79921",
        "success": "#b8bb26",
        "warning": "#fabd2f",
        "danger": "#fb4934",
        "cyan": "#83a598",
        "pink": "#d3869b"
    },
    "gruvbox-light": {
        "name": "Gruvbox Light",
        "description": "Pergamino cálido retro con acentos rojizos y dorados",
        "author": "morhetz",
        "isDark": False,
        "bg": "#fbf1c7",
        "bgSurface": "#f2e5bc",
        "bgHover": "#ebdbb2",
        "border": "#d5c4a1",
        "text": "#282828",
        "subtext": "#3c3836",
        "overlay": "#7c6f64",
        "primary": "#b57614",
        "success": "#79740e",
        "warning": "#af3a03",
        "danger": "#9d0006",
        "cyan": "#427b58",
        "pink": "#8f3f71"
    },
    "rose-pine": {
        "name": "Rosé Pine",
        "description": "Elegancia minimalista con matices florales y vintage",
        "author": "Rosé Pine",
        "isDark": True,
        "bg": "#191724",
        "bgSurface": "#1f1d2e",
        "bgHover": "#26233a",
        "border": "#403d52",
        "text": "#e0def4",
        "subtext": "#908caa",
        "overlay": "#6e6a86",
        "primary": "#ebbcba",
        "success": "#9ccfd8",
        "warning": "#f6c177",
        "danger": "#eb6f92",
        "cyan": "#31748f",
        "pink": "#c4a7e7"
    },
    "rose-pine-dawn": {
        "name": "Rosé Pine Dawn",
        "description": "Luz de amanecer con tonos lavanda, pino y pétalo",
        "author": "Rosé Pine",
        "isDark": False,
        "bg": "#faf4ed",
        "bgSurface": "#fffaf3",
        "bgHover": "#f2e9e1",
        "border": "#cecacd",
        "text": "#575279",
        "subtext": "#797593",
        "overlay": "#9893a5",
        "primary": "#d7827e",
        "success": "#56949f",
        "warning": "#ea9d34",
        "danger": "#b4637a",
        "cyan": "#286983",
        "pink": "#907aa9"
    },
    "oled-pure": {
        "name": "OLED Pure Black",
        "description": "Negro absoluto para pantallas OLED y máximo ahorro",
        "author": "Custom",
        "isDark": True,
        "bg": "#000000",
        "bgSurface": "#0d0d0d",
        "bgHover": "#1c1c1c",
        "border": "#2c2c2c",
        "text": "#f5f5f5",
        "subtext": "#cccccc",
        "overlay": "#666666",
        "primary": "#ffffff",
        "success": "#4ade80",
        "warning": "#fbbf24",
        "danger": "#f87171",
        "cyan": "#38bdf8",
        "pink": "#f472b6"
    }
}

def ensure_dirs():
    os.makedirs(THEMES_DIR, exist_ok=True)
    os.makedirs(os.path.dirname(CONFIG_FILE), exist_ok=True)

def get_current_theme_name():
    ensure_dirs()
    if os.path.exists(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, 'r', encoding='utf-8') as f:
                data = json.load(f)
                return data.get("theme", "catppuccin-mocha")
        except Exception:
            pass
    return "catppuccin-mocha"

def get_all_themes():
    themes = dict(BUILTIN_THEMES)
    ensure_dirs()
    for filename in os.listdir(THEMES_DIR):
        if filename.endswith(".json"):
            tid = filename[:-5]
            try:
                with open(os.path.join(THEMES_DIR, filename), 'r', encoding='utf-8') as f:
                    themes[tid] = json.load(f)
            except Exception:
                pass
    return themes

def get_theme(name=None):
    if not name:
        name = get_current_theme_name()
    all_themes = get_all_themes()
    if name in all_themes:
        th = all_themes[name]
        th["id"] = name
        return th
    th = BUILTIN_THEMES["catppuccin-mocha"]
    th["id"] = "catppuccin-mocha"
    return th

def sync_terminal_theme(theme_data):
    try:
        omarchy_theme_dir = os.path.expanduser("~/.local/state/omarchy/current/theme")
        os.makedirs(omarchy_theme_dir, exist_ok=True)

        is_dark = theme_data.get("isDark", True)
        bg = theme_data.get("bg", "#1e1e2e")
        bg_surface = theme_data.get("bgSurface", "#181825")
        bg_hover = theme_data.get("bgHover", "#313244")
        border = theme_data.get("border", "#45475a")
        fg = theme_data.get("text", "#cdd6f4")
        subtext = theme_data.get("subtext", "#a6adc8")
        overlay = theme_data.get("overlay", "#6c7086")
        primary = theme_data.get("primary", "#89b4fa")
        success = theme_data.get("success", "#a6e3a1")
        warning = theme_data.get("warning", "#f9e2af")
        danger = theme_data.get("danger", "#f38ba8")
        cyan = theme_data.get("cyan", "#89dceb")
        pink = theme_data.get("pink", "#f5c2e7")

        # Generación de configuración para Kitty
        kitty_content = f"""# Generado automáticamente por Quickshell Theme Manager
foreground {fg}
background {bg}
selection_foreground {fg}
selection_background {bg_hover}

cursor {primary}
cursor_text_color {bg}

active_border_color {primary}
inactive_border_color {border}
active_tab_background {primary}
active_tab_foreground {bg}
inactive_tab_background {bg_surface}
inactive_tab_foreground {subtext}

# Paleta ANSI estándar
color0 {bg_surface if is_dark else bg_hover}
color1 {danger}
color2 {success}
color3 {warning}
color4 {primary}
color5 {pink}
color6 {cyan}
color7 {fg}

# Paleta ANSI brillante
color8 {overlay}
color9 {danger}
color10 {success}
color11 {warning}
color12 {primary}
color13 {pink}
color14 {cyan}
color15 {subtext if is_dark else fg}
"""
        kitty_path = os.path.join(omarchy_theme_dir, "kitty.conf")
        with open(kitty_path, "w", encoding="utf-8") as f:
            f.write(kitty_content)

        # Generación de configuración para Foot
        foot_section = "colors-dark" if is_dark else "colors-light"
        foot_content = f"""# Generado automáticamente por Quickshell Theme Manager
[{foot_section}]
foreground={fg.lstrip('#')}
background={bg.lstrip('#')}
selection-foreground={fg.lstrip('#')}
selection-background={bg_hover.lstrip('#')}

cursor={bg.lstrip('#')} {primary.lstrip('#')}

regular0={(bg_surface if is_dark else bg_hover).lstrip('#')}
regular1={danger.lstrip('#')}
regular2={success.lstrip('#')}
regular3={warning.lstrip('#')}
regular4={primary.lstrip('#')}
regular5={pink.lstrip('#')}
regular6={cyan.lstrip('#')}
regular7={fg.lstrip('#')}

bright0={overlay.lstrip('#')}
bright1={danger.lstrip('#')}
bright2={success.lstrip('#')}
bright3={warning.lstrip('#')}
bright4={primary.lstrip('#')}
bright5={pink.lstrip('#')}
bright6={cyan.lstrip('#')}
bright7={(subtext if is_dark else fg).lstrip('#')}
"""
        foot_path = os.path.join(omarchy_theme_dir, "foot.ini")
        with open(foot_path, "w", encoding="utf-8") as f:
            f.write(foot_content)

        # Guardar nombre de tema activo en omarchy
        name_file = os.path.expanduser("~/.local/state/omarchy/current/theme.name")
        with open(name_file, "w", encoding="utf-8") as f:
            f.write(theme_data.get("id", "custom") + "\n")

        # Notificar a las instancias abiertas de Kitty para recargar colores en vivo
        import subprocess
        subprocess.run(["killall", "-SIGUSR1", "kitty"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        subprocess.run(["kitty", "@", "set-colors", "-a", kitty_path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception as e:
        print(f"Warning syncing terminal theme: {e}", file=sys.stderr)

def set_theme(name):
    ensure_dirs()
    all_themes = get_all_themes()
    if name not in all_themes:
        print(f"Error: Theme '{name}' not found", file=sys.stderr)
        return False
    with open(CONFIG_FILE, 'w', encoding='utf-8') as f:
        json.dump({"theme": name}, f, indent=2)
    
    theme_obj = all_themes[name]
    theme_obj["id"] = name
    sync_terminal_theme(theme_obj)
    return True

def main():
    if len(sys.argv) > 1:
        cmd = sys.argv[1]
        if cmd == "list":
            all_themes = get_all_themes()
            res = []
            cur = get_current_theme_name()
            for tid, val in all_themes.items():
                res.append({
                    "id": tid,
                    "name": val.get("name", tid),
                    "description": val.get("description", "Tema para Quickshell"),
                    "author": val.get("author", "Comunidad"),
                    "isDark": val.get("isDark", True),
                    "bg": val.get("bg", "#1e1e2e"),
                    "bgSurface": val.get("bgSurface", "#181825"),
                    "bgHover": val.get("bgHover", "#313244"),
                    "border": val.get("border", "#45475a"),
                    "text": val.get("text", "#cdd6f4"),
                    "subtext": val.get("subtext", "#a6adc8"),
                    "overlay": val.get("overlay", "#6c7086"),
                    "primary": val.get("primary", "#89b4fa"),
                    "success": val.get("success", "#a6e3a1"),
                    "warning": val.get("warning", "#f9e2af"),
                    "danger": val.get("danger", "#f38ba8"),
                    "cyan": val.get("cyan", "#89dceb"),
                    "pink": val.get("pink", "#f5c2e7"),
                    "isCurrent": tid == cur
                })
            print(json.dumps(res))
            return
        elif cmd == "set" and len(sys.argv) > 2:
            target = sys.argv[2]
            if set_theme(target):
                print(json.dumps(get_theme(target)))
            else:
                sys.exit(1)
            return
    
    current_th = get_theme()
    # Sincronizar terminal al consultar tema actual
    sync_terminal_theme(current_th)
    print(json.dumps(current_th))

if __name__ == '__main__':
    main()
