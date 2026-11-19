# Labwc

Greetd launches Labwc by default. Its session entry is also available with F3 in
tuigreet.

- Laptop: eDP-1, 3120x2080 at 120 Hz, scale 2; outer margin 10 logical pixels.
- Terminal: Foot, IosevkaTerm Nerd Font Mono 12, shared ANSI colors.
- Touchpad: natural scrolling, no tap, clickfinger, speed -0.25, scroll factor 0.3.
- Super+Return: terminal; Super+D: applications; Super+B: bookmarks.
- Super+X: quick settings; Super+Shift+X: lock; Super+Right: next track.
- Super+H/J/K/L: snap to left/bottom/top/right half.
- Super+M: maximize; Super+F: fullscreen.
- Alt+Tab and Super+Tab: window switcher on the current workspace; Alt+Shift+Tab reverses direction.
- Super+left/right drag: move/resize.
- Super+1…9: workspaces; add Shift to move the window.
- Print or Super+Shift+S: screenshot region to clipboard.
- Super+Shift+Q: close window; Super+Shift+E: exit the session.
- Lock after 10 minutes, power off the display after 15; lock before suspend.

Screen sharing uses PipeWire and xdg-desktop-portal-wlr for a whole output.
A real browser call in the physical labwc session still needs testing.

Ubuntu's labwc package depends on Xwayland. `WLR_XWAYLAND=/usr/bin/false`
blocks starting the X server; X11 applications will not work in this session.
For X11 games, use the Labwc session installed by the [gaming profile](../../game/README.md).
