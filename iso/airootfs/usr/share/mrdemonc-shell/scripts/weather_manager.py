#!/usr/bin/env python3
"""
weather_manager.py: Gestor de ubicaciones y consulta de clima para Quickshell en MrDemonc-SHELL.
Utiliza Open-Meteo y wttr.in con caché persistente en ~/.config/quickshell/weather_cache.json
para garantizar que la ubicación y el clima sobrevivan a reinicios y apagados del PC.
"""
import sys
import os
import json
import urllib.request
import urllib.parse
import time

CONFIG_DIR = os.path.expanduser("~/.config/quickshell")
LOCATION_FILE = os.path.join(CONFIG_DIR, "weather_location.json")
CACHE_FILE = os.path.join(CONFIG_DIR, "weather_cache.json")

os.makedirs(CONFIG_DIR, exist_ok=True)

# Códigos WMO de Open-Meteo a descripciones e iconos Nerd Font
WMO_CODES = {
    0: ("󰖙", "Despejado"),
    1: ("󰖕", "Mayormente despejado"),
    2: ("󰖕", "Parcialmente nublado"),
    3: ("󰖐", "Nublado"),
    45: ("󰖑", "Niebla"),
    48: ("󰖑", "Niebla con escarcha"),
    51: ("󰖖", "Llovizna ligera"),
    53: ("󰖖", "Llovizna moderada"),
    55: ("󰖖", "Llovizna densa"),
    56: ("󰖖", "Llovizna helada"),
    57: ("󰖖", "Llovizna helada densa"),
    61: ("󰖖", "Lluvia ligera"),
    63: ("󰖖", "Lluvia moderada"),
    65: ("󰖖", "Lluvia fuerte"),
    66: ("󰖖", "Lluvia helada"),
    67: ("󰖖", "Lluvia helada fuerte"),
    71: ("󰼶", "Nieve ligera"),
    73: ("󰼶", "Nieve moderada"),
    75: ("󰼶", "Nieve fuerte"),
    77: ("󰼶", "Granizo"),
    80: ("󰖖", "Chubascos ligeros"),
    81: ("󰖖", "Chubascos moderados"),
    82: ("󰖖", "Chubascos torrenciales"),
    85: ("󰼶", "Chubascos de nieve"),
    86: ("󰼶", "Chubascos fuertes de nieve"),
    95: ("󰖓", "Tormenta"),
    96: ("󰖓", "Tormenta con granizo"),
    99: ("󰖓", "Tormenta fuerte con granizo"),
}

def get_current_location():
    if os.path.isfile(LOCATION_FILE):
        try:
            with open(LOCATION_FILE, "r") as f:
                data = json.load(f)
                if isinstance(data, dict):
                    return data
        except Exception:
            pass
    return {"auto": True, "name": "Ubicación actual", "country": "", "label": "Ubicación actual (Automática)"}

def save_cache(w_data):
    try:
        with open(CACHE_FILE, "w") as f:
            json.dump(w_data, f, indent=2)
    except Exception:
        pass

def load_initial_cached_weather():
    loc = get_current_location()
    is_auto = loc.get("auto", True)
    city = loc.get("name", "Ubicación actual")
    country = loc.get("country", "")

    # Intentar cargar caché persistente del disco
    if os.path.isfile(CACHE_FILE):
        try:
            with open(CACHE_FILE, "r") as f:
                cdata = json.load(f)
                if isinstance(cdata, dict):
                    # Si es modo manual y la ciudad coincide, o si es auto
                    if is_auto or (cdata.get("city") == city):
                        return cdata
        except Exception:
            pass

    # Si no hay caché válido aún, inicializar con la ubicación configurada
    return {
        "city": city,
        "country": country,
        "temp": "--°C",
        "feels_like": "--°C",
        "desc": "Consultando clima...",
        "icon": "󰖐",
        "humidity": "--%",
        "wind": "-- km/h",
        "available": False
    }

