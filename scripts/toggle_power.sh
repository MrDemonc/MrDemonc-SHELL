#!/usr/bin/env bash
# Alterna la visibilidad del menú de apagado/energía de Quickshell (SUPER + ESC)
STATE="${XDG_RUNTIME_DIR:-/tmp}/quickshell_power.toggle"
touch "$STATE"
