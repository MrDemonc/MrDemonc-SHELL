#!/usr/bin/env python3
import os
import json
import sys
import glob
import shutil
import tempfile
import zipfile
import tarfile
import urllib.request
import re

THEMES_DIR = os.path.expanduser("~/.config/quickshell/themes")
CONFIG_FILE = os.path.expanduser("~/.config/quickshell/current_theme.json")

# Tema Default basado en La Gran Ola de Kanagawa (default.jpg) y tonos nórdicos
BUILTIN_THEMES = {
    "default": {
        "name": "Default",
        "description": "Tema predeterminado inspirado en La Gran Ola de Kanagawa y tonos pizarra nórdicos",
        "author": "MrDemonc",
        "isDark": True,
        "wallpaper": "wallpaper.jpg",
        "bg": "#1a1d24",
        "bgSurface": "#14161d",
        "bgHover": "#282d38",
        "border": "#353b49",
        "text": "#eceff4",
        "subtext": "#d8dee9",
        "overlay": "#7b889b",
        "primary": "#88c0d0",
        "success": "#a3be8c",
        "warning": "#ebcb8b",
        "danger": "#bf616a",
        "cyan": "#81a1c1",
        "pink": "#b48ead"
    },
    "street": {
        "name": "Street",
        "description": "Tema atmosférico extraído de la carretera húmeda entre pinares con líneas doradas y niebla otoñal",
        "author": "MrDemonc",
        "isDark": True,
        "wallpaper": "wallpaper.jpg",
        "bg": "#14171a",
        "bgSurface": "#1b1f23",
        "bgHover": "#282e35",
        "border": "#3a434c",
        "text": "#ece5de",
        "subtext": "#b8ab9f",
        "overlay": "#707a84",
        "primary": "#f5af19",
        "success": "#6f9479",
        "warning": "#e59b1f",
        "danger": "#c85a42",
        "cyan": "#77a2b2",
        "pink": "#b67d8f"
    }
}

THEME_SEARCH_DIRS = [
    os.path.expanduser("~/.config/quickshell/themes"),
    os.path.expanduser("~/Documentos/MrDemonc-SHELL/themes"),
    "/usr/share/mrdemonc-shell/themes"
]

def ensure_dirs():
    os.makedirs(THEMES_DIR, exist_ok=True)
    os.makedirs(os.path.dirname(CONFIG_FILE), exist_ok=True)

def get_current_theme_name():
    ensure_dirs()
    if os.path.exists(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, 'r', encoding='utf-8') as f:
                data = json.load(f)
                return data.get("theme", "default")
        except Exception:
            pass
    return "default"

def get_all_themes():
    ensure_dirs()
    themes = {}

    # Buscar temas en las carpetas estructuradas (themes/<theme_id>/theme.json)
    for base_dir in THEME_SEARCH_DIRS:
        if not os.path.isdir(base_dir):
            continue
        for entry in os.listdir(base_dir):
            sub_path = os.path.join(base_dir, entry)
            if os.path.isdir(sub_path):
                tj = os.path.join(sub_path, "theme.json")
                if os.path.isfile(tj):
                    try:
                        with open(tj, 'r', encoding='utf-8') as f:
                            th_data = json.load(f)
                            tid = th_data.get("id", entry)
                            th_data["id"] = tid
                            th_data["_dir"] = sub_path
                            # Resolver ruta absoluta de wallpaper si existe en la carpeta del tema
                            w = th_data.get("wallpaper", "")
                            if w:
                                if not os.path.isabs(w):
                                    w = os.path.join(sub_path, w)
                                if os.path.exists(w):
                                    th_data["wallpaperPath"] = w
                            else:
                                for ext in [".jpg", ".jpeg", ".png", ".webp"]:
                                    cand = os.path.join(sub_path, f"wallpaper{ext}")
                                    if os.path.exists(cand):
                                        th_data["wallpaperPath"] = cand
                                        break
                            if tid not in themes:
                                themes[tid] = th_data
                    except Exception:
                        pass
            elif entry.endswith(".json"):
                tid = entry[:-5]
                try:
                    with open(sub_path, 'r', encoding='utf-8') as f:
                        th_data = json.load(f)
                        th_data["id"] = tid
                        if tid not in themes:
                            themes[tid] = th_data
                except Exception:
                    pass

    # Integrar BUILTIN_THEMES si no están cargados aún
    for tid, val in BUILTIN_THEMES.items():
        if tid not in themes:
            th = dict(val)
            th["id"] = tid
            # Buscar wallpaper para el builtin
            for base_dir in THEME_SEARCH_DIRS:
                cand = os.path.join(base_dir, tid, "wallpaper.jpg")
                if os.path.exists(cand):
                    th["wallpaperPath"] = cand
                    break
            themes[tid] = th

    return themes

def get_theme(name=None):
    if not name:
        name = get_current_theme_name()
    all_themes = get_all_themes()
    if name in all_themes:
        th = all_themes[name]
        th["id"] = name
        return th
    th = dict(BUILTIN_THEMES["default"])
    th["id"] = "default"
    return th

