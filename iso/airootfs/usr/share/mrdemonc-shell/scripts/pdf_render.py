#!/usr/bin/env python3
"""
Renderizador progresivo de PDFs para MrDemonc PDF en Quickshell.
Extrae metadatos y convierte páginas a PNG de forma ordenada y no bloqueante.
"""
import os
import sys
import json
import glob
import subprocess

def main():
    if len(sys.argv) < 3:
        sys.exit(1)

    pdf_path = os.path.abspath(sys.argv[1])
    out_dir = os.path.abspath(sys.argv[2])
    os.makedirs(out_dir, exist_ok=True)

    if not os.path.isfile(pdf_path):
        print(json.dumps({"status": "error", "message": "Archivo no encontrado"}), flush=True)
        sys.exit(1)

    # 1. Obtener metadatos con Poppler (sin warnings)
    total_pages = 1
    w = 612.0
    h = 792.0

    try:
        import gi
        gi.require_version('Poppler', '0.18')
        from gi.repository import Poppler, Gio
        gfile = Gio.File.new_for_path(pdf_path)
        doc = Poppler.Document.new_from_gfile(gfile, None)
        total_pages = doc.get_n_pages()
        p0 = doc.get_page(0)
        w, h = p0.get_size()
    except Exception:
        # Fallback a pdfinfo
        try:
            res = subprocess.check_output(['pdfinfo', pdf_path], text=True, stderr=subprocess.DEVNULL)
            for line in res.splitlines():
                if line.startswith('Pages:'):
                    total_pages = int(line.split(':')[1].strip())
        except Exception:
            pass

    # Emitir metadatos inmediatamente a QML
    print(json.dumps({"status": "info", "pages": total_pages, "w": w, "h": h}), flush=True)

    # 2. Función auxiliar para renderizar rango de páginas
    def render_range(first, last):
        prefix = os.path.join(out_dir, f"tmp_{first}_{last}")
        cmd = ['pdftoppm', '-png', '-r', '135', '-f', str(first), '-l', str(last), pdf_path, prefix]
        try:
            subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            matches = glob.glob(f"{prefix}-*.png")
            for filepath in matches:
                try:
                    base = os.path.basename(filepath)
                    num_part = base.split('-')[-1].split('.')[0]
                    p_num = int(num_part)
                    target_name = os.path.join(out_dir, f"page_{p_num}.png")
                    os.replace(filepath, target_name)
                    print(json.dumps({"status": "page", "page": p_num}), flush=True)
                except Exception:
                    pass
        except Exception:
            pass

    # 3. Fase 1: Renderizar página 1 de forma ultra-rápida (50ms)
    render_range(1, 1)

    # 4. Fase 2: Renderizar páginas 2 a 5
    if total_pages >= 2:
        render_range(2, min(5, total_pages))

    # 5. Fase 3: Renderizar el resto en bloques de 5 páginas
    current = 6
    while current <= total_pages:
        chunk_end = min(current + 4, total_pages)
        render_range(current, chunk_end)
        current = chunk_end + 1

    print(json.dumps({"status": "done"}), flush=True)

if __name__ == "__main__":
    main()
