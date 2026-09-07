#!/usr/bin/env python3
import subprocess
import json
import sys

def get_icon_symbol(icon_name, dev_name):
    icon_name = (icon_name or "").lower()
    dev_name = (dev_name or "").lower()

    if any(k in icon_name or k in dev_name for k in ["headset", "headphone", "airpods", "earbuds", "buds", "f516"]):
        return "󰋋"
    if any(k in icon_name or k in dev_name for k in ["audio", "speaker", "sound"]):
        return "󰓃"
    if any(k in icon_name or k in dev_name for k in ["mouse", "trackpad"]):
        return "󰍽"
    if any(k in icon_name or k in dev_name for k in ["keyboard", "kb"]):
        return "󰌌"
    if any(k in icon_name or k in dev_name for k in ["gamepad", "joystick", "controller", "ps4", "ps5", "xbox"]):
        return "󰊴"
    if any(k in icon_name or k in dev_name for k in ["phone", "mobile", "iphone", "android"]):
        return "󰏲"
    if any(k in icon_name or k in dev_name for k in ["computer", "laptop", "pc"]):
        return "󰌢"
    return "󰂯"

def get_bluetooth_data():
    is_powered = False
    is_scanning = False
    controller_name = ""
    devices = {}

    try:
        show_out = subprocess.check_output(["bluetoothctl", "show"], stderr=subprocess.DEVNULL, timeout=2).decode("utf-8", errors="ignore")
        for line in show_out.splitlines():
            line = line.strip()
            if line.startswith("Powered: yes"):
                is_powered = True
            elif line.startswith("Discovering: yes"):
                is_scanning = True
            elif line.startswith("Name:") or line.startswith("Alias:"):
                if not controller_name:
                    controller_name = line.split(":", 1)[1].strip()
    except Exception:
        pass

    if is_powered:
        try:
            dev_out = subprocess.check_output(["bluetoothctl", "devices"], stderr=subprocess.DEVNULL, timeout=2).decode("utf-8", errors="ignore")
            for line in dev_out.splitlines():
                parts = line.strip().split(" ", 2)
                if len(parts) >= 3 and parts[0] == "Device":
                    mac = parts[1]
                    name = parts[2]
                    devices[mac] = {
                        "mac": mac,
                        "name": name,
                        "icon": "generic",
                        "iconSymbol": get_icon_symbol("", name),
                        "isPaired": True,
                        "isConnected": False,
                        "battery": -1
                    }
        except Exception:
            pass

        # Query info for each device
        for mac in list(devices.keys()):
            try:
                info_out = subprocess.check_output(["bluetoothctl", "info", mac], stderr=subprocess.DEVNULL, timeout=2).decode("utf-8", errors="ignore")
                for l in info_out.splitlines():
                    l = l.strip()
                    if l.startswith("Connected: yes"):
                        devices[mac]["isConnected"] = True
                    elif l.startswith("Paired: yes"):
                        devices[mac]["isPaired"] = True
                    elif l.startswith("Icon:"):
                        icon = l.split(":", 1)[1].strip()
                        devices[mac]["icon"] = icon
                        devices[mac]["iconSymbol"] = get_icon_symbol(icon, devices[mac]["name"])
                    elif "Battery Percentage" in l:
                        try:
                            val_str = l.split("(", 1)[1].split(")", 1)[0]
                            devices[mac]["battery"] = int(val_str)
                        except Exception:
                            pass
            except Exception:
                pass

    dev_list = list(devices.values())
    dev_list.sort(key=lambda d: (not d["isConnected"], not d["isPaired"], d["name"].lower()))

    connected_count = sum(1 for d in dev_list if d["isConnected"])

    return {
        "isPowered": is_powered,
        "isScanning": is_scanning,
        "controllerName": controller_name,
        "connectedCount": connected_count,
        "devices": dev_list
    }

if __name__ == "__main__":
    print(json.dumps(get_bluetooth_data()))
