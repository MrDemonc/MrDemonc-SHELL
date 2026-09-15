#!/usr/bin/env python3
import sys
import os
import json
import subprocess

CONFIG_DIR = os.path.expanduser("~/.config/quickshell")
HYPR_MONITORS_LUA = os.path.expanduser("~/.config/hypr/monitors.lua")

os.makedirs(CONFIG_DIR, exist_ok=True)

def run_cmd(cmd):
    try:
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=False)
        return res.stdout.strip()
    except Exception:
        return ""

def eval_hyprland_lua(lua_code):
    cmd = ["hyprctl", "eval", lua_code]
    return run_cmd(cmd)

def is_laptop_display(name):
    lower = name.lower()
    return lower.startswith("edp") or lower.startswith("lvds") or lower.startswith("dsi")

def get_monitors():
    out = run_cmd(["hyprctl", "monitors", "all", "-j"])
    data = []
    if out:
        try:
            data = json.loads(out)
        except Exception:
            data = []

    monitors = []
    for m in data:
        name = m.get("name", "")
        if not name:
            continue
        
        is_laptop = is_laptop_display(name)
        disabled = bool(m.get("disabled", False))
        width = m.get("width", 1920)
        height = m.get("height", 1080)
        rr = round(float(m.get("refreshRate", 60.0)), 2)
        scale = float(m.get("scale", 1.0))
        focused = bool(m.get("focused", False))
        mirror = m.get("mirrorOf", "none") or "none"
        transform = int(m.get("transform", 0))
        desc = m.get("description", "") or m.get("model", "") or ("Pantalla Integrada" if is_laptop else "Monitor Externo")

        def calculate_aspect_ratio(w, h):
            import math
            g = math.gcd(w, h)
            aw, ah = w // g, h // g
            if (aw, ah) == (8, 5): return "16:10"
            if (aw, ah) == (64, 27) or (aw, ah) == (43, 18) or (aw, ah) == (12, 5): return "21:9"
            if (aw, ah) == (32, 9): return "32:9"
            return f"{aw}:{ah}"

        def get_edid_max_refresh(connector_name):
            import glob
            for edid_file in glob.glob(f"/sys/class/drm/*{connector_name}*/edid"):
                try:
                    with open(edid_file, "rb") as f:
                        data = f.read()
                    if len(data) >= 128:
                        for offset in [54, 72, 90, 108]:
                            if data[offset:offset+5] == b"\x00\x00\x00\xfd\x00":
                                max_v_rate = data[offset + 6]
                                if 30 <= max_v_rate <= 360:
                                    return float(max_v_rate)
                except Exception:
                    pass
            return None

        raw_modes = m.get("availableModes", [])
        res_modes = {}
        import re
        for rm in raw_modes:
            match = re.match(r"^(\d+)x(\d+)(?:[@\s]+([\d\.]+))?(?:Hz)?", rm, re.IGNORECASE)
            if match:
                w = int(match.group(1))
                h = int(match.group(2))
                rate = float(match.group(3)) if match.group(3) else 60.0
                key = (w, h)
                if key not in res_modes:
                    res_modes[key] = set()
                res_modes[key].add(rate)

        # Check EDID for hardware maximum refresh rate (e.g. 120Hz, 144Hz)
        edid_max = get_edid_max_refresh(name)
        if edid_max and edid_max >= 100.0:
            if (width, height) not in res_modes:
                res_modes[(width, height)] = set()
            res_modes[(width, height)].add(edid_max)
            if edid_max >= 120.0:
                res_modes[(width, height)].add(120.0)
            res_modes[(width, height)].add(60.0)

        # Ensure current active resolution and refresh rate are present
        if (width, height) not in res_modes:
            res_modes[(width, height)] = set()
        res_modes[(width, height)].add(rr)

        if not res_modes:
            res_modes[(width, height)] = {rr}
            aspect = calculate_aspect_ratio(width, height)
            if aspect == "16:9":
                res_modes.setdefault((1920, 1080), {60.0})
                res_modes.setdefault((1600, 900), {60.0})
                res_modes.setdefault((1366, 768), {60.0})
                res_modes.setdefault((1280, 720), {60.0})
            elif aspect == "16:10":
                res_modes.setdefault((1920, 1200), {60.0})
                res_modes.setdefault((1680, 1050), {60.0})
                res_modes.setdefault((1440, 900), {60.0})
                res_modes.setdefault((1280, 800), {60.0})

        # Order resolutions by pixel count descending
        sorted_keys = sorted(res_modes.keys(), key=lambda x: (x[0] * x[1]), reverse=True)
        structured_modes = []

        # Find max rate for native resolution
        native_rates = sorted(list(res_modes.get((width, height), {rr})), reverse=True)
        max_native_rate = int(round(native_rates[0])) if native_rates else int(round(rr))
        native_aspect = calculate_aspect_ratio(width, height)

        # Preferred / Native Option
        structured_modes.append({
            "mode": "preferred",
            "resolution": f"{width}x{height}",
            "label": f"{width} × {height} ({native_aspect})",
            "rate": f"{max_native_rate}Hz",
            "display": f"{width} × {height} ({native_aspect}) · Automática ({max_native_rate}Hz)",
            "is_native": True
        })

        for w, h in sorted_keys:
            aspect = calculate_aspect_ratio(w, h)
            rates = sorted(list(res_modes[(w, h)]), reverse=True)
            seen_rounded = set()
            for r in rates:
                r_int = int(round(r))
                if r_int in seen_rounded:
                    continue
                seen_rounded.add(r_int)
                is_native = (w == width and h == height)
                mode_str = f"{w}x{h}@{r:.2f}Hz"
                disp_str = f"{w} × {h} ({aspect}) · {r_int}Hz" + (" (Nativa)" if (is_native and r_int == max_native_rate) else "")
                structured_modes.append({
                    "mode": mode_str,
                    "resolution": f"{w}x{h}",
                    "label": f"{w} × {h} ({aspect})",
                    "rate": f"{r_int}Hz",
                    "display": disp_str,
                    "is_native": is_native
                })

        monitors.append({
            "name": name,
            "description": desc,
            "is_laptop": is_laptop,
            "is_external": not is_laptop,
            "width": width,
            "height": height,
            "refresh_rate": rr,
            "current_mode": f"{width}x{height}@{rr}Hz",
            "scale": scale,
            "focused": focused,
            "disabled": disabled,
            "mirror": mirror,
            "transform": transform,
            "modes": structured_modes,
            "available_modes": [sm["mode"] for sm in structured_modes],
            "resolutions": [f"{w}x{h}" for w, h in sorted_keys],
            "pos_x": m.get("x", 0),
            "pos_y": m.get("y", 0)
        })

    monitors.sort(key=lambda x: (not x["is_laptop"], x["name"]))

    laptop_count = sum(1 for m in monitors if m["is_laptop"])
    external_count = sum(1 for m in monitors if m["is_external"])

    return {
        "monitors": monitors,
        "count": len(monitors),
        "laptop_count": laptop_count,
        "external_count": external_count,
        "has_external": external_count > 0,
        "has_laptop": laptop_count > 0
    }

