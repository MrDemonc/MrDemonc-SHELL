#!/usr/bin/env python3
"""
get_about_info.py: Obtiene información detallada del sistema, hardware,
entorno de escritorio y repositorio para la sección "Acerca de" de MrDemonc-SHELL.
"""

import os
import sys
import json
import subprocess
import re

def get_about_info():
    info = {
        "os_name": "Arch Linux",
        "kernel": os.uname().release,
        "user": os.environ.get("USER", "usuario"),
        "host": os.uname().nodename,
        "uptime": "--",
        "model": "Equipo PC",
        "cpu": "Procesador Desconocido",
        "gpu": "Gráficos Integrados",
        "ram_total": "--",
        "ram_used": "--",
        "ram_percent": 0,
        "disk_total": "--",
        "disk_free": "--",
        "disk_percent": 0,
        "wm": "Hyprland",
        "framework": "Quickshell",
        "shell_name": "MrDemonc-SHELL",
        "github_user": "MrDemonc",
        "github_url": "https://github.com/MrDemonc",
        "repo_url": "https://github.com/MrDemonc/MrDemonc-SHELL",
        "packages": 0
    }

    # 1. Nombre y Versión del Sistema Operativo
    try:
        with open("/etc/os-release") as f:
            for line in f:
                if line.startswith("PRETTY_NAME="):
                    info["os_name"] = line.split("=", 1)[1].strip().strip("\"")
                    break
    except Exception:
        pass

    # 2. Tiempo de Actividad (Uptime)
    try:
        with open("/proc/uptime") as f:
            tot = float(f.readline().split()[0])
            h, m = int(tot // 3600), int((tot % 3600) // 60)
            if h > 0:
                info["uptime"] = f"{h}h {m}m"
            else:
                info["uptime"] = f"{m}m"
    except Exception:
        pass

    # 3. Modelo del Equipo / Placa Base
    try:
        p, v = "", ""
        if os.path.exists("/sys/devices/virtual/dmi/id/product_name"):
            with open("/sys/devices/virtual/dmi/id/product_name") as f:
                p = f.read().strip()
        if os.path.exists("/sys/devices/virtual/dmi/id/sys_vendor"):
            with open("/sys/devices/virtual/dmi/id/sys_vendor") as f:
                v = f.read().strip()
        if p and p != "None":
            name = f"{v} {p}".strip()
            name = re.sub(r"^(HP|Dell|Lenovo|ASUS|Acer)\s+\1\b", r"\1", name, flags=re.I)
            info["model"] = name
    except Exception:
        pass

    # 4. Procesador (CPU)
    try:
        with open("/proc/cpuinfo") as f:
            for line in f:
                if "model name" in line:
                    c = line.split(":")[1].strip()
                    c = re.sub(r"\s+", " ", c)
                    c = c.replace("(R)", "").replace("(TM)", "").strip()
                    info["cpu"] = c
                    break
    except Exception:
        pass

    # 5. Tarjeta Gráfica (GPU)
    try:
        out = subprocess.check_output(["lspci"], text=True, stderr=subprocess.DEVNULL)
        gpus = []
        for line in out.splitlines():
            if any(k in line for k in ("VGA", "3D", "Display")):
                p = line.split(":", 2)[-1].strip()
                p = re.sub(r"\[.*?\]", "", p)
                p = re.sub(r"\s*\(rev\s+.*?\)", "", p)
                p = p.replace("Intel Corporation", "Intel")
                p = p.replace("Advanced Micro Devices, Inc.", "AMD")
                p = p.replace("NVIDIA Corporation", "NVIDIA")
                gpus.append(re.sub(r"\s+", " ", p).strip())
        if gpus:
            info["gpu"] = " / ".join(gpus)
    except Exception:
        pass

    # 6. Memoria RAM
    try:
        with open("/proc/meminfo") as f:
            mem = {}
            for line in f:
                parts = line.split(":")
                if len(parts) == 2:
                    mem[parts[0].strip()] = int(parts[1].split()[0])
            tot_mb = mem.get("MemTotal", 0) / 1024
            avail_mb = mem.get("MemAvailable", 0) / 1024
            used_mb = max(tot_mb - avail_mb, 0)
            info["ram_total"] = f"{tot_mb / 1024:.1f} GB"
            info["ram_used"] = f"{used_mb / 1024:.1f} GB"
            if tot_mb > 0:
                info["ram_percent"] = int((used_mb / tot_mb) * 100)
    except Exception:
        pass

    # 7. Almacenamiento en Disco (Partición raíz /)
    try:
        st = os.statvfs("/")
        tot_gb = (st.f_blocks * st.f_frsize) / (1024**3)
        free_gb = (st.f_bavail * st.f_frsize) / (1024**3)
        used_gb = max(tot_gb - free_gb, 0)
        info["disk_total"] = f"{tot_gb:.0f} GB"
        info["disk_free"] = f"{free_gb:.0f} GB"
        if tot_gb > 0:
            info["disk_percent"] = int((used_gb / tot_gb) * 100)
    except Exception:
        pass

    # 8. Versión de Hyprland
    try:
        out = subprocess.check_output(["hyprctl", "version"], text=True, stderr=subprocess.DEVNULL).splitlines()[0]
        m = re.search(r"Hyprland\s+([\d.]+)", out)
        if m:
            info["wm"] = f"Hyprland v{m.group(1)}"
    except Exception:
        pass

    # 9. Conteo total de paquetes instalados
    try:
        out = subprocess.check_output(["pacman", "-Qq"], text=True, stderr=subprocess.DEVNULL)
        info["packages"] = len(out.strip().splitlines())
    except Exception:
        pass

    return info

if __name__ == "__main__":
    print(json.dumps(get_about_info()))
