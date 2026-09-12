#!/usr/bin/env python3
import sys
import os
import subprocess

def authenticate(password: str) -> bool:
    user = os.environ.get("USER")
    if not user:
        import getpass
        user = getpass.getuser()

    # 1. Intentar con unix_chkpwd (método estándar PAM de bajo nivel)
    chkpwd_paths = ["/usr/bin/unix_chkpwd", "/sbin/unix_chkpwd", "/usr/sbin/unix_chkpwd"]
    chkpwd = next((p for p in chkpwd_paths if os.path.exists(p) and os.access(p, os.X_OK)), None)

    if chkpwd:
        try:
            p = subprocess.Popen(
                [chkpwd, user, "nullok"],
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            p.communicate(password.encode("utf-8") + b"\x00")
            if p.returncode == 0:
                return True
        except Exception:
            pass

    # 2. Intentar con módulo pam de python si estuviese disponible
    try:
        import pam
        p = pam.pam()
        if p.authenticate(user, password):
            return True
    except Exception:
        pass

    return False

def main():
    # Leer contraseña de forma segura por stdin (no visible en ps aux)
    try:
        raw = sys.stdin.buffer.read()
        # Limpiar salto de línea terminal si viene por pipe
        pwd = raw.rstrip(b"\r\n\x00").decode("utf-8", errors="replace")
    except Exception:
        pwd = ""

    if authenticate(pwd):
        sys.exit(0)
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()
