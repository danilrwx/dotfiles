# Iosevka on the system console

The full installer configures the console font on Ubuntu, Alpine and
OpenBSD. For a standalone install on OpenBSD, run
`doas sh lib/install-console-font.sh` from the repository. The installer activates
the font immediately and registers it with `rcctl` for future boots.

The loader uses the cell size reported by OpenBSD. The included 8×16, 12×24,
16×32 and 32×64 bitmaps cover the stock framebuffer sizes. The DM250 preview
at 1024×600 uses 12×24 cells with 21-pixel Iosevka Medium glyphs. The X390
at 1920×1080 uses 16×32 cells with 28-pixel glyphs.

All sizes include ASCII and Russian Cyrillic. The 8×16 and 12×24 wscons
bitmaps also include box drawing. At 16×32 and 32×64, the Unicode indices
for those glyphs exceed the 512 KiB bitmap limit. The login profile enables
UTF-8 on local `vt220` displays. Serial terminals use the client's font.

On Ubuntu, Alpine and Chimera Linux the Linux console uses the same 16×32
PSF2 bitmap with 256 slots and a Unicode table for ASCII, Russian Cyrillic
and common box-drawing glyphs. On Chimera, install the `console-setup` package
and run `sh lib/install-console-font.sh` as root to configure the font for the
next boot. Run this from a Linux virtual console to try the bitmap.

```sh
setfont ~/dotfiles/config/console/iosevka-16x32.psfu.gz
```

The bitmaps are derived from Iosevka 34.2.1 under the [SIL Open Font License](OFL.txt).
To regenerate them, run `python3 config/console/build-fonts.py /path/to/Iosevka-Medium.ttf`
with Pillow installed.
