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

def notify(title, message, urgency="normal", icon="system-software-update"):
    cmd = ["notify-send", title, message, "-u", urgency, "-a", "MrDemonc-SHELL"]
    if icon:
        cmd.extend(["-i", icon])
    try:
        subprocess.run(cmd, capture_output=True)
    except Exception:
        pass

def clear_cache():
    if os.path.exists(CACHE_FILE):
        try:
            os.remove(CACHE_FILE)
        except Exception:
            pass

def check_sudo():
    res = subprocess.run(["sudo", "-n", "true"], capture_output=True)
    return res.returncode == 0

def auth_sudo(password: str) -> bool:
    if not password:
        return False

    # 1. Validar primero con unix_chkpwd para respuesta ultrarrápida si es incorrecta
    user = os.environ.get("USER")
    if not user:
        import getpass
        user = getpass.getuser()

    chkpwd_paths = ["/usr/bin/unix_chkpwd", "/sbin/unix_chkpwd", "/usr/sbin/unix_chkpwd"]
    chkpwd = next((p for p in chkpwd_paths if os.path.exists(p) and os.access(p, os.X_OK)), None)
    if chkpwd:
        try:
            p_chk = subprocess.Popen(
                [chkpwd, user, "nullok"],
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            p_chk.communicate(input=password.encode("utf-8") + b"\x00", timeout=4)
            if p_chk.returncode != 0:
                return False
        except Exception:
            pass

    # 2. Actualizar el ticket de sesión sudo en el kernel
    try:
        p = subprocess.Popen(
            ["sudo", "-S", "-v", "-p", ""],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        p.communicate(input=password.encode("utf-8") + b"\n", timeout=8)
        return p.returncode == 0
    except Exception:
        return False

def ensure_sudo_auth():
    # 1. Comprobar si sudo ya está validado sin contraseña en la sesión del kernel
    if check_sudo():
        return True

    # 2. Si hay entrada disponible en stdin no interactivo, intentar autenticar
    if not sys.stdin.isatty():
        try:
            line = sys.stdin.readline().strip()
            if line and auth_sudo(line):
                return True
        except Exception:
            pass

    return False


def update_package(pkg_name):
    if not pkg_name:
        return
    # Determinar si es AUR o Pacman
    is_aur = False
    res_aur = subprocess.run(["pacman", "-Qqm"], capture_output=True, text=True)
    if res_aur.returncode == 0 and pkg_name in res_aur.stdout.split():
        is_aur = True

    if not ensure_sudo_auth():
        notify("Operación cancelada", f"Se canceló la autenticación para actualizar {pkg_name}.", urgency="low")
        return

    notify("Actualizando aplicación", f"Descargando e instalando {pkg_name} en segundo plano...", icon="system-software-update")

    if is_aur and shutil.which("yay"):
        cmd = ["yay", "-S", "--needed", "--noconfirm", "--sudoloop", pkg_name]
    else:
        cmd = ["sudo", "pacman", "-S", "--needed", "--noconfirm", pkg_name]

    res = subprocess.run(cmd, capture_output=True, text=True)
    clear_cache()

    if res.returncode == 0:
        notify("Actualización completada", f"{pkg_name} se actualizó exitosamente.", icon="software-update-available")
    else:
        err_msg = res.stderr.strip() or res.stdout.strip()
        notify("Error al actualizar", f"No se pudo actualizar {pkg_name}.\n{err_msg[:120]}", urgency="critical", icon="dialog-error")

def update_all():
    if not ensure_sudo_auth():
        notify("Operación cancelada", "Se canceló la autenticación para actualizar el sistema.", urgency="low")
        return

    notify("Actualizando sistema", "Buscando e instalando todas las actualizaciones disponibles...", icon="system-software-update")

    if shutil.which("yay"):
        cmd = ["yay", "-Syu", "--noconfirm", "--sudoloop"]
    else:
        cmd = ["sudo", "pacman", "-Syu", "--noconfirm"]

    res = subprocess.run(cmd, capture_output=True, text=True)
    clear_cache()

    if res.returncode == 0:
        notify("Sistema al día", "Todas las aplicaciones y paquetes se actualizaron correctamente.", icon="software-update-available")
    else:
        notify("Error en actualización", "Ocurrió un error al actualizar los paquetes del sistema.", urgency="critical", icon="dialog-error")

def remove_package(pkg_name):
    if not pkg_name:
        return

    if not ensure_sudo_auth():
        notify("Operación cancelada", f"Se canceló la autenticación para desinstalar {pkg_name}.", urgency="low")
        return

    notify("Desinstalando paquete", f"Eliminando {pkg_name} y dependencias no utilizadas...", icon="system-software-update")

    if shutil.which("yay"):
        cmd = ["yay", "-Rns", "--noconfirm", pkg_name]
    else:
        cmd = ["sudo", "pacman", "-Rns", "--noconfirm", pkg_name]

    res = subprocess.run(cmd, capture_output=True, text=True)
    clear_cache()

    if res.returncode == 0:
        notify("Desinstalación completada", f"{pkg_name} se desinstaló correctamente.", icon="software-update-available")
    else:
        err_msg = res.stderr.strip() or res.stdout.strip()
        notify("Error al desinstalar", f"No se pudo desinstalar {pkg_name}.\n{err_msg[:120]}", urgency="critical", icon="dialog-error")

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
    elif action in ("check-sudo", "check_sudo"):
        if check_sudo():
            print(json.dumps({"authenticated": True}))
            sys.exit(0)
        else:
            print(json.dumps({"authenticated": False}))
            sys.exit(1)
    elif action == "auth":
        try:
            line = sys.stdin.readline()
            pwd = line.rstrip("\r\n")
        except Exception:
            pwd = ""
        if auth_sudo(pwd):
            print(json.dumps({"success": True}))
            sys.exit(0)
        else:
            print(json.dumps({"success": False, "error": "Contraseña incorrecta"}))
            sys.exit(1)
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
