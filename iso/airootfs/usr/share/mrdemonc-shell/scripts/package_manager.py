#!/usr/bin/env python3
import os
import sys
import json
import glob
import shutil
import subprocess
import time
import configparser

CACHE_FILE = os.path.expanduser(f"{os.environ.get('XDG_RUNTIME_DIR', '/tmp')}/quickshell_packages_cache.json")
CACHE_TTL = 30  # 30 segundos de caché para respuesta ultra fluida

ICON_SEARCH_DIRS = [
    "/usr/share/pixmaps",
    os.path.expanduser("~/.local/share/icons"),
    "/usr/share/icons/hicolor",
    "/usr/share/icons/Papirus",
    "/usr/share/icons/Papirus-Dark",
    "/usr/share/icons/breeze"
]

def build_icon_map():
    icon_map = {}
    for base_dir in ICON_SEARCH_DIRS:
        if not os.path.isdir(base_dir):
            continue
        for root, _, files in os.walk(base_dir):
            for f in files:
                if f.endswith(('.png', '.svg', '.webp', '.xpm')):
                    name, _ = os.path.splitext(f)
                    if name not in icon_map:
                        icon_map[name] = os.path.join(root, f)
    return icon_map

def get_installed_packages(force=False):
    if not force and os.path.exists(CACHE_FILE):
        try:
            mtime = os.path.getmtime(CACHE_FILE)
            if time.time() - mtime < CACHE_TTL:
                with open(CACHE_FILE, "r", encoding="utf-8") as f:
                    return json.load(f)
        except Exception:
            pass

    # 1. Obtener lista de paquetes foráneos (AUR / yay)
    aur_pkgs = set()
    res_aur = subprocess.run(["pacman", "-Qqm"], capture_output=True, text=True)
    if res_aur.returncode == 0:
        aur_pkgs = set(res_aur.stdout.strip().split())

    # 2. Obtener actualizaciones pendientes
    updates = {}
    # Pacman
    res_up_pac = subprocess.run(["pacman", "-Qu"], capture_output=True, text=True)
    if res_up_pac.returncode == 0:
        for line in res_up_pac.stdout.strip().split("\n"):
            parts = line.split()
            if len(parts) >= 4 and parts[1] == "->":
                updates[parts[0]] = parts[2]
            elif len(parts) >= 3 and parts[2] == "->":
                updates[parts[0]] = parts[3]

    # AUR (yay)
    if shutil.which("yay"):
        res_up_aur = subprocess.run(["yay", "-Qua"], capture_output=True, text=True)
        if res_up_aur.returncode == 0:
            for line in res_up_aur.stdout.strip().split("\n"):
                parts = line.split()
                if len(parts) >= 4 and parts[2] == "->":
                    updates[parts[0]] = parts[3]

    # 3. Mapear archivos .desktop a paquetes y extraer nombres/iconos
    icon_map = build_icon_map()
    pkg_to_desktop = {}
    
    # Mapeo rápido vía pacman -Ql para encontrar qué paquete provee qué .desktop
    res_ql = subprocess.run(["sh", "-c", "pacman -Ql | grep \"/applications/.*\\.desktop$\""], capture_output=True, text=True)
    if res_ql.returncode == 0:
        for line in res_ql.stdout.strip().split("\n"):
            parts = line.split(None, 1)
            if len(parts) == 2:
                pkg_name, dt_path = parts[0], parts[1].strip()
                if os.path.isfile(dt_path) and pkg_name not in pkg_to_desktop:
                    pkg_to_desktop[pkg_name] = dt_path

    desktop_info = {}
    for pkg_name, dt_path in pkg_to_desktop.items():
        try:
            cfg = configparser.ConfigParser(interpolation=None)
            cfg.read(dt_path, encoding="utf-8")
            if "Desktop Entry" in cfg:
                entry = cfg["Desktop Entry"]
                raw_icon = entry.get("Icon", "").strip()
                resolved_icon = ""
                if raw_icon:
                    if os.path.isabs(raw_icon) and os.path.exists(raw_icon):
                        resolved_icon = raw_icon
                    elif raw_icon in icon_map:
                        resolved_icon = icon_map[raw_icon]
                
                desktop_info[pkg_name] = {
                    "displayName": entry.get("Name", "").strip(),
                    "icon": resolved_icon or raw_icon,
                    "comment": entry.get("Comment", "").strip(),
                    "genericName": entry.get("GenericName", "").strip()
                }
        except Exception:
            pass

    # 4. Obtener información detallada de todos los paquetes instalados explícitamente
    res_qi = subprocess.run(["env", "LC_ALL=C", "pacman", "-Qei"], capture_output=True, text=True)
    packages = []
    cur = {}
    
    for line in res_qi.stdout.split("\n"):
        if not line.strip():
            if cur and "Name" in cur:
                pkg_name = cur["Name"]
                src = "aur" if pkg_name in aur_pkgs else "pacman"
                new_ver = updates.get(pkg_name, "")
                dt = desktop_info.get(pkg_name)

                display_name = dt["displayName"] if dt and dt["displayName"] else pkg_name
                desc = cur.get("Description", "")
                if dt and dt.get("comment"):
                    desc = dt["comment"]

                packages.append({
                    "name": pkg_name,
                    "displayName": display_name,
                    "version": cur.get("Version", ""),
                    "newVersion": new_ver,
                    "hasUpdate": bool(new_ver),
                    "source": src,
                    "sourceLabel": "AUR (yay)" if src == "aur" else "Pacman",
                    "description": desc,
                    "size": cur.get("Installed Size", ""),
                    "url": cur.get("URL", ""),
                    "icon": dt["icon"] if dt else "",
                    "isDesktopApp": bool(dt)
                })
            cur = {}
            continue
        if " : " in line:
            k, v = line.split(" : ", 1)
            cur[k.strip()] = v.strip()
        elif ":" in line:
            k, v = line.split(":", 1)
            cur[k.strip()] = v.strip()

    # Ordenar: primero las apps con interfaz de escritorio o con actualizaciones, luego alfabéticamente
    packages.sort(key=lambda p: (not p["hasUpdate"], not p["isDesktopApp"], p["displayName"].lower()))

    total = len(packages)
    aur_count = sum(1 for p in packages if p["source"] == "aur")
    pacman_count = sum(1 for p in packages if p["source"] == "pacman")
    updates_count = sum(1 for p in packages if p["hasUpdate"])

    result = {
        "total": total,
        "pacmanCount": pacman_count,
        "aurCount": aur_count,
        "updatesCount": updates_count,
        "packages": packages
    }

    try:
        with open(CACHE_FILE, "w", encoding="utf-8") as f:
            json.dump(result, f, indent=2)
    except Exception:
        pass

    return result

