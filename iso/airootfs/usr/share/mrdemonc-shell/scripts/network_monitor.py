#!/usr/bin/env python3
import sys
import os
import time
import subprocess
import json
import re
import threading

def format_speed(bps):
    """Convierte bits por segundo a string legible (Kbps, Mbps, Gbps)."""
    if bps >= 1000 * 1000 * 1000:
        return f"{bps / (1000 * 1000 * 1000):.2f} Gbps"
    elif bps >= 1000 * 1000:
        return f"{bps / (1000 * 1000):.2f} Mbps"
    elif bps >= 1000:
        return f"{bps / 1000:.1f} Kbps"
    else:
        return f"{int(bps)} bps"

def get_default_interface():
    """Detecta la interfaz de red activa con ruta predeterminada."""
    try:
        with open("/proc/net/route", "r") as f:
            for line in f:
                fields = line.strip().split()
                if len(fields) >= 4 and fields[1] == '00000000' and int(fields[3], 16) & 2:
                    return fields[0]
    except Exception:
        pass

    try:
        out = subprocess.check_output(["ip", "route", "show", "default"], text=True, stderr=subprocess.DEVNULL)
        m = re.search(r'dev\s+(\S+)', out)
        if m:
            return m.group(1)
    except Exception:
        pass

    try:
        with open("/proc/net/dev", "r") as f:
            for line in f:
                if ":" in line:
                    iface = line.split(":")[0].strip()
                    if iface != "lo" and not iface.startswith("docker") and not iface.startswith("veth"):
                        return iface
    except Exception:
        pass

    return "wlo1"

def get_io_bytes(iface):
    """Lee bytes recibidos (RX/Download) y transmitidos (TX/Upload) desde /proc/net/dev."""
    try:
        with open("/proc/net/dev", "r") as f:
            for line in f:
                if iface in line:
                    parts = line.split(":")
                    if len(parts) == 2:
                        data = parts[1].split()
                        rx = int(data[0])
                        tx = int(data[8])
                        return rx, tx
    except Exception:
        pass
    return 0, 0

def get_net_details(iface):
    """Obtiene metadatos detallados de la conexión de red (IP, Gateway, DNS, SSID, señal, MAC)."""
    info = {
        "interface": iface,
        "type": "wifi" if iface.startswith("wl") else "ethernet",
        "ssid": "",
        "signal": 0,
        "freq": "",
        "ip": "",
        "gateway": "",
        "dns": "",
        "mac": ""
    }

    try:
        out = subprocess.check_output(
            ["nmcli", "-t", "-f", "GENERAL.CONNECTION,IP4.ADDRESS,IP4.GATEWAY,IP4.DNS,GENERAL.HWADDR", "dev", "show", iface],
            text=True, stderr=subprocess.DEVNULL
        )
        for line in out.splitlines():
            k, _, v = line.partition(":")
            v = v.strip()
            if "CONNECTION" in k and not info["ssid"]:
                info["ssid"] = v
            elif "IP4.ADDRESS" in k and not info["ip"]:
                info["ip"] = v.split("/")[0]
            elif "GATEWAY" in k and not info["gateway"]:
                info["gateway"] = v
            elif "DNS" in k and not info["dns"]:
                info["dns"] = v
            elif "HWADDR" in k and not info["mac"]:
                info["mac"] = v
    except Exception:
        pass

    if info["type"] == "wifi":
        try:
            out = subprocess.check_output(
                ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,FREQ", "dev", "wifi", "list", "--rescan", "no"],
                text=True, stderr=subprocess.DEVNULL
            )
            for line in out.splitlines():
                if line.startswith("*:"):
                    parts = line.split(":")
                    if len(parts) >= 4:
                        info["signal"] = int(parts[2]) if parts[2].isdigit() else 0
                        info["freq"] = parts[3]
                        if not info["ssid"]:
                            info["ssid"] = parts[1]
                    break
        except Exception:
            pass

    return info

latest_ping = 0.0
def ping_worker():
    global latest_ping
    while True:
        try:
            out = subprocess.check_output(["ping", "-c", "1", "-W", "1", "1.1.1.1"], text=True, stderr=subprocess.DEVNULL)
            m = re.search(r'(?:time|tiempo)=([\d.]+)', out)
            if m:
                latest_ping = round(float(m.group(1)), 1)
        except Exception:
            pass
        time.sleep(3)

