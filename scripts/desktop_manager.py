#!/usr/bin/env python3
import os
import sys
import json
import glob
import re
import configparser
import subprocess
import time

CONFIG_DIR = os.path.expanduser("~/.config/quickshell")
SETTINGS_FILE = os.path.join(CONFIG_DIR, "desktop_settings.json")
RUNTIME_DIR = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
RELOAD_TRIGGER = os.path.join(RUNTIME_DIR, "quickshell_desktop.reload")

DEFAULT_SETTINGS = {
    "enabled": True,
    "iconSize": 48,
    "showFolders": True,
    "showTrash": True,
    "showDrives": True,
    "selectedApps": ["org.gnome.Nautilus.desktop", "kitty.desktop"]
}

ICON_SEARCH_DIRS = [
    "/usr/share/pixmaps",
    os.path.expanduser("~/.local/share/icons"),
    "/usr/share/icons/Papirus",
    "/usr/share/icons/Papirus-Dark",
    "/usr/share/icons/hicolor",
    "/usr/share/icons/Adwaita",
    "/usr/share/icons/breeze"
]

APP_DIRS = [
    "/usr/share/applications",
    "/usr/local/share/applications",
    os.path.expanduser("~/.local/share/applications"),
    "/var/lib/flatpak/exports/share/applications"
]

def get_settings():
    os.makedirs(CONFIG_DIR, exist_ok=True)
    if os.path.exists(SETTINGS_FILE):
        try:
            with open(SETTINGS_FILE, "r", encoding="utf-8") as f:
                data = json.load(f)
                merged = dict(DEFAULT_SETTINGS)
                merged.update(data)
                return merged
        except Exception:
            pass
    return dict(DEFAULT_SETTINGS)

def save_settings(settings):
    os.makedirs(CONFIG_DIR, exist_ok=True)
    temp_file = SETTINGS_FILE + ".tmp"
    with open(temp_file, "w", encoding="utf-8") as f:
        json.dump(settings, f, indent=2, ensure_ascii=False)
    os.replace(temp_file, SETTINGS_FILE)
    notify_reload()

def notify_reload():
    try:
        with open(RELOAD_TRIGGER, "w", encoding="utf-8") as f:
            f.write(str(time.time()))
    except Exception:
        pass

def clean_exec_command(exec_str):
    if not exec_str:
        return ""
    return re.sub(r'%[a-zA-Z]', '', exec_str).strip()

def score_icon_path(p):
    score = 0
    if "Papirus" in p:
        score += 40
    if p.endswith(".svg"):
        score += 100
    elif p.endswith(".png"):
        score += 50
    if "scalable" in p:
        score += 80
    elif "256x256" in p or "128x128" in p:
        score += 70
    elif "64x64" in p:
        score += 60
    elif "48x48" in p:
        score += 40
    elif "32x32" in p:
        score += 30
    elif "16x16" in p:
        score += 10
    if "symbolic" in p:
        score -= 60  # prefer colorful icons over monochrome symbolic
    return score

_icon_cache = {}
def build_icon_map():
    global _icon_cache
    if _icon_cache:
        return _icon_cache
    
    icon_map = {}
    icon_scores = {}
    for base_dir in ICON_SEARCH_DIRS:
        if not os.path.isdir(base_dir):
            continue
        for root, _, files in os.walk(base_dir):
            for f in files:
                if f.endswith(('.svg', '.png', '.webp', '.xpm')):
                    name, _ = os.path.splitext(f)
                    path = os.path.join(root, f)
                    score = score_icon_path(path)
                    if name not in icon_map or score > icon_scores.get(name, -999):
                        icon_map[name] = path
                        icon_scores[name] = score
    _icon_cache = icon_map
    return _icon_cache

