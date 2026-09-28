#!/usr/bin/env python3
"""
scripts/setup_bookmarks.py
MrDemonc-SHELL - Inicializador y gestor de marcadores para GTK (~/.config/gtk-3.0/bookmarks).
Asegura que las carpetas estándar de usuario (Descargas, Documentos, Imágenes, Vídeos, Música)
estén ancladas en la barra lateral del explorador de archivos por defecto.
"""

import os
import sys
import argparse
import subprocess
import re

try:
    from gi.repository import Gio
    HAS_GIO = True
except ImportError:
    HAS_GIO = False


def path_to_uri(path):
    if HAS_GIO:
        try:
            return Gio.File.new_for_path(path).get_uri()
        except Exception:
            pass
    import urllib.parse
    return "file://" + urllib.parse.quote(os.path.abspath(path))


def uri_to_path(uri):
    if HAS_GIO:
        try:
            f = Gio.File.new_for_uri(uri)
            p = f.get_path()
            if p:
                return os.path.normpath(p)
        except Exception:
            pass
    if uri.startswith("file://"):
        import urllib.parse
        return os.path.normpath(urllib.parse.unquote(uri[7:]))
    return None


def get_user_dirs(home_dir):
    """
    Obtiene las rutas de los directorios estándar de usuario para el home especificado.
    Prioriza ~/.config/user-dirs.dirs, luego xdg-user-dir, y finalmente fallbacks estándar.
    """
    # Si es el usuario actual, intentar correr xdg-user-dirs-update primero
    if os.path.abspath(home_dir) == os.path.abspath(os.path.expanduser("~")):
        try:
            subprocess.run(
                ["xdg-user-dirs-update"],
                check=False,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
        except Exception:
            pass

    user_dirs_file = os.path.join(home_dir, ".config", "user-dirs.dirs")
    dirs_map = {}

    if os.path.exists(user_dirs_file):
        try:
            with open(user_dirs_file, "r", encoding="utf-8", errors="replace") as f:
                for line in f:
                    m = re.match(r'^XDG_([A-Z]+)_DIR=[\"\']?(.*?)[\"\']?$', line.strip())
                    if m:
                        k = m.group(1)
                        val = m.group(2).replace("$HOME", home_dir).replace("${HOME}", home_dir)
                        dirs_map[k] = val
        except Exception:
            pass

    categories = [
        ("DOWNLOAD", ["Descargas", "Downloads"]),
        ("DOCUMENTS", ["Documentos", "Documents"]),
        ("PICTURES", ["Imágenes", "Pictures"]),
        ("VIDEOS", ["Vídeos", "Videos"]),
        ("MUSIC", ["Música", "Music"]),
    ]

    target_paths = []
    for cat, fallbacks in categories:
        path = dirs_map.get(cat)

        # Si no se encontró en el archivo y estamos en el home actual, probar xdg-user-dir
        if (not path or not os.path.isdir(path)) and os.path.abspath(home_dir) == os.path.abspath(os.path.expanduser("~")):
            try:
                out = subprocess.check_output(
                    ["xdg-user-dir", cat],
                    text=True,
                    stderr=subprocess.DEVNULL
                ).strip()
                if out and out != home_dir:
                    path = out
            except Exception:
                pass

        # Si aún no existe, buscar entre los fallbacks o crear el preferente
        if not path or not os.path.isdir(path) or path == home_dir:
            found = False
            for fb in fallbacks:
                candidate = os.path.join(home_dir, fb)
                if os.path.isdir(candidate):
                    path = candidate
                    found = True
                    break
            if not found:
                path = os.path.join(home_dir, fallbacks[0])
                try:
                    os.makedirs(path, exist_ok=True)
                except Exception:
                    pass

        if path and path != home_dir and path not in target_paths:
            target_paths.append(path)

    return target_paths


def sync_bookmarks(home_dir, quiet=False):
    home_dir = os.path.abspath(home_dir)
    gtk3_dir = os.path.join(home_dir, ".config", "gtk-3.0")
    os.makedirs(gtk3_dir, exist_ok=True)
    bookmarks_file = os.path.join(gtk3_dir, "bookmarks")

    target_paths = get_user_dirs(home_dir)

    # Leer entradas existentes
    existing_lines = []
    existing_paths = set()
    if os.path.exists(bookmarks_file):
        try:
            with open(bookmarks_file, "r", encoding="utf-8", errors="replace") as f:
                for line in f:
                    line_str = line.strip()
                    if not line_str:
                        continue
                    parts = line_str.split(maxsplit=1)
                    uri = parts[0]
                    p = uri_to_path(uri)
                    if p:
                        existing_paths.add(p)
                    existing_lines.append((line_str, p))
        except Exception as e:
            if not quiet:
                print(f"[!] Error al leer marcadores existentes: {e}", file=sys.stderr)

    # Construir líneas estándar (al inicio)
    standard_lines = []
    for p in target_paths:
        try:
            os.makedirs(p, exist_ok=True)
        except Exception:
            pass
        uri = path_to_uri(p)
        name = os.path.basename(p)
        standard_lines.append(f"{uri} {name}")

    # Preservar marcadores personalizados existentes que no pertenezcan a carpetas estándar
    custom_lines = []
    for line_str, p in existing_lines:
        if p not in target_paths:
            custom_lines.append(line_str)

    final_lines = standard_lines + custom_lines
    new_content = "\n".join(final_lines) + "\n"

    current_content = ""
    if os.path.exists(bookmarks_file):
        try:
            with open(bookmarks_file, "r", encoding="utf-8", errors="replace") as f:
                current_content = f.read()
        except Exception:
            pass

    if new_content != current_content:
        with open(bookmarks_file, "w", encoding="utf-8") as f:
            f.write(new_content)
        if not quiet:
            print(f"[+] Marcadores de Nautilus actualizados en: {bookmarks_file}")
            for p in target_paths:
                print(f"    - {os.path.basename(p)} ({p})")
    else:
        if not quiet:
            print(f"[=] Marcadores de Nautilus ya configurados en: {bookmarks_file}")


def main():
    parser = argparse.ArgumentParser(
        description="Configura los marcadores estándar de usuario en GTK (~/.config/gtk-3.0/bookmarks)"
    )
    parser.add_argument(
        "--home",
        type=str,
        default=os.path.expanduser("~"),
        help="Ruta al directorio de inicio (HOME) del usuario objetivo"
    )
    parser.add_argument(
        "-q", "--quiet",
        action="store_true",
        help="Modo silencioso (no imprimir detalles en stdout)"
    )

    args = parser.parse_args()
    sync_bookmarks(args.home, args.quiet)


if __name__ == "__main__":
    main()
