#!/usr/bin/env python3
import os
import glob
import subprocess
import json

def get_battery_info():
    # 1. Buscar directorio de batería
    bat_dirs = glob.glob("/sys/class/power_supply/BAT*") + glob.glob("/sys/class/power_supply/battery*")
    if not bat_dirs:
        for ps in glob.glob("/sys/class/power_supply/*"):
            type_file = os.path.join(ps, "type")
            if os.path.isfile(type_file):
                try:
                    with open(type_file, "r") as f:
                        if f.read().strip() == "Battery":
                            bat_dirs.append(ps)
                            break
                except Exception:
                    pass

    # Perfil de energía
    profile = "balanced"
    try:
        profile = subprocess.check_output(["powerprofilesctl", "get"], stderr=subprocess.DEVNULL, timeout=1).decode().strip() or "balanced"
    except Exception:
        pass

    if bat_dirs and os.path.isdir(bat_dirs[0]):
        bpath = bat_dirs[0]
        def read_val(fname, default=""):
            p = os.path.join(bpath, fname)
            if os.path.isfile(p):
                try:
                    with open(p, "r") as f:
                        return f.read().strip()
                except Exception:
                    pass
            return default

        try:
            cap = int(read_val("capacity", "0"))
        except ValueError:
            cap = 0

        status = read_val("status", "Discharging")
        try:
            cycle = int(read_val("cycle_count", "0"))
        except ValueError:
            cycle = 0

        # Health
        full_str = read_val("energy_full") or read_val("charge_full") or "0"
        des_str = read_val("energy_full_design") or read_val("charge_full_design") or "0"
        try:
            full = float(full_str)
            des = float(des_str)
            health = f"{min(100, round((full / des) * 100))}%" if full > 0 and des > 0 else "100%"
        except Exception:
            health = "100%"

        # Power rate
        pow_str = read_val("power_now") or read_val("current_now") or "0"
        try:
            p_val = float(pow_str)
            power_rate = f"{(p_val / 1000000.0):.1f} W" if p_val > 0 else "0.0 W"
        except Exception:
            power_rate = "0.0 W"

        # Voltage
        volt_str = read_val("voltage_now", "0")
        try:
            v_val = float(volt_str)
            voltage = f"{(v_val / 1000000.0):.1f} V" if v_val > 0 else "0.0 V"
        except Exception:
            voltage = "0.0 V"

        return {
            "hasBattery": True,
            "percentage": cap,
            "status": status,
            "cycleCount": cycle,
            "health": health,
            "powerRate": power_rate,
            "voltage": voltage,
            "profile": profile
        }

    # Sin batería física (máquina virtual o PC de sobremesa con CA)
    return {
        "hasBattery": False,
        "percentage": 100,
        "status": "AC",
        "cycleCount": 0,
        "health": "N/A",
        "powerRate": "0.0 W",
        "voltage": "N/A",
        "profile": profile
    }

if __name__ == "__main__":
    print(json.dumps(get_battery_info()))