def save_monitors_lua(monitors):
    try:
        lines = ["-- Autogenerated by MrDemonc-SHELL Monitor Manager"]
        for m in monitors:
            name = m["name"]
            if m.get("disabled", False):
                lines.append(f'hl.monitor({{ output = "{name}", disabled = true }})')
            else:
                mode = m.get("mode", "preferred")
                pos = m.get("pos", "auto")
                scale = m.get("scale", 1.0)
                trans = m.get("transform", 0)
                mirror = m.get("mirror", "")
                if mirror and mirror != "none":
                    lines.append(f'hl.monitor({{ output = "{name}", mirror = "{mirror}" }})')
                else:
                    lines.append(f'hl.monitor({{ output = "{name}", mode = "{mode}", position = "{pos}", scale = {scale}, transform = {trans}, disabled = false }})')
        with open(HYPR_MONITORS_LUA, "w") as f:
            f.write("\n".join(lines) + "\n")
    except Exception:
        pass

def apply_monitor_rule(output, mode="preferred", position="auto", scale=1.0, transform=0, disabled=False, mirror=""):
    if disabled:
        run_cmd(["hyprctl", "keyword", "monitor", f"{output},disable"])
        lua = f'hl.monitor({{ output = "{output}", disabled = true }})'
    elif mirror and mirror != "none":
        run_cmd(["hyprctl", "keyword", "monitor", f"{output},preferred,auto,1,mirror,{mirror}"])
        lua = f'hl.monitor({{ output = "{output}", mode = "preferred", position = "auto", scale = 1.0, mirror = "{mirror}", disabled = false }})'
    else:
        run_cmd(["hyprctl", "keyword", "monitor", f"{output},{mode},{position},{scale},transform,{transform}"])
        lua = f'hl.monitor({{ output = "{output}", mode = "{mode}", position = "{position}", scale = {scale}, transform = {transform}, disabled = false }})'
    eval_hyprland_lua(lua)

