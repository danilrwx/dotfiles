# Foot

Foot uses Terminus without antialiasing at 16 pixels on a 1× display and
32 pixels on a 2× display. Bold text uses Terminus Bold. Italic text uses
the upright face at the requested weight.
`./install` installs `fonts-terminus-otb` on Ubuntu.

`./install --configs` renders the current color syntax for Foot 1.27 and
newer from the shared palettes. Older Foot versions use the linked config.

The dark Foot theme and Linux virtual console logins use
[`pastel.ini`](pastel.ini). The virtual console uses the theme's background
and text colors for ANSI slots 0 and 7. Bash applies the palette at login.
On Ubuntu, a real Linux console login loads the packaged 16×32 Terminus bitmap.

For the kernel console on this machine, press Ctrl+Alt+F1. Return to Labwc with
Ctrl+Alt+F7.
