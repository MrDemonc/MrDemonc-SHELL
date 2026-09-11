#!/usr/bin/env python3
import os
import sys
import json
import subprocess
from pathlib import Path

WALLPAPER_DIR = os.path.expanduser("~/Pictures/Wallpapers")
CONFIG_DIR = os.path.expanduser("~/.config/quickshell")
CONFIG_FILE = os.path.join(CONFIG_DIR, "current_wallpaper.json")

SUPPORTED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".bmp", ".gif"}

THEME_SEARCH_DIRS = [
    os.path.expanduser("~/.config/quickshell/themes"),
    os.path.expanduser("~/Documentos/MrDemonc-SHELL/themes"),
    "/usr/share/mrdemonc-shell/themes"
]

def ensure_dirs():
    os.makedirs(WALLPAPER_DIR, exist_ok=True)
    os.makedirs(CONFIG_DIR, exist_ok=True)

def find_theme_wallpapers():
    theme_walls = []
    seen_paths = set()
    for base in THEME_SEARCH_DIRS:
        if not os.path.isdir(base):
            continue
        for item in sorted(os.listdir(base)):
            item_dir = os.path.join(base, item)
            if not os.path.isdir(item_dir):
                continue
            # Intentar leer theme.json
            tj = os.path.join(item_dir, "theme.json")
            theme_name = item.replace("_", " ").replace("-", " ").title()
            wall_file = None
            if os.path.isfile(tj):
                try:
                    with open(tj, 'r', encoding='utf-8') as f:
                        data = json.load(f)
                        theme_name = data.get("name", theme_name)
                        w = data.get("wallpaper", "")
                        if w:
                            cand = os.path.join(item_dir, w) if not os.path.isabs(w) else w
                            if os.path.exists(cand):
                                wall_file = cand
                except Exception:
                    pass
            if not wall_file:
                for ext in [".jpg", ".jpeg", ".png", ".webp"]:
                    cand = os.path.join(item_dir, f"wallpaper{ext}")
                    if os.path.exists(cand):
                        wall_file = cand
                        break
            if wall_file and wall_file not in seen_paths:
                seen_paths.add(wall_file)
                theme_walls.append({
                    "name": theme_name,
                    "fileName": os.path.basename(wall_file),
                    "path": wall_file,
                    "isThemeWallpaper": True
                })
    return theme_walls

def get_current_wallpaper():
    ensure_dirs()
    if os.path.exists(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, "r", encoding="utf-8") as f:
                data = json.load(f)
                path = data.get("path", "")
                if path and os.path.exists(path):
                    return path
        except Exception:
            pass
    
    # Si no hay configuración previa, obtener el wallpaper del tema activo
    try:
        scripts_dir = os.path.dirname(os.path.abspath(__file__))
        sys.path.insert(0, scripts_dir)
        import theme_manager
        cur_theme = theme_manager.get_theme()
        wp = cur_theme.get("wallpaperPath")
        if wp and os.path.exists(wp):
            return wp
    except Exception:
        pass

    all_walls = list_wallpapers()
    if all_walls:
        return all_walls[0]["path"]
    return ""

def list_wallpapers():
    ensure_dirs()
    current_path = ""
    if os.path.exists(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, "r", encoding="utf-8") as f:
                current_path = json.load(f).get("path", "")
        except Exception:
            pass

    wallpapers = []
    seen_paths = set()

    # 1. Primero incluir los wallpapers de los temas disponibles
    theme_walls = find_theme_wallpapers()
    for tw in theme_walls:
        p = tw["path"]
        seen_paths.add(p)
        wallpapers.append({
            "name": tw["name"],
            "fileName": tw["fileName"],
            "path": p,
            "isCurrent": (p == current_path)
        })

    # 2. Luego incluir los wallpapers adicionales que el usuario coloque en ~/Pictures/Wallpapers
    if os.path.exists(WALLPAPER_DIR):
        files = sorted(os.listdir(WALLPAPER_DIR))
        for fname in files:
            ext = os.path.splitext(fname)[1].lower()
            if ext in SUPPORTED_EXTENSIONS:
                full_path = os.path.join(WALLPAPER_DIR, fname)
                if full_path not in seen_paths:
                    seen_paths.add(full_path)
                    name_without_ext = os.path.splitext(fname)[0].replace("_", " ").replace("-", " ").title()
                    wallpapers.append({
                        "name": name_without_ext,
                        "fileName": fname,
                        "path": full_path,
                        "isCurrent": (full_path == current_path)
                    })

    # Si ninguno está marcado como current pero hay elementos, marcar el primero
    if wallpapers and not any(w["isCurrent"] for w in wallpapers):
        wallpapers[0]["isCurrent"] = True

    return wallpapers

def set_wallpaper(path):
    ensure_dirs()
    if not os.path.exists(path):
        return {"error": "File not found"}
    
    fname = os.path.basename(path)
    name = os.path.splitext(fname)[0].replace("_", " ").replace("-", " ").title()
    
    data = {
        "path": path,
        "fileName": fname,
        "name": name
    }
    
    with open(CONFIG_FILE, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)

    return {"status": "ok", "current": data}

def open_folder():
    ensure_dirs()
    import shutil
    for fm in ["nautilus", "dolphin", "thunar", "nemo", "pcmanfm"]:
        if shutil.which(fm):
            subprocess.Popen([fm, WALLPAPER_DIR])
            return {"status": "opened", "manager": fm}
    subprocess.Popen(["xdg-open", WALLPAPER_DIR])
    return {"status": "opened"}

def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "get"
    
    if cmd == "list":
        print(json.dumps(list_wallpapers()))
    elif cmd == "get":
        cur = get_current_wallpaper()
        fname = os.path.basename(cur) if cur else ""
        name = ""
        if cur and ("themes/" in cur or "themes" in os.path.dirname(cur)):
            parent = os.path.basename(os.path.dirname(cur))
            name = parent.replace("_", " ").replace("-", " ").title()
        if not name and fname:
            name = os.path.splitext(fname)[0].replace("_", " ").replace("-", " ").title()
        print(json.dumps({
            "path": cur,
            "fileName": fname,
            "name": name
        }))
    elif cmd == "set":
        if len(sys.argv) > 2:
            target = sys.argv[2]
            print(json.dumps(set_wallpaper(target)))
    elif cmd == "open_dir":
        print(json.dumps(open_folder()))
    else:
        print(json.dumps({"error": f"Unknown command {cmd}"}))

if __name__ == "__main__":
    main()