def search_cities(query):
    query = query.strip()
    if not query or len(query) < 2:
        return []

    url = f"https://geocoding-api.open-meteo.com/v1/search?name={urllib.parse.quote(query)}&count=10&language=es&format=json"
    req = urllib.request.Request(url, headers={"User-Agent": "MrDemonc-SHELL/1.0"})
    try:
        with urllib.request.urlopen(req, timeout=4.0) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            results = []
            for r in data.get("results", []):
                name = r.get("name", "")
                country = r.get("country", "")
                admin1 = r.get("admin1", "")
                lat = r.get("latitude")
                lon = r.get("longitude")

                sub_parts = []
                if admin1 and admin1 != name:
                    sub_parts.append(admin1)
                if country:
                    sub_parts.append(country)
                sub_label = ", ".join(sub_parts)

                results.append({
                    "name": name,
                    "country": country,
                    "admin1": admin1,
                    "sub_label": sub_label,
                    "lat": lat,
                    "lon": lon,
                    "query": f"{lat},{lon}" if lat is not None and lon is not None else name,
                    "label": f"{name} ({sub_label})" if sub_label else name
                })
            return results
    except Exception:
        return []

def fetch_open_meteo(lat, lon, custom_name="", custom_country=""):
    url = f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m"
    req = urllib.request.Request(url, headers={"User-Agent": "MrDemonc-SHELL/1.0"})
    with urllib.request.urlopen(req, timeout=5.0) as resp:
        data = json.loads(resp.read().decode("utf-8"))
        cur = data.get("current", {})
        temp = round(cur.get("temperature_2m", 0))
        feels = round(cur.get("apparent_temperature", temp))
        code = cur.get("weather_code", 0)
        icon, desc = WMO_CODES.get(code, ("󰖐", "Nublado"))
        humidity = round(cur.get("relative_humidity_2m", 0))
        wind = round(cur.get("wind_speed_10m", 0))
        now = time.time()
        return {
            "city": custom_name or "Ubicación",
            "country": custom_country or "",
            "temp": f"{temp}°C",
            "feels_like": f"{feels}°C",
            "desc": desc,
            "icon": icon,
            "humidity": f"{humidity}%",
            "wind": f"{wind} km/h",
            "available": True,
            "_time": now
        }

