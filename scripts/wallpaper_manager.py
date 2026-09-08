#!/usr/bin/env python3
import os
import sys
import json
import glob
import subprocess
from pathlib import Path

WALLPAPER_DIR = os.path.expanduser("~/Pictures/Wallpapers")
CONFIG_DIR = os.path.expanduser("~/.config/quickshell")
CONFIG_FILE = os.path.join(CONFIG_DIR, "current_wallpaper.json")

# Formatos de imagen soportados
SUPPORTED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".bmp", ".gif"}

def ensure_dirs():
    os.makedirs(WALLPAPER_DIR, exist_ok=True)
    os.makedirs(CONFIG_DIR, exist_ok=True)

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
    
    # Si no hay configuración o no existe el archivo, tomar el primer wallpaper disponible
    all_walls = list_wallpapers()
    if all_walls:
        return all_walls[0]["path"]
    return ""

def list_wallpapers():
    ensure_dirs()
    # Copiar fotos de ~/Pictures/wallpapers si ~/Pictures/Wallpapers está vacío
    legacy_dir = os.path.expanduser("~/Pictures/wallpapers")
    if os.path.exists(legacy_dir) and not os.listdir(WALLPAPER_DIR):
        for item in os.listdir(legacy_dir):
            src = os.path.join(legacy_dir, item)
            dst = os.path.join(WALLPAPER_DIR, item)
            if os.path.isfile(src) and not os.path.exists(dst):
                try:
                    import shutil
                    shutil.copy2(src, dst)
                except Exception:
                    pass

    current_path = ""
    if os.path.exists(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, "r", encoding="utf-8") as f:
                current_path = json.load(f).get("path", "")
        except Exception:
            pass

    wallpapers = []
    files = sorted(os.listdir(WALLPAPER_DIR))
    for fname in files:
        ext = os.path.splitext(fname)[1].lower()
        if ext in SUPPORTED_EXTENSIONS:
            full_path = os.path.join(WALLPAPER_DIR, fname)
            name_without_ext = os.path.splitext(fname)[0].replace("_", " ").replace("-", " ").title()
            is_active = (full_path == current_path)
            wallpapers.append({
                "name": name_without_ext,
                "fileName": fname,
                "path": full_path,
                "isCurrent": is_active
            })

    # Si ninguno está marcado como current pero hay elementos, marcar el primero si no había config
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
    for fm in ["dolphin", "nautilus", "thunar", "nemo", "pcmanfm"]:
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
        name = os.path.splitext(fname)[0].replace("_", " ").replace("-", " ").title() if fname else ""
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
