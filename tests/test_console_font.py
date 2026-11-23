import gzip
import struct
import unittest
from pathlib import Path


FONTS = Path(__file__).resolve().parents[1] / "config/console"


class ConsoleFontTest(unittest.TestCase):
    def test_linux_font_preserves_ascii_slots_and_includes_cyrillic(self):
        font = gzip.decompress((FONTS / "jetbrains-mono-16x32.psfu.gz").read_bytes())
        magic, version, offset, flags, count, stride, height, width = struct.unpack_from("<8I", font)
        self.assertEqual((magic, version, flags, count, height, width), (0x864AB572, 0, 1, 256, 32, 16))
        self.assertEqual(stride, 64)
        space = offset + 0x20 * stride
        self.assertEqual(font[space:space + stride], bytes(stride))
        table = font[offset + count * stride:].split(b"\xff")
        self.assertEqual(len(table), count + 1)
        self.assertEqual([entry[0] for entry in table[0x20:0x7F]], list(range(0x20, 0x7F)))
        self.assertEqual(table[ord("?")], "?�".encode())
        for char in "ЁёЯя─│┌┐└┘":
            with self.subTest(char=char):
                glyph = offset + table.index(char.encode()) * stride
                self.assertTrue(any(font[glyph:glyph + stride]))

    def test_wscons_bitmaps_fit_the_kernel_and_use_unicode_indices(self):
        for width, height in [(8, 16), (12, 24), (16, 32), (32, 64)]:
            with self.subTest(width=width, height=height):
                font = gzip.decompress((FONTS / f"jetbrains-mono-{width}x{height}.wsfont.gz").read_bytes())
                stride = (width + 7) // 8 * height

                def glyph(char):
                    start = ord(char) * stride
                    return font[start:start + stride]

                self.assertLessEqual(len(font), 512 * 1024)
                self.assertEqual(len(font) % stride, 0)
                self.assertEqual(glyph(" "), bytes(stride))
                for char in "AЁёЯя":
                    self.assertTrue(any(glyph(char)))
                    self.assertNotEqual(glyph(char), glyph("?"))
                if width <= 12:
                    self.assertIn(0xFF, glyph("─"))
                    self.assertTrue(any(glyph("│")))
