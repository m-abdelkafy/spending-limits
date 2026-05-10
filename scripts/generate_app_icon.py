#!/usr/bin/env python3
"""Generate the iOS app icon set for ExpenseTracker.

iOS 18 / Xcode 16 supports a single 1024x1024 PNG per appearance
(light, dark, tinted) — Xcode renders all derived sizes at build time.

Design: full-bleed gradient with a stylized white bar chart and a
horizontal baseline. Tinted/Dark variants drop the background so iOS
can render its own backdrop and accent tint.

Run from repo root: python3 scripts/generate_app_icon.py
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

REPO = Path(__file__).resolve().parent.parent
ICONSET = REPO / "ExpenseTracker" / "Assets.xcassets" / "AppIcon.appiconset"

SIZE = 1024

ACCENT_TOP = (79, 142, 247)     # #4F8EF7 — accent
ACCENT_BOTTOM = (26, 188, 156)  # #1ABC9C — Health/seafoam green
WHITE = (255, 255, 255)


def vertical_gradient(size: int, top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    img = Image.new("RGB", (size, size), top)
    pixels = img.load()
    for y in range(size):
        t = y / (size - 1)
        r = round(top[0] * (1 - t) + bottom[0] * t)
        g = round(top[1] * (1 - t) + bottom[1] * t)
        b = round(top[2] * (1 - t) + bottom[2] * t)
        for x in range(size):
            pixels[x, y] = (r, g, b)
    return img


def draw_chart(canvas: Image.Image, fill) -> None:
    """Draw three bars + baseline on the given canvas. Works for RGBA or L."""
    draw = ImageDraw.Draw(canvas)
    cx = SIZE // 2

    # Three bars of increasing height
    bar_widths = 130
    spacing = 60
    # Bars heights
    heights = [340, 480, 620]
    # Baseline at y = 760
    baseline_y = 760
    radius = 30

    total_width = bar_widths * 3 + spacing * 2
    start_x = cx - total_width // 2

    for i, h in enumerate(heights):
        x0 = start_x + i * (bar_widths + spacing)
        y0 = baseline_y - h
        x1 = x0 + bar_widths
        y1 = baseline_y
        draw.rounded_rectangle((x0, y0, x1, y1), radius=radius, fill=fill)

    # Baseline
    bl_thickness = 28
    bl_left = start_x - 60
    bl_right = start_x + total_width + 60
    draw.rounded_rectangle(
        (bl_left, baseline_y, bl_right, baseline_y + bl_thickness),
        radius=bl_thickness // 2,
        fill=fill,
    )

    # Up-arrow on the tallest bar (rightmost) suggesting "tracked"
    tip_x = start_x + 2 * (bar_widths + spacing) + bar_widths // 2
    tip_y = baseline_y - heights[2] - 90
    arrow_w = 90
    arrow_h = 90
    draw.polygon(
        [
            (tip_x, tip_y),
            (tip_x - arrow_w, tip_y + arrow_h),
            (tip_x - arrow_w // 2, tip_y + arrow_h),
            (tip_x - arrow_w // 2, tip_y + arrow_h + 80),
            (tip_x + arrow_w // 2, tip_y + arrow_h + 80),
            (tip_x + arrow_w // 2, tip_y + arrow_h),
            (tip_x + arrow_w, tip_y + arrow_h),
        ],
        fill=fill,
    )


def make_light() -> Image.Image:
    bg = vertical_gradient(SIZE, ACCENT_TOP, ACCENT_BOTTOM)
    img = bg.convert("RGBA")
    draw_chart(img, fill=WHITE + (255,))
    return img.convert("RGB")


def make_dark() -> Image.Image:
    # Transparent background; iOS provides the dark backdrop.
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    grad = vertical_gradient(SIZE, ACCENT_TOP, ACCENT_BOTTOM).convert("RGBA")
    mask = Image.new("L", (SIZE, SIZE), 0)
    draw_chart(mask, fill=255)
    img.paste(grad, (0, 0), mask)
    return img


def make_tinted() -> Image.Image:
    # Transparent background; iOS applies the user's tint to luminance.
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw_chart(img, fill=WHITE + (255,))
    return img


def main() -> None:
    ICONSET.mkdir(parents=True, exist_ok=True)

    light_path = ICONSET / "AppIcon.png"
    dark_path = ICONSET / "AppIcon-Dark.png"
    tinted_path = ICONSET / "AppIcon-Tinted.png"

    make_light().save(light_path, format="PNG", optimize=True)
    make_dark().save(dark_path, format="PNG", optimize=True)
    make_tinted().save(tinted_path, format="PNG", optimize=True)

    contents = """{
  "images" : [
    {
      "filename" : "AppIcon.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "filename" : "AppIcon-Dark.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "tinted"
        }
      ],
      "filename" : "AppIcon-Tinted.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""
    (ICONSET / "Contents.json").write_text(contents)

    for p in (light_path, dark_path, tinted_path):
        print(f"Wrote {p.relative_to(REPO)} ({p.stat().st_size:,} bytes)")


if __name__ == "__main__":
    main()