def resolve_icon(icon_name, fallback=""):
    if not icon_name:
        return fallback
    if os.path.isabs(icon_name) and os.path.exists(icon_name):
        return icon_name
    icon_map = build_icon_map()
    if icon_name in icon_map:
        return icon_map[icon_name]
    bname, _ = os.path.splitext(icon_name)
    if bname in icon_map:
        return icon_map[bname]
    return fallback

def get_trash_info():
    trash_info_dir = os.path.expanduser("~/.local/share/Trash/info")
    count = 0
    if os.path.exists(trash_info_dir):
        try:
            count = len(os.listdir(trash_info_dir))
        except Exception:
            count = 0
    icon_name = "user-trash-full" if count > 0 else "user-trash"
    icon_path = resolve_icon(icon_name, "/usr/share/icons/Papirus/128x128/places/user-trash.svg")
    name = f"Papelera ({count})" if count > 0 else "Papelera"
    return {
        "id": "system_trash",
        "type": "trash",
        "name": name,
        "icon": icon_path,
        "path": "trash:///",
        "exec": "nautilus trash:///",
        "terminal": False,
        "count": count
    }

def get_removable_drives():
    drives = []
    seen_mounts = set()
    user = os.environ.get("USER", "")

    # Check /run/media/$USER and /media
    search_dirs = []
    if user:
        search_dirs.append(f"/run/media/{user}")
        search_dirs.append(f"/media/{user}")
    search_dirs.append("/media")

    drive_icon = resolve_icon("drive-removable-media", "/usr/share/icons/Papirus/128x128/devices/drive-removable-media.svg")

    for s_dir in search_dirs:
        if os.path.isdir(s_dir):
            for entry in os.listdir(s_dir):
                full_path = os.path.join(s_dir, entry)
                if os.path.ismount(full_path) and full_path not in seen_mounts:
                    seen_mounts.add(full_path)
                    drives.append({
                        "id": f"drive_{entry}",
                        "type": "drive",
                        "name": entry,
                        "icon": drive_icon,
                        "path": full_path,
                        "exec": f'nautilus "{full_path}"',
                        "terminal": False
                    })

    # Also check lsblk for mounted hotplug or USB devices
    try:
        out = subprocess.check_output(
            ["lsblk", "-J", "-o", "NAME,MOUNTPOINT,RM,HOTPLUG,TRAN,LABEL,MODEL"],
            stderr=subprocess.DEVNULL
        ).decode("utf-8")
        data = json.loads(out)
        def parse_devices(dev_list):
            for dev in dev_list:
                mp = dev.get("mountpoint")
                is_removable = dev.get("rm") or dev.get("hotplug") or dev.get("tran") == "usb"
                if mp and is_removable and mp not in seen_mounts and mp not in ["/boot", "/", "/var", "/home"]:
                    seen_mounts.add(mp)
                    label = dev.get("label") or dev.get("model") or dev.get("name") or os.path.basename(mp)
                    drives.append({
                        "id": f"drive_{dev.get('name')}",
                        "type": "drive",
                        "name": label.strip(),
                        "icon": drive_icon,
                        "path": mp,
                        "exec": f'nautilus "{mp}"',
                        "terminal": False
                    })
                if "children" in dev and isinstance(dev["children"], list):
                    parse_devices(dev["children"])
        if "blockdevices" in data:
            parse_devices(data["blockdevices"])
    except Exception:
        pass

    return drives

def get_desktop_dir():
    try:
        out = subprocess.check_output(["xdg-user-dir", "DESKTOP"], stderr=subprocess.DEVNULL)
        path = out.decode("utf-8").strip()
        if os.path.isdir(path):
            return path
    except Exception:
        pass
    home_desk = os.path.expanduser("~/Escritorio")
    if os.path.isdir(home_desk):
        return home_desk
    return os.path.expanduser("~/Desktop")

