#!/usr/bin/env python3
import os
import sys
import json
import subprocess
import hashlib
from pathlib import Path

WALLPAPER_DIR = os.path.expanduser("~/Pictures/Wallpapers")
CONFIG_DIR = os.path.expanduser("~/.config/quickshell")
CONFIG_FILE = os.path.join(CONFIG_DIR, "current_wallpaper.json")

SUPPORTED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".bmp", ".gif"}

_script_dir = os.path.dirname(os.path.abspath(__file__))
_repo_themes = os.path.join(os.path.dirname(_script_dir), "themes")

_RAW_THEME_SEARCH_DIRS = [
    os.path.expanduser("~/.config/quickshell/themes"),
    _repo_themes,
    os.path.expanduser("~/Documentos/MrDemonc-SHELL/themes"),
    "/usr/share/mrdemonc-shell/themes"
]

# Normalizar y deduplicar directorios de búsqueda de temas preservando prioridad
THEME_SEARCH_DIRS = []
_seen_dirs = set()
for d in _RAW_THEME_SEARCH_DIRS:
    rp = os.path.realpath(d) if os.path.exists(d) else os.path.normpath(d)
    if rp not in _seen_dirs:
        _seen_dirs.add(rp)
        THEME_SEARCH_DIRS.append(d)

def ensure_dirs():
    os.makedirs(WALLPAPER_DIR, exist_ok=True)
    os.makedirs(CONFIG_DIR, exist_ok=True)

def get_file_fingerprint(filepath):
    """Calcula una huella rápida y única basada en tamaño y contenido para evitar duplicados."""
    try:
        rp = os.path.realpath(filepath)
        if not os.path.isfile(rp):
            return None
        size = os.path.getsize(rp)
        if size == 0:
            return None
        with open(rp, "rb") as f:
            chunk1 = f.read(131072)
            if size > 262144:
                f.seek(-131072, os.SEEK_END)
                chunk2 = f.read(131072)
            else:
                chunk2 = b""
        h = hashlib.sha256(chunk1)
        if chunk2:
            h.update(chunk2)
        return f"{size}:{h.hexdigest()}"
    except Exception:
        return None

def find_theme_wallpapers():
    theme_walls = []
    seen_paths = set()
    seen_realpaths = set()
    seen_fingerprints = set()
    seen_theme_ids = set()

    # 1. Intentar usar theme_manager si está disponible para respetar temas registrados y su prioridad
    try:
        sys.path.insert(0, _script_dir)
        import theme_manager
        all_themes = theme_manager.get_all_themes()
        for tid, th_data in all_themes.items():
            wp = th_data.get("wallpaperPath")
            if wp and os.path.exists(wp):
                rp = os.path.realpath(wp)
                fp = get_file_fingerprint(wp)
                if rp not in seen_realpaths and (not fp or fp not in seen_fingerprints):
                    seen_paths.add(wp)
                    seen_realpaths.add(rp)
                    if fp:
                        seen_fingerprints.add(fp)
                    seen_theme_ids.add(tid.lower())
                    theme_walls.append({
                        "name": th_data.get("name", tid.replace("_", " ").replace("-", " ").title()),
                        "fileName": os.path.basename(wp),
                        "path": wp,
                        "fingerprint": fp,
                        "isThemeWallpaper": True
                    })
    except Exception:
        pass

    # 2. Escaneo complementario de directorios para temas no registrados
    for base in THEME_SEARCH_DIRS:
        if not os.path.isdir(base):
            continue
        for item in sorted(os.listdir(base)):
            item_dir = os.path.join(base, item)
            if not os.path.isdir(item_dir):
                continue
            item_key = item.lower()
            if item_key in seen_theme_ids:
                continue

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

            if wall_file and os.path.exists(wall_file):
                rp = os.path.realpath(wall_file)
                fp = get_file_fingerprint(wall_file)
                if wall_file not in seen_paths and rp not in seen_realpaths and (not fp or fp not in seen_fingerprints):
                    seen_paths.add(wall_file)
                    seen_realpaths.add(rp)
                    if fp:
                        seen_fingerprints.add(fp)
                    seen_theme_ids.add(item_key)
                    theme_walls.append({
                        "name": theme_name,
                        "fileName": os.path.basename(wall_file),
                        "path": wall_file,
                        "fingerprint": fp,
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
        sys.path.insert(0, _script_dir)
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

    cur_rp = os.path.realpath(current_path) if (current_path and os.path.exists(current_path)) else ""
    cur_fp = get_file_fingerprint(current_path) if (current_path and os.path.exists(current_path)) else None

    wallpapers = []
    seen_paths = set()
    seen_realpaths = set()
    seen_fingerprints = set()

    # 1. Primero incluir los wallpapers de los temas disponibles
    theme_walls = find_theme_wallpapers()
    for tw in theme_walls:
        p = tw["path"]
        rp = os.path.realpath(p)
        fp = tw.get("fingerprint") or get_file_fingerprint(p)
        seen_paths.add(p)
        if rp:
            seen_realpaths.add(rp)
        if fp:
            seen_fingerprints.add(fp)

        is_cur = False
        if current_path:
            if p == current_path or (rp and rp == cur_rp) or (cur_fp and fp and fp == cur_fp):
                is_cur = True

        wallpapers.append({
            "name": tw["name"],
            "fileName": tw["fileName"],
            "path": p,
            "isCurrent": is_cur
        })

    # 2. Luego incluir los wallpapers adicionales que el usuario coloque en ~/Pictures/Wallpapers
    if os.path.exists(WALLPAPER_DIR):
        files = sorted(os.listdir(WALLPAPER_DIR))
        for fname in files:
            ext = os.path.splitext(fname)[1].lower()
            if ext in SUPPORTED_EXTENSIONS:
                full_path = os.path.join(WALLPAPER_DIR, fname)
                rp = os.path.realpath(full_path)
                fp = get_file_fingerprint(full_path)

                # Deduplicar si ya existe la misma ruta, realpath o idéntico contenido
                if full_path in seen_paths:
                    continue
                if rp and rp in seen_realpaths:
                    continue
                if fp and fp in seen_fingerprints:
                    continue

                seen_paths.add(full_path)
                if rp:
                    seen_realpaths.add(rp)
                if fp:
                    seen_fingerprints.add(fp)

                name_without_ext = os.path.splitext(fname)[0].replace("_", " ").replace("-", " ").title()
                is_cur = False
                if current_path:
                    if full_path == current_path or (rp and rp == cur_rp) or (cur_fp and fp and fp == cur_fp):
                        is_cur = True

                wallpapers.append({
                    "name": name_without_ext,
                    "fileName": fname,
                    "path": full_path,
                    "isCurrent": is_cur
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
    name = ""
    # Si viene de una carpeta de tema (themes/<theme_id>/wallpaper.ext), resolver nombre descriptivo
    parent_dir = os.path.dirname(path)
    grandparent_dir = os.path.basename(os.path.dirname(parent_dir)) if parent_dir else ""
    parent_name = os.path.basename(parent_dir)
    if parent_name and (grandparent_dir == "themes" or "themes" in parent_dir):
        tj = os.path.join(parent_dir, "theme.json")
        if os.path.exists(tj):
            try:
                with open(tj, "r", encoding="utf-8") as f:
                    name = json.load(f).get("name", "")
            except Exception:
                pass
        if not name:
            name = parent_name.replace("_", " ").replace("-", " ").title()

    if not name or name.lower() in ("wallpaper", "themes"):
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
