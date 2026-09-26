#!/usr/bin/env python3
import os
import sys
import json
import glob
import subprocess

CONFIG_DIR = os.path.expanduser("~/.config/quickshell")
CONFIG_FILE = os.path.join(CONFIG_DIR, "power_profile.json")

EPP_MAP_SET = {
    "power-saver": "power",
    "balanced": "balance_performance",
    "performance": "performance"
}

EPP_MAP_GET = {
    "power": "power-saver",
    "balance_power": "power-saver",
    "balance_performance": "balanced",
    "default": "balanced",
    "performance": "performance"
}

def load_cached_profile():
    if os.path.exists(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, "r") as f:
                data = json.load(f)
                p = data.get("profile", "").strip()
                if p in ("power-saver", "balanced", "performance"):
                    return p
        except Exception:
            pass
    return None

def save_profile(profile):
    try:
        os.makedirs(CONFIG_DIR, exist_ok=True)
        tmp = CONFIG_FILE + ".tmp"
        with open(tmp, "w") as f:
            json.dump({"profile": profile}, f, indent=2)
        os.replace(tmp, CONFIG_FILE)
    except Exception:
        pass

def get_profile():
    # 1. Intentar con powerprofilesctl si está disponible
    try:
        out = subprocess.check_output(["powerprofilesctl", "get"], stderr=subprocess.DEVNULL, timeout=1).decode().strip()
        if out in ("power-saver", "balanced", "performance"):
            save_profile(out)
            return out
    except Exception:
        pass

    # 2. Intentar leer del estado persistido
    cached = load_cached_profile()
    if cached:
        return cached

    # 3. Intentar leer desde cpufreq energy_performance_preference del kernel
    epp_file = "/sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference"
    if os.path.isfile(epp_file):
        try:
            with open(epp_file, "r") as f:
                val = f.read().strip()
                if val in EPP_MAP_GET:
                    return EPP_MAP_GET[val]
        except Exception:
            pass

    return "balanced"

def set_profile(profile):
    if profile not in ("power-saver", "balanced", "performance"):
        return {"profile": get_profile(), "success": False, "error": "Invalid profile"}

    # 1. Guardar de inmediato para persistencia en la UI
    save_profile(profile)

    # 2. Aplicar vía powerprofilesctl si está disponible
    success = False
    try:
        res = subprocess.run(["powerprofilesctl", "set", profile], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=2)
        if res.returncode == 0:
            success = True
    except Exception:
        pass

    # 3. Aplicar a nivel de kernel sysfs (EPP) si es accesible
    epp_val = EPP_MAP_SET.get(profile)
    if epp_val:
        epp_files = glob.glob("/sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference")
        for ef in epp_files:
            try:
                with open(ef, "w") as f:
                    f.write(epp_val)
                success = True
            except Exception:
                pass

    return {"profile": profile, "success": success}

def main():
    if len(sys.argv) > 1:
        cmd = sys.argv[1].lower()
        if cmd == "get":
            print(json.dumps({"profile": get_profile()}))
            return
        elif cmd == "set" and len(sys.argv) > 2:
            target = sys.argv[2].lower()
            res = set_profile(target)
            print(json.dumps(res))
            return
    print(json.dumps({"profile": get_profile()}))

if __name__ == "__main__":
    main()