def launch_terminal(title, command):
    # Envolver comando con banner visual y pausa antes de cerrar
    shell_cmd = f"""
echo -e '\\033[1;36m==> MrDemonc-SHELL: {title}\\033[0m'
echo -e '\\033[0;34mEjecutando: {command}\\033[0m'
echo ''
{command}
EXIT_CODE=$?
echo ''
if [ $EXIT_CODE -eq 0 ]; then
    echo -e '\\033[1;32m[✓] Operación completada exitosamente.\\033[0m'
else
    echo -e '\\033[1;31m[✗] Error durante la operación (Código: '$EXIT_CODE').\\033[0m'
fi
# Limpiar caché de paquetes para actualizar la UI
rm -f "{CACHE_FILE}" 2>/dev/null || true
echo ''
read -n 1 -s -p 'Presiona cualquier tecla para cerrar...'
"""
    terminals = [
        ("kitty", ["kitty", "--class", "shell-update", "--title", title, "bash", "-c", shell_cmd]),
        ("foot", ["foot", "--app-id", "shell-update", "--title", title, "bash", "-c", shell_cmd]),
        ("alacritty", ["alacritty", "--class", "shell-update", "--title", title, "-e", "bash", "-c", shell_cmd]),
        ("xterm", ["xterm", "-class", "shell-update", "-title", title, "-e", "bash", "-c", shell_cmd])
    ]
    for term_name, term_argv in terminals:
        if shutil.which(term_name):
            subprocess.Popen(term_argv, start_new_session=True)
            return True
    return False

def update_package(pkg_name):
    if not pkg_name:
        return
    # Determinar si es AUR o Pacman
    is_aur = False
    res_aur = subprocess.run(["pacman", "-Qqm"], capture_output=True, text=True)
    if res_aur.returncode == 0 and pkg_name in res_aur.stdout.split():
        is_aur = True

    if is_aur and shutil.which("yay"):
        cmd = f"yay -S --needed {pkg_name}"
    else:
        cmd = f"sudo pacman -S --needed {pkg_name}"

    launch_terminal(f"Actualizar {pkg_name}", cmd)

def update_all():
    if shutil.which("yay"):
        cmd = "yay -Syu"
    else:
        cmd = "sudo pacman -Syu"
    launch_terminal("Actualización Completa del Sistema", cmd)

def remove_package(pkg_name):
    if not pkg_name:
        return
    # Preferir yay para limpiar dependencias si está disponible, o pacman -Rns
    if shutil.which("yay"):
        cmd = f"yay -Rns {pkg_name}"
    else:
        cmd = f"sudo pacman -Rns {pkg_name}"

    launch_terminal(f"Desinstalar {pkg_name}", cmd)

def main():
    if len(sys.argv) < 2:
        res = get_installed_packages()
        print(json.dumps(res, indent=2))
        return

    action = sys.argv[1].lower()
    if action in ("list", "get"):
        force = "--force" in sys.argv or "-f" in sys.argv
        res = get_installed_packages(force=force)
        print(json.dumps(res, indent=2))
    elif action == "update" and len(sys.argv) > 2:
        update_package(sys.argv[2])
    elif action in ("update-all", "update_all"):
        update_all()
    elif action in ("remove", "uninstall", "delete") and len(sys.argv) > 2:
        remove_package(sys.argv[2])
    elif action == "clear-cache":
        if os.path.exists(CACHE_FILE):
            os.remove(CACHE_FILE)
        print(json.dumps({"status": "ok"}))
    else:
        print(json.dumps({"error": f"Comando no reconocido: {action}"}))

if __name__ == "__main__":
    main()
