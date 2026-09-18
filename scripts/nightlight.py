#!/usr/bin/env python3
import os
import sys
import json
import math
import shutil
import subprocess

CONFIG_DIR = os.path.expanduser("~/.config/quickshell")
CONFIG_FILE = os.path.join(CONFIG_DIR, "nightlight.json")
RUNTIME_DIR = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
NOTIFY_FILE = os.path.join(RUNTIME_DIR, "quickshell_nightlight.set")
SHADER_FILE = os.path.join(RUNTIME_DIR, "quickshell_nightlight.frag")

DEFAULT_STATE = {
    "enabled": False,
    "temperature": 4000
}

def kelvin_to_rgb(temp_kelvin):
    # Tanner Helland formula
    t = temp_kelvin / 100.0
    if t <= 66:
        red = 255.0
    else:
        red = 329.698727446 * ((t - 60) ** -0.1332047592)
        red = max(0.0, min(255.0, red))

    if t <= 66:
        green = 99.4708025861 * math.log(t) - 161.1195681661
    else:
        green = 288.1221695283 * ((t - 60) ** -0.0755148492)
    green = max(0.0, min(255.0, green))

    if t >= 66:
        blue = 255.0
    elif t <= 19:
        blue = 0.0
    else:
        blue = 138.5177312231 * math.log(t - 10) - 305.0447927307
    blue = max(0.0, min(255.0, blue))

    return red / 255.0, green / 255.0, blue / 255.0

def load_state():
    if not os.path.exists(CONFIG_FILE):
        return dict(DEFAULT_STATE)
    try:
        with open(CONFIG_FILE, "r") as f:
            data = json.load(f)
            return {
                "enabled": bool(data.get("enabled", False)),
                "temperature": int(data.get("temperature", 4000))
            }
    except Exception:
        return dict(DEFAULT_STATE)

def save_state(state):
    try:
        os.makedirs(CONFIG_DIR, exist_ok=True)
        with open(CONFIG_FILE, "w") as f:
            json.dump(state, f, indent=2)
        with open(NOTIFY_FILE, "w") as f:
            f.write(json.dumps(state))
    except Exception:
        pass

def generate_shader(r, g, b):
    content = f"""precision highp float;
varying vec2 v_texcoord;
uniform sampler2D tex;

void main() {{
    vec4 pixColor = texture2D(tex, v_texcoord);
    gl_FragColor = vec4(pixColor.r * {r:.4f}, pixColor.g * {g:.4f}, pixColor.b * {b:.4f}, pixColor.a);
}}
"""
    try:
        with open(SHADER_FILE, "w") as f:
            f.write(content)
        return True
    except Exception:
        return False

def apply_state(state):
    enabled = state.get("enabled", False)
    temp = state.get("temperature", 4000)

    # 1. Si existe hyprsunset, usarlo como complemento
    has_hyprsunset = shutil.which("hyprsunset") is not None
    if has_hyprsunset:
        subprocess.run(["pkill", "-x", "hyprsunset"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if enabled:
            subprocess.Popen(["hyprsunset", "-t", str(temp)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    # 2. Aplicar de forma nativa vía Hyprland Screen Shader
    try:
        if enabled:
            r, g, b = kelvin_to_rgb(temp)
            if generate_shader(r, g, b):
                lua_cmd = f"hl.config({{ decoration = {{ screen_shader = '{SHADER_FILE}' }} }})"
                subprocess.run(["hyprctl", "eval", lua_cmd], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        else:
            lua_cmd = "hl.config({ decoration = { screen_shader = '' } })"
            subprocess.run(["hyprctl", "eval", lua_cmd], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

def main():
    state = load_state()
    if len(sys.argv) > 1:
        cmd = sys.argv[1].lower()
        if cmd == "get":
            print(json.dumps(state))
            return
        elif cmd == "set" and len(sys.argv) > 2:
            try:
                t = int(sys.argv[2])
                t = max(2000, min(6500, t))
                state["temperature"] = t
                save_state(state)
                apply_state(state)
            except ValueError:
                pass
        elif cmd == "toggle":
            state["enabled"] = not state["enabled"]
            save_state(state)
            apply_state(state)
        elif cmd == "on":
            state["enabled"] = True
            if len(sys.argv) > 2:
                try:
                    t = int(sys.argv[2])
                    state["temperature"] = max(2000, min(6500, t))
                except ValueError:
                    pass
            save_state(state)
            apply_state(state)
        elif cmd == "off":
            state["enabled"] = False
            save_state(state)
            apply_state(state)
        elif cmd == "apply":
            apply_state(state)

    print(json.dumps(state))

if __name__ == "__main__":
    main()
