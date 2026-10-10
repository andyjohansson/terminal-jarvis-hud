#!/usr/bin/env python3
"""Build "Jarvis HUD.terminal" for macOS Terminal from the palette below.

Terminal stores colors and fonts as NSKeyedArchiver blobs. This script writes
them with plistlib only, so it runs anywhere (no macOS or PyObjC needed).

Usage:  python3 tools/build_profile.py   ->  writes "Jarvis HUD.terminal"
"""
import plistlib
from pathlib import Path

PROFILE_NAME = "Jarvis HUD"

# (hex, alpha)
PALETTE = {
    "BackgroundColor":      ("#05090f", 0.96),
    "TextColor":            ("#d4f3ff", 1.0),
    "TextBoldColor":        ("#e9fbff", 1.0),
    "CursorColor":          ("#00d8ff", 1.0),
    "SelectionColor":       ("#0e4a5e", 1.0),
    "ANSIBlackColor":       ("#0a1620", 1.0),
    "ANSIRedColor":         ("#ff4d5e", 1.0),
    "ANSIGreenColor":       ("#3dffb8", 1.0),
    "ANSIYellowColor":      ("#ffb347", 1.0),
    "ANSIBlueColor":        ("#3d8bff", 1.0),
    "ANSIMagentaColor":     ("#b48cff", 1.0),
    "ANSICyanColor":        ("#00d8ff", 1.0),
    "ANSIWhiteColor":       ("#a9c7d6", 1.0),
    "ANSIBrightBlackColor": ("#4e7082", 1.0),
    "ANSIBrightRedColor":   ("#ff7a86", 1.0),
    "ANSIBrightGreenColor": ("#7dffd0", 1.0),
    "ANSIBrightYellowColor": ("#ffd08a", 1.0),
    "ANSIBrightBlueColor":  ("#7db0ff", 1.0),
    "ANSIBrightMagentaColor": ("#d2b8ff", 1.0),
    "ANSIBrightCyanColor":  ("#7deeff", 1.0),
    "ANSIBrightWhiteColor": ("#ffffff", 1.0),
}

FONT_NAME = "SFMono-Regular"
FONT_SIZE = 13.0


def archive(obj_dict, classname, classes):
    """Wrap one object in an NSKeyedArchiver binary plist."""
    root = dict(obj_dict)
    root["$class"] = plistlib.UID(2)
    data = {
        "$archiver": "NSKeyedArchiver",
        "$version": 100000,
        "$top": {"root": plistlib.UID(1)},
        "$objects": ["$null", root, {"$classname": classname, "$classes": classes}],
    }
    return plistlib.dumps(data, fmt=plistlib.FMT_BINARY)


def color(hex_value, alpha=1.0):
    h = hex_value.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
    rgb = f"{r:.6f} {g:.6f} {b:.6f}"
    if alpha < 1.0:
        rgb += f" {alpha:.6f}"
    # NSColorSpace 2 = device RGB, close to sRGB on modern Macs
    return archive({"NSColorSpace": 2, "NSRGB": rgb.encode() + b"\x00"},
                   "NSColor", ["NSColor", "NSObject"])


def font(name, size):
    root = {"NSName": plistlib.UID(3), "NSSize": size, "NSfFlags": 16}
    root["$class"] = plistlib.UID(2)
    data = {
        "$archiver": "NSKeyedArchiver",
        "$version": 100000,
        "$top": {"root": plistlib.UID(1)},
        "$objects": ["$null", root,
                     {"$classname": "NSFont", "$classes": ["NSFont", "NSObject"]},
                     name],
    }
    return plistlib.dumps(data, fmt=plistlib.FMT_BINARY)


def build():
    profile = {
        "name": PROFILE_NAME,
        "type": "Window Settings",
        "ProfileCurrentVersion": 2.07,
        "Font": font(FONT_NAME, FONT_SIZE),
        "FontAntialias": True,
        "FontWidthSpacing": 1.0,
        "FontHeightSpacing": 1.1,
        "UseBoldFonts": True,
        "UseBrightBold": True,
        "CursorType": 0,          # 0 block, 1 underline, 2 bar
        "CursorBlink": True,
        "BackgroundBlur": 0.35,
        "columnCount": 110,
        "rowCount": 32,
        "ShowWindowSettingsNameInTitle": False,
        "shellExitAction": 1,     # close if the shell exited cleanly
    }
    for key, (hex_value, alpha) in PALETTE.items():
        profile[key] = color(hex_value, alpha)

    out = Path(__file__).resolve().parent.parent / f"{PROFILE_NAME}.terminal"
    out.write_bytes(plistlib.dumps(profile, fmt=plistlib.FMT_XML))
    print(f"wrote {out}")


if __name__ == "__main__":
    build()