def fetch_wttr_in(query="", custom_name="", custom_country=""):
    endpoint = f"https://wttr.in/{urllib.parse.quote(query)}?format=j1" if query else "https://wttr.in/?format=j1"
    req = urllib.request.Request(endpoint, headers={"User-Agent": "curl/7.88.1"})
    with urllib.request.urlopen(req, timeout=6.0) as resp:
        data = json.loads(resp.read().decode("utf-8"))
        cur = data["current_condition"][0]
        area = data.get("nearest_area", [{}])[0]

        city = custom_name or area.get("areaName", [{}])[0].get("value", "Ubicación")
        country = custom_country or area.get("country", [{}])[0].get("value", "")
        temp = cur["temp_C"]
        feels = cur.get("FeelsLikeC", temp)
        desc_en = cur["weatherDesc"][0]["value"].strip()
        code = int(cur.get("weatherCode", "113"))
        humidity = cur.get("humidity", "0")
        wind = cur.get("windspeedKmph", "0")

        if code == 113:
            icon = "󰖙"; desc = "Despejado"
        elif code in (116,):
            icon = "󰖕"; desc = "Parcialmente nublado"
        elif code in (119, 122):
            icon = "󰖐"; desc = "Nublado"
        elif code in (143, 248, 260):
            icon = "󰖑"; desc = "Niebla"
        elif code in (200, 386, 389, 392, 395):
            icon = "󰖓"; desc = "Tormenta"
        elif 311 <= code <= 377:
            icon = "󰼶"; desc = "Nieve"
        elif "rain" in desc_en.lower() or "drizzle" in desc_en.lower() or code in (176, 263, 266, 293, 296, 299, 302, 305, 308, 353, 356):
            icon = "󰖖"; desc = "Lluvia"
        else:
            icon = "󰖐"; desc = desc_en

        now = time.time()
        return {
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

def fetch_weather(query="", custom_name="", custom_country="", lat=None, lon=None):
    # Intentar extraer lat y lon de query si no se pasaron directamente
    if (lat is None or lon is None) and query and "," in query:
        try:
            parts = query.split(",")
            lat = float(parts[0].strip())
            lon = float(parts[1].strip())
        except Exception:
            pass

    # 1. Si disponemos de coordenadas, Open-Meteo es ultra-rápido (<20ms) y altamente fiable
    if lat is not None and lon is not None:
        try:
            w = fetch_open_meteo(lat, lon, custom_name=custom_name, custom_country=custom_country)
            if w:
                save_cache(w)
                return w
        except Exception:
            pass

    # 2. Respaldo wttr.in (necesario para modo automático por IP o si Open-Meteo no responde)
    try:
        w = fetch_wttr_in(query=query, custom_name=custom_name, custom_country=custom_country)
        if w:
            save_cache(w)
            return w
    except Exception:
        pass

    return None

def fetch_current_weather():
    loc = get_current_location()
    is_auto = loc.get("auto", True)
    city = loc.get("name", "") if not is_auto else ""
    country = loc.get("country", "") if not is_auto else ""
    lat = loc.get("lat")
    lon = loc.get("lon")
    query = loc.get("query", "")

    return fetch_weather(query=query, custom_name=city, custom_country=country, lat=lat, lon=lon)

def set_location(name, country, admin1, query, lat=None, lon=None):
    if (lat is None or lon is None) and query and "," in query:
        try:
            parts = query.split(",")
            lat = float(parts[0].strip())
            lon = float(parts[1].strip())
        except Exception:
            pass

    loc_data = {
        "auto": False,
        "name": name,
        "country": country,
        "admin1": admin1,
        "lat": lat,
        "lon": lon,
        "query": query,
        "label": f"{name}, {country}" if country else name
    }
    with open(LOCATION_FILE, "w") as f:
        json.dump(loc_data, f, indent=2)

    # Invalida caché anterior para forzar la actualización con la nueva ciudad
    if os.path.exists(CACHE_FILE):
        try:
            os.remove(CACHE_FILE)
        except Exception:
            pass

    w = fetch_weather(query, custom_name=name, custom_country=country, lat=lat, lon=lon)
    return {"status": "ok", "location": loc_data, "weather": w}

def set_auto_location():
    loc_data = {
        "auto": True,
        "name": "Ubicación actual",
        "country": "",
        "query": "",
        "label": "Ubicación actual (Automática)"
    }
    with open(LOCATION_FILE, "w") as f:
        json.dump(loc_data, f, indent=2)

    if os.path.exists(CACHE_FILE):
        try:
            os.remove(CACHE_FILE)
        except Exception:
            pass

    w = fetch_weather("")
    return {"status": "ok", "location": loc_data, "weather": w}

def main():
    if len(sys.argv) < 2:
        print(json.dumps(get_current_location()))
        return

    cmd = sys.argv[1]

    if cmd == "get":
        print(json.dumps(get_current_location()))
        return

    if cmd == "search":
        q = " ".join(sys.argv[2:]) if len(sys.argv) > 2 else ""
        results = search_cities(q)
        print(json.dumps(results))
        return

    if cmd == "set":
        name = sys.argv[2] if len(sys.argv) > 2 else ""
        country = sys.argv[3] if len(sys.argv) > 3 else ""
        admin1 = sys.argv[4] if len(sys.argv) > 4 else ""
        query = sys.argv[5] if len(sys.argv) > 5 else name
        res = set_location(name, country, admin1, query)
        print(json.dumps(res))
        return

    if cmd == "auto":
        res = set_auto_location()
        print(json.dumps(res))
        return

    if cmd == "weather":
        w = fetch_current_weather()
        print(json.dumps(w or load_initial_cached_weather()))
        return

if __name__ == "__main__":
    main()