def sync_terminal_theme(theme_data):
    try:
        mrdemonc_theme_dir = os.path.expanduser("~/.local/state/mrdemonc/current/theme")
        os.makedirs(mrdemonc_theme_dir, exist_ok=True)

        is_dark = theme_data.get("isDark", True)
        bg = theme_data.get("bg", "#2e3340")
        bg_surface = theme_data.get("bgSurface", "#242833")
        bg_hover = theme_data.get("bgHover", "#3b4252")
        border = theme_data.get("border", "#434c5e")
        fg = theme_data.get("text", "#eceff4")
        subtext = theme_data.get("subtext", "#d8dee9")
        overlay = theme_data.get("overlay", "#7b889b")
        primary = theme_data.get("primary", "#88c0d0")
        success = theme_data.get("success", "#a3be8c")
        warning = theme_data.get("warning", "#ebcb8b")
        danger = theme_data.get("danger", "#bf616a")
        cyan = theme_data.get("cyan", "#81a1c1")
        pink = theme_data.get("pink", "#b48ead")

        # Generación de configuración para Kitty
        kitty_content = f"""# Generado automáticamente por Quickshell Theme Manager
foreground {fg}
background {bg}
selection_foreground {fg}
selection_background {bg_hover}

cursor {primary}
cursor_text_color {bg}

active_border_color {primary}
inactive_border_color {border}
active_tab_background {primary}
active_tab_foreground {bg}
inactive_tab_background {bg_surface}
inactive_tab_foreground {subtext}

# Paleta ANSI estándar
color0 {bg_surface if is_dark else bg_hover}
color1 {danger}
color2 {success}
color3 {warning}
color4 {cyan}
color5 {pink}
color6 {primary}
color7 {fg}

# Paleta ANSI brillante
color8 {overlay}
color9 {danger}
color10 {success}
color11 {warning}
color12 {cyan}
color13 {pink}
color14 {primary}
color15 {subtext if is_dark else fg}
"""
        # Escribir en ~/.config/kitty/theme.conf (para include directo sin problemas de expansión)
        kitty_cfg_dir = os.path.expanduser("~/.config/kitty")
        os.makedirs(kitty_cfg_dir, exist_ok=True)
        with open(os.path.join(kitty_cfg_dir, "theme.conf"), "w", encoding="utf-8") as f:
            f.write(kitty_content)

        kitty_path = os.path.join(mrdemonc_theme_dir, "kitty.conf")
        with open(kitty_path, "w", encoding="utf-8") as f:
            f.write(kitty_content)

        # Generación de configuración para Foot
        foot_section = "colors-dark" if is_dark else "colors-light"
        foot_content = f"""# Generado automáticamente por Quickshell Theme Manager
[{foot_section}]
foreground={fg.lstrip('#')}
background={bg.lstrip('#')}
selection-foreground={fg.lstrip('#')}
selection-background={bg_hover.lstrip('#')}

cursor={bg.lstrip('#')} {primary.lstrip('#')}

regular0={(bg_surface if is_dark else bg_hover).lstrip('#')}
regular1={danger.lstrip('#')}
regular2={success.lstrip('#')}
regular3={warning.lstrip('#')}
regular4={cyan.lstrip('#')}
regular5={pink.lstrip('#')}
regular6={primary.lstrip('#')}
regular7={fg.lstrip('#')}

bright0={overlay.lstrip('#')}
bright1={danger.lstrip('#')}
bright2={success.lstrip('#')}
bright3={warning.lstrip('#')}
bright4={cyan.lstrip('#')}
bright5={pink.lstrip('#')}
bright6={primary.lstrip('#')}
bright7={(subtext if is_dark else fg).lstrip('#')}
"""
        foot_path = os.path.join(mrdemonc_theme_dir, "foot.ini")
        with open(foot_path, "w", encoding="utf-8") as f:
            f.write(foot_content)

        # Guardar nombre de tema activo
        name_f = os.path.expanduser("~/.local/state/mrdemonc/current/theme.name")
        os.makedirs(os.path.dirname(name_f), exist_ok=True)
        with open(name_f, "w", encoding="utf-8") as f:
            f.write(theme_data.get("id", "default") + "\n")

        # Notificar a las instancias abiertas de Kitty para recargar colores en vivo
        import subprocess
        try:
            # Recargar configuración con señal SIGUSR1 (Kitty recarga theme.conf instantáneamente)
            subprocess.run(["pkill", "-SIGUSR1", "kitty"], stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.run(["killall", "-SIGUSR1", "kitty"], stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except Exception:
            pass
    except Exception:
        pass

def sync_nvim_theme(theme_data):
    try:
        theme_name = theme_data.get("name", "Default")
        is_dark = theme_data.get("isDark", True)
        bg = theme_data.get("bg", "#1a1d24")
        bg_surface = theme_data.get("bgSurface", "#14161d")
        bg_hover = theme_data.get("bgHover", "#282d38")
        border = theme_data.get("border", "#353b49")
        fg = theme_data.get("text", "#eceff4")
        subtext = theme_data.get("subtext", "#d8dee9")
        overlay = theme_data.get("overlay", "#7b889b")
        primary = theme_data.get("primary", "#88c0d0")
        success = theme_data.get("success", "#a3be8c")
        warning = theme_data.get("warning", "#ebcb8b")
        danger = theme_data.get("danger", "#bf616a")
        cyan = theme_data.get("cyan", "#81a1c1")
        pink = theme_data.get("pink", "#b48ead")

        nvim_colors = f"""-- Generado automáticamente por Quickshell Theme Manager
-- Tema activo: {theme_name}
vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end
vim.g.colors_name = "quickshell"
vim.o.termguicolors = true
vim.o.background = "{"dark" if is_dark else "light"}"

local c = {{
  bg = "{bg}",
  bg_surface = "{bg_surface}",
  bg_hover = "{bg_hover}",
  border = "{border}",
  fg = "{fg}",
  subtext = "{subtext}",
  overlay = "{overlay}",
  primary = "{primary}",
  success = "{success}",
  warning = "{warning}",
  danger = "{danger}",
  cyan = "{cyan}",
  pink = "{pink}",
}}

local hl = function(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

-- Fondo transparente integrado directamente con Kitty (cero desfase de bordes)
hl("Normal", {{ fg = c.fg, bg = "none" }})
hl("NormalNC", {{ fg = c.subtext, bg = "none" }})
hl("NormalFloat", {{ fg = c.fg, bg = "none" }})
hl("FloatBorder", {{ fg = c.primary, bg = "none" }})
hl("FloatTitle", {{ fg = c.primary, bg = "none", bold = true }})
hl("CursorLine", {{ bg = c.bg_hover }})
hl("CursorColumn", {{ bg = c.bg_hover }})
hl("ColorColumn", {{ bg = c.bg_surface }})
hl("LineNr", {{ fg = c.overlay, bg = "none" }})
hl("CursorLineNr", {{ fg = c.primary, bg = "none", bold = true }})
hl("SignColumn", {{ fg = c.overlay, bg = "none" }})
hl("VertSplit", {{ fg = c.border, bg = "none" }})
hl("WinSeparator", {{ fg = c.border, bg = "none" }})
hl("StatusLine", {{ fg = c.fg, bg = c.bg_surface }})
hl("StatusLineNC", {{ fg = c.overlay, bg = c.bg_surface }})
hl("TabLine", {{ fg = c.overlay, bg = c.bg_surface }})
hl("TabLineFill", {{ bg = c.bg_surface }})
hl("TabLineSel", {{ fg = c.bg, bg = c.primary, bold = true }})
hl("Pmenu", {{ fg = c.fg, bg = c.bg_surface }})
hl("PmenuSel", {{ fg = c.bg, bg = c.primary, bold = true }})
hl("PmenuSbar", {{ bg = c.bg_surface }})
hl("PmenuThumb", {{ bg = c.overlay }})
hl("Visual", {{ bg = c.bg_hover }})
hl("VisualNOS", {{ bg = c.bg_hover }})
hl("Search", {{ fg = c.bg, bg = c.warning }})
hl("IncSearch", {{ fg = c.bg, bg = c.primary }})
hl("CurSearch", {{ fg = c.bg, bg = c.primary, bold = true }})
hl("MatchParen", {{ fg = c.primary, bold = true, underline = true }})
hl("Directory", {{ fg = c.primary, bold = true }})
hl("Title", {{ fg = c.primary, bold = true }})

-- Sintaxis estándar
hl("Comment", {{ fg = c.overlay, italic = true }})
hl("Constant", {{ fg = c.warning }})
hl("String", {{ fg = c.success }})
hl("Character", {{ fg = c.success }})
hl("Number", {{ fg = c.warning }})
hl("Boolean", {{ fg = c.warning, bold = true }})
hl("Float", {{ fg = c.warning }})
hl("Identifier", {{ fg = c.fg }})
hl("Function", {{ fg = c.primary, bold = true }})
hl("Statement", {{ fg = c.pink }})
hl("Conditional", {{ fg = c.pink }})
hl("Repeat", {{ fg = c.pink }})
hl("Label", {{ fg = c.pink }})
hl("Operator", {{ fg = c.cyan }})
hl("Keyword", {{ fg = c.pink, bold = true }})
hl("Exception", {{ fg = c.danger }})
hl("PreProc", {{ fg = c.cyan }})
hl("Include", {{ fg = c.cyan }})
hl("Define", {{ fg = c.cyan }})
hl("Macro", {{ fg = c.cyan }})
hl("Type", {{ fg = c.cyan }})
hl("StorageClass", {{ fg = c.cyan }})
hl("Structure", {{ fg = c.cyan }})
hl("Typedef", {{ fg = c.cyan }})
hl("Special", {{ fg = c.primary }})
hl("SpecialChar", {{ fg = c.warning }})
hl("Tag", {{ fg = c.primary }})
hl("Delimiter", {{ fg = c.subtext }})
hl("SpecialComment", {{ fg = c.overlay, bold = true }})
hl("Debug", {{ fg = c.danger }})
hl("Underlined", {{ underline = true }})
hl("Error", {{ fg = c.danger, bold = true }})
hl("Todo", {{ fg = c.bg, bg = c.warning, bold = true }})

-- Diagnósticos LSP
hl("DiagnosticError", {{ fg = c.danger }})
hl("DiagnosticWarn", {{ fg = c.warning }})
hl("DiagnosticInfo", {{ fg = c.cyan }})
hl("DiagnosticHint", {{ fg = c.primary }})
hl("DiagnosticUnderlineError", {{ undercurl = true, sp = c.danger }})
hl("DiagnosticUnderlineWarn", {{ undercurl = true, sp = c.warning }})
hl("DiagnosticUnderlineInfo", {{ undercurl = true, sp = c.cyan }})
hl("DiagnosticUnderlineHint", {{ undercurl = true, sp = c.primary }})

-- Git Signs
hl("GitSignsAdd", {{ fg = c.success, bg = "none" }})
hl("GitSignsChange", {{ fg = c.warning, bg = "none" }})
hl("GitSignsDelete", {{ fg = c.danger, bg = "none" }})

-- Treesitter
hl("@function", {{ fg = c.primary, bold = true }})
hl("@function.call", {{ fg = c.primary }})
hl("@method", {{ fg = c.primary }})
hl("@keyword", {{ fg = c.pink, bold = true }})
hl("@keyword.function", {{ fg = c.pink, bold = true }})
hl("@keyword.return", {{ fg = c.pink, bold = true }})
hl("@string", {{ fg = c.success }})
hl("@variable", {{ fg = c.fg }})
hl("@variable.builtin", {{ fg = c.pink }})
hl("@property", {{ fg = c.cyan }})
hl("@type", {{ fg = c.cyan }})
hl("@type.builtin", {{ fg = c.cyan }})
hl("@constant", {{ fg = c.warning }})
hl("@comment", {{ fg = c.overlay, italic = true }})
hl("@punctuation", {{ fg = c.subtext }})
hl("@operator", {{ fg = c.cyan }})

-- Neo-tree / Snacks / Telescope
hl("NeoTreeNormal", {{ fg = c.fg, bg = "none" }})
hl("NeoTreeNormalNC", {{ fg = c.subtext, bg = "none" }})
hl("NeoTreeDirectoryIcon", {{ fg = c.primary }})
hl("NeoTreeDirectoryName", {{ fg = c.fg, bold = true }})
hl("NeoTreeFileName", {{ fg = c.subtext }})
hl("NeoTreeRootName", {{ fg = c.primary, bold = true }})
hl("NeoTreeGitAdded", {{ fg = c.success }})
hl("NeoTreeGitModified", {{ fg = c.warning }})
hl("NeoTreeGitDeleted", {{ fg = c.danger }})
hl("TelescopeNormal", {{ fg = c.fg, bg = "none" }})
hl("TelescopeBorder", {{ fg = c.primary, bg = "none" }})
hl("TelescopePromptNormal", {{ fg = c.fg, bg = "none" }})
hl("TelescopePromptBorder", {{ fg = c.primary, bg = "none" }})
hl("TelescopePromptTitle", {{ fg = c.bg, bg = c.primary, bold = true }})
hl("TelescopePreviewTitle", {{ fg = c.bg, bg = c.success, bold = true }})
hl("TelescopeResultsTitle", {{ fg = c.bg, bg = c.cyan, bold = true }})
hl("TelescopeSelection", {{ bg = c.bg_hover, bold = true }})
hl("SnacksNormal", {{ fg = c.fg, bg = "none" }})
hl("SnacksNormalNC", {{ fg = c.subtext, bg = "none" }})
hl("SnacksDashboardHeader", {{ fg = c.primary, bold = true }})
hl("SnacksDashboardKey", {{ fg = c.pink, bold = true }})
hl("SnacksDashboardDesc", {{ fg = c.fg }})
hl("SnacksDashboardIcon", {{ fg = c.cyan }})
"""

        lualine_theme = f"""-- Generado automáticamente por Quickshell Theme Manager
local colors = {{
  bg = "{bg}",
  bg_surface = "{bg_surface}",
  bg_hover = "{bg_hover}",
  fg = "{fg}",
  primary = "{primary}",
  success = "{success}",
  warning = "{warning}",
  danger = "{danger}",
  pink = "{pink}",
  cyan = "{cyan}",
  overlay = "{overlay}",
}}

return {{
  normal = {{
    a = {{ fg = colors.bg, bg = colors.primary, gui = "bold" }},
    b = {{ fg = colors.fg, bg = colors.bg_surface }},
    c = {{ fg = colors.overlay, bg = "none" }},
  }},
  insert = {{
    a = {{ fg = colors.bg, bg = colors.success, gui = "bold" }},
    b = {{ fg = colors.fg, bg = colors.bg_surface }},
    c = {{ fg = colors.overlay, bg = "none" }},
  }},
  visual = {{
    a = {{ fg = colors.bg, bg = colors.pink, gui = "bold" }},
    b = {{ fg = colors.fg, bg = colors.bg_surface }},
    c = {{ fg = colors.overlay, bg = "none" }},
  }},
  replace = {{
    a = {{ fg = colors.bg, bg = colors.danger, gui = "bold" }},
    b = {{ fg = colors.fg, bg = colors.bg_surface }},
    c = {{ fg = colors.overlay, bg = "none" }},
  }},
  command = {{
    a = {{ fg = colors.bg, bg = colors.warning, gui = "bold" }},
    b = {{ fg = colors.fg, bg = colors.bg_surface }},
    c = {{ fg = colors.overlay, bg = "none" }},
  }},
  inactive = {{
    a = {{ fg = colors.overlay, bg = "none", gui = "bold" }},
    b = {{ fg = colors.overlay, bg = "none" }},
    c = {{ fg = colors.overlay, bg = "none" }},
  }},
}}
"""

        nvim_targets = [
            os.path.expanduser("~/.config/nvim"),
            os.path.expanduser("~/Documentos/MrDemonc-SHELL/nvim"),
            "/usr/share/mrdemonc-shell/nvim"
        ]
        for t in nvim_targets:
            if os.path.isdir(t):
                try:
                    c_dir = os.path.join(t, "colors")
                    os.makedirs(c_dir, exist_ok=True)
                    with open(os.path.join(c_dir, "quickshell.lua"), "w", encoding="utf-8") as f:
                        f.write(nvim_colors)
                    # Limpiar nombre anterior si existe
                    old_c = os.path.join(c_dir, "mrdemonc.lua")
                    if os.path.isfile(old_c):
                        try: os.remove(old_c)
                        except Exception: pass
                    
                    ll_dir = os.path.join(t, "lua", "lualine", "themes")
                    os.makedirs(ll_dir, exist_ok=True)
                    with open(os.path.join(ll_dir, "quickshell.lua"), "w", encoding="utf-8") as f:
                        f.write(lualine_theme)
                    old_ll = os.path.join(ll_dir, "mrdemonc.lua")
                    if os.path.isfile(old_ll):
                        try: os.remove(old_ll)
                        except Exception: pass
                except Exception:
                    pass
    except Exception:
        pass

def sync_hyprland_theme(theme_data):
    try:
        primary = theme_data.get("primary", "#88c0d0").lstrip('#')
        cyan = theme_data.get("cyan", "#81a1c1").lstrip('#')
        border = theme_data.get("border", "#434c5e").lstrip('#')
        
        # 1. Actualizar ~/.config/hypr/theme_colors.lua para que Hyprland lo lea al iniciar/recargar
        hypr_dir = os.path.expanduser("~/.config/hypr")
        os.makedirs(hypr_dir, exist_ok=True)
        theme_lua = os.path.join(hypr_dir, "theme_colors.lua")
        
        lua_content = f"""-- Generado automáticamente por Quickshell Theme Manager
return {{
    active_border    = "rgba({primary}ee)",
    secondary_border = "rgba({cyan}ee)",
    inactive_border  = "rgba({border}aa)",
}}
"""
        with open(theme_lua, "w", encoding="utf-8") as f:
            f.write(lua_content)
            
        # 2. Aplicar bordes de ventana en caliente en Hyprland en tiempo real e instantáneo
        import subprocess
        lua_cmd = f'package.loaded["theme_colors"] = nil; hl.config({{ general = {{ col = {{ active_border = {{ colors = {{"rgba({primary}ee)", "rgba({cyan}ee)"}}, angle = 45 }}, inactive_border = "rgba({border}aa)" }} }} }})'
        subprocess.run(["hyprctl", "eval", lua_cmd], stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        subprocess.run(["hyprctl", "reload"], stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass



def get_nearest_gnome_accent(hex_color):
    try:
        hexstr = str(hex_color).lstrip('#')
        if len(hexstr) < 6:
            return "blue"
        r, g, b = (int(hexstr[i:i + 2], 16) for i in (0, 2, 4))
        mx, mn = max(r, g, b), min(r, g, b)
        if mx == 0 or (mx - mn) / mx < 0.20:
            return "slate"
        d = mx - mn
        if mx == r:
            hue = (60 * ((g - b) / d)) % 360
        elif mx == g:
            hue = 60 * ((b - r) / d) + 120
        else:
            hue = 60 * ((r - g) / d) + 240
        names = ["red", "orange", "yellow", "green", "teal", "blue", "purple", "pink"]
        refs = [0, 28, 52, 125, 185, 215, 275, 330]
        best, best_d = "blue", 999
        for name, ref in zip(names, refs):
            diff = abs(hue - ref)
            diff = min(diff, 360 - diff)
            if diff < best_d:
                best, best_d = name, diff
        return best
    except Exception:
        return "blue"


def sync_gtk_theme(theme_data):
    try:
        import subprocess
        is_dark = theme_data.get("isDark", True)
        mode = "dark" if is_dark else "light"
        bg = theme_data.get("bg", "#1a1d24").lstrip('#')
        bg_surface = theme_data.get("bgSurface", "#14161d").lstrip('#')
        fg = theme_data.get("text", "#eceff4").lstrip('#')
        subtext = theme_data.get("subtext", "#d8dee9").lstrip('#')
        primary = theme_data.get("primary", "#88c0d0").lstrip('#')
        danger = theme_data.get("danger", "#bf616a").lstrip('#')
        success = theme_data.get("success", "#a3be8c").lstrip('#')
        warning = theme_data.get("warning", "#ebcb8b").lstrip('#')

        color_scheme = "prefer-dark" if is_dark else "prefer-light"
        accent_enum = get_nearest_gnome_accent(primary)

        # Mapear el acento al tema de iconos oficial de Adwaita correspondiente
        accent_icons = {
            "blue": "Adwaita-Blue-Default",
            "teal": "Adwaita-Teal",
            "green": "Adwaita-Green",
            "yellow": "Adwaita-Yellow",
            "orange": "Adwaita-Orange",
            "red": "Adwaita-Red",
            "pink": "Adwaita-Pink",
            "purple": "Adwaita-Purple",
            "slate": "Adwaita-Slate",
        }
        icon_theme = accent_icons.get(accent_enum, "Adwaita-Teal")

        # 1. Configuración oficial en GSettings (Libadwaita / GTK4 / XDG Portals / Navegadores)
        for key, val in [
            ("color-scheme", color_scheme),
            ("accent-color", accent_enum),
            ("gtk-theme", "Adwaita"),
            ("icon-theme", icon_theme),
            ("cursor-theme", "capitaine-cursors"),
            ("cursor-size", "24"),
        ]:
            try:
                subprocess.run(["gsettings", "set", "org.gnome.desktop.interface", key, str(val)],
                               stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            except Exception:
                pass

        # 2. Configuración para aplicaciones GTK-3.0 y GTK-4.0 clásicas (settings.ini)
        settings_content = f"""[Settings]
gtk-application-prefer-dark-theme={1 if is_dark else 0}
gtk-theme-name=Adwaita
gtk-icon-theme-name={icon_theme}
gtk-cursor-theme-name=capitaine-cursors
gtk-cursor-theme-size=24
gtk-font-name=Sans 10
"""
        for gtk_ver in ["gtk-3.0", "gtk-4.0"]:
            d = os.path.expanduser(f"~/.config/{gtk_ver}")
            os.makedirs(d, exist_ok=True)
            with open(os.path.join(d, "settings.ini"), "w", encoding="utf-8") as f:
                f.write(settings_content)

        # 3. Paleta oficial Libadwaita / GTK4 sin sobreescrituras destructivas (Método Omarchy / Caelestia)
        # Se usan sombras transparentes rgba(0,0,0,...) para garantizar botones planos originales sin bordes blancos
        def luminance(hexstr):
            try:
                def chan(i):
                    v = int(hexstr[i:i + 2], 16) / 255
                    return v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4
                return 0.2126 * chan(0) + 0.7152 * chan(2) + 0.0722 * chan(4)
            except Exception:
                return 0.5

        accent_fg = "#ffffff" if luminance(primary) < 0.45 else f"#{bg}"
        card_bg = "rgba(255, 255, 255, 0.05)" if is_dark else "rgba(0, 0, 0, 0.04)"
        dialog_bg = f"#{bg_surface}"
        shade_alpha = 0.25 if is_dark else 0.12

        gtk4_css = f"""/* Generado automáticamente por Quickshell Theme Manager */
/* Paleta del tema adaptada a Libadwaita / GTK4 preservando el diseño original */
@define-color window_bg_color #{bg};
@define-color window_fg_color #{fg};
@define-color view_bg_color #{bg};
@define-color view_fg_color #{fg};
@define-color headerbar_bg_color #{bg};
@define-color headerbar_fg_color #{fg};
@define-color headerbar_backdrop_color #{bg_surface};
@define-color headerbar_shade_color rgba(0, 0, 0, 0.15);
@define-color headerbar_darker_shade_color rgba(0, 0, 0, 0.35);
@define-color sidebar_bg_color #{bg_surface};
@define-color sidebar_fg_color #{fg};
@define-color sidebar_backdrop_color #{bg_surface};
@define-color sidebar_shade_color rgba(0, 0, 0, 0.10);
@define-color sidebar_border_color rgba(0, 0, 0, 0.25);
@define-color secondary_sidebar_bg_color #{bg_surface};
@define-color secondary_sidebar_fg_color #{fg};
@define-color card_bg_color {card_bg};
@define-color card_fg_color #{fg};
@define-color card_shade_color rgba(0, 0, 0, 0.15);
@define-color dialog_bg_color {dialog_bg};
@define-color dialog_fg_color #{fg};
@define-color popover_bg_color {dialog_bg};
@define-color popover_fg_color #{fg};
@define-color thumbnail_bg_color {dialog_bg};
@define-color thumbnail_fg_color #{subtext};
@define-color accent_bg_color #{primary};
@define-color accent_fg_color {accent_fg};
@define-color accent_color #{primary};
@define-color destructive_bg_color #{danger};
@define-color destructive_fg_color #ffffff;
@define-color destructive_color #{danger};
@define-color success_bg_color #{success};
@define-color success_fg_color #ffffff;
@define-color success_color #{success};
@define-color warning_bg_color #{warning};
@define-color warning_fg_color #{bg};
@define-color warning_color #{warning};
@define-color error_bg_color #{danger};
@define-color error_fg_color #ffffff;
@define-color error_color #{danger};
@define-color shade_color rgba(0, 0, 0, {shade_alpha});
@define-color scrollbar_outline_color rgba(255, 255, 255, 0.10);
"""

        gtk3_css = f"""/* Generado automáticamente por Quickshell Theme Manager */
/* Compatibilidad para GTK3 */
@define-color theme_bg_color #{bg};
@define-color theme_fg_color #{fg};
@define-color theme_base_color #{bg_surface};
@define-color theme_text_color #{fg};
@define-color theme_selected_bg_color #{primary};
@define-color theme_selected_fg_color {accent_fg};
@define-color accent_bg_color #{primary};
@define-color accent_fg_color {accent_fg};
@define-color accent_color #{primary};
"""
        gtk4_dir = os.path.expanduser("~/.config/gtk-4.0")
        os.makedirs(gtk4_dir, exist_ok=True)
        with open(os.path.join(gtk4_dir, "gtk.css"), "w", encoding="utf-8") as f:
            f.write(gtk4_css)

        gtk3_dir = os.path.expanduser("~/.config/gtk-3.0")
        os.makedirs(gtk3_dir, exist_ok=True)
        with open(os.path.join(gtk3_dir, "gtk.css"), "w", encoding="utf-8") as f:
            f.write(gtk3_css)

        # Sincronizar en directorio de estado mrdemonc
        mrdemonc_theme_dir = os.path.expanduser("~/.local/state/mrdemonc/current/theme")
        os.makedirs(mrdemonc_theme_dir, exist_ok=True)
        with open(os.path.join(mrdemonc_theme_dir, "gtk-4.0.css"), "w", encoding="utf-8") as f:
            f.write(gtk4_css)
        with open(os.path.join(mrdemonc_theme_dir, "gtk-3.0.css"), "w", encoding="utf-8") as f:
            f.write(gtk3_css)
    except Exception:
        pass


def sync_limine_theme(theme_data):
    try:
        limine_candidates = ["/boot/limine.conf", "/boot/limine/limine.conf", "/boot/EFI/BOOT/limine.conf"]
        target_conf = None
        for cand in limine_candidates:
            if os.path.exists(cand):
                target_conf = cand
                break
        if not target_conf:
            return

        bg = theme_data.get("bg", "#1a1d24").lstrip('#')
        bg_surf = theme_data.get("bgSurface", "#14161d").lstrip('#')
        pri = theme_data.get("primary", "#88c0d0").lstrip('#')
        cyan = theme_data.get("cyan", "#81a1c1").lstrip('#')
        border = theme_data.get("border", "#353b49").lstrip('#')
        fg = theme_data.get("text", "#eceff4").lstrip('#')
        danger = theme_data.get("danger", "#bf616a").lstrip('#')
        succ = theme_data.get("success", "#a3be8c").lstrip('#')
        warn = theme_data.get("warning", "#ebcb8b").lstrip('#')
        pink = theme_data.get("pink", "#b48ead").lstrip('#')

        # Sincronizar wallpaper en /boot si es accesible
        wall_path = theme_data.get("wallpaperPath", "")
        if wall_path and os.path.isfile(wall_path) and os.access("/boot", os.W_OK):
            import shutil
            shutil.copyfile(wall_path, "/boot/limine-wallpaper.jpg")

        if os.access(target_conf, os.W_OK):
            with open(target_conf, "r", encoding="utf-8") as f:
                lines = f.readlines()
            new_lines = []
            for line in lines:
                if line.startswith("backdrop:"):
                    new_lines.append(f"backdrop: {bg}\n")
                elif line.startswith("interface_branding_color:"):
                    new_lines.append(f"interface_branding_color: {pri}\n")
                elif line.startswith("interface_help_color:"):
                    new_lines.append(f"interface_help_color: {cyan}\n")
                elif line.startswith("term_palette:"):
                    new_lines.append(f"term_palette: {bg};{danger};{succ};{warn};{cyan};{pink};{pri};{fg}\n")
                elif line.startswith("term_palette_bright:"):
                    new_lines.append(f"term_palette_bright: {border};{danger};{succ};{warn};{cyan};{pink};{pri};{fg}\n")
                elif line.startswith("term_background:"):
                    new_lines.append(f"term_background: b0{bg_surf}\n")
                elif line.startswith("term_foreground:"):
                    new_lines.append(f"term_foreground: {fg}\n")
                else:
                    new_lines.append(line)
            with open(target_conf, "w", encoding="utf-8") as f:
                f.writelines(new_lines)
    except Exception:
        pass

def set_theme(name):
    ensure_dirs()
    all_themes = get_all_themes()
    if name not in all_themes:
        print(f"Error: Theme '{name}' not found", file=sys.stderr)
        return False
    with open(CONFIG_FILE, 'w', encoding='utf-8') as f:
        json.dump({"theme": name}, f, indent=2)
    
    theme_obj = all_themes[name]
    theme_obj["id"] = name

    # Sincronizar automáticamente el wallpaper vinculado al tema si existe
    wall_path = theme_obj.get("wallpaperPath")
    if not wall_path or not os.path.exists(wall_path):
        for base_dir in THEME_SEARCH_DIRS:
            for ext in [".jpg", ".jpeg", ".png", ".webp"]:
                cand = os.path.join(base_dir, name, f"wallpaper{ext}")
                if os.path.exists(cand):
                    wall_path = cand
                    theme_obj["wallpaperPath"] = cand
                    break
            if wall_path and os.path.exists(wall_path):
                break

    if wall_path and os.path.exists(wall_path):
        try:
            scripts_dir = os.path.dirname(os.path.abspath(__file__))
            sys.path.insert(0, scripts_dir)
            import wallpaper_manager
            wallpaper_manager.set_wallpaper(wall_path)
        except Exception:
            pass

    # Notificar a Quickshell para recarga instantánea de tema y wallpaper
    runtime_dir = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
    trigger = os.path.join(runtime_dir, "quickshell_theme_reload.toggle")
    wp_trigger = os.path.join(runtime_dir, "quickshell_wallpaper_reload.toggle")
    try:
        with open(trigger, 'w') as f:
            f.write(name)
        with open(wp_trigger, 'w') as f:
            f.write(wall_path or name)
    except Exception:
        pass

    sync_terminal_theme(theme_obj)
    sync_nvim_theme(theme_obj)
    sync_hyprland_theme(theme_obj)
    sync_gtk_theme(theme_obj)
    sync_limine_theme(theme_obj)
    return True

def sanitize_theme_id(name):
    s = re.sub(r'[^a-zA-Z0-9_-]', '-', str(name).strip().lower())
    s = re.sub(r'-+', '-', s).strip('-')
    return s or "custom-theme"

def validate_color(col, default="#ffffff"):
    if not isinstance(col, str):
        return default
    c = col.strip()
    if not c.startswith('#'):
        c = '#' + c
    if re.match(r'^#[0-9a-fA-F]{3}$', c) or re.match(r'^#[0-9a-fA-F]{6}$', c) or re.match(r'^#[0-9a-fA-F]{8}$', c):
        return c.lower()
    return default

def install_theme(source, target_id=None, apply_after=False):
    """
    Instala un tema desde:
    - Archivo .json local
    - Carpeta local
    - Archivo comprimido .zip / .tar.gz / .tar
    - URL web (descarga directa de JSON, archivo comprimido o repositorio Git)
    """
    ensure_dirs()
    temp_dir = None

    try:
        source_str = str(source).strip()

        # 1. Si es URL remota
        if source_str.startswith("http://") or source_str.startswith("https://"):
            temp_dir = tempfile.mkdtemp(prefix="mrdemonc_theme_")
            if source_str.endswith(".git") or ("github.com" in source_str and "/raw/" not in source_str and not source_str.endswith((".json", ".zip", ".tar.gz", ".tgz"))):
                import subprocess
                subprocess.run(["git", "clone", "--depth=1", source_str, temp_dir], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                source_path = temp_dir
            else:
                filename = os.path.basename(source_str.split("?")[0]) or "downloaded_theme"
                local_file = os.path.join(temp_dir, filename)
                req = urllib.request.Request(source_str, headers={'User-Agent': 'Mozilla/5.0'})
                with urllib.request.urlopen(req) as resp, open(local_file, 'wb') as out_f:
                    out_f.write(resp.read())
                source_path = local_file
        else:
            source_path = os.path.abspath(os.path.expanduser(source_str))

        if not os.path.exists(source_path):
            return {"success": False, "error": f"La ruta o archivo '{source_path}' no existe."}

        # 2. Si es archivo comprimido (.zip o .tar.*)
        if os.path.isfile(source_path) and (source_path.endswith((".zip", ".tar.gz", ".tgz", ".tar.xz", ".tar"))):
            if not temp_dir:
                temp_dir = tempfile.mkdtemp(prefix="mrdemonc_theme_")
            extract_dir = os.path.join(temp_dir, "extracted")
            os.makedirs(extract_dir, exist_ok=True)
            
            if source_path.endswith(".zip"):
                with zipfile.ZipFile(source_path, 'r') as zf:
                    zf.extractall(extract_dir)
            else:
                with tarfile.open(source_path, 'r:*') as tf:
                    tf.extractall(extract_dir)
            source_path = extract_dir

        theme_data = None
        theme_dir_to_copy = None

        # 3. Analizar contenido
        if os.path.isdir(source_path):
            json_candidates = []
            for root, dirs, files in os.walk(source_path):
                if "theme.json" in files:
                    json_candidates.insert(0, os.path.join(root, "theme.json"))
                else:
                    for f in files:
                        if f.endswith(".json") and f not in ("package.json", "current_theme.json"):
                            json_candidates.append(os.path.join(root, f))
            if not json_candidates:
                return {"success": False, "error": f"No se encontró un archivo 'theme.json' válido en '{source_path}'."}
            
            main_json = json_candidates[0]
            with open(main_json, 'r', encoding='utf-8') as f:
                theme_data = json.load(f)
            theme_dir_to_copy = os.path.dirname(main_json)
        elif os.path.isfile(source_path) and source_path.endswith(".json"):
            with open(source_path, 'r', encoding='utf-8') as f:
                theme_data = json.load(f)
            theme_dir_to_copy = os.path.dirname(source_path)
        else:
            return {"success": False, "error": f"Formato no soportado: '{source_path}'"}

        if not isinstance(theme_data, dict):
            return {"success": False, "error": "El archivo de tema no contiene un objeto JSON válido."}

        # 4. Determinar ID y validar metadatos
        theme_id = target_id or theme_data.get("id") or theme_data.get("name") or os.path.basename(source_path).replace(".json", "")
        theme_id = sanitize_theme_id(theme_id)

        name = theme_data.get("name") or theme_id.replace("-", " ").title()
        is_dark = bool(theme_data.get("isDark", True))

        # Valores y colores normalizados con fallbacks consistentes
        normalized_theme = {
            "id": theme_id,
            "name": name,
            "description": theme_data.get("description", f"Tema {name} para MrDemonc-SHELL"),
            "author": theme_data.get("author", os.environ.get("USER", "Personalizado")),
            "isDark": is_dark,
            "wallpaper": theme_data.get("wallpaper", "wallpaper.jpg"),
            "bg": validate_color(theme_data.get("bg"), "#1a1d24" if is_dark else "#f5f7fb"),
            "bgSurface": validate_color(theme_data.get("bgSurface"), "#14161d" if is_dark else "#e9edf5"),
            "bgHover": validate_color(theme_data.get("bgHover"), "#282d38" if is_dark else "#dce2ee"),
            "border": validate_color(theme_data.get("border"), "#353b49" if is_dark else "#c9d3e3"),
            "text": validate_color(theme_data.get("text"), "#eceff4" if is_dark else "#242933"),
            "subtext": validate_color(theme_data.get("subtext"), "#d8dee9" if is_dark else "#4c566a"),
            "overlay": validate_color(theme_data.get("overlay"), "#7b889b" if is_dark else "#9aa5b8"),
            "primary": validate_color(theme_data.get("primary"), "#88c0d0"),
            "success": validate_color(theme_data.get("success"), "#a3be8c"),
            "warning": validate_color(theme_data.get("warning"), "#ebcb8b"),
            "danger": validate_color(theme_data.get("danger"), "#bf616a"),
            "cyan": validate_color(theme_data.get("cyan"), "#81a1c1"),
            "pink": validate_color(theme_data.get("pink"), "#b48ead")
        }

        # 5. Instalar en ~/.config/quickshell/themes/<theme_id>/
        dest_dir = os.path.join(THEMES_DIR, theme_id)
        os.makedirs(dest_dir, exist_ok=True)

        # Copiar wallpapers u otros recursos si existen en el origen
        if theme_dir_to_copy and os.path.isdir(theme_dir_to_copy):
            for item in os.listdir(theme_dir_to_copy):
                src_item = os.path.join(theme_dir_to_copy, item)
                dst_item = os.path.join(dest_dir, item)
                if item != "theme.json" and os.path.isfile(src_item) and item.lower().endswith((".jpg", ".jpeg", ".png", ".webp")):
                    shutil.copy2(src_item, dst_item)

        # Guardar theme.json normalizado
        target_json = os.path.join(dest_dir, "theme.json")
        with open(target_json, 'w', encoding='utf-8') as f:
            json.dump(normalized_theme, f, indent=2, ensure_ascii=False)

        # 6. Si se solicita aplicar inmediatamente
        if apply_after:
            set_theme(theme_id)

        return {
            "success": True,
            "id": theme_id,
            "name": name,
            "path": dest_dir,
            "jsonPath": target_json,
            "applied": apply_after
        }

    except Exception as e:
        return {"success": False, "error": str(e)}
    finally:
        if temp_dir and os.path.isdir(temp_dir):
            try:
                shutil.rmtree(temp_dir)
            except Exception:
                pass

def create_theme(theme_id, name=None, is_dark=True, primary_color="#88c0d0"):
    """
    Crea una plantilla estructurada de un nuevo tema en ~/.config/quickshell/themes/<theme_id>/
    """
    ensure_dirs()
    tid = sanitize_theme_id(theme_id)
    dest_dir = os.path.join(THEMES_DIR, tid)
    if os.path.exists(dest_dir):
        return {"success": False, "error": f"Ya existe un tema con el identificador '{tid}' en {dest_dir}."}

    os.makedirs(dest_dir, exist_ok=True)
    theme_name = name or tid.replace("-", " ").title()

    template = {
        "id": tid,
        "name": theme_name,
        "description": f"Tema personalizado {theme_name} para MrDemonc-SHELL",
        "author": os.environ.get("USER", "usuario"),
        "isDark": is_dark,
        "wallpaper": "wallpaper.jpg",
        "bg": "#1a1d24" if is_dark else "#f7f9fc",
        "bgSurface": "#14161d" if is_dark else "#eef2f7",
        "bgHover": "#282d38" if is_dark else "#dfe5f0",
        "border": "#353b49" if is_dark else "#d1d9e6",
        "text": "#eceff4" if is_dark else "#242933",
        "subtext": "#d8dee9" if is_dark else "#4c566a",
        "overlay": "#7b889b" if is_dark else "#9aa5b8",
        "primary": validate_color(primary_color, "#88c0d0"),
        "success": "#a3be8c",
        "warning": "#ebcb8b",
        "danger": "#bf616a",
        "cyan": "#81a1c1",
        "pink": "#b48ead"
    }

    target_json = os.path.join(dest_dir, "theme.json")
    with open(target_json, 'w', encoding='utf-8') as f:
        json.dump(template, f, indent=2, ensure_ascii=False)

    return {
        "success": True,
        "id": tid,
        "name": theme_name,
        "path": dest_dir,
        "jsonPath": target_json
    }

def export_theme(theme_id, output_path=None):
    all_themes = get_all_themes()
    if theme_id not in all_themes:
        return {"success": False, "error": f"El tema '{theme_id}' no está instalado."}
    th = all_themes[theme_id]
    th_dir = th.get("_dir")
    temp_dir = None
    if not th_dir or not os.path.isdir(th_dir):
        temp_dir = tempfile.mkdtemp()
        th_dir = os.path.join(temp_dir, theme_id)
        os.makedirs(th_dir, exist_ok=True)
        with open(os.path.join(th_dir, "theme.json"), "w", encoding="utf-8") as f:
            clean = dict(th)
            clean.pop("_dir", None)
            clean.pop("wallpaperPath", None)
            json.dump(clean, f, indent=2)

    out_file = os.path.abspath(os.path.expanduser(output_path or f"~/{theme_id}.zip"))
    with zipfile.ZipFile(out_file, 'w', zipfile.ZIP_DEFLATED) as zf:
        for root, dirs, files in os.walk(th_dir):
            for file in files:
                full = os.path.join(root, file)
                rel = os.path.relpath(full, os.path.dirname(th_dir))
                zf.write(full, rel)

    if temp_dir and os.path.isdir(temp_dir):
        try:
            shutil.rmtree(temp_dir)
        except Exception:
            pass

    return {"success": True, "output": out_file}

def remove_theme(theme_id):
    if theme_id == "default":
        return {"success": False, "error": "No se puede eliminar el tema predeterminado 'default'."}
    all_themes = get_all_themes()
    if theme_id not in all_themes:
        return {"success": False, "error": f"El tema '{theme_id}' no existe."}
    th_dir = os.path.join(THEMES_DIR, theme_id)
    if os.path.isdir(th_dir):
        shutil.rmtree(th_dir)
        if get_current_theme_name() == theme_id:
            set_theme("default")
        return {"success": True, "id": theme_id}
    return {"success": False, "error": f"El tema está en una ubicación protegida del sistema: {all_themes[theme_id].get('_dir')}"}

def print_help():
    print("""Uso: shell-theme [COMANDO] [OPCIONES]

Comandos disponibles:
  (sin argumentos)              Abre el Selector Gráfico de Temas de Quickshell
  list                          Lista todos los temas instalados en formato JSON
  set, apply <id>               Aplica un tema inmediatamente en Quickshell, Hyprland y Kitty
  install <origen> [--apply]    Instala un nuevo tema desde archivo, carpeta, .zip o URL
  create <id> [--name <nombre>] Crea una plantilla para un nuevo tema en ~/.config/quickshell/themes/
  export <id> [archivo.zip]     Empaqueta un tema en un archivo .zip para compartirlo
  remove, delete <id>           Elimina un tema instalado por el usuario
  info [id]                     Muestra los detalles y paleta de colores del tema
  help, -h, --help              Muestra esta ayuda

Ejemplos de instalación:
  shell-theme install ~/Descargas/mi-tema.json
  shell-theme install ~/Descargas/cyberpunk-theme.zip --apply
  shell-theme install https://ejemplo.com/temas/nordic.tar.gz --apply
  shell-theme create neon-sunset --name "Neon Sunset"
""")

def main():
    if len(sys.argv) > 1:
        cmd = sys.argv[1].lower()
        if cmd in ("help", "-h", "--help"):
            print_help()
            return
        elif cmd == "list":
            all_themes = get_all_themes()
            res = []
            cur = get_current_theme_name()
            for tid, val in all_themes.items():
                res.append({
                    "id": tid,
                    "name": val.get("name", tid),
                    "description": val.get("description", "Tema para Quickshell"),
                    "author": val.get("author", "Comunidad"),
                    "isDark": val.get("isDark", True),
                    "wallpaper": val.get("wallpaper", ""),
                    "wallpaperPath": val.get("wallpaperPath", ""),
                    "bg": val.get("bg", "#2e3340"),
                    "bgSurface": val.get("bgSurface", "#242833"),
                    "bgHover": val.get("bgHover", "#3b4252"),
                    "border": val.get("border", "#434c5e"),
                    "text": val.get("text", "#eceff4"),
                    "subtext": val.get("subtext", "#d8dee9"),
                    "overlay": val.get("overlay", "#7b889b"),
                    "primary": val.get("primary", "#88c0d0"),
                    "success": val.get("success", "#a3be8c"),
                    "warning": val.get("warning", "#ebcb8b"),
                    "danger": val.get("danger", "#bf616a"),
                    "cyan": val.get("cyan", "#81a1c1"),
                    "pink": val.get("pink", "#b48ead"),
                    "isCurrent": tid == cur
                })
            print(json.dumps(res))
            return
        elif cmd in ("set", "apply") and len(sys.argv) > 2:
            target = sys.argv[2]
            if set_theme(target):
                print(json.dumps(get_theme(target)))
            else:
                sys.exit(1)
            return
        elif cmd == "install" and len(sys.argv) > 2:
            src = sys.argv[2]
            apply_now = "--apply" in sys.argv
            target_id = None
            if "--name" in sys.argv:
                idx = sys.argv.index("--name")
                if idx + 1 < len(sys.argv):
                    target_id = sys.argv[idx + 1]
            res = install_theme(src, target_id=target_id, apply_after=apply_now)
            if res.get("success"):
                if "--json" in sys.argv:
                    print(json.dumps(res))
                else:
                    print(f"\033[1;32m✔ Tema '{res['name']}' [{res['id']}] instalado exitosamente en:\033[0m")
                    print(f"  {res['path']}")
                    if res.get("applied"):
                        print(f"\033[1;36m➜ Tema aplicado en vivo en todo el sistema.\033[0m")
                sys.exit(0)
            else:
                if "--json" in sys.argv:
                    print(json.dumps(res))
                else:
                    print(f"\033[1;31m✖ Error al instalar tema:\033[0m {res.get('error')}", file=sys.stderr)
                sys.exit(1)
        elif cmd == "create" and len(sys.argv) > 2:
            tid = sys.argv[2]
            is_dark = "--light" not in sys.argv
            name = None
            if "--name" in sys.argv:
                idx = sys.argv.index("--name")
                if idx + 1 < len(sys.argv):
                    name = sys.argv[idx + 1]
            res = create_theme(tid, name=name, is_dark=is_dark)
            if res.get("success"):
                if "--json" in sys.argv:
                    print(json.dumps(res))
                else:
                    print(f"\033[1;32m✔ Plantilla de tema '{res['name']}' creada en:\033[0m")
                    print(f"  {res['jsonPath']}")
                    print(f"\033[1;34mEdita el archivo para personalizar los colores y luego aplícalo con:\033[0m")
                    print(f"  shell-theme set {res['id']}")
                sys.exit(0)
            else:
                print(f"\033[1;31m✖ Error:\033[0m {res.get('error')}", file=sys.stderr)
                sys.exit(1)
        elif cmd == "export" and len(sys.argv) > 2:
            tid = sys.argv[2]
            out = sys.argv[3] if len(sys.argv) > 3 and not sys.argv[3].startswith("-") else None
            res = export_theme(tid, out)
            if res.get("success"):
                print(f"\033[1;32m✔ Tema '{tid}' exportado exitosamente a:\033[0m {res['output']}")
                sys.exit(0)
            else:
                print(f"\033[1;31m✖ Error al exportar:\033[0m {res.get('error')}", file=sys.stderr)
                sys.exit(1)
        elif cmd in ("remove", "delete") and len(sys.argv) > 2:
            tid = sys.argv[2]
            res = remove_theme(tid)
            if res.get("success"):
                print(f"\033[1;32m✔ Tema '{tid}' eliminado correctamente.\033[0m")
                sys.exit(0)
            else:
                print(f"\033[1;31m✖ Error:\033[0m {res.get('error')}", file=sys.stderr)
                sys.exit(1)
        elif cmd == "info":
            tid = sys.argv[2] if len(sys.argv) > 2 else get_current_theme_name()
            th = get_theme(tid)
            print(json.dumps(th, indent=2))
            return

    current_th = get_theme()
    print(json.dumps(current_th))

if __name__ == '__main__':
    main()
