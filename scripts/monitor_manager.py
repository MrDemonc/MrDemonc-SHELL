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

        raw_modes = m.get("availableModes", [])
        res_dict = {}
        import re
        for rm in raw_modes:
            match = re.match(r"^(\d+)x(\d+)(?:@([\d\.]+)Hz)?", rm)
            if match:
                w = int(match.group(1))
                h = int(match.group(2))
                rate = float(match.group(3)) if match.group(3) else 60.0
                key = (w, h)
                if key not in res_dict or rate > res_dict[key]:
                    res_dict[key] = rate

        if not res_dict:
            res_dict[(width, height)] = rr
            aspect = calculate_aspect_ratio(width, height)
            if aspect == "16:9":
                res_dict.setdefault((1920, 1080), 60.0)
                res_dict.setdefault((1600, 900), 60.0)
                res_dict.setdefault((1366, 768), 60.0)
                res_dict.setdefault((1280, 720), 60.0)
            elif aspect == "16:10":
                res_dict.setdefault((1920, 1200), 60.0)
                res_dict.setdefault((1680, 1050), 60.0)
                res_dict.setdefault((1440, 900), 60.0)
                res_dict.setdefault((1280, 800), 60.0)

        # Ordenar resoluciones por total de píxeles (de mayor a menor)
        sorted_keys = sorted(res_dict.keys(), key=lambda x: (x[0] * x[1]), reverse=True)
        structured_modes = []

        # Opción Nativa / Recomendada
        native_aspect = calculate_aspect_ratio(width, height)
        structured_modes.append({
            "mode": "preferred",
            "resolution": f"{width}x{height}",
            "label": f"{width} × {height} ({native_aspect})",
            "rate": f"{int(round(rr))}Hz",
            "display": f"{width} × {height} ({native_aspect}) · Nativa",
            "is_native": True
        })

        for w, h in sorted_keys:
            best_rate = res_dict[(w, h)]
            aspect = calculate_aspect_ratio(w, h)
            is_native = (w == width and h == height)
            rate_int = int(round(best_rate))
            structured_modes.append({
                "mode": f"{w}x{h}@{best_rate:.2f}Hz",
                "resolution": f"{w}x{h}",
                "label": f"{w} × {h} ({aspect})",
                "rate": f"{rate_int}Hz",
                "display": f"{w} × {h} ({aspect}) · {rate_int}Hz" + (" (Nativa)" if is_native else ""),
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
        lua = f'hl.monitor({{ output = "{output}", disabled = true }})'
    elif mirror and mirror != "none":
        lua = f'hl.monitor({{ output = "{output}", mirror = "{mirror}" }})'
    else:
        lua = f'hl.monitor({{ output = "{output}", mode = "{mode}", position = "{position}", scale = {scale}, transform = {transform}, disabled = false }})'
    eval_hyprland_lua(lua)

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
