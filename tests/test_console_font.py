import gzip
import struct
import unittest
from pathlib import Path


FONTS = Path(__file__).resolve().parents[1] / "config/console"


class ConsoleFontTest(unittest.TestCase):
    def assert_graphics_cells(self, glyph, width, height):
        row_bytes = (width + 7) // 8

        def rows(char):
            data = glyph(char)
            return [
                tuple(bool(data[y * row_bytes + x // 8] & (0x80 >> (x % 8))) for x in range(width))
                for y in range(height)
            ]

        for upper, lower in (("┌", "│"), ("│", "└"), ("┏", "┃"), ("╔", "║")):
            with self.subTest(upper=upper, lower=lower):
                edge = rows(upper)[-1]
                self.assertTrue(any(edge))
                self.assertEqual(edge, rows(lower)[0])
        for left, right in (("┌", "─"), ("─", "┐"), ("┏", "━"), ("╔", "═")):
            with self.subTest(left=left, right=right):
                edge = [row[-1] for row in rows(left)]
                self.assertTrue(any(edge))
                self.assertEqual(edge, [row[0] for row in rows(right)])
        self.assertEqual([sum(row) for row in rows("▀")], [width] * (height // 2) + [0] * (height // 2))
        self.assertEqual([sum(row) for row in rows("▄")], [0] * (height // 2) + [width] * (height // 2))
        for char, fraction in zip("░▒▓", (1, 2, 3)):
            self.assertEqual(sum(map(sum, rows(char))), width * height * fraction // 4)

    def test_linux_font_preserves_ascii_slots_and_includes_cyrillic(self):
        font = gzip.decompress((FONTS / "iosevka-16x32.psfu.gz").read_bytes())
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

        def bitmap(char):
            position = offset + table.index(char.encode()) * stride
            return font[position:position + stride]

        self.assert_graphics_cells(bitmap, width, height)

    def test_wscons_bitmaps_fit_the_kernel_and_use_unicode_indices(self):
        for width, height in [(8, 16), (12, 24), (16, 32), (32, 64)]:
            with self.subTest(width=width, height=height):
                font = gzip.decompress((FONTS / f"iosevka-{width}x{height}.wsfont.gz").read_bytes())
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
                    self.assert_graphics_cells(glyph, width, height)
