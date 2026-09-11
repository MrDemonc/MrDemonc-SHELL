#!/usr/bin/env python3
import sys
import os
import json
import urllib.request
import urllib.parse
import time

CONFIG_DIR = os.path.expanduser("~/.config/quickshell")
LOCATION_FILE = os.path.join(CONFIG_DIR, "weather_location.json")
CACHE_FILE = "/tmp/mrdemonc_weather.json"

os.makedirs(CONFIG_DIR, exist_ok=True)

def get_current_location():
    if os.path.isfile(LOCATION_FILE):
        try:
            with open(LOCATION_FILE, "r") as f:
                data = json.load(f)
                return data
        except Exception:
            pass
    return {"auto": True, "name": "Ubicación actual", "label": "Ubicación actual (Automática)"}

def search_cities(query):
    query = query.strip()
    if not query or len(query) < 2:
        return []

    url = f"https://geocoding-api.open-meteo.com/v1/search?name={urllib.parse.quote(query)}&count=10&language=es&format=json"
    req = urllib.request.Request(url, headers={"User-Agent": "MrDemonc-SHELL/1.0"})
    try:
        with urllib.request.urlopen(req, timeout=3.5) as resp:
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
    except Exception as e:
        return []

def fetch_weather_for_query(query, custom_name="", custom_country=""):
    now = time.time()
    endpoint = f"https://wttr.in/{urllib.parse.quote(query)}?format=j1" if query else "https://wttr.in/?format=j1"
    req = urllib.request.Request(endpoint, headers={"User-Agent": "curl/7.88.1"})
    try:
        with urllib.request.urlopen(req, timeout=4.0) as resp:
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
            with open(CACHE_FILE, "w") as f:
                json.dump(w_data, f)
            return w_data
    except Exception as e:
        return None

def set_location(name, country, admin1, query):
    loc_data = {
        "auto": False,
        "name": name,
        "country": country,
        "admin1": admin1,
        "query": query,
        "label": f"{name}, {country}" if country else name
    }
    with open(LOCATION_FILE, "w") as f:
        json.dump(loc_data, f)

    # Invalidate cache and fetch immediately
    if os.path.exists(CACHE_FILE):
        try:
            os.remove(CACHE_FILE)
        except Exception:
            pass

    fetch_weather_for_query(query, custom_name=name, custom_country=country)
    return {"status": "ok", "location": loc_data}

def set_auto_location():
    loc_data = {
        "auto": True,
        "name": "Ubicación actual",
        "country": "",
        "query": "",
        "label": "Ubicación actual (Automática)"
    }
    with open(LOCATION_FILE, "w") as f:
        json.dump(loc_data, f)

    if os.path.exists(CACHE_FILE):
        try:
            os.remove(CACHE_FILE)
        except Exception:
            pass

    fetch_weather_for_query("")
    return {"status": "ok", "location": loc_data}

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
        # Format: weather_manager.py set <name> <country> <admin1> <query>
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

if __name__ == "__main__":
    main()
