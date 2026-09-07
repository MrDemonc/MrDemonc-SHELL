#!/usr/bin/env python3
import subprocess
import json

def get_network_info():
    networks = {}
    active_net = None

    # 1. Obtener lista de conexiones guardadas en NetworkManager
    saved_connections = set()
    try:
        conns_out = subprocess.check_output(
            ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"],
            stderr=subprocess.DEVNULL,
            timeout=2
        ).decode("utf-8", errors="ignore")
        for line in conns_out.splitlines():
            if ":802-11-wireless" in line or ":wifi" in line:
                c_name = line.split(":")[0].strip()
                if c_name:
                    saved_connections.add(c_name)
    except Exception:
        pass

    # 2. Escanear redes disponibles
    try:
        out = subprocess.check_output(
            ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "dev", "wifi", "list", "--rescan", "auto"],
            stderr=subprocess.DEVNULL,
            timeout=3
        ).decode("utf-8", errors="ignore")
    except Exception:
        out = ""

    for line in out.splitlines():
        if not line:
            continue
        parts = line.split(":")
        if len(parts) >= 4:
            in_use = parts[0].strip() == "*" or parts[0].strip().lower() in ("yes", "sí", "si", "true")
            ssid = parts[1].strip()
            try:
                signal = int(parts[2].strip())
            except Exception:
                signal = 0
            sec_raw = ":".join(parts[3:]).strip()
            security = sec_raw if sec_raw else "Abierta"

            # Omitir redes ocultas de la lista principal
            if not ssid:
                if in_use:
                    active_net = {
                        "inUse": True,
                        "ssid": "<Red Oculta Conectada>",
                        "rawSsid": "",
                        "isHidden": True,
                        "isSaved": True,
                        "signal": signal,
                        "security": security
                    }
                continue

            is_saved = ssid in saved_connections

            net_obj = {
                "inUse": in_use,
                "ssid": ssid,
                "rawSsid": ssid,
                "isHidden": False,
                "isSaved": is_saved,
                "signal": signal,
                "security": security
            }

            if ssid not in networks:
                networks[ssid] = net_obj
            else:
                if in_use:
                    networks[ssid]["inUse"] = True
                if is_saved:
                    networks[ssid]["isSaved"] = True
                if signal > networks[ssid]["signal"]:
                    networks[ssid]["signal"] = signal

            if in_use:
                active_net = networks[ssid]

    # 3. Determinar SSID activa directamente desde el dispositivo WiFi si no se detectó en el listado
    direct_ssid = ""
    ip_addr = ""
    gateway = ""
    try:
        dev_out = subprocess.check_output(
            ["sh", "-c", "nmcli -t -f DEVICE,TYPE dev 2>/dev/null | grep ':wifi$' | cut -d: -f1 | head -n1"],
            stderr=subprocess.DEVNULL,
            timeout=2
        ).decode("utf-8", errors="ignore").strip()

        if dev_out:
            # Obtener el nombre de la conexión activa en el dispositivo wifi
            c_out = subprocess.check_output(
                ["sh", "-c", f"nmcli -t -f GENERAL.CONNECTION,GENERAL.STATE dev show {dev_out} 2>/dev/null"],
                stderr=subprocess.DEVNULL,
                timeout=2
            ).decode("utf-8", errors="ignore")
            for line in c_out.splitlines():
                if line.startswith("GENERAL.CONNECTION:"):
                    conn_val = line.split(":", 1)[1].strip()
                    if conn_val and conn_val != "--":
                        direct_ssid = conn_val

            ip_cmd = f"ip -4 addr show {dev_out} 2>/dev/null | grep -oP '(?<=inet\\s)\\d+(\\.\\d+){{3}}' | head -n1"
            ip_addr = subprocess.check_output(["sh", "-c", ip_cmd], stderr=subprocess.DEVNULL, timeout=2).decode("utf-8", errors="ignore").strip()

        gw_cmd = "ip route show default 2>/dev/null | awk '{print $3}' | head -n1"
        gateway = subprocess.check_output(["sh", "-c", gw_cmd], stderr=subprocess.DEVNULL, timeout=2).decode("utf-8", errors="ignore").strip()
    except Exception:
        pass

    # Si hay una SSID detectada directamente pero no estaba marcada inUse en el listado, sincronizar
    if direct_ssid:
        if direct_ssid in networks:
            networks[direct_ssid]["inUse"] = True
            active_net = networks[direct_ssid]
        elif not active_net:
            active_net = {
                "inUse": True,
                "ssid": direct_ssid,
                "rawSsid": direct_ssid,
                "isHidden": False,
                "isSaved": True,
                "signal": 100,
                "security": ""
            }
            networks[direct_ssid] = active_net

    # Reordenar: Red activa primero, luego redes guardadas, luego por señal
    net_list = list(networks.values())
    net_list.sort(key=lambda x: (not x["inUse"], not x["isSaved"], -x["signal"]))

    is_connected = active_net is not None or len(direct_ssid) > 0 or len(ip_addr) > 0
    active_ssid = active_net["ssid"] if active_net else (direct_ssid if direct_ssid else "")
    active_signal = active_net["signal"] if active_net else (100 if is_connected else 0)

    result = {
        "isConnected": is_connected,
        "ssid": active_ssid,
        "signalStrength": active_signal,
        "ipAddress": ip_addr,
        "gateway": gateway,
        "security": active_net["security"] if active_net else "",
        "networks": net_list
    }
    return result

if __name__ == "__main__":
    print(json.dumps(get_network_info()))
