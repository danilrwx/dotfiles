# Gaming profile

On the gaming Ubuntu amd64 system, run these in order:

```sh
./install --desktop
./debloat
./install_game
```

The last installer adds Steam, Gamescope, MangoHud, GameMode, Xwayland,
32-bit Mesa/OpenGL/Vulkan libraries, and scx_lavd pinned to v1.1.4. It enables
the scx_lavd autopilot system service. Native Lolka is installed by this gaming
installer only; the main desktop installer does not install it.

Select **Labwc (gaming)** at login. That session shares the regular Labwc
configuration and enables Xwayland for Steam and other X11 games.

Optional CPU idle control uses `systemctl start cpu-idle.service` and
`systemctl stop cpu-idle.service`. Start it before gaming and stop it afterward
to restore idle states. Disabling idle states increases power use and heat.

Steam launch options, using the gaming screen's actual width and height:

```text
gamemoderun gamescope -W WIDTH -H HEIGHT -w WIDTH -h HEIGHT -f --immediate-flips -- mangohud %command%
```

Proton is managed by Steam. Proprietary NVIDIA drivers and their matching
32-bit libraries must be installed for that machine separately; this profile
installs Mesa drivers. The kernel must support sched_ext.