def dpms_off():
    user_home = os.path.expanduser("~")
    shell_dpms_bin = os.path.join(user_home, ".local", "bin", "shell-dpms")
    if not os.path.isfile(shell_dpms_bin):
        shell_dpms_bin = "/usr/local/bin/shell-dpms"
    if os.path.isfile(shell_dpms_bin):
        run_cmd([shell_dpms_bin, "off"])
    else:
        eval_hyprland_lua('hl.dispatch(hl.dsp.dpms("off"))')

def dpms_on():
    user_home = os.path.expanduser("~")
    shell_dpms_bin = os.path.join(user_home, ".local", "bin", "shell-dpms")
    if not os.path.isfile(shell_dpms_bin):
        shell_dpms_bin = "/usr/local/bin/shell-dpms"
    if os.path.isfile(shell_dpms_bin):
        run_cmd([shell_dpms_bin, "on"])
    else:
        eval_hyprland_lua('hl.dispatch(hl.dsp.dpms("on"))')

def handle_lid_close():
    data = get_monitors()
    monitors = data.get("monitors", [])
    laptop = next((m for m in monitors if m.get("is_laptop", False)), None)
    externals = [m for m in monitors if m.get("is_external", False)]
    # Si hay pantalla externa conectada (HDMI, DisplayPort, etc.):
    # Modo clamshell: NO bloquear, apagar sólo la pantalla integrada de la laptop y mantener la externa activa
    if externals:
        res = apply_preset("external_only")
        dpms_on()
        return res
    else:
        # Solo laptop sin pantalla externa: bloquear inmediatamente y apagar el display
        user_home = os.path.expanduser("~")
        shell_lock_bin = os.path.join(user_home, ".local", "bin", "shell-lock")
        if not os.path.isfile(shell_lock_bin):
            shell_lock_bin = "/usr/local/bin/shell-lock"
        if not os.path.isfile(shell_lock_bin):
            shell_lock_bin = "shell-lock"
        run_cmd([shell_lock_bin])
        import time
        time.sleep(0.1)
        dpms_off()
        return {"status": "ok", "action": "locked_and_dpms_off"}

def handle_lid_open():
    dpms_on()
    data = get_monitors()
    monitors = data.get("monitors", [])
    laptop = next((m for m in monitors if m.get("is_laptop", False)), None)
    externals = [m for m in monitors if m.get("is_external", False)]
    if laptop and externals:
        res = apply_preset("extend")
    else:
        if laptop:
            apply_monitor_rule(laptop["name"], mode="preferred", position="0x0", scale=1.0, disabled=False)
            save_monitors_lua([{"name": laptop["name"], "mode": "preferred", "pos": "0x0", "scale": 1.0, "disabled": False}])
            run_cmd(["hyprctl", "dispatch", "focusmonitor", laptop["name"]])
        res = {"status": "ok", "action": "laptop_active"}
    dpms_on()
    return res

