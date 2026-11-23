# Iosevka on the system console

The full installer configures the console font on Ubuntu, Alpine and
OpenBSD. For a standalone install on OpenBSD, run
`doas sh lib/install-console-font.sh` from the repository. The installer activates
the font immediately and registers it with `rcctl` for future boots.

OpenBSD framebuffer consoles can only load fonts with the active cell size.
The included 8×16, 12×24, 16×32 and 32×64 bitmaps cover the stock OpenBSD/amd64
framebuffer sizes. All include ASCII and Russian Cyrillic. The 8×16 and 12×24 variants
also include box-drawing characters. The 512 KiB wscons limit excludes those
Unicode slots at 16×32 and 32×64. The login profile enables UTF-8 on local
`vt220` displays. Serial terminals use the font selected on the client.

On Ubuntu, Alpine and Chimera Linux the Linux console uses the same 16×32
PSF2 bitmap with 256 slots and a Unicode table for ASCII, Russian Cyrillic
and common box-drawing glyphs. On Chimera, install the `console-setup` package
and run `sh lib/install-console-font.sh` as root to configure the font for the
next boot. Run this from a Linux virtual console to try the bitmap.

```sh
setfont ~/dotfiles/config/console/iosevka-16x32.psfu.gz
```

The bitmaps are derived from Iosevka 34.2.1 under the [SIL Open Font License](OFL.txt).
To regenerate them, run `python3 config/console/build-fonts.py /path/to/Iosevka-Regular.ttf`
with Pillow installed.
