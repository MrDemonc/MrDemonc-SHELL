#!/usr/bin/env python3
import sys
import os
import json

CONFIG_DIR = os.path.expanduser("~/.config/quickshell")
CONFIG_FILE = os.path.join(CONFIG_DIR, "indicators_order.json")
SECTIONS_FILE = os.path.join(CONFIG_DIR, "bar_sections.json")
DEFAULT_SECTIONS = {
    "left": ["workspaces", "cava"],
    "center": ["clock"],
    "right": ["tray", "audio", "bluetooth", "wifi", "battery"]
}
ALL_ITEMS = ["workspaces", "cava", "clock", "tray", "audio", "bluetooth", "wifi", "battery"]

def get_sections():
    if not os.path.exists(SECTIONS_FILE):
        return DEFAULT_SECTIONS
    try:
        with open(SECTIONS_FILE, "r") as f:
            data = json.load(f)
            if isinstance(data, dict) and "left" in data and "center" in data and "right" in data:
                # Validar que todos los items existan sin duplicados
                seen = set()
                res = {"left": [], "center": [], "right": []}
                for sec in ["left", "center", "right"]:
                    for it in data.get(sec, []):
                        if it in ALL_ITEMS and it not in seen:
                            seen.add(it)
                            res[sec].append(it)
                # Agregar faltantes si los hay
                for it in ALL_ITEMS:
                    if it not in seen:
                        if it in ("workspaces", "cava"):
                            res["left"].append(it)
                        elif it == "clock":
                            res["center"].append(it)
                        else:
                            res["right"].append(it)
                        seen.add(it)
                return res
    except Exception:
        pass
    return DEFAULT_SECTIONS

def save_sections(sections):
    try:
        os.makedirs(CONFIG_DIR, exist_ok=True)
        with open(SECTIONS_FILE, "w") as f:
            json.dump(sections, f)
    except Exception:
        pass

POSITION_FILE = os.path.join(CONFIG_DIR, "bar_position.json")

def get_position():
    if not os.path.exists(POSITION_FILE):
        return {"position": "top"}
    try:
        with open(POSITION_FILE, "r") as f:
            data = json.load(f)
            if data.get("position") in ["top", "bottom", "left", "right"]:
                return data
    except Exception:
        pass
    return {"position": "top"}

def save_position(pos):
    if pos not in ["top", "bottom", "left", "right"]:
        return
    try:
        os.makedirs(CONFIG_DIR, exist_ok=True)
        with open(POSITION_FILE, "w") as f:
            json.dump({"position": pos}, f)
        # Notify running quickshell instance
        runtime_dir = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
        notify_file = os.path.join(runtime_dir, "quickshell_bar_position.set")
        with open(notify_file, "w") as f:
            f.write(pos)
    except Exception:
        pass

VISIBILITY_FILE = os.path.join(CONFIG_DIR, "indicators_visibility.json")
DEFAULT_VISIBILITY = {
    "workspaces": True,
    "cava": True,
    "clock": True,
    "tray": True,
    "audio": True,
    "bluetooth": True,
    "wifi": True,
    "battery": True
}

def get_visibility():
    res = dict(DEFAULT_VISIBILITY)
    if not os.path.exists(VISIBILITY_FILE):
        return res
    try:
        with open(VISIBILITY_FILE, "r") as f:
            data = json.load(f)
            if isinstance(data, dict):
                for k, v in data.items():
                    if k in res:
                        res[k] = bool(v)
    except Exception:
        pass
    return res

def save_visibility(vis):
    try:
        os.makedirs(CONFIG_DIR, exist_ok=True)
        cur = get_visibility()
        if isinstance(vis, dict):
            for k, v in vis.items():
                if k in cur:
                    cur[k] = bool(v)
        with open(VISIBILITY_FILE, "w") as f:
            json.dump(cur, f, indent=2)
        runtime_dir = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
        notify_file = os.path.join(runtime_dir, "quickshell_indicators_visibility.set")
        with open(notify_file, "w") as f:
            f.write(json.dumps(cur))
    except Exception:
        pass

if __name__ == "__main__":
    if len(sys.argv) > 1:
        action = sys.argv[1]
        if action == "save_position" and len(sys.argv) > 2:
            pos = sys.argv[2].strip().lower()
            save_position(pos)
            print(json.dumps({"success": True, "position": pos}))
            sys.exit(0)
        elif action == "get_position":
            print(json.dumps(get_position()))
            sys.exit(0)
        elif action == "save_sections" and len(sys.argv) > 2:
            try:
                new_sec = json.loads(sys.argv[2])
                if isinstance(new_sec, dict):
                    save_sections(new_sec)
                    print(json.dumps({"success": True, "sections": new_sec}))
                    sys.exit(0)
            except Exception as e:
                print(json.dumps({"success": False, "error": str(e)}))
                sys.exit(1)
        elif action == "get_sections":
            print(json.dumps({"sections": get_sections()}))
            sys.exit(0)
        elif action == "get_visibility":
            print(json.dumps({"visibility": get_visibility()}))
            sys.exit(0)
        elif action == "save_visibility" and len(sys.argv) > 2:
            try:
                new_vis = json.loads(sys.argv[2])
                if isinstance(new_vis, dict):
                    save_visibility(new_vis)
                    print(json.dumps({"success": True, "visibility": get_visibility()}))
                    sys.exit(0)
            except Exception as e:
                print(json.dumps({"success": False, "error": str(e)}))
                sys.exit(1)
    print(json.dumps({"sections": get_sections()}))