def apply_preset(preset_name):
    data = get_monitors()
    monitors = data.get("monitors", [])
    if not monitors:
        return {"status": "error", "message": "No se detectaron monitores"}

    laptop = next((m for m in monitors if m["is_laptop"]), None)
    externals = [m for m in monitors if m["is_external"]]

    lua_rules = []

    if preset_name == "external_only":
        if not externals:
            return {"status": "error", "message": "No hay monitor externo conectado"}
        if laptop:
            apply_monitor_rule(laptop["name"], disabled=True)
            lua_rules.append({"name": laptop["name"], "disabled": True})
        for i, ext in enumerate(externals):
            pos = "0x0" if i == 0 else "auto-right"
            apply_monitor_rule(ext["name"], mode="preferred", position=pos, scale=1.0, disabled=False)
            lua_rules.append({"name": ext["name"], "mode": "preferred", "pos": pos, "scale": 1.0, "disabled": False})
        run_cmd(["hyprctl", "dispatch", "focusmonitor", externals[0]["name"]])

    elif preset_name == "laptop_only":
        if not laptop:
            return {"status": "error", "message": "No se detectó pantalla de laptop"}
        for ext in externals:
            apply_monitor_rule(ext["name"], disabled=True)
            lua_rules.append({"name": ext["name"], "disabled": True})
        apply_monitor_rule(laptop["name"], mode="preferred", position="0x0", scale=1.0, disabled=False)
        lua_rules.append({"name": laptop["name"], "mode": "preferred", "pos": "0x0", "scale": 1.0, "disabled": False})
        run_cmd(["hyprctl", "dispatch", "focusmonitor", laptop["name"]])

    elif preset_name == "extend":
        if laptop:
            apply_monitor_rule(laptop["name"], mode="preferred", position="0x0", scale=1.0, disabled=False)
            lua_rules.append({"name": laptop["name"], "mode": "preferred", "pos": "0x0", "scale": 1.0, "disabled": False})
        for i, ext in enumerate(externals):
            pos = "auto-right" if (laptop or i > 0) else "0x0"
            apply_monitor_rule(ext["name"], mode="preferred", position=pos, scale=1.0, disabled=False)
            lua_rules.append({"name": ext["name"], "mode": "preferred", "pos": pos, "scale": 1.0, "disabled": False})

    elif preset_name == "mirror":
        primary = laptop if laptop else (externals[0] if externals else None)
        if not primary:
            return {"status": "error", "message": "No hay monitores para duplicar"}
        apply_monitor_rule(primary["name"], mode="preferred", position="0x0", scale=1.0, disabled=False)
        lua_rules.append({"name": primary["name"], "mode": "preferred", "pos": "0x0", "scale": 1.0, "disabled": False})

        for ext in externals:
            if ext["name"] != primary["name"]:
                apply_monitor_rule(ext["name"], mirror=primary["name"])
                lua_rules.append({"name": ext["name"], "mirror": primary["name"], "disabled": False})

    save_monitors_lua(lua_rules)
    return {"status": "ok", "preset": preset_name}

def main():
    if len(sys.argv) < 2:
        print(json.dumps(get_monitors(), indent=2))
        return

    action = sys.argv[1]

    if action == "get":
        print(json.dumps(get_monitors()))
        return

    if action == "lid_close":
        print(json.dumps(handle_lid_close()))
        return

    if action == "lid_open":
        print(json.dumps(handle_lid_open()))
        return

    if action == "preset":
        if len(sys.argv) < 3:
            print(json.dumps({"status": "error", "message": "Falta el nombre del preset"}))
            return
        res = apply_preset(sys.argv[2])
        print(json.dumps(res))
        return

    if action == "set":
        import argparse
        parser = argparse.ArgumentParser()
        parser.add_argument("action")
        parser.add_argument("--output", required=True)
        parser.add_argument("--enable", action="store_true")
        parser.add_argument("--disable", action="store_true")
        parser.add_argument("--mode", default="preferred")
        parser.add_argument("--scale", type=float, default=1.0)
        parser.add_argument("--pos", default="auto")
        parser.add_argument("--transform", type=int, default=0)
        parser.add_argument("--mirror", default="")
        args = parser.parse_args()

        disabled = args.disable if args.disable else (not args.enable if args.enable else False)
        apply_monitor_rule(
            output=args.output,
            mode=args.mode,
            position=args.pos,
            scale=args.scale,
            transform=args.transform,
            disabled=disabled,
            mirror=args.mirror
        )
        print(json.dumps({"status": "ok", "output": args.output}))
        return

if __name__ == "__main__":
    main()
