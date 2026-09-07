#!/usr/bin/env python3
import subprocess
import json

def get_icon_symbol(app_name, icon_name):
    lower = (app_name + " " + (icon_name or "")).lower()
    if any(k in lower for k in ["spotify", "music", "ncspot", "cider"]):
        return "󰓇"
    if any(k in lower for k in ["zen", "firefox", "chrome", "chromium", "brave", "edge", "browser"]):
        return "󰖟"
    if any(k in lower for k in ["mpv", "vlc", "celluloid", "video", "totem"]):
        return "󰕼"
    if any(k in lower for k in ["discord", "telegram", "slack", "webcord", "vesktop"]):
        return "󰙯"
    if any(k in lower for k in ["steam", "game", "retroarch", "heroic", "lutris"]):
        return "󰊴"
    if any(k in lower for k in ["obs", "audacity", "ardour", "reaper"]):
        return "󰎆"
    return "󰓃"

def get_audio_data():
    default_sink = ""
    default_source = ""
    try:
        info_out = subprocess.check_output(["pactl", "info"], stderr=subprocess.DEVNULL, timeout=2).decode("utf-8", errors="ignore")
        for line in info_out.splitlines():
            if line.startswith("Default Sink:"):
                default_sink = line.split(":", 1)[1].strip()
            elif line.startswith("Default Source:"):
                default_source = line.split(":", 1)[1].strip()
    except Exception:
        pass

    sinks = []
    master_vol = 0
    master_muted = False
    try:
        sinks_json = json.loads(subprocess.check_output(["pactl", "-f", "json", "list", "sinks"], stderr=subprocess.DEVNULL, timeout=2))
        for s in sinks_json:
            name = s.get("name", "")
            props = s.get("properties", {})
            desc = s.get("description", "") or props.get("device.description", "") or props.get("node.nick", name)
            if desc == "(null)" or not desc:
                desc = props.get("device.nick", "") or props.get("alsa.card_name", name)
            if not desc or desc == "(null)":
                desc = "Altavoces / Salida de Audio"

            is_default = (name == default_sink) or (not default_sink and len(sinks) == 0)

            vol_obj = s.get("volume", {})
            vol_vals = []
            for ch, val in vol_obj.items():
                pct = val.get("value_percent", "0%").rstrip("%")
                try:
                    vol_vals.append(int(pct))
                except Exception:
                    pass
            vol_pct = int(sum(vol_vals) / len(vol_vals)) if vol_vals else 0
            muted = s.get("mute", False)

            if is_default:
                master_vol = vol_pct
                master_muted = muted

            sinks.append({
                "name": name,
                "description": desc,
                "volume": vol_pct,
                "muted": muted,
                "isDefault": is_default
            })
    except Exception:
        pass

    mic_vol = 0
    mic_muted = False
    try:
        sources_json = json.loads(subprocess.check_output(["pactl", "-f", "json", "list", "sources"], stderr=subprocess.DEVNULL, timeout=2))
        for s in sources_json:
            name = s.get("name", "")
            if "monitor" in name:
                continue
            is_default = (name == default_source) or (not default_source)
            if is_default:
                vol_obj = s.get("volume", {})
                vol_vals = []
                for ch, val in vol_obj.items():
                    pct = val.get("value_percent", "0%").rstrip("%")
                    try:
                        vol_vals.append(int(pct))
                    except Exception:
                        pass
                mic_vol = int(sum(vol_vals) / len(vol_vals)) if vol_vals else 0
                mic_muted = s.get("mute", False)
                break
    except Exception:
        pass

    apps = []
    try:
        inputs_json = json.loads(subprocess.check_output(["pactl", "-f", "json", "list", "sink-inputs"], stderr=subprocess.DEVNULL, timeout=2))
        for inp in inputs_json:
            idx = inp.get("index")
            props = inp.get("properties", {})
            app_name = props.get("application.name") or props.get("node.name") or "Aplicación"
            media_name = props.get("media.name", "")
            icon = props.get("application.icon_name") or props.get("application.process.binary", "audio")

            vol_obj = inp.get("volume", {})
            vol_vals = []
            for ch, val in vol_obj.items():
                pct = val.get("value_percent", "0%").rstrip("%")
                try:
                    vol_vals.append(int(pct))
                except Exception:
                    pass
            vol_pct = int(sum(vol_vals) / len(vol_vals)) if vol_vals else 100
            muted = inp.get("mute", False)
            corked = inp.get("corked", False)

            symbol = get_icon_symbol(app_name, icon)

            apps.append({
                "index": idx,
                "name": app_name,
                "media": media_name,
                "icon": icon,
                "iconSymbol": symbol,
                "volume": vol_pct,
                "muted": muted,
                "corked": corked
            })
    except Exception:
        pass

    return {
        "masterVolume": master_vol,
        "masterMuted": master_muted,
        "micVolume": mic_vol,
        "micMuted": mic_muted,
        "sinks": sinks,
        "apps": apps
    }

if __name__ == "__main__":
    print(json.dumps(get_audio_data()))
