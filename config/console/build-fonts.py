#!/usr/bin/env python3
"""Build the checked-in console fonts from JetBrainsMono-Regular.ttf using Pillow."""

import argparse
import gzip
import math
import struct
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


OUTPUT = Path(__file__).resolve().parent
WSFONT_LIMIT = 512 * 1024
ASCII = "".join(map(chr, range(0x20, 0x7F)))
CYRILLIC = "Ё" + "".join(map(chr, range(0x410, 0x450))) + "ё"
BOXES = "─│┌┐└┘├┤┬┴┼━┃┏┓┗┛┣┫┳┻╋═║╔╗╚╝╠╣╦╩╬╭╮╯╰╱╲╳"
BLOCKS = "▀▄█▌▐░▒▓"
SYMBOLS = " ©«»°±·×÷–—‘’“”•…←↑→↓↔✓✗"


def glyphs(source, width, height, characters):
    text_size = 20 if (width, height) == (12, 24) else round(height * 0.8)
    text = ImageFont.truetype(source, text_size)
    graphics_size = math.ceil(width * text_size / text.getlength("─"))
    graphics = ImageFont.truetype(source, graphics_size)
    baseline = height - round(height * 0.22)
    _, top, _, bottom = graphics.getbbox("─", anchor="ls")
    graphics_baseline = (height - top - bottom) // 2
    missing = bytes(text.getmask("\U0010ffff", mode="1"))
    for char in characters:
        image = Image.new("1", (width, height))
        draw = ImageDraw.Draw(image)
        draw.fontmode = "1"
        if char in BOXES + BLOCKS:
            draw.text((0, graphics_baseline), char, font=graphics, anchor="ls", fill=1)
        else:
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
    write_font("jetbrains-mono-16x32.psfu.gz", header + data + table)


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
    write_font(f"jetbrains-mono-{width}x{height}.wsfont.gz", data)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("ttf", help="path to JetBrainsMono-Regular.ttf")
    args = parser.parse_args()
    build_psf(args.ttf)
    for width, height in [(8, 16), (12, 24), (16, 32), (32, 64)]:
        build_wsfont(args.ttf, width, height)


if __name__ == "__main__":
    main()
