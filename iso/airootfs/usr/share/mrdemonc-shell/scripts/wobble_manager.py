#!/usr/bin/env python3
import os
import sys
import json
import subprocess

CONFIG_DIR = os.path.expanduser("~/.config/quickshell")
SETTINGS_FILE = os.path.join(CONFIG_DIR, "wobble.json")
HYPR_CONFIG_DIR = os.path.expanduser("~/.config/hypr")
HYPR_LUA_FILE = os.path.join(HYPR_CONFIG_DIR, "wobble_config.lua")

PRESETS = {
    "subtle": {
        "name": "Sutil",
        "stiffness": 220.0,
        "damping": 14.0,
        "mass": 1.0,
        "intensity": 0.15
    },
    "compiz": {
        "name": "Compiz Clásico",
        "stiffness": 180.0,
        "damping": 11.0,
        "mass": 1.0,
        "intensity": 0.25
    },
    "jelly": {
        "name": "Gelatina Total",
        "stiffness": 120.0,
        "damping": 8.0,
        "mass": 1.0,
        "intensity": 0.40
    }
}

DEFAULT_SETTINGS = {
    "enabled": True,
    "preset": "compiz",
    "mesh": 12,
    "stiffness": 180.0,
    "damping": 11.0,
    "mass": 1.0,
    "intensity": 0.25
}

def load_settings():
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
    os.makedirs(HYPR_CONFIG_DIR, exist_ok=True)
    
    # Guardar JSON
    tmp_json = SETTINGS_FILE + ".tmp"
    with open(tmp_json, "w", encoding="utf-8") as f:
        json.dump(settings, f, indent=2)
    os.replace(tmp_json, SETTINGS_FILE)

    # Generar módulo Lua para arranque nativo de Hyprland
    lua_code = f"""-- Configuración automática de Wobble / Ventanas Gelatinosas (Hyprland 0.57+)
-- Archivo generado automáticamente por MrDemonc-SHELL
return {{
    enabled   = {str(settings.get("enabled", True)).lower()},
    mesh      = {int(settings.get("mesh", 12))},
    stiffness = {float(settings.get("stiffness", 180.0))},
    damping   = {float(settings.get("damping", 11.0))},
    mass      = {float(settings.get("mass", 1.0))},
    intensity = {float(settings.get("intensity", 0.25))},
}}
"""
    tmp_lua = HYPR_LUA_FILE + ".tmp"
    with open(tmp_lua, "w", encoding="utf-8") as f:
        f.write(lua_code)
    os.replace(tmp_lua, HYPR_LUA_FILE)

    # Aplicar inmediatamente en vivo a Hyprland si el compositor está activo
    apply_to_hyprland(settings)

def apply_to_hyprland(settings):
    enabled_str = "true" if settings.get("enabled", True) else "false"
    mesh = int(settings.get("mesh", 12))
    stiffness = float(settings.get("stiffness", 180.0))
    damping = float(settings.get("damping", 11.0))
    mass = float(settings.get("mass", 1.0))
    intensity = float(settings.get("intensity", 0.25))

    lua_cmd = f"hl.config({{ decoration = {{ wobble = {{ enabled = {enabled_str}, mesh = {mesh}, stiffness = {stiffness}, damping = {damping}, mass = {mass}, intensity = {intensity} }} }} }})"
    try:
        subprocess.run(["hyprctl", "eval", lua_cmd], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

def main():
    if len(sys.argv) < 2:
        print(json.dumps(load_settings()))
        return

    cmd = sys.argv[1]

    if cmd == "get":
        print(json.dumps(load_settings()))
    elif cmd == "set_enabled" and len(sys.argv) >= 3:
        val = sys.argv[2].lower() in ["true", "1", "yes", "on"]
        s = load_settings()
        s["enabled"] = val
        save_settings(s)
        print(json.dumps(s))
    elif cmd == "toggle":
        s = load_settings()
        s["enabled"] = not s.get("enabled", True)
        save_settings(s)
        print(json.dumps(s))
    elif cmd == "set_preset" and len(sys.argv) >= 3:
        p_name = sys.argv[2].lower()
        if p_name in PRESETS:
            s = load_settings()
            s["preset"] = p_name
            s.update(PRESETS[p_name])
            save_settings(s)
            print(json.dumps(s))
        else:
            print(json.dumps({"error": f"Preset desconocido {p_name}"}))
    elif cmd == "set" and len(sys.argv) >= 5:
        try:
            stiffness = float(sys.argv[2])
            damping = float(sys.argv[3])
            intensity = float(sys.argv[4])
            s = load_settings()
            s["stiffness"] = stiffness
            s["damping"] = damping
            s["intensity"] = intensity
            s["preset"] = "custom"
            save_settings(s)
            print(json.dumps(s))
        except Exception as e:
            print(json.dumps({"error": str(e)}))
    else:
        print(json.dumps({"error": f"Comando desconocido {cmd}"}))

if __name__ == "__main__":
    main()
