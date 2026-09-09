#!/usr/bin/env python3
import subprocess
import json

def get_network_info():
    networks = {}
    active_wifi_net = None
    saved_connections = set()

    # 1. Conexiones guardadas en NetworkManager
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

    # 2. Escanear redes Wi-Fi disponibles
    try:
        out = subprocess.check_output(
            ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "dev", "wifi", "list", "--rescan", "auto"],
            stderr=subprocess.DEVNULL,
            timeout=3
        ).decode("utf-8", errors="ignore")
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

                if not ssid:
                    if in_use:
                        active_wifi_net = {
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
                if ssid not in networks or signal > networks[ssid]["signal"]:
                    networks[ssid] = net_obj
                if in_use:
                    networks[ssid]["inUse"] = True
                    active_wifi_net = networks[ssid]
    except Exception:
        pass

    # 3. Inspeccionar dispositivos de red activos con nmcli
    active_wifi_dev = None
    active_eth_dev = None

    try:
        dev_out = subprocess.check_output(
            ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "dev"],
            stderr=subprocess.DEVNULL,
            timeout=2
        ).decode("utf-8", errors="ignore")
        for line in dev_out.splitlines():
            parts = line.split(":")
            if len(parts) >= 4:
                dev, dtype, state, conn = parts[0].strip(), parts[1].strip(), parts[2].strip(), parts[3].strip()
                if state in ("connected", "conectado"):
                    if dtype == "wifi" and not active_wifi_dev:
                        active_wifi_dev = (dev, conn)
                    elif dtype == "ethernet" and not active_eth_dev:
                        active_eth_dev = (dev, conn)
    except Exception:
        pass

    # Gateway predeterminado
    gateway = ""
    try:
        gateway = subprocess.check_output(
            ["sh", "-c", "ip route show default 2>/dev/null | awk '{print $3}' | head -n1"],
            stderr=subprocess.DEVNULL,
            timeout=2
        ).decode("utf-8", errors="ignore").strip()
    except Exception:
        pass

    def get_ipv4(dev_name):
        try:
            return subprocess.check_output(
                ["sh", "-c", f"ip -4 addr show {dev_name} 2>/dev/null | grep -oP '(?<=inet\\s)\\d+(\\.\\d+){{3}}' | head -n1"],
                stderr=subprocess.DEVNULL,
                timeout=2
            ).decode("utf-8", errors="ignore").strip()
        except Exception:
            return ""

    net_list = list(networks.values())
    net_list.sort(key=lambda x: (not x["inUse"], not x["isSaved"], -x["signal"]))

    # Caso A: Wi-Fi conectado
    if active_wifi_dev:
        w_dev, w_conn = active_wifi_dev
        ip_addr = get_ipv4(w_dev)
        ssid_name = active_wifi_net["ssid"] if active_wifi_net else w_conn
        signal = active_wifi_net["signal"] if active_wifi_net else 100
        sec = active_wifi_net["security"] if active_wifi_net else ""
        return {
            "isConnected": True,
            "isEthernet": False,
            "ssid": ssid_name,
            "signalStrength": signal,
            "ipAddress": ip_addr,
            "gateway": gateway,
            "security": sec,
            "networks": net_list
        }

    # Caso B: Ethernet conectado
    if active_eth_dev:
        e_dev, e_conn = active_eth_dev
        ip_addr = get_ipv4(e_dev)
        return {
            "isConnected": True,
            "isEthernet": True,
            "ssid": e_conn if e_conn else f"Ethernet ({e_dev})",
            "signalStrength": 100,
            "ipAddress": ip_addr,
            "gateway": gateway,
            "security": "Cableada",
            "networks": net_list
        }

    # Caso C: Desconectado
    return {
        "isConnected": False,
        "isEthernet": False,
        "ssid": "",
        "signalStrength": 0,
        "ipAddress": "",
        "gateway": gateway,
        "security": "",
        "networks": net_list
    }

if __name__ == "__main__":
    print(json.dumps(get_network_info()))
