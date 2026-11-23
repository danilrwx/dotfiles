#!/usr/bin/env python3
"""Build the checked-in console fonts from Iosevka-Regular.ttf using Pillow."""

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
BLOCKS = "▀▄█▌▐░▒▓"
SYMBOLS = " ©«»°±·×÷–—‘’“”•…←↑→↓↔✓✗"


def glyphs(source, width, height, characters):
    text = ImageFont.truetype(source, round(height * 0.8))
    graphics = ImageFont.truetype(source, width * 2)
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
            if bytes(text.getmask(char, mode="1")) == missing:
                continue
            x = round((width - text.getlength(char)) / 2)
            draw.text((x, baseline), char, font=text, anchor="ls", fill=1)
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
    parser.add_argument("ttf", help="path to Iosevka-Regular.ttf")
    args = parser.parse_args()
    build_psf(args.ttf)
    for width, height in [(8, 16), (12, 24), (16, 32), (32, 64)]:
        build_wsfont(args.ttf, width, height)


if __name__ == "__main__":
    main()
