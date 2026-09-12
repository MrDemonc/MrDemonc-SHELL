pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool isOpen: false
    property string hexColor: "#3B82F6"
    property string rgbColor: "rgb(59, 130, 246)"
    property string hslColor: "hsl(217, 91%, 60%)"
    property string hsvColor: "hsv(217, 76%, 96%)"
    property string cmykColor: "cmyk(76%, 47%, 0%, 4%)"

    property var actionProc: Process {
        running: false
    }

    function hexToRgb(hex) {
        let clean = hex.replace("#", "").trim();
        if (clean.length === 3) {
            clean = clean.split("").map(c => c + c).join("");
        }
        let num = parseInt(clean, 16);
        if (isNaN(num)) return { r: 0, g: 0, b: 0 };
        return {
            r: (num >> 16) & 255,
            g: (num >> 8) & 255,
            b: num & 255
        };
    }

    function rgbToHsl(r, g, b) {
        r /= 255; g /= 255; b /= 255;
        let max = Math.max(r, g, b), min = Math.min(r, g, b);
        let h = 0, s = 0, l = (max + min) / 2;
        if (max !== min) {
            let d = max - min;
            s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
            switch (max) {
                case r: h = (g - b) / d + (g < b ? 6 : 0); break;
                case g: h = (b - r) / d + 2; break;
                case b: h = (r - g) / d + 4; break;
            }
            h /= 6;
        }
        return {
            h: Math.round(h * 360),
            s: Math.round(s * 100),
            l: Math.round(l * 100)
        };
    }

    function rgbToHsv(r, g, b) {
        r /= 255; g /= 255; b /= 255;
        let max = Math.max(r, g, b), min = Math.min(r, g, b);
        let d = max - min;
        let h = 0;
        let s = max === 0 ? 0 : d / max;
        let v = max;
        if (max !== min) {
            switch (max) {
                case r: h = (g - b) / d + (g < b ? 6 : 0); break;
                case g: h = (b - r) / d + 2; break;
                case b: h = (r - g) / d + 4; break;
            }
            h /= 6;
        }
        return {
            h: Math.round(h * 360),
            s: Math.round(s * 100),
            v: Math.round(v * 100)
        };
    }

    function rgbToCmyk(r, g, b) {
        let c = 1 - (r / 255);
        let m = 1 - (g / 255);
        let y = 1 - (b / 255);
        let k = Math.min(c, Math.min(m, y));
        if (k === 1) return { c: 0, m: 0, y: 0, k: 100 };
        return {
            c: Math.round(((c - k) / (1 - k)) * 100),
            m: Math.round(((m - k) / (1 - k)) * 100),
            y: Math.round(((y - k) / (1 - k)) * 100),
            k: Math.round(k * 100)
        };
    }

    function setColor(hex) {
        if (!hex) return;
        let h = hex.trim().toUpperCase();
        if (!h.startsWith("#")) h = "#" + h;
        hexColor = h;

        let rgb = hexToRgb(h);
        rgbColor = `rgb(${rgb.r}, ${rgb.g}, ${rgb.b})`;

        let hsl = rgbToHsl(rgb.r, rgb.g, rgb.b);
        hslColor = `hsl(${hsl.h}, ${hsl.s}%, ${hsl.l}%)`;

        let hsv = rgbToHsv(rgb.r, rgb.g, rgb.b);
        hsvColor = `hsv(${hsv.h}, ${hsv.s}%, ${hsv.v}%)`;

        let cmyk = rgbToCmyk(rgb.r, rgb.g, rgb.b);
        cmykColor = `cmyk(${cmyk.c}%, ${cmyk.m}%, ${cmyk.y}%, ${cmyk.k}%)`;
    }

    function openWithColor(hex) {
        console.log("COLOR PICKER openWithColor called with: " + hex);
        setColor(hex);
        isOpen = true;
        console.log("COLOR PICKER isOpen is now: " + isOpen);
    }

    function launchPicker() {
        isOpen = false;
        actionProc.command = ["sh", "-c", '"$HOME/.local/bin/shell-colorpicker" &'];
        actionProc.running = false;
        actionProc.running = true;
    }

    function copyToClipboard(text) {
        let cmd = "wl-copy " + JSON.stringify(text);
        actionProc.command = ["sh", "-c", cmd];
        actionProc.running = false;
        actionProc.running = true;
    }

    property var watchPickerProc: Process {
        command: ["sh", "-c", "DATA=\"${XDG_RUNTIME_DIR:-/tmp}/quickshell_colorpicker.data\"; while true; do if [ -f \"$DATA\" ]; then VAL=$(cat \"$DATA\"); rm -f \"$DATA\"; echo \"$VAL\"; fi; sleep 0.15; done"]
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                let col = String(data).trim();
                if (col.length >= 4 && (col.startsWith("#") || col.match(/^[0-9A-Fa-f]{6}/))) {
                    root.openWithColor(col);
                }
            }
        }
    }
}
