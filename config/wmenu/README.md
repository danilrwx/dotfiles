# wmenu on HiDPI

`x-menu` uses the packaged wmenu with JetBrains Mono. The optional patch below is
for bitmap fonts. It renders text at the buffer's physical scale, so at 2×
Terminus 16 px uses the 32-pixel strike.

The patch applies to `wmenu` 0.2.0. Unpack the [Ubuntu source tarball](https://archive.ubuntu.com/ubuntu/pool/universe/w/wmenu/wmenu_0.2.0.orig.tar.xz)
with SHA-256 `3df7aaadfc36c157ccfc327004d38955159c032d9dcf34237089e53cd61594d7`.
From the source directory, with the wmenu build dependencies installed, run:

```sh
patch -p1 < ~/dotfiles/config/wmenu/hidpi.patch
meson setup build --prefix="$HOME/.local/opt/wmenu" --buildtype=release
meson install -C build
```