def run_daemon():
    """Ejecuta el monitor de tráfico continuo en tiempo real (1 muestra por segundo)."""
    t = threading.Thread(target=ping_worker, daemon=True)
    t.start()

    iface = get_default_interface()
    last_rx, last_tx = get_io_bytes(iface)
    last_time = time.time()

    details = get_net_details(iface)
    detail_counter = 0

    while True:
        time.sleep(1.0)
        now = time.time()
        elapsed = max(now - last_time, 0.001)

        detail_counter += 1
        if detail_counter >= 8:
            detail_counter = 0
            curr_iface = get_default_interface()
            if curr_iface != iface:
                iface = curr_iface
                last_rx, last_tx = get_io_bytes(iface)
            details = get_net_details(iface)

        rx, tx = get_io_bytes(iface)

        delta_rx = max(rx - last_rx, 0)
        delta_tx = max(tx - last_tx, 0)

        last_rx = rx
        last_tx = tx
        last_time = now

        # Convertir bytes a bits/segundo para velocidad
        rx_bps = (delta_rx * 8) / elapsed
        tx_bps = (delta_tx * 8) / elapsed

        rx_mbps = round(rx_bps / (1000 * 1000), 2)
        tx_mbps = round(tx_bps / (1000 * 1000), 2)

        data = {
            "interface": details.get("interface", iface),
            "type": details.get("type", "wifi"),
            "ssid": details.get("ssid", "Conectado"),
            "signal": details.get("signal", 80),
            "freq": details.get("freq", ""),
            "ip": details.get("ip", ""),
            "gateway": details.get("gateway", ""),
            "dns": details.get("dns", ""),
            "mac": details.get("mac", ""),
            "ping": latest_ping,
            "rx_bps": rx_bps,
            "tx_bps": tx_bps,
            "rx_mbps": rx_mbps,
            "tx_mbps": tx_mbps,
            "rx_str": format_speed(rx_bps),
            "tx_str": format_speed(tx_bps),
            "total_rx_mb": round(rx / (1024 * 1024), 1),
            "total_tx_mb": round(tx / (1024 * 1024), 1)
        }

        try:
            print(json.dumps(data), flush=True)
        except Exception:
            break

