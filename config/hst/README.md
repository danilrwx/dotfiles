# hst

The optional hst terminal is the user-local `~/.local/bin/st-wl` build.
The default desktop terminal is now Foot; launch hst explicitly with `st-wl`.

`config.h` preserves the font, palette and bindings used for this build.
`hst.patch` preserves the Fontconfig, integer HiDPI and terminfo fixes.
`BUILD.txt` records the exact hst and neuwld revisions.

Sources are in `~/.local/src/{hst,neuwld}`; the installation prefix is
`~/.local/opt/hst`. neuwld is built with its Wayland SHM backend and DRM disabled.
Build hst with `PKG_CONFIG_PATH=$HOME/.local/opt/hst/lib/pkgconfig` and
`LDFLAGS=-Wl,-rpath,$HOME/.local/opt/hst/lib` after applying the patch and copying
`config.h` into its source directory. Install its terminfo with `tic -sx st-wl.info`.

The main installer does not build or update this local fork.
