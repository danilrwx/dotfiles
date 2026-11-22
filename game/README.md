# Gaming profile

On Ubuntu amd64, `./install` installs Steam from Flathub, GameMode,
Xwayland and Lolka X (`lolka-x`). Steam gets its 32-bit graphics libraries
from the Flatpak runtime and runs in the regular Labwc session.

On kernels with sched_ext support, the installer also installs scx_lavd
v1.1.4 and enables its performance-mode service.

The laptop panel defaults to 3120×2080 at 120 Hz and output scale 2.
Xwayland applications see a 1560×1040 desktop. Launch Steam from the
application menu for the desktop client.

On this HONOR, Labwc uses a software cursor. On this Intel Xe laptop,
`WLR_DRM_NO_ATOMIC=1` in the HONOR Labwc environment enables
asynchronous page flips through legacy DRM. It takes effect at login.
In fullscreen CS2, Super+Shift+F11 switches between synchronized and
asynchronous flips.

Use these CS2 launch options to select the session’s SDL backend:

```sh
SDL_VIDEO_DRIVER="$XDG_SESSION_TYPE" %command%
```

Optional CPU idle control uses `systemctl start cpu-idle.service` and
`systemctl stop cpu-idle.service`. Start it before gaming and stop it afterward
to restore idle states. Disabling idle states increases power use and heat.

Proton is managed by Steam. The installer includes Mesa drivers.

