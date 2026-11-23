# Labwc

Greetd launches Labwc on Ubuntu and Alpine. Its session entry is also available
with F3 in Ubuntu's tuigreet.

- Laptop: eDP-1, 3120x2080 at 120 Hz, scale 2; outer margin 10 logical pixels.
  Kanshi reapplies scale 2 when the built-in panel reconnects by itself.
- Terminal: Foot, Iosevka at 16 pixels on 1× displays and 32 pixels on 2× displays, shared ANSI colors.
- Touchpad: natural scrolling, no tap, clickfinger, speed -0.25, scroll factor 0.3.
- Super+Return: terminal; Super+D: applications; Super+B: bookmarks.
- Super+X: quick settings; Super+Shift+X: lock; Super+Right: next track.
- Super+H/J/K/L: snap to left/bottom/top/right half.
- Super+M: maximize; Super+F: fullscreen.
- Super+Shift+F11: toggle tearing for the focused fullscreen window.
- Alt+Tab and Super+Tab: window switcher on the current workspace; Alt+Shift+Tab reverses direction.
- Super+Shift+V: pass shortcuts through to the focused VNC window. Press again to restore local shortcuts.
- Super+left/right drag: move/resize.
- Super+1…5 switches workspaces. Add Shift to move the window.
- Print or Super+Shift+S: screenshot region to clipboard.
- Super+Shift+Q: close window; Super+Shift+E: exit the session.
- Lock after 10 minutes, power off the display after 15; lock before suspend.

Screen sharing uses PipeWire and xdg-desktop-portal-wlr for a whole output.
A real browser call in the physical labwc session still needs testing.

Labwc starts Xwayland on demand for X11 apps. Steam from Flathub uses
the same session.
