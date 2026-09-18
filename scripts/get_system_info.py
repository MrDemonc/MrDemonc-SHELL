#!/usr/bin/env python3
"""
get_system_info.py: Monitor de información de usuario, clima actual por geolocalización,
medios (MPRIS) y recursos del sistema (CPU, RAM, Disco) para Quickshell ClockPopout en MrDemonc-SHELL.
"""

import os
import sys
import json
import time
import shutil
import subprocess
import threading
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import weather_manager

_cached_weather = weather_manager.load_initial_cached_weather()
_last_weather_check = 0
_last_weather_success = 0
_weather_retry_delay = 10  # Reintentar en 10s si falla la conexión en el arranque del PC
_fetching_lock = threading.Lock()
_is_fetching = False

def _fetch_weather_worker():
    global _cached_weather, _last_weather_check, _last_weather_success, _is_fetching
    with _fetching_lock:
        if _is_fetching:
            return
        _is_fetching = True

    try:
        now = time.time()
        w = weather_manager.fetch_current_weather()
        if w and w.get("available", False):
            _cached_weather = w
            _last_weather_success = now
            _last_weather_check = now
        else:
            # Si falla la red, reintentar pronto (10s) en vez de bloquear 5 minutos
            _last_weather_check = now - (300 - _weather_retry_delay)
            loc = weather_manager.get_current_location()
            if not loc.get("auto", True) and loc.get("name"):
                _cached_weather["city"] = loc.get("name")
                _cached_weather["country"] = loc.get("country", "")
    finally:
        _is_fetching = False

_last_cache_mtime = 0
_last_loc_mtime = 0

def get_weather_info():
    global _last_weather_check, _cached_weather, _last_cache_mtime, _last_loc_mtime
    now = time.time()
    cache_file = weather_manager.CACHE_FILE
    loc_file = weather_manager.LOCATION_FILE

    # Si la ubicación cambió, invalidar para forzar fetch inmediato
    try:
        if os.path.isfile(loc_file):
            lm = os.path.getmtime(loc_file)
            if lm != _last_loc_mtime:
                _last_loc_mtime = lm
                _last_weather_check = 0
                loc = weather_manager.get_current_location()
                if not loc.get("auto", True):
                    _cached_weather["city"] = loc.get("name", "Ubicación")
                    _cached_weather["country"] = loc.get("country", "")
                    _cached_weather["desc"] = "Consultando clima..."
    except Exception:
        pass

    # Si el archivo de caché en disco fue actualizado, recargarlo de inmediato
    try:
        if os.path.isfile(cache_file):
            cm = os.path.getmtime(cache_file)
            if cm != _last_cache_mtime:
                _last_cache_mtime = cm
                with open(cache_file, "r") as f:
                    _cached_weather = json.load(f)
                _last_weather_check = now
    except Exception:
        pass

    if now - _last_weather_check > 300 or _last_weather_check == 0:
        _last_weather_check = now
        t = threading.Thread(target=_fetch_weather_worker, daemon=True)
        t.start()

    return _cached_weather

