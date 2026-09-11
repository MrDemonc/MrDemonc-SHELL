#!/usr/bin/env python3
import os
import json
import sys
import glob

THEMES_DIR = os.path.expanduser("~/.config/quickshell/themes")
CONFIG_FILE = os.path.expanduser("~/.config/quickshell/current_theme.json")

# Tema Default basado en La Gran Ola de Kanagawa (default.jpg) y tonos nórdicos
BUILTIN_THEMES = {
    "default": {
        "name": "Default",
        "description": "Tema predeterminado inspirado en La Gran Ola de Kanagawa y tonos pizarra nórdicos",
        "author": "MrDemonc",
        "isDark": True,
        "wallpaper": "wallpaper.jpg",
        "bg": "#1a1d24",
        "bgSurface": "#14161d",
        "bgHover": "#282d38",
        "border": "#353b49",
        "text": "#eceff4",
        "subtext": "#d8dee9",
        "overlay": "#7b889b",
        "primary": "#88c0d0",
        "success": "#a3be8c",
        "warning": "#ebcb8b",
        "danger": "#bf616a",
        "cyan": "#81a1c1",
        "pink": "#b48ead"
    }
}

THEME_SEARCH_DIRS = [
    os.path.expanduser("~/.config/quickshell/themes"),
    os.path.expanduser("~/Documentos/MrDemonc-SHELL/themes"),
    "/usr/share/mrdemonc-shell/themes"
]

def ensure_dirs():
    os.makedirs(THEMES_DIR, exist_ok=True)
    os.makedirs(os.path.dirname(CONFIG_FILE), exist_ok=True)

def get_current_theme_name():
    ensure_dirs()
    if os.path.exists(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, 'r', encoding='utf-8') as f:
                data = json.load(f)
                return data.get("theme", "default")
        except Exception:
            pass
    return "default"

def get_all_themes():
    ensure_dirs()
    themes = {}

    # Buscar temas en las carpetas estructuradas (themes/<theme_id>/theme.json)
    for base_dir in THEME_SEARCH_DIRS:
        if not os.path.isdir(base_dir):
            continue
        for entry in os.listdir(base_dir):
            sub_path = os.path.join(base_dir, entry)
            if os.path.isdir(sub_path):
                tj = os.path.join(sub_path, "theme.json")
                if os.path.isfile(tj):
                    try:
                        with open(tj, 'r', encoding='utf-8') as f:
                            th_data = json.load(f)
                            tid = th_data.get("id", entry)
                            th_data["id"] = tid
                            th_data["_dir"] = sub_path
                            # Resolver ruta absoluta de wallpaper si existe en la carpeta del tema
                            w = th_data.get("wallpaper", "")
                            if w:
                                if not os.path.isabs(w):
                                    w = os.path.join(sub_path, w)
                                if os.path.exists(w):
                                    th_data["wallpaperPath"] = w
                            else:
                                for ext in [".jpg", ".jpeg", ".png", ".webp"]:
                                    cand = os.path.join(sub_path, f"wallpaper{ext}")
                                    if os.path.exists(cand):
                                        th_data["wallpaperPath"] = cand
                                        break
                            if tid not in themes:
                                themes[tid] = th_data
                    except Exception:
                        pass
            elif entry.endswith(".json"):
                tid = entry[:-5]
                try:
                    with open(sub_path, 'r', encoding='utf-8') as f:
                        th_data = json.load(f)
                        th_data["id"] = tid
                        if tid not in themes:
                            themes[tid] = th_data
                except Exception:
                    pass

    # Integrar BUILTIN_THEMES si no están cargados aún
    for tid, val in BUILTIN_THEMES.items():
        if tid not in themes:
            th = dict(val)
            th["id"] = tid
            # Buscar wallpaper para el builtin
            for base_dir in THEME_SEARCH_DIRS:
                cand = os.path.join(base_dir, tid, "wallpaper.jpg")
                if os.path.exists(cand):
                    th["wallpaperPath"] = cand
                    break
            themes[tid] = th

    return themes

def get_theme(name=None):
    if not name:
        name = get_current_theme_name()
    all_themes = get_all_themes()
    if name in all_themes:
        th = all_themes[name]
        th["id"] = name
        return th
    th = dict(BUILTIN_THEMES["default"])
    th["id"] = "default"
    return th

