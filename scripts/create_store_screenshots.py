#!/usr/bin/env python3
"""
Create App Store marketing screenshots with vibrant per-screen gradients.
Uses Avenir Next font, iPhone-style rounded corners, and unique color themes.
Usage: python3 scripts/create_store_screenshots.py
"""

from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os

# --- Config ---
STORE_WIDTH = 1242
STORE_HEIGHT = 2688
CORNER_RADIUS = 110
SCREENSHOT_MARGIN_X = 90
SCREENSHOT_TOP = 580
SHADOW_OFFSET = 25
SHADOW_BLUR = 50
BEZEL_WIDTH = 3

# Each screen has its own gradient palette and text
# Format: (filename, line1, line2, [top_color, mid_color, bottom_color], bezel_rgba)
SCREENS = [
    (
        "screen_1.png",
        "Find Chords",
        "For Any Song",
        [(45, 100, 220), (30, 60, 180), (15, 30, 120)],
        (80, 120, 255, 140),
    ),
    (
        "screen_2.png",
        "Chords & Diagrams",
        "Right On Screen",
        [(140, 50, 180), (100, 30, 150), (60, 15, 100)],
        (180, 80, 220, 140),
    ),
    (
        "screen_3.png",
        "Tune Your Guitar",
        "With Precision",
        [(20, 140, 120), (15, 100, 90), (8, 60, 55)],
        (60, 200, 170, 140),
    ),
    (
        "screen_4.png",
        "Built-in",
        "Metronome",
        [(200, 80, 50), (160, 55, 35), (100, 30, 20)],
        (240, 120, 80, 140),
    ),
    (
        "screen_5.png",
        "Customize",
        "Your Experience",
        [(50, 50, 70), (35, 35, 55), (20, 20, 35)],
        (120, 120, 150, 140),
    ),
    (
        "screen_6.png",
        "Search Songs",
        "In One Tap",
        [(30, 80, 160), (50, 130, 190), (20, 60, 130)],
        (70, 150, 220, 140),
    ),
]

RAW_DIR = os.path.join(os.path.dirname(__file__), "..", "screenshots", "raw")
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "screenshots", "store")
AVENIR_NEXT = "/System/Library/Fonts/Supplemental/Avenir Next.ttc"


def lerp(c1, c2, t):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))


def make_gradient(w, h, colors):
    img = Image.new("RGB", (w, h))
    draw = ImageDraw.Draw(img)
    segs = len(colors) - 1
    seg_h = h / segs
    for y in range(h):
        s = min(int(y / seg_h), segs - 1)
        t = (y - s * seg_h) / seg_h
        draw.line([(0, y), (w, y)], fill=lerp(colors[s], colors[s + 1], t))
    return img


def round_corners(img, r):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([(0, 0), img.size], radius=r, fill=255)
    result = img.copy()
    result.putalpha(mask)
    return result


def make_shadow(size, r, blur, offset):
    pad = blur * 4
    shadow = Image.new("RGBA", (size[0] + pad, size[1] + pad), (0, 0, 0, 0))
    d = ImageDraw.Draw(shadow)
    x0, y0 = pad // 2, pad // 2 + offset
    d.rounded_rectangle([(x0, y0), (x0 + size[0], y0 + size[1])], radius=r, fill=(0, 0, 0, 130))
    return shadow.filter(ImageFilter.GaussianBlur(blur))


def get_font(size, weight="bold"):
    idx = {"heavy": 8, "bold": 0, "demibold": 2, "medium": 5, "regular": 7}.get(weight, 0)
    try:
        return ImageFont.truetype(AVENIR_NEXT, size, index=idx)
    except Exception:
        try:
            return ImageFont.truetype("/System/Library/Fonts/SFNS.ttf", size)
        except Exception:
            return ImageFont.load_default()


def draw_centered(draw, y, text, font, fill, w):
    bbox = draw.textbbox((0, 0), text, font=font)
    draw.text(((w - bbox[2] + bbox[0]) // 2, y), text, fill=fill, font=font)


def create_screenshot(raw_path, output_path, line1, line2, gradient_colors, bezel_color):
    bg = make_gradient(STORE_WIDTH, STORE_HEIGHT, gradient_colors).convert("RGBA")

    # Load, scale, round corners
    shot = Image.open(raw_path).convert("RGBA")
    tw = STORE_WIDTH - SCREENSHOT_MARGIN_X * 2
    th = int(shot.height * (tw / shot.width))
    shot = shot.resize((tw, th), Image.LANCZOS)
    shot = round_corners(shot, CORNER_RADIUS)

    # Shadow
    shadow = make_shadow((tw, th), CORNER_RADIUS, SHADOW_BLUR, SHADOW_OFFSET)
    bg.paste(shadow, (SCREENSHOT_MARGIN_X - SHADOW_BLUR * 2, SCREENSHOT_TOP - SHADOW_BLUR * 2), shadow)

    # Screenshot
    bg.paste(shot, (SCREENSHOT_MARGIN_X, SCREENSHOT_TOP), shot)

    # Bezel outline
    draw = ImageDraw.Draw(bg)
    bw = BEZEL_WIDTH
    draw.rounded_rectangle(
        [(SCREENSHOT_MARGIN_X - bw, SCREENSHOT_TOP - bw),
         (SCREENSHOT_MARGIN_X + tw + bw, SCREENSHOT_TOP + th + bw)],
        radius=CORNER_RADIUS + bw,
        outline=bezel_color,
        width=bw,
    )

    # Text
    draw_centered(draw, 150, line1, get_font(100, "heavy"), (255, 255, 255), STORE_WIDTH)
    draw_centered(draw, 280, line2, get_font(64, "medium"), (255, 255, 255, 200), STORE_WIDTH)

    bg.convert("RGB").save(output_path, "PNG", quality=95)
    print(f"  Created: {output_path}")


def main():
    os.makedirs(OUT_DIR, exist_ok=True)

    missing = [f for f, *_ in SCREENS if not os.path.exists(os.path.join(RAW_DIR, f))]
    if missing:
        print(f"Missing: {', '.join(missing)}")
        return

    print("Creating App Store screenshots...")
    for i, (fname, l1, l2, colors, bezel) in enumerate(SCREENS, 1):
        create_screenshot(
            os.path.join(RAW_DIR, fname),
            os.path.join(OUT_DIR, f"store_{i}.png"),
            l1, l2, colors, bezel,
        )
    print(f"\nDone! {len(SCREENS)} screenshots saved to {OUT_DIR}")


if __name__ == "__main__":
    main()
