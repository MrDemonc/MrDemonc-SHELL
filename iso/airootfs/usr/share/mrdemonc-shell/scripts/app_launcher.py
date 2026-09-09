#!/usr/bin/env python3
import os
import sys
import json
import glob
import re
import configparser
import subprocess
import time

CACHE_FILE = os.path.expanduser(f"{os.environ.get('XDG_RUNTIME_DIR', '/tmp')}/quickshell_apps_cache.json")

ICON_SEARCH_DIRS = [
    "/usr/share/pixmaps",
    os.path.expanduser("~/.local/share/icons"),
    "/usr/share/icons/hicolor",
    "/usr/share/icons/Papirus",
    "/usr/share/icons/Papirus-Dark",
    "/usr/share/icons/Adwaita",
    "/usr/share/icons/breeze"
]

APP_DIRS = [
    "/usr/share/applications",
    "/usr/local/share/applications",
    os.path.expanduser("~/.local/share/applications"),
    "/var/lib/flatpak/exports/share/applications"
]

def build_icon_map():
    icon_map = {}
    for base_dir in ICON_SEARCH_DIRS:
        if not os.path.isdir(base_dir):
            continue
        for root, _, files in os.walk(base_dir):
            for f in files:
                if f.endswith(('.png', '.svg', '.webp', '.xpm')):
                    name, _ = os.path.splitext(f)
                    if name not in icon_map:
                        icon_map[name] = os.path.join(root, f)
    return icon_map

def clean_exec_command(exec_str):
    return re.sub(r'%[a-zA-Z]', '', exec_str).strip()

def get_installed_apps(force_refresh=False):
    if not force_refresh and os.path.exists(CACHE_FILE):
        try:
            mtime = os.path.getmtime(CACHE_FILE)
            if time.time() - mtime < 60:
                with open(CACHE_FILE, "r", encoding="utf-8") as f:
                    return json.load(f)
        except Exception:
            pass

    icon_map = build_icon_map()
    seen_names = set()
    apps = []

    for app_dir in APP_DIRS:
        if not os.path.isdir(app_dir):
            continue
        for filepath in glob.glob(os.path.join(app_dir, "*.desktop")):
            cfg = configparser.ConfigParser(interpolation=None)
            try:
                cfg.read(filepath, encoding="utf-8")
                if "Desktop Entry" in cfg:
                    entry = cfg["Desktop Entry"]
                    if entry.get("NoDisplay", "false").lower() == "true":
                        continue
                    if entry.get("Type", "Application") != "Application":
                        continue
                    
                    name = entry.get("Name", "").strip()
                    exec_cmd = clean_exec_command(entry.get("Exec", ""))
                    icon_name = entry.get("Icon", "").strip()
                    comment = entry.get("Comment", "").strip()
                    generic = entry.get("GenericName", "").strip()
                    terminal = entry.get("Terminal", "false").lower() == "true"
                    categories = entry.get("Categories", "").strip()

                    if not name or not exec_cmd:
                        continue
                    
                    app_id = name.lower()
                    if app_id in seen_names:
                        continue
                    seen_names.add(app_id)

                    icon_file = ""
                    if os.path.isabs(icon_name) and os.path.exists(icon_name):
                        icon_file = icon_name
                    elif icon_name in icon_map:
                        icon_file = icon_map[icon_name]
                    else:
                        bname, _ = os.path.splitext(icon_name)
                        if bname in icon_map:
                            icon_file = icon_map[bname]

                    apps.append({
                        "name": name,
                        "genericName": generic,
                        "comment": comment,
                        "exec": exec_cmd,
                        "iconName": icon_name,
                        "iconPath": icon_file,
                        "terminal": terminal,
                        "categories": categories,
                        "desktopFile": filepath
                    })
            except Exception:
                continue

    apps.sort(key=lambda x: x["name"].lower())

    try:
        with open(CACHE_FILE, "w", encoding="utf-8") as f:
            json.dump(apps, f)
    except Exception:
        pass

    return apps

def launch_app(exec_cmd, is_terminal=False):
    if not exec_cmd:
        return {"error": "Empty command"}
    
    cmd_to_run = exec_cmd
    if is_terminal:
        cmd_to_run = f"kitty {exec_cmd}"

    try:
        subprocess.Popen(
            cmd_to_run,
            shell=True,
            start_new_session=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            stdin=subprocess.DEVNULL
        )
        return {"status": "launched", "cmd": cmd_to_run}
    except Exception as e:
        return {"error": str(e)}

def main():
    action = sys.argv[1] if len(sys.argv) > 1 else "list"
    
    if action == "list":
        apps = get_installed_apps(force_refresh=True)
        print(json.dumps(apps))
    elif action == "launch" and len(sys.argv) > 2:
        exec_target = sys.argv[2]
        is_term = len(sys.argv) > 3 and sys.argv[3].lower() == "true"
        print(json.dumps(launch_app(exec_target, is_term)))
    else:
        print(json.dumps({"error": f"Unknown action {action}"}))

if __name__ == "__main__":
    main()
