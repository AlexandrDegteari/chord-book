#!/usr/bin/env python3
"""Generate Sixstrings app icon at 1024x1024 using Pillow."""

from PIL import Image, ImageDraw
import os

SIZE = 1024
CENTER = SIZE // 2
img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# --- Colors ---
BG_TOP = (22, 33, 62)       # deep navy
BG_BOT = (12, 20, 45)
RING = (255, 140, 66)       # warm orange
GOLD = (255, 210, 128)
ORANGE = (255, 160, 60)
HOLE = (8, 14, 36)
STRING_COLOR = (255, 185, 90)

# --- Background gradient ---
for y in range(SIZE):
    t = y / SIZE
    r = int(BG_TOP[0] + (BG_BOT[0] - BG_TOP[0]) * t)
    g = int(BG_TOP[1] + (BG_BOT[1] - BG_TOP[1]) * t)
    b = int(BG_TOP[2] + (BG_BOT[2] - BG_TOP[2]) * t)
    draw.line([(0, y), (SIZE, y)], fill=(r, g, b))

def draw_ring(cx, cy, radius, color, width):
    bbox = [cx - radius, cy - radius, cx + radius, cy + radius]
    draw.ellipse(bbox, outline=color, width=width)

def draw_filled_circle(cx, cy, radius, color):
    bbox = [cx - radius, cy - radius, cx + radius, cy + radius]
    draw.ellipse(bbox, fill=color)

# --- Rosette rings ---
draw_ring(CENTER, CENTER, 400, (*RING, 70), 5)      # outermost thin
draw_ring(CENTER, CENTER, 360, RING, 30)              # main thick ring
draw_ring(CENTER, CENTER, 312, (*RING, 80), 6)        # inner thin

# --- Sound hole ---
draw_filled_circle(CENTER, CENTER, 290, HOLE)

# --- 6 Strings (evenly spaced) ---
# 6 strings centered, spanning ~260px total width
string_spacing = 56
first_string_x = CENTER - int(2.5 * string_spacing)  # 6 strings: -2.5, -1.5, -0.5, 0.5, 1.5, 2.5
string_positions = [first_string_x + i * string_spacing for i in range(6)]
# Widths: thicker bass strings (left), thinner treble (right)
string_widths = [8, 7, 6, 5, 5, 4]
string_alphas = [170, 170, 175, 175, 165, 160]

for sx, sw, sa in zip(string_positions, string_widths, string_alphas):
    for dy in range(SIZE):
        dist_from_center = abs(dy - CENTER)
        if dist_from_center > 460:
            continue
        alpha = sa
        if dist_from_center > 400:
            alpha = int(sa * (460 - dist_from_center) / 60)
        draw.line([(sx - sw // 2, dy), (sx + sw // 2, dy)], fill=(*STRING_COLOR, alpha))

# --- Nut (top fret bar) ---
nut_y = 310
nut_left = string_positions[0] - 20
nut_right = string_positions[5] + 20
draw.rectangle([nut_left, nut_y, nut_right, nut_y + 16], fill=(*GOLD, 230))

# --- Fret lines ---
fret_ys = [410, 510, 610]
for fy in fret_ys:
    draw.rectangle([nut_left, fy, nut_right, fy + 4], fill=(*RING, 65))

# --- Am chord: X 0 2 2 1 0 ---
# String indices: 0=E(low), 1=A, 2=D, 3=G, 4=B, 5=e(high)
DOT_R = 26

# Fret 1 center y: between nut(310) and fret1(410) -> 360
# Fret 2 center y: between fret1(410) and fret2(510) -> 460

# String 4 (B, index 4), fret 1
draw_filled_circle(string_positions[4], 360, DOT_R, ORANGE)

# String 3 (G, index 3), fret 2
draw_filled_circle(string_positions[3], 460, DOT_R, ORANGE)

# String 2 (D, index 2), fret 2
draw_filled_circle(string_positions[2], 460, DOT_R, ORANGE)

# --- Open string markers above nut ---
OPEN_R = 22
marker_y = 268

# String 1 (A, index 1) - open
draw_ring(string_positions[1], marker_y, OPEN_R, GOLD, 8)

# String 5 (e high, index 5) - open
draw_ring(string_positions[5], marker_y, OPEN_R, GOLD, 8)

# --- Muted string 0 (E low) - X mark (shifted left to avoid overlap with O) ---
x_cx = string_positions[0]
x_cy = marker_y - 5
x_sz = 18
draw.line([(x_cx - x_sz, x_cy - x_sz), (x_cx + x_sz, x_cy + x_sz)], fill=GOLD, width=8)
draw.line([(x_cx + x_sz, x_cy - x_sz), (x_cx - x_sz, x_cy + x_sz)], fill=GOLD, width=8)

# --- Bridge line ---
draw.rectangle([nut_left, 695, nut_right, 705], fill=(*RING, 120))

# --- Save ---
out_dir = os.path.join(os.path.dirname(__file__), "..", "logo_concepts", "export")
os.makedirs(out_dir, exist_ok=True)
out_path = os.path.join(out_dir, "icon_1024.png")
img.save(out_path, "PNG")
print(f"Saved {out_path}")

assets_path = os.path.join(os.path.dirname(__file__), "..", "assets", "images", "logo.png")
img.save(assets_path, "PNG")
print(f"Saved {assets_path}")
