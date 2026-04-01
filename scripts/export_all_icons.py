#!/usr/bin/env python3
"""Export 1024px master icon to all required platform sizes using Pillow."""

from PIL import Image
import os

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MASTER = os.path.join(BASE, "logo_concepts", "export", "icon_1024.png")

def resize_and_save(src_img, size, dest_path):
    resized = src_img.resize((size, size), Image.LANCZOS)
    # Convert to RGB (no alpha) for app icons
    rgb = Image.new("RGB", resized.size, (0, 0, 0))
    rgb.paste(resized, mask=resized.split()[3] if resized.mode == "RGBA" else None)
    rgb.save(dest_path, "PNG")
    print(f"  {size}x{size} -> {os.path.relpath(dest_path, BASE)}")

img = Image.open(MASTER)

# --- iOS icons ---
print("iOS icons:")
ios_dir = os.path.join(BASE, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
ios_sizes = {
    "Icon-App-20x20@1x.png": 20,
    "Icon-App-20x20@2x.png": 40,
    "Icon-App-20x20@3x.png": 60,
    "Icon-App-29x29@1x.png": 29,
    "Icon-App-29x29@2x.png": 58,
    "Icon-App-29x29@3x.png": 87,
    "Icon-App-40x40@1x.png": 40,
    "Icon-App-40x40@2x.png": 80,
    "Icon-App-40x40@3x.png": 120,
    "Icon-App-60x60@2x.png": 120,
    "Icon-App-60x60@3x.png": 180,
    "Icon-App-76x76@1x.png": 76,
    "Icon-App-76x76@2x.png": 152,
    "Icon-App-83.5x83.5@2x.png": 167,
    "Icon-App-1024x1024@1x.png": 1024,
}
for fname, size in ios_sizes.items():
    resize_and_save(img, size, os.path.join(ios_dir, fname))

# --- macOS icons ---
print("\nmacOS icons:")
mac_dir = os.path.join(BASE, "macos", "Runner", "Assets.xcassets", "AppIcon.appiconset")
mac_sizes = {
    "app_icon_16.png": 16,
    "app_icon_32.png": 32,
    "app_icon_64.png": 64,
    "app_icon_128.png": 128,
    "app_icon_256.png": 256,
    "app_icon_512.png": 512,
    "app_icon_1024.png": 1024,
}
for fname, size in mac_sizes.items():
    resize_and_save(img, size, os.path.join(mac_dir, fname))

# --- Android icons ---
print("\nAndroid icons:")
android_base = os.path.join(BASE, "android", "app", "src", "main", "res")
android_sizes = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}
for folder, size in android_sizes.items():
    dest = os.path.join(android_base, folder, "ic_launcher.png")
    if os.path.exists(os.path.dirname(dest)):
        resize_and_save(img, size, dest)

# --- watchOS icon ---
print("\nwatchOS icon:")
watch_dir = os.path.join(BASE, "ios", "ChordBookWatch", "ChordBookWatch", "Assets.xcassets", "AppIcon.appiconset")
if os.path.exists(watch_dir):
    resize_and_save(img, 1024, os.path.join(watch_dir, "AppIcon.png"))

# --- Web icons ---
print("\nWeb icons:")
web_dir = os.path.join(BASE, "web")
web_icons = {
    "icons/Icon-192.png": 192,
    "icons/Icon-512.png": 512,
    "icons/Icon-maskable-192.png": 192,
    "icons/Icon-maskable-512.png": 512,
    "favicon.png": 32,
}
for fname, size in web_icons.items():
    resize_and_save(img, size, os.path.join(web_dir, fname))

print("\nDone! All icons exported.")