def sync_terminal_theme(theme_data):
    try:
        mrdemonc_theme_dir = os.path.expanduser("~/.local/state/mrdemonc/current/theme")
        os.makedirs(mrdemonc_theme_dir, exist_ok=True)

        is_dark = theme_data.get("isDark", True)
        bg = theme_data.get("bg", "#2e3340")
        bg_surface = theme_data.get("bgSurface", "#242833")
        bg_hover = theme_data.get("bgHover", "#3b4252")
        border = theme_data.get("border", "#434c5e")
        fg = theme_data.get("text", "#eceff4")
        subtext = theme_data.get("subtext", "#d8dee9")
        overlay = theme_data.get("overlay", "#7b889b")
        primary = theme_data.get("primary", "#88c0d0")
        success = theme_data.get("success", "#a3be8c")
        warning = theme_data.get("warning", "#ebcb8b")
        danger = theme_data.get("danger", "#bf616a")
        cyan = theme_data.get("cyan", "#81a1c1")
        pink = theme_data.get("pink", "#b48ead")

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
color4 {cyan}
color5 {pink}
color6 {primary}
color7 {fg}

# Paleta ANSI brillante
color8 {overlay}
color9 {danger}
color10 {success}
color11 {warning}
color12 {cyan}
color13 {pink}
color14 {primary}
color15 {subtext if is_dark else fg}
"""
        # Escribir en ~/.config/kitty/theme.conf (para include directo sin problemas de expansión)
        kitty_cfg_dir = os.path.expanduser("~/.config/kitty")
        os.makedirs(kitty_cfg_dir, exist_ok=True)
        with open(os.path.join(kitty_cfg_dir, "theme.conf"), "w", encoding="utf-8") as f:
            f.write(kitty_content)

        kitty_path = os.path.join(mrdemonc_theme_dir, "kitty.conf")
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
regular4={cyan.lstrip('#')}
regular5={pink.lstrip('#')}
regular6={primary.lstrip('#')}
regular7={fg.lstrip('#')}

bright0={overlay.lstrip('#')}
bright1={danger.lstrip('#')}
bright2={success.lstrip('#')}
bright3={warning.lstrip('#')}
bright4={cyan.lstrip('#')}
bright5={pink.lstrip('#')}
bright6={primary.lstrip('#')}
bright7={(subtext if is_dark else fg).lstrip('#')}
"""
        foot_path = os.path.join(mrdemonc_theme_dir, "foot.ini")
        with open(foot_path, "w", encoding="utf-8") as f:
            f.write(foot_content)

        # Guardar nombre de tema activo
        name_f = os.path.expanduser("~/.local/state/mrdemonc/current/theme.name")
        os.makedirs(os.path.dirname(name_f), exist_ok=True)
        with open(name_f, "w", encoding="utf-8") as f:
            f.write(theme_data.get("id", "default") + "\n")

        # Notificar a las instancias abiertas de Kitty para recargar colores en vivo
        import subprocess
        try:
            subprocess.run(["pkill", "-SIGUSR1", "kitty"], stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.run(["killall", "-SIGUSR1", "kitty"], stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except Exception:
            pass
    except Exception:
        pass

def sync_hyprland_theme(theme_data):
    try:
        primary = theme_data.get("primary", "#88c0d0").lstrip('#')
        cyan = theme_data.get("cyan", "#81a1c1").lstrip('#')
        border = theme_data.get("border", "#434c5e").lstrip('#')
        
        # 1. Actualizar ~/.config/hypr/theme_colors.lua para que Hyprland lo lea al iniciar/recargar
        hypr_dir = os.path.expanduser("~/.config/hypr")
        os.makedirs(hypr_dir, exist_ok=True)
        theme_lua = os.path.join(hypr_dir, "theme_colors.lua")
        
        lua_content = f"""-- Generado automáticamente por Quickshell Theme Manager
return {{
    active_border    = "rgba({primary}ee)",
    secondary_border = "rgba({cyan}ee)",
    inactive_border  = "rgba({border}aa)",
}}
"""
        with open(theme_lua, "w", encoding="utf-8") as f:
            f.write(lua_content)
            
        # 2. Aplicar bordes de ventana en caliente en Hyprland en tiempo real
        import subprocess
        lua_cmd = f'hl.config({{ general = {{ col = {{ active_border = {{ colors = {{"rgba({primary}ee)", "rgba({cyan}ee)"}}, angle = 45 }}, inactive_border = "rgba({border}aa)" }} }} }})'
        subprocess.run(["hyprctl", "repl", lua_cmd], stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=0.25)
    except Exception:
        pass

def sync_hyprlock_theme(theme_data):
    try:
        def hex_to_rgb(hex_str, default=(200, 200, 200)):
            if not hex_str or not isinstance(hex_str, str):
                return default
            h = hex_str.lstrip('#')
            if len(h) < 6:
                return default
            try:
                return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
            except ValueError:
                return default

        bg_r, bg_g, bg_b = hex_to_rgb(theme_data.get("bg", "#2e3340"))
        surf_r, surf_g, surf_b = hex_to_rgb(theme_data.get("bgSurface", "#242833"))
        pri_r, pri_g, pri_b = hex_to_rgb(theme_data.get("primary", "#88c0d0"))
        txt_r, txt_g, txt_b = hex_to_rgb(theme_data.get("text", "#eceff4"))
        sub_r, sub_g, sub_b = hex_to_rgb(theme_data.get("subtext", "#d8dee9"))
        ovr_r, ovr_g, ovr_b = hex_to_rgb(theme_data.get("overlay", "#7b889b"))
        suc_r, suc_g, suc_b = hex_to_rgb(theme_data.get("success", "#a3be8c"))
        dan_r, dan_g, dan_b = hex_to_rgb(theme_data.get("danger", "#bf616a"))
        war_r, war_g, war_b = hex_to_rgb(theme_data.get("warning", "#ebcb8b"))

        content = f"""# Generado automáticamente por Quickshell Theme Manager
$bg = rgba({bg_r}, {bg_g}, {bg_b}, 1.0)
$surface = rgba({surf_r}, {surf_g}, {surf_b}, 0.85)
$surface_alpha = rgba({surf_r}, {surf_g}, {surf_b}, 0.70)
$primary = rgba({pri_r}, {pri_g}, {pri_b}, 1.0)
$primary_dim = rgba({pri_r}, {pri_g}, {pri_b}, 0.70)
$text = rgba({txt_r}, {txt_g}, {txt_b}, 1.0)
$subtext = rgba({sub_r}, {sub_g}, {sub_b}, 1.0)
$overlay = rgba({ovr_r}, {ovr_g}, {ovr_b}, 1.0)
$success = rgba({suc_r}, {suc_g}, {suc_b}, 1.0)
$danger = rgba({dan_r}, {dan_g}, {dan_b}, 1.0)
$warning = rgba({war_r}, {war_g}, {war_b}, 1.0)
"""
        hypr_dir = os.path.expanduser("~/.config/hypr")
        os.makedirs(hypr_dir, exist_ok=True)
        with open(os.path.join(hypr_dir, "hyprlock_colors.conf"), "w", encoding="utf-8") as f:
            f.write(content)

        repo_hypr = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "hypr")
        if os.path.isdir(repo_hypr):
            with open(os.path.join(repo_hypr, "hyprlock_colors.conf"), "w", encoding="utf-8") as f:
                f.write(content)
    except Exception:
        pass

def sync_limine_theme(theme_data):
    try:
        limine_candidates = ["/boot/limine.conf", "/boot/limine/limine.conf", "/boot/EFI/BOOT/limine.conf"]
        target_conf = None
        for cand in limine_candidates:
            if os.path.exists(cand):
                target_conf = cand
                break
        if not target_conf:
            return

        bg = theme_data.get("bg", "#1a1d24").lstrip('#')
        bg_surf = theme_data.get("bgSurface", "#14161d").lstrip('#')
        pri = theme_data.get("primary", "#88c0d0").lstrip('#')
        cyan = theme_data.get("cyan", "#81a1c1").lstrip('#')
        border = theme_data.get("border", "#353b49").lstrip('#')
        fg = theme_data.get("text", "#eceff4").lstrip('#')
        danger = theme_data.get("danger", "#bf616a").lstrip('#')
        succ = theme_data.get("success", "#a3be8c").lstrip('#')
        warn = theme_data.get("warning", "#ebcb8b").lstrip('#')
        pink = theme_data.get("pink", "#b48ead").lstrip('#')

        # Sincronizar wallpaper en /boot si es accesible
        wall_path = theme_data.get("wallpaperPath", "")
        if wall_path and os.path.isfile(wall_path) and os.access("/boot", os.W_OK):
            import shutil
            shutil.copyfile(wall_path, "/boot/limine-wallpaper.jpg")

        if os.access(target_conf, os.W_OK):
            with open(target_conf, "r", encoding="utf-8") as f:
                lines = f.readlines()
            new_lines = []
            for line in lines:
                if line.startswith("backdrop:"):
                    new_lines.append(f"backdrop: {bg}\n")
                elif line.startswith("interface_branding_color:"):
                    new_lines.append(f"interface_branding_color: {pri}\n")
                elif line.startswith("interface_help_color:"):
                    new_lines.append(f"interface_help_color: {cyan}\n")
                elif line.startswith("term_palette:"):
                    new_lines.append(f"term_palette: {bg};{danger};{succ};{warn};{cyan};{pink};{pri};{fg}\n")
                elif line.startswith("term_palette_bright:"):
                    new_lines.append(f"term_palette_bright: {border};{danger};{succ};{warn};{cyan};{pink};{pri};{fg}\n")
                elif line.startswith("term_background:"):
                    new_lines.append(f"term_background: b0{bg_surf}\n")
                elif line.startswith("term_foreground:"):
                    new_lines.append(f"term_foreground: {fg}\n")
                else:
                    new_lines.append(line)
            with open(target_conf, "w", encoding="utf-8") as f:
                f.writelines(new_lines)
    except Exception:
        pass

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

    # Sincronizar automáticamente el wallpaper vinculado al tema si existe
    wall_path = theme_obj.get("wallpaperPath")
    if wall_path and os.path.exists(wall_path):
        try:
            scripts_dir = os.path.dirname(os.path.abspath(__file__))
            sys.path.insert(0, scripts_dir)
            import wallpaper_manager
            wallpaper_manager.set_wallpaper(wall_path)
        except Exception:
            pass

    # Notificar a Quickshell para recarga instantánea
    runtime_dir = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
    trigger = os.path.join(runtime_dir, "quickshell_theme_reload.toggle")
    try:
        with open(trigger, 'w') as f:
            f.write(name)
    except Exception:
        pass

    sync_terminal_theme(theme_obj)
    sync_hyprland_theme(theme_obj)
    sync_hyprlock_theme(theme_obj)
    sync_limine_theme(theme_obj)
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
                    "wallpaper": val.get("wallpaper", ""),
                    "wallpaperPath": val.get("wallpaperPath", ""),
                    "bg": val.get("bg", "#2e3340"),
                    "bgSurface": val.get("bgSurface", "#242833"),
                    "bgHover": val.get("bgHover", "#3b4252"),
                    "border": val.get("border", "#434c5e"),
                    "text": val.get("text", "#eceff4"),
                    "subtext": val.get("subtext", "#d8dee9"),
                    "overlay": val.get("overlay", "#7b889b"),
                    "primary": val.get("primary", "#88c0d0"),
                    "success": val.get("success", "#a3be8c"),
                    "warning": val.get("warning", "#ebcb8b"),
                    "danger": val.get("danger", "#bf616a"),
                    "cyan": val.get("cyan", "#81a1c1"),
                    "pink": val.get("pink", "#b48ead"),
                    "isCurrent": tid == cur
                })
            print(json.dumps(res))
            return
        elif cmd in ("set", "apply") and len(sys.argv) > 2:
            target = sys.argv[2]
            if set_theme(target):
                print(json.dumps(get_theme(target)))
            else:
                sys.exit(1)
            return
    
    current_th = get_theme()
    sync_hyprlock_theme(current_th)
    print(json.dumps(current_th))

if __name__ == '__main__':
    main()