def get_user_info():
    user = os.environ.get("USER", "usuario")
    try:
        host = os.uname().nodename
    except Exception:
        host = "archlinux"

    home = os.path.expanduser("~")
    avatar_candidates = [
        os.path.join(home, ".face"),
        os.path.join(home, ".face.icon"),
        f"/var/lib/AccountsService/icons/{user}"
    ]
    avatar = ""
    for cand in avatar_candidates:
        if os.path.isfile(cand):
            avatar = cand
            break

    uptime_str = "0m"
    try:
        with open("/proc/uptime", "r") as f:
            total_seconds = float(f.readline().split()[0])
            hours = int(total_seconds // 3600)
            minutes = int((total_seconds % 3600) // 60)
            if hours > 0:
                uptime_str = f"{hours}h {minutes}m"
            else:
                uptime_str = f"{minutes}m"
    except Exception:
        pass

    return {
        "username": user,
        "hostname": host,
        "uptime": uptime_str,
        "avatar": avatar
    }

def get_media_info():
    try:
        cmd = ["playerctl", "metadata", "--format", "{{status}};;;{{playerName}};;;{{xesam:title}};;;{{xesam:artist}};;;{{mpris:artUrl}}"]
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, timeout=0.8)
        if res.returncode == 0 and res.stdout.strip():
            parts = res.stdout.strip().split(";;;")
            status = parts[0] if len(parts) > 0 else ""
            player = parts[1] if len(parts) > 1 else ""
            title = parts[2] if len(parts) > 2 else ""
            artist = parts[3] if len(parts) > 3 else ""
            art_url = parts[4] if len(parts) > 4 else ""

            if art_url.startswith("file://"):
                art_url = art_url[7:]

            return {
                "active": True,
                "status": status,
                "player": player,
                "title": title or "Desconocido",
                "artist": artist or "Desconocido",
                "artUrl": art_url,
                "isPlaying": status.lower() == "playing"
            }
    except Exception:
        pass

    return {
        "active": False,
        "status": "Stopped",
        "player": "",
        "title": "Sin reproducción",
        "artist": "Reproductor inactivo",
        "artUrl": "",
        "isPlaying": False
    }

def get_cpu_percent(prev_stat=None):
    try:
        with open("/proc/stat", "r") as f:
            line = f.readline()
        fields = [float(x) for x in line.strip().split()[1:8]]
        idle_time = fields[3] + fields[4]
        total_time = sum(fields)
        
        if prev_stat:
            prev_idle, prev_total = prev_stat
            delta_idle = idle_time - prev_idle
            delta_total = total_time - prev_total
            if delta_total > 0:
                cpu_pct = max(0, min(100, round((1.0 - delta_idle / delta_total) * 100)))
                return cpu_pct, (idle_time, total_time)
        return 0, (idle_time, total_time)
    except Exception:
        return 0, (0, 0)

def get_memory_info():
    mem_total = 0
    mem_avail = 0
    try:
        with open("/proc/meminfo", "r") as f:
            for line in f:
                if line.startswith("MemTotal:"):
                    mem_total = int(line.split()[1])
                elif line.startswith("MemAvailable:"):
                    mem_avail = int(line.split()[1])
        if mem_total > 0:
            used = mem_total - mem_avail
            pct = round((used / mem_total) * 100)
            return {
                "total_gb": round(mem_total / (1024 * 1024), 1),
                "used_gb": round(used / (1024 * 1024), 1),
                "percent": pct
            }
    except Exception:
        pass
    return {"total_gb": 0, "used_gb": 0, "percent": 0}

def get_disk_info():
    try:
        usage = shutil.disk_usage("/")
        total_gb = round(usage.total / (1024 ** 3), 1)
        used_gb = round(usage.used / (1024 ** 3), 1)
        pct = round((usage.used / usage.total) * 100)
        return {
            "total_gb": total_gb,
            "used_gb": used_gb,
            "percent": pct
        }
    except Exception:
        return {"total_gb": 0, "used_gb": 0, "percent": 0}

def collect_all(prev_cpu_stat=None):
    cpu_pct, new_cpu_stat = get_cpu_percent(prev_cpu_stat)
    data = {
        "user": get_user_info(),
        "weather": get_weather_info(),
        "media": get_media_info(),
        "cpu": {
            "percent": cpu_pct
        },
        "ram": get_memory_info(),
        "disk": get_disk_info()
    }
    return data, new_cpu_stat

def main():
    # Lanzar la actualización del clima en segundo plano para iniciar al instante con la caché
    t = threading.Thread(target=_fetch_weather_worker, daemon=True)
    t.start()

    if "--daemon" in sys.argv or "-d" in sys.argv:
        prev_cpu = None
        _, prev_cpu = get_cpu_percent(None)
        time.sleep(0.15)
        while True:
            data, prev_cpu = collect_all(prev_cpu)
            print(json.dumps(data), flush=True)
            time.sleep(1.5)
    else:
        _, prev_cpu = get_cpu_percent(None)
        time.sleep(0.1)
        data, _ = collect_all(prev_cpu)
        print(json.dumps(data))

if __name__ == "__main__":
    main()
