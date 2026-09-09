#!/usr/bin/env python3
import os
import json
import re

def parse_colors():
    theme_path = os.path.expanduser('~/.local/state/mrdemonc/current/theme/colors.toml')
    colors = {}
    if os.path.exists(theme_path):
        try:
            with open(theme_path, 'r', encoding='utf-8') as f:
                for line in f:
                    m = re.match(r'^\s*([a-zA-Z0-9_-]+)\s*=\s*[\"\']([^\"\']+)[\"\']', line)
                    if m:
                        colors[m.group(1)] = m.group(2)
        except Exception:
            pass

    bg = colors.get('background', '#181825')
    fg = colors.get('foreground', '#cdd6f4')
    accent = colors.get('accent', colors.get('color4', '#89b4fa'))

    def hex_to_rgb(hex_str):
        hex_str = hex_str.lstrip('#')
        if len(hex_str) == 6:
            return tuple(int(hex_str[i:i+2], 16) for i in (0, 2, 4))
        return (24, 24, 37)

    def rgb_to_hex(r, g, b):
        return f"#{max(0, min(255, int(r))):02x}{max(0, min(255, int(g))):02x}{max(0, min(255, int(b))):02x}"

    def adjust_brightness(hex_str, factor):
        r, g, b = hex_to_rgb(hex_str)
        if factor > 0:
            r = r + (255 - r) * factor
            g = g + (255 - g) * factor
            b = b + (255 - b) * factor
        else:
            r = r * (1 + factor)
            g = g * (1 + factor)
            b = b * (1 + factor)
        return rgb_to_hex(r, g, b)

    r, g, b = hex_to_rgb(bg)
    lum = 0.299 * r + 0.587 * g + 0.114 * b
    is_dark = lum < 128

    bg_surface = adjust_brightness(bg, 0.08 if is_dark else -0.05)
    bg_hover = adjust_brightness(bg, 0.16 if is_dark else -0.10)
    border = adjust_brightness(bg, 0.22 if is_dark else -0.15)
    overlay = colors.get('color8', adjust_brightness(fg, -0.45 if is_dark else 0.45))
    subtext = colors.get('color7', adjust_brightness(fg, -0.25 if is_dark else 0.25))

    theme_data = {
        "isDark": is_dark,
        "bg": bg,
        "bgSurface": bg_surface,
        "bgHover": bg_hover,
        "border": border,
        "text": fg,
        "subtext": subtext,
        "overlay": overlay,
        "primary": accent,
        "success": colors.get('color2', '#a6e3a1'),
        "warning": colors.get('color3', '#f9e2af'),
        "danger": colors.get('color1', '#f38ba8'),
        "cyan": colors.get('color6', '#89dceb'),
        "pink": colors.get('color5', '#f5c2e7')
    }

    print(json.dumps(theme_data))

if __name__ == '__main__':
    parse_colors()