def get_desktop_folder_items():
    desk_dir = get_desktop_dir()
    if not os.path.isdir(desk_dir):
        return []
    
    items = []
    folder_icon = resolve_icon("folder", "/usr/share/icons/Papirus/128x128/places/folder.svg")
    generic_file_icon = resolve_icon("application-x-generic", "/usr/share/icons/Papirus/128x128/mimetypes/application-x-generic.svg")
    
    try:
        entries = sorted(os.listdir(desk_dir))
    except Exception:
        return []

    for entry in entries:
        if entry.startswith("."):
            continue
        full_path = os.path.join(desk_dir, entry)

        if os.path.isdir(full_path):
            items.append({
                "id": f"desk_folder_{entry}",
                "type": "folder",
                "name": entry,
                "icon": folder_icon,
                "path": full_path,
                "exec": f'nautilus "{full_path}"',
                "terminal": False
            })
        elif entry.endswith(".desktop"):
            # Parse desktop file
            cfg = configparser.ConfigParser(interpolation=None)
            try:
                cfg.read(full_path, encoding="utf-8")
                if "Desktop Entry" in cfg:
                    e = cfg["Desktop Entry"]
                    name = e.get("Name", entry[:-8])
                    icon_raw = e.get("Icon", "")
                    icon_path = resolve_icon(icon_raw, "/usr/share/icons/Papirus/128x128/apps/application-default-icon.svg")
                    exec_cmd = clean_exec_command(e.get("Exec", ""))
                    terminal = e.get("Terminal", "false").lower() == "true"
                    items.append({
                        "id": f"desk_app_{entry}",
                        "type": "app",
                        "name": name,
                        "icon": icon_path,
                        "path": full_path,
                        "exec": exec_cmd,
                        "terminal": terminal
                    })
            except Exception:
                pass
        else:
            # File
            ext = os.path.splitext(entry)[1].lower()
            icon_for_file = generic_file_icon
            if ext in [".png", ".jpg", ".jpeg", ".svg", ".webp", ".gif"]:
                icon_for_file = resolve_icon("image-x-generic", generic_file_icon)
            elif ext in [".mp4", ".mkv", ".avi", ".webm"]:
                icon_for_file = resolve_icon("video-x-generic", generic_file_icon)
            elif ext in [".mp3", ".flac", ".wav", ".ogg"]:
                icon_for_file = resolve_icon("audio-x-generic", generic_file_icon)
            elif ext in [".pdf"]:
                icon_for_file = resolve_icon("application-pdf", generic_file_icon)
            elif ext in [".txt", ".md", ".json", ".sh", ".py"]:
                icon_for_file = resolve_icon("text-plain", generic_file_icon)
            elif ext in [".zip", ".tar", ".gz", ".xz", ".7z"]:
                icon_for_file = resolve_icon("package-x-generic", generic_file_icon)

            items.append({
                "id": f"desk_file_{entry}",
                "type": "file",
                "name": entry,
                "icon": icon_for_file,
                "path": full_path,
                "exec": f'xdg-open "{full_path}"',
                "terminal": False
            })

    return items