def run_speedtest():
    """Ejecuta un test de velocidad benchmark completo y continuo (Ping, Descarga y Subida con muestras continuas)."""
    iface = get_default_interface()

    # 1. PING
    print(json.dumps({"phase": "ping", "progress": 0.05, "message": "Midiendo latencia de red..."}), flush=True)
    pings = []
    for _ in range(4):
        try:
            out = subprocess.check_output(["ping", "-c", "1", "-W", "1", "1.1.1.1"], text=True, stderr=subprocess.DEVNULL)
            m = re.search(r'(?:time|tiempo)=([\d.]+)', out)
            if m:
                pings.append(float(m.group(1)))
        except Exception:
            pass
        time.sleep(0.08)

    avg_ping = round(sum(pings) / len(pings), 1) if pings else 18.0
    print(json.dumps({"phase": "ping_done", "ping": avg_ping, "progress": 0.15, "message": f"Latencia: {avg_ping} ms"}), flush=True)

    # 2. DESCARGA CONTINUA (5.0 segundos)
    print(json.dumps({"phase": "download_start", "progress": 0.15, "message": "Iniciando prueba de descarga..."}), flush=True)
    t_dl_start = time.time()
    last_t = t_dl_start
    last_rx, _ = get_io_bytes(iface)
    dl_samples = []
    total_dl_bytes = 0
    dl_duration = 5.0

    while time.time() - t_dl_start < dl_duration:
        if dl_duration - (time.time() - t_dl_start) <= 0.2:
            break
        try:
            p = subprocess.Popen(["curl", "-s", "-L", "-o", "/dev/null", "https://speed.cloudflare.com/__down?bytes=25000000"])
            while p.poll() is None and time.time() - t_dl_start < dl_duration:
                time.sleep(0.2)
                now = time.time()
                dt = now - last_t
                rx, _ = get_io_bytes(iface)
                delta_rx = max(rx - last_rx, 0)
                total_dl_bytes += delta_rx
                mbps = round(((delta_rx * 8) / (dt * 1000 * 1000)), 2)
                dl_samples.append(mbps)
                last_t = now
                last_rx = rx
                elapsed = now - t_dl_start
                prog = min(0.15 + (elapsed / dl_duration) * 0.40, 0.54)
                print(json.dumps({
                    "phase": "download",
                    "progress": round(prog, 3),
                    "speed": mbps,
                    "download_mbps": mbps,
                    "download_str": format_speed(mbps * 1000 * 1000),
                    "message": f"Descarga: {format_speed(mbps * 1000 * 1000)}"
                }), flush=True)
            if p.poll() is None:
                p.terminate()
                p.wait()
        except Exception:
            break

    # Calcular promedio de descarga
    valid_dl = [s for s in dl_samples if s > 1.0]
    if valid_dl:
        avg_dl = round(sum(valid_dl) / len(valid_dl), 2)
    else:
        avg_dl = round(sum(dl_samples) / len(dl_samples), 2) if dl_samples else 0.0

    print(json.dumps({
        "phase": "download_done",
        "progress": 0.55,
        "download_mbps": avg_dl,
        "download_str": format_speed(avg_dl * 1000 * 1000),
        "message": f"Descarga finalizada: {format_speed(avg_dl * 1000 * 1000)}"
    }), flush=True)

    # 3. SUBIDA CONTINUA (5.0 segundos)
    print(json.dumps({"phase": "upload_start", "progress": 0.55, "message": "Iniciando prueba de subida..."}), flush=True)
    chunk_file = "/tmp/quickshell_speedtest_up.bin"
    try:
        with open(chunk_file, "wb") as f:
            f.write(b"0" * 10000000)
    except Exception:
        pass

    t_ul_start = time.time()
    last_t = t_ul_start
    _, last_tx = get_io_bytes(iface)
    ul_samples = []
    ul_duration = 5.0

    while time.time() - t_ul_start < ul_duration:
        if ul_duration - (time.time() - t_ul_start) <= 0.2:
            break
        try:
            p = subprocess.Popen(["curl", "-s", "-o", "/dev/null", "-X", "POST", "--data-binary", f"@{chunk_file}", "https://speed.cloudflare.com/__up"])
            while p.poll() is None and time.time() - t_ul_start < ul_duration:
                time.sleep(0.2)
                now = time.time()
                dt = now - last_t
                _, tx = get_io_bytes(iface)
                delta_tx = max(tx - last_tx, 0)
                mbps = round(((delta_tx * 8) / (dt * 1000 * 1000)), 2)
                ul_samples.append(mbps)
                last_t = now
                last_tx = tx
                elapsed = now - t_ul_start
                prog = min(0.55 + (elapsed / ul_duration) * 0.40, 0.94)
                print(json.dumps({
                    "phase": "upload",
                    "progress": round(prog, 3),
                    "speed": mbps,
                    "upload_mbps": mbps,
                    "upload_str": format_speed(mbps * 1000 * 1000),
                    "message": f"Subida: {format_speed(mbps * 1000 * 1000)}"
                }), flush=True)
            if p.poll() is None:
                p.terminate()
                p.wait()
        except Exception:
            break

    try:
        if os.path.exists(chunk_file):
            os.remove(chunk_file)
    except Exception:
        pass

    # Calcular promedio de subida
    valid_ul = [s for s in ul_samples if s > 1.0]
    if valid_ul:
        avg_ul = round(sum(valid_ul) / len(valid_ul), 2)
    else:
        avg_ul = round(sum(ul_samples) / len(ul_samples), 2) if ul_samples else 0.0

    print(json.dumps({
        "phase": "upload_done",
        "progress": 0.95,
        "upload_mbps": avg_ul,
        "upload_str": format_speed(avg_ul * 1000 * 1000),
        "message": f"Subida finalizada: {format_speed(avg_ul * 1000 * 1000)}"
    }), flush=True)

    # 4. FINALIZADO
    print(json.dumps({
        "phase": "done",
        "progress": 1.0,
        "ping": avg_ping,
        "download_mbps": avg_dl,
        "upload_mbps": avg_ul,
        "download_str": format_speed(avg_dl * 1000 * 1000),
        "upload_str": format_speed(avg_ul * 1000 * 1000),
        "message": "Prueba de velocidad completada"
    }), flush=True)

if __name__ == "__main__":
    if "--speedtest" in sys.argv:
        run_speedtest()
    else:
        run_daemon()
