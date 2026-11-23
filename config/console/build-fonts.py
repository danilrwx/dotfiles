#!/usr/bin/env python3
"""Build the checked-in console fonts from Iosevka-Medium.ttf using Pillow."""

import argparse
import gzip
import struct
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


OUTPUT = Path(__file__).resolve().parent
WSFONT_LIMIT = 512 * 1024
ASCII = "".join(map(chr, range(0x20, 0x7F)))
CYRILLIC = "Ё" + "".join(map(chr, range(0x410, 0x450))) + "ё"
BOXES = "─│┌┐└┘├┤┬┴┼━┃┏┓┗┛┣┫┳┻╋═║╔╗╚╝╠╣╦╩╬╭╮╯╰╱╲╳"
DOUBLE_BOXES = dict(zip("═║╔╗╚╝╠╣╦╩╬", ("EW", "NS", "ES", "SW", "NE", "NW",
                                           "NES", "NSW", "ESW", "NEW", "NESW")))
BLOCKS = "▀▄█▌▐░▒▓"
SYMBOLS = " ©«»°±·×÷–—‘’“”•…←↑→↓↔✓✗"


def double_box(draw, width, height, arms):
    # Draw on exact pixels so the two strokes stay distinct after rasterizing.
    left, right = width // 2 - 2, width // 2 + 1
    top, bottom = height // 2 - 2, height // 2 + 1
    for horizontal, edge_x, near_x, far_x in (("W", 0, left, right),
                                             ("E", width - 1, right, left)):
        for vertical, edge_y, near_y, far_y in (("N", 0, top, bottom),
                                               ("S", height - 1, bottom, top)):
            if horizontal in arms and vertical in arms:
                draw.line((edge_x, near_y, near_x, near_y, near_x, edge_y), fill=1)
                if len(arms) == 2:
                    draw.line((edge_x, far_y, far_x, far_y, far_x, edge_y), fill=1)
    if arms == "EW":
        for y in (top, bottom):
            draw.line((0, y, width - 1, y), fill=1)
    elif "E" in arms and "W" in arms and len(arms) == 3:
        y = bottom if "N" in arms else top
        draw.line((0, y, width - 1, y), fill=1)
    if arms == "NS":
        for x in (left, right):
            draw.line((x, 0, x, height - 1), fill=1)
    elif "N" in arms and "S" in arms and len(arms) == 3:
        x = left if "E" in arms else right
        draw.line((x, 0, x, height - 1), fill=1)


def glyphs(source, width, height, characters):
    text_size = {24: 21, 32: 28}.get(height, round(height * 0.8))
    text = ImageFont.truetype(source, text_size)
    graphics = ImageFont.truetype(source, width * 8)
    baseline = height - round(height * 0.22)
    # The full block defines the same cell boundaries for every graphics glyph.
    block, (left, top) = graphics.getmask2("█", mode="1", anchor="ls")
    x0, y0, x1, y1 = block.getbbox()
    graphics_cell = (x1 - x0, y1 - y0)
    graphics_origin = (-left - x0, -top - y0)
    missing = bytes(text.getmask("\U0010ffff", mode="1"))
    for char in characters:
        if char in "░▒▓":
            image = Image.new("1", (width, height))
            level = "░▒▓".index(char) + 1
            pattern = ((0, 2), (3, 1))
            image.putdata([pattern[y % 2][x % 2] < level for y in range(height) for x in range(width)])
        elif char in DOUBLE_BOXES:
            image = Image.new("1", (width, height))
            double_box(ImageDraw.Draw(image), width, height, DOUBLE_BOXES[char])
        elif char in BOXES + BLOCKS:
            image = Image.new("1", graphics_cell)
            draw = ImageDraw.Draw(image)
            draw.fontmode = "1"
            draw.text(graphics_origin, char, font=graphics, anchor="ls", fill=1)
            # Retain thin strokes that fall between two output pixels.
            image = image.convert("L").resize((width, height), Image.Resampling.BOX)
            image = image.point(lambda value: 255 if value >= 96 else 0, "1")
        else:
            image = Image.new("1", (width, height))
            draw = ImageDraw.Draw(image)
            draw.fontmode = "1"
            mask, (left, top) = text.getmask2(char, mode="1", anchor="ls")
            if bytes(mask) == missing:
                continue
            x = round((width - text.getlength(char)) / 2)
            y = baseline
            bounds = mask.getbbox()
            if bounds:
                x0, y0, x1, y1 = bounds
                if x1 - x0 <= width:
                    x = max(-left - x0, min(x, width - left - x1))
                if y1 - y0 <= height:
                    y = max(-top - y0, min(y, height - top - y1))
            draw.text((x, y), char, font=text, anchor="ls", fill=1)
        yield char, image.tobytes()


def write_font(name, data):
    (OUTPUT / name).write_bytes(gzip.compress(data, mtime=0))


def build_psf(source):
    width, height = 16, 32
    bitmaps = dict(glyphs(source, width, height, ASCII + CYRILLIC + BOXES + BLOCKS + SYMBOLS))
    assert set(ASCII + CYRILLIC + BOXES + BLOCKS) <= bitmaps.keys()
    count, bytes_per_glyph = 256, 64
    header = struct.pack("<8I", 0x864AB572, 0, 32, 1, count, bytes_per_glyph, height, width)
    # Linux also uses glyph 0x20 for clearing the screen. Keep ASCII at its native slots.
    slots = [""] * count
    slots[0x20:0x7F] = ASCII
    extra_slots = list(range(0x7F, count)) + list(range(1, 0x20))
    for index, char in enumerate(char for char in bitmaps if char not in ASCII):
        slots[extra_slots[index]] = char
    blank = bytes(bytes_per_glyph)
    data = b"".join(bitmaps.get(char, blank) for char in slots)
    table = b"".join((char + ("�" if char == "?" else "")).encode("utf-8") + b"\xff" for char in slots)
    write_font("iosevka-16x32.psfu.gz", header + data + table)


def build_wsfont(source, width, height):
    bytes_per_glyph = (width + 7) // 8 * height
    limit = WSFONT_LIMIT // bytes_per_glyph
    latin1 = "".join(map(chr, range(0xA0, 0x100)))
    characters = (char for char in ASCII + latin1 + CYRILLIC + BOXES + BLOCKS + SYMBOLS
                  if ord(char) < limit)
    bitmaps = dict(glyphs(source, width, height, characters))
    assert set(ASCII + CYRILLIC) <= bitmaps.keys()
    # wscons uses the Unicode code point directly as the glyph index.
    data = b"".join(bitmaps.get(chr(code), bitmaps["?"]) for code in range(ord(max(bitmaps)) + 1))
    write_font(f"iosevka-{width}x{height}.wsfont.gz", data)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("ttf", help="path to Iosevka-Medium.ttf")
    args = parser.parse_args()
    build_psf(args.ttf)
    for width, height in [(8, 16), (12, 24), (16, 32), (32, 64)]:
        build_wsfont(args.ttf, width, height)


if __name__ == "__main__":
    main()