def get_all_installed_apps():
    icon_map = build_icon_map()
    seen_ids = set()
    apps = []

    for app_dir in APP_DIRS:
        if not os.path.isdir(app_dir):
            continue
        for filepath in glob.glob(os.path.join(app_dir, "*.desktop")):
            desktop_id = os.path.basename(filepath)
            if desktop_id in seen_ids:
                continue
            seen_ids.add(desktop_id)

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
                    terminal = entry.get("Terminal", "false").lower() == "true"
                    categories = entry.get("Categories", "").strip()

                    if not name or not exec_cmd:
                        continue

                    icon_file = resolve_icon(icon_name, "")

                    apps.append({
                        "id": desktop_id,
                        "name": name,
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
    return apps

def list_desktop_items():
    settings = get_settings()
    if not settings.get("enabled", True):
        return []

    items = []

    # 1. System items: Trash
    if settings.get("showTrash", True):
        items.append(get_trash_info())

    # 2. System items: Drives
    if settings.get("showDrives", True):
        items.extend(get_removable_drives())

    # 3. Desktop directory files & folders
    if settings.get("showFolders", True):
        items.extend(get_desktop_folder_items())

    # 4. Selected Application shortcuts
    selected_apps = settings.get("selectedApps", [])
    if selected_apps:
        all_apps = {a["id"]: a for a in get_all_installed_apps()}
        for app_id in selected_apps:
            if app_id in all_apps:
                app = all_apps[app_id]
                items.append({
                    "id": f"app_{app_id}",
                    "type": "app",
                    "name": app["name"],
                    "icon": app["iconPath"],
                    "path": app["desktopFile"],
                    "exec": app["exec"],
                    "terminal": app["terminal"]
                })

    return items

def list_apps_with_selection():
    settings = get_settings()
    selected_apps = set(settings.get("selectedApps", []))
    all_apps = get_all_installed_apps()
    for a in all_apps:
        a["isSelected"] = a["id"] in selected_apps
    return all_apps

def toggle_app_selection(desktop_id):
    settings = get_settings()
    selected = list(settings.get("selectedApps", []))
    if desktop_id in selected:
        selected.remove(desktop_id)
    else:
        selected.append(desktop_id)
    settings["selectedApps"] = selected
    save_settings(settings)
    return settings

def empty_trash():
    try:
        subprocess.run(["gio", "trash", "--empty"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        notify_reload()
        return {"status": "ok"}
    except Exception as e:
        return {"error": str(e)}

def unmount_drive(mount_path):
    try:
        subprocess.run(["gio", "mount", "-e", mount_path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        notify_reload()
        return {"status": "ok"}
    except Exception as e:
        return {"error": str(e)}

def launch_target(exec_cmd, terminal=False):
    if not exec_cmd:
        return {"error": "empty command"}
    cmd = exec_cmd
    if terminal:
        cmd = f"kitty {exec_cmd}"
    try:
        subprocess.Popen(
            cmd,
            shell=True,
            start_new_session=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            stdin=subprocess.DEVNULL
        )
        return {"status": "launched", "cmd": cmd}
    except Exception as e:
        return {"error": str(e)}

def main():
    if len(sys.argv) < 2:
        print(json.dumps(list_desktop_items(), ensure_ascii=False))
        return

    cmd = sys.argv[1]

    if cmd == "list_items":
        print(json.dumps(list_desktop_items(), ensure_ascii=False))
    elif cmd == "get_settings":
        print(json.dumps(get_settings(), ensure_ascii=False))
    elif cmd == "set_setting" and len(sys.argv) >= 4:
        key = sys.argv[2]
        raw_val = sys.argv[3]
        if raw_val.lower() == "true":
            val = True
        elif raw_val.lower() == "false":
            val = False
        else:
            try:
                val = int(raw_val)
            except ValueError:
                val = raw_val
        settings = get_settings()
        settings[key] = val
        save_settings(settings)
        print(json.dumps(settings, ensure_ascii=False))
    elif cmd == "list_apps":
        print(json.dumps(list_apps_with_selection(), ensure_ascii=False))
    elif cmd == "toggle_app" and len(sys.argv) >= 3:
        desktop_id = sys.argv[2]
        res = toggle_app_selection(desktop_id)
        print(json.dumps(res, ensure_ascii=False))
    elif cmd == "empty_trash":
        print(json.dumps(empty_trash(), ensure_ascii=False))
    elif cmd == "unmount_drive" and len(sys.argv) >= 3:
        print(json.dumps(unmount_drive(sys.argv[2]), ensure_ascii=False))
    elif cmd == "launch" and len(sys.argv) >= 3:
        exec_cmd = sys.argv[2]
        is_term = len(sys.argv) >= 4 and sys.argv[3].lower() == "true"
        print(json.dumps(launch_target(exec_cmd, is_term), ensure_ascii=False))
    else:
        print(json.dumps({"error": f"Unknown action {cmd}"}))

if __name__ == "__main__":
    main()
