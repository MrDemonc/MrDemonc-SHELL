#!/usr/bin/env python3
"""
osd_server.py: Servidor / demonio IPC ultrarrápido para el OSD estilo macOS de Quickshell.
Crea y escucha en un FIFO Unix en tiempo real (latencia <1ms) sin consumo de CPU.
"""

import os
import sys
import time
import signal
import select

RUNTIME_DIR = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
FIFO_PATH = os.path.join(RUNTIME_DIR, "quickshell_osd.fifo")
STATE_FILE = os.path.join(RUNTIME_DIR, "quickshell_osd.last")

running = True

def cleanup(*args):
    global running
    running = False
    try:
        if os.path.exists(FIFO_PATH):
            os.remove(FIFO_PATH)
    except Exception:
        pass
    sys.exit(0)

signal.signal(signal.SIGINT, cleanup)
signal.signal(signal.SIGTERM, cleanup)

def main():
    global running
    # Limpiar FIFO previo si existiera
    try:
        if os.path.exists(FIFO_PATH):
            os.remove(FIFO_PATH)
    except Exception:
        pass

    try:
        os.mkfifo(FIFO_PATH, 0o600)
    except Exception as e:
        sys.stderr.write(f"Error creando FIFO OSD: {e}\n")
        sys.stderr.flush()

    # Abrir extremo de lectura no bloqueante y escritor dummy para evitar EOF constante
    try:
        r_fd = os.open(FIFO_PATH, os.O_RDONLY | os.O_NONBLOCK)
        w_dummy = os.open(FIFO_PATH, os.O_WRONLY)
    except Exception as e:
        sys.stderr.write(f"Error abriendo FIFO: {e}\n")
        sys.stderr.flush()
        return

    poll = select.poll()
    poll.register(r_fd, select.POLLIN)

    buffer = ""

    # Mensaje inicial de confirmación
    sys.stdout.write('{"status":"ready"}\n')
    sys.stdout.flush()

    while running:
        try:
            events = poll.poll(1000) # Espera hasta 1s o hasta nuevo evento
            if not events:
                continue

            chunk = os.read(r_fd, 4096)
            if not chunk:
                time.sleep(0.01)
                continue

            buffer += chunk.decode("utf-8", errors="ignore")
            while "\n" in buffer:
                line, buffer = buffer.split("\n", 1)
                line = line.strip()
                if line and line.startswith("{") and line.endswith("}"):
                    sys.stdout.write(line + "\n")
                    sys.stdout.flush()

        except KeyboardInterrupt:
            break
        except Exception as ex:
            time.sleep(0.05)

    cleanup()

if __name__ == "__main__":
    main()
