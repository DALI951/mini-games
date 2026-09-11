#!/usr/bin/env python3
"""Generates Android launcher icons for MiniGames.

Dark cinema background with a 2x2 rounded-tile motif: one red accent tile,
three muted gray tiles. Pure Pillow, no external fonts.

Run:  python dev/make_icons.py   (from anywhere; paths are repo-relative)
"""
import os
from PIL import Image, ImageDraw

BASE = 512
BG = (11, 13, 16, 255)
RED = (220, 38, 38, 255)
GRAY_A = (35, 38, 47, 255)
GRAY_B = (42, 46, 55, 255)

SIZES = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def draw_base() -> Image.Image:
    img = Image.new("RGBA", (BASE, BASE), BG)
    d = ImageDraw.Draw(img)

    tile = 210
    gap = 44
    x0 = (BASE - tile * 2 - gap) // 2
    y0 = x0
    radius = 42

    colors = [RED, GRAY_A, GRAY_A, GRAY_B]
    for i, color in enumerate(colors):
        col = i % 2
        row = i // 2
        x = x0 + col * (tile + gap)
        y = y0 + row * (tile + gap)
        d.rounded_rectangle(
            [x, y, x + tile, y + tile],
            radius=radius,
            fill=color,
        )
    return img


def main() -> None:
    base = draw_base()
    res_dir = os.path.join(REPO_ROOT, "android", "app", "src", "main", "res")
    for density, size in SIZES.items():
        folder = os.path.join(res_dir, f"mipmap-{density}")
        os.makedirs(folder, exist_ok=True)
        icon = base.resize((size, size), Image.LANCZOS).convert("RGB")
        icon.save(os.path.join(folder, "ic_launcher.png"))
        icon.save(os.path.join(folder, "ic_launcher_round.png"))
        print(f"wrote {density} ({size}x{size})")


if __name__ == "__main__":
    main()