# wmenu on HiDPI

`x-menu` uses `~/.local/opt/wmenu/bin/wmenu` when present. This build keeps the
menu's logical geometry and measures and renders text with a native bitmap at
the buffer's physical scale. At 2×, Terminus 16 px uses the 32-pixel strike.

The patch applies to `wmenu` 0.2.0. Unpack the [Ubuntu source tarball](https://archive.ubuntu.com/ubuntu/pool/universe/w/wmenu/wmenu_0.2.0.orig.tar.xz)
with SHA-256 `3df7aaadfc36c157ccfc327004d38955159c032d9dcf34237089e53cd61594d7`.
From the source directory, with the wmenu build dependencies installed, run:

```sh
patch -p1 < ~/dotfiles/config/wmenu/hidpi.patch
meson setup build --prefix="$HOME/.local/opt/wmenu" --buildtype=release
meson install -C build
```
