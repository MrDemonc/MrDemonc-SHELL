#!/usr/bin/env python3
import sys
import os
import json

CONFIG_DIR = os.path.expanduser("~/.config/quickshell")
CONFIG_FILE = os.path.join(CONFIG_DIR, "indicators_order.json")
SECTIONS_FILE = os.path.join(CONFIG_DIR, "bar_sections.json")
DEFAULT_SECTIONS = {
    "left": ["workspaces"],
    "center": ["clock"],
    "right": ["audio", "bluetooth", "wifi", "battery"]
}
ALL_ITEMS = ["workspaces", "clock", "audio", "bluetooth", "wifi", "battery"]

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
                        if it == "workspaces":
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

if __name__ == "__main__":
    if len(sys.argv) > 1:
        action = sys.argv[1]
        if action == "save_sections" and len(sys.argv) > 2:
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
    print(json.dumps({"sections": get_sections()}))
