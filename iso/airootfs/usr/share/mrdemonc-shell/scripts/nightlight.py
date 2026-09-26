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
        tmp_cfg = CONFIG_FILE + ".tmp"
        with open(tmp_cfg, "w") as f:
            json.dump(state, f, indent=2)
        os.replace(tmp_cfg, CONFIG_FILE)

        tmp_not = NOTIFY_FILE + ".tmp"
        with open(tmp_not, "w") as f:
            f.write(json.dumps(state))
        os.replace(tmp_not, NOTIFY_FILE)
    except Exception:
        pass

def generate_shader(r, g, b):
    # Formato GLSL 3.00 ES estándar para Hyprland moderno
    content = f"""#version 300 es
precision mediump float;
in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;
uniform sampler2D tex;

void main() {{
    vec4 pixColor = texture(tex, v_texcoord);
    fragColor = vec4(pixColor.r * {r:.4f}, pixColor.g * {g:.4f}, pixColor.b * {b:.4f}, pixColor.a);
}}
"""
    try:
        tmp_sh = SHADER_FILE + ".tmp"
        with open(tmp_sh, "w") as f:
            f.write(content)
        os.replace(tmp_sh, SHADER_FILE)
        return True
    except Exception:
        return False

def apply_state(state):
    enabled = state.get("enabled", False)
    temp = state.get("temperature", 4000)

    has_hyprsunset = shutil.which("hyprsunset") is not None
    has_wlsunset = shutil.which("wlsunset") is not None

    if not enabled:
        # Desactivar todas las herramientas de luz nocturna
        if has_hyprsunset:
            subprocess.run(["pkill", "-x", "hyprsunset"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if has_wlsunset:
            subprocess.run(["pkill", "-x", "wlsunset"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

        # Limpiar screen_shader en Hyprland tanto con eval como con keyword
        subprocess.run(["hyprctl", "eval", "hl.config({ decoration = { screen_shader = '' } })"],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        subprocess.run(["hyprctl", "keyword", "decoration:screen_shader", "''"],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return

    # Si está activado:
    if has_hyprsunset:
        # Limpiar screen_shader previo para evitar doble tinte
        subprocess.run(["hyprctl", "eval", "hl.config({ decoration = { screen_shader = '' } })"],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        subprocess.run(["pkill", "-x", "hyprsunset"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        subprocess.Popen(["hyprsunset", "-t", str(temp)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    elif has_wlsunset:
        subprocess.run(["hyprctl", "eval", "hl.config({ decoration = { screen_shader = '' } })"],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        subprocess.run(["pkill", "-x", "wlsunset"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        subprocess.Popen(["wlsunset", "-t", str(temp), "-T", str(temp)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    else:
        # Fallback nativo: Hyprland Screen Shader GLSL 3.00 ES
        try:
            r, g, b = kelvin_to_rgb(temp)
            if generate_shader(r, g, b):
                res = subprocess.run(["hyprctl", "eval", f"hl.config({{ decoration = {{ screen_shader = '{SHADER_FILE}' }} }})"],
                                     stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
                if res.returncode != 0 or "unknown" in res.stderr.lower():
                    subprocess.run(["hyprctl", "keyword", "decoration:screen_shader", SHADER_FILE],
                                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
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
