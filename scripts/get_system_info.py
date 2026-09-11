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

_cached_weather = {
    "city": "Ubicación actual",
    "country": "",
    "temp": "--°C",
    "feels_like": "--°C",
    "desc": "Consultando clima...",
    "icon": "󰖐",
    "humidity": "--%",
    "wind": "-- km/h",
    "available": False
}
_last_weather_check = 0

def _fetch_weather_worker():
    global _cached_weather, _last_weather_check
    cache_file = "/tmp/mrdemonc_weather.json"
    now = time.time()

    loc_file = os.path.expanduser("~/.config/quickshell/weather_location.json")
    custom_query = ""
    custom_city = ""
    custom_country = ""
    if os.path.isfile(loc_file):
        try:
            with open(loc_file, "r") as f:
                loc_cfg = json.load(f)
                if not loc_cfg.get("auto", True):
                    custom_query = loc_cfg.get("query", "")
                    custom_city = loc_cfg.get("name", "")
                    custom_country = loc_cfg.get("country", "")
        except Exception:
            pass

    # Si hay caché en disco menor a 600 segundos y coincide con la ciudad elegida, usarlo
    if os.path.isfile(cache_file):
        try:
            with open(cache_file, "r") as f:
                cdata = json.load(f)
                valid_city = (not custom_city) or (cdata.get("city") == custom_city)
                if valid_city and (now - cdata.get("_time", 0) < 600):
                    _cached_weather = cdata
                    _last_weather_check = now
                    return
        except Exception:
            pass

    try:
        endpoint = f"https://wttr.in/{urllib.parse.quote(custom_query)}?format=j1" if custom_query else "https://wttr.in/?format=j1"
        req = urllib.request.Request(endpoint, headers={"User-Agent": "curl/7.88.1"})
        with urllib.request.urlopen(req, timeout=3.5) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            cur = data["current_condition"][0]
            area = data.get("nearest_area", [{}])[0]
            city = custom_city or area.get("areaName", [{}])[0].get("value", "Ubicación")
            country = custom_country or area.get("country", [{}])[0].get("value", "")
            temp = cur["temp_C"]
            feels = cur.get("FeelsLikeC", temp)
            desc_en = cur["weatherDesc"][0]["value"].strip()
            code = int(cur.get("weatherCode", "113"))
            humidity = cur.get("humidity", "0")
            wind = cur.get("windspeedKmph", "0")

            if code == 113:
                icon = "󰖙"
                desc = "Despejado"
            elif code in (116,):
                icon = "󰖕"
                desc = "Parcialmente nublado"
            elif code in (119, 122):
                icon = "󰖐"
                desc = "Nublado"
            elif code in (143, 248, 260):
                icon = "󰖑"
                desc = "Niebla"
            elif code in (200, 386, 389, 392, 395):
                icon = "󰖓"
                desc = "Tormenta"
            elif 311 <= code <= 377:
                icon = "󰼶"
                desc = "Nieve"
            elif "rain" in desc_en.lower() or "drizzle" in desc_en.lower() or code in (176, 263, 266, 293, 296, 299, 302, 305, 308, 353, 356):
                icon = "󰖖"
                desc = "Lluvia"
            else:
                icon = "󰖐"
                desc = desc_en

            w_data = {
                "city": city,
                "country": country,
                "temp": f"{temp}°C",
                "feels_like": f"{feels}°C",
                "desc": desc,
                "icon": icon,
                "humidity": f"{humidity}%",
                "wind": f"{wind} km/h",
                "available": True,
                "_time": now
            }
            _cached_weather = w_data
            _last_weather_check = now
            try:
                with open(cache_file, "w") as f:
                    json.dump(w_data, f)
            except Exception:
                pass
    except Exception:
        if os.path.isfile(cache_file):
            try:
                with open(cache_file, "r") as f:
                    _cached_weather = json.load(f)
            except Exception:
                pass
        _last_weather_check = now

_last_cache_mtime = 0
_last_loc_mtime = 0

def get_weather_info():
    global _last_weather_check, _cached_weather, _last_cache_mtime, _last_loc_mtime
    now = time.time()
    cache_file = "/tmp/mrdemonc_weather.json"
    loc_file = os.path.expanduser("~/.config/quickshell/weather_location.json")

    # Si la ubicación cambió, invalidar para forzar fetch inmediato
    try:
        if os.path.isfile(loc_file):
            lm = os.path.getmtime(loc_file)
            if lm != _last_loc_mtime:
                _last_loc_mtime = lm
                _last_weather_check = 0
    except Exception:
        pass

    # Si el archivo de caché en disco fue actualizado por weather_manager.py, recargarlo de inmediato
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
    # Inicializar clima de inmediato
    _fetch_weather_worker()

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
