# dotfiles

**A whole Ubuntu laptop from one command.** A light Wayland desktop with Labwc, Foot and wmenu,
one pastel colour theme, and a plugin-free Vim setup. Made for a HONOR MagicBook
Pro 14 2026 at 3120×2080, with 2× scaling.

```sh
git clone https://github.com/danilrwx/dotfiles ~/dotfiles
cd ~/dotfiles && ./install
```

## Why it is nice to live in

- **One theme, everywhere.** Pastel: 16 soft ANSI colours, a black ground and white text.
  The terminal palette is in [`config/foot/pastel.ini`](config/foot/pastel.ini); tmux, fzf and k9s
  use the terminal's ANSI slots. Vim uses the terminal palette in the dark theme. GTK, dunst, wmenu and other apps keep colours in their own configs.
- **A small desktop.** Labwc from Ubuntu's archive, Foot, wmenu and no permanent bar.
  **Super+i** shows a status card; **Super+x** opens quick settings.
- **HiDPI.** Native 2× scaling, Iosevka at 32 pixels in Foot, and 10-logical-pixel outer gaps
  to keep maximized windows clear of the laptop panel's rounded corners.
- **Vim, plugin-free.** Fuzzy `:find`, quickfix search, tag navigation and netrw.
  See [the Vim configuration](experiments/vim/README.md).
- **Quick settings in one key.** `super+x`: Wi-Fi, Bluetooth, drives, sound in and out, the headset's
  profile, VLESS, OpenVPN, the power profile.
- **Every root password prompt says what it is for.** `sudo -A` shows the command it will run, and whether
  Claude Code is the one asking.
- **Safe to rerun.** `./install` checks before it changes anything; `dotfiles-update` is the same script
  on your PATH.

## Requirements

- Ubuntu for the full laptop setup, or Alpine and OpenBSD for the shared Labwc desktop
- Chimera Linux supports `./install --configs` for an existing Labwc desktop
- `git`, `curl` and `sudo`
- Optional: an SSH key in `~/.ssh`. With one, `install` switches the repo to SSH and pulls the private
  submodule; without one both are skipped.

## Install

```sh
cd ~/dotfiles && ./install             # Labwc, native Firefox, and on Ubuntu development tools and Steam
./install --configs                    # apply user configs and reload Labwc when available
./install --android                    # on Ubuntu, add the Android SDK and Studio
./debloat -n                           # inspect optional Ubuntu system cleanup
```

Use `--configs` to apply CLI and Labwc configuration without installing packages.
This mode updates user links, then reloads tmux, Labwc
and the user service definitions when a session is available. It needs an initial full installation:
it does not run sudo, install packages, download fonts, build tools, change system files,
run `private/install`, enable services or update the private submodule. Existing windows stay open;
new terminal windows pick up font changes. Shell changes take effect in a new shell.

The full installer remains the way to install or update tools and system configuration.
`./install --skip-go` skips Go tool updates; it still allows downloads and system changes.

### Backups and restore

Before replacing a user file, directory or conflicting symlink, the installer moves it into
`~/.local/state/dotfiles/backups/YYYYmmdd-HHMMSS.XXXXXX/`, or under `$XDG_STATE_HOME` if set.
System files replaced by a full installation are copied there with sudo. Each run gets a unique,
private directory, created only when needed. The original absolute path is retained below it:
`home/danil/.bashrc`, `etc/greetd/config.toml`, and so on. Previous archives are never overwritten.
Old managed `.bak` files and the earlier `retired` / `dotfiles-x11` archives migrate there intact.
The system archives from the desktop cleanup are preserved under `backups/legacy-system-*/var/backups/`.
The private submodule has its own installer and backup policy.

To restore a user file, first move the installed symlink aside, then move its archived file back
to the original path. Restore a system file with `sudo cp -a` from its archived `etc/...` path.
Stop the affected application before restoring a directory. The `.new` / `.old` trees used while
updating downloaded software are temporary rollback files, separate from config archives.

Installer regression checks run without sudo or a desktop session:

```sh
python3 -m unittest discover -s tests -v
for script in install lib/install*.sh; do sh -n "$script" || exit; done
shellcheck -S warning install
```

The tests use temporary home directories, including paths with spaces, and reject calls to
package managers and download/build tools. They cover repeated config application, conflicting files, backup preservation,
legacy archives and download verification.

`install --android` is independent of the desktop: the SDK in `~/Android/Sdk` (the
command-line tools with `sdkmanager` and `avdmanager`, `platform-tools` for `adb`, the emulator, the newest
platform and build-tools), OpenJDK 21 for Gradle, the udev rules that make a phone on USB visible to `adb`,
`scrcpy`, and Android Studio in `/opt/android-studio` with a menu entry. `ANDROID_HOME` and the SDK's three
`bin` directories come from `.profile`. No version is pinned here: `sdkmanager` takes what Google calls
stable when the script runs, Studio comes from the tarball its download page links with a sha256, and a
rerun is the update. The emulator needs `/dev/kvm`: the script adds you to the `kvm` group, and that takes a new login.

## The desktop

Greetd starts the package-owned [Labwc session](config/labwc) by default.
The laptop panel runs at 3120×2080 at 120 Hz with 2× scaling. Browser screen
sharing uses `xdg-desktop-portal-wlr` and PipeWire.

**Super+Return** opens Foot. **Super+H/J/K/L** snaps windows to screen edges.
**Super+1…5** selects workspaces. Add **Shift** to send a window to a workspace.
**Super+B** opens Firefox bookmarks and **Super+S** opens Firefox search.
**Print** or **Super+Shift+S** copies a selected screenshot.

Swayidle and Swaylock lock the screen after ten minutes and before suspend.
The display powers off after fifteen minutes. Dunst handles notifications,
and the session starts a GTK polkit authentication agent.
`x-battery.timer` checks the battery once a minute, with one warning at 10% and one critical warning
at 5% per discharge. `Super+i` shows battery charge and estimated time remaining,
connected Bluetooth headphone charge, volume/microphone, brightness, Wi-Fi signal,
local IPv4 address, memory, free disk space and uptime, with devices and values
below bold labels and spacing between related groups. A separate month-calendar card starts on Monday
and highlights today.
Headphone charge comes from
BlueZ; devices that do not report it show `unknown`. The card stays for ten seconds
and gathers data only when requested; there is no status polling loop.

Tmux refreshes its status every 15 seconds: one local kubeconfig read provides both the current
context and namespace. The username uses tmux's environment without spawning `whoami`.

## Colours

One theme, pastel: soft 16 ANSI colours after Alabaster's, a black ground, white text. It is the terminal's
palette, [`config/foot/pastel.ini`](config/foot/pastel.ini), and everything that can takes its colours from
those slots — tmux, fzf, k9s. What wants a colour of its own has it in its own config: GTK's
named colours and `settings.ini` in [`config/gtk`](config/gtk), the borders in `config/hypr`, dunst's cards,
wmenu's (`bin/x-menu`), k9s's `skins/theme.yaml`, and Claude Code's,
in `private` beside its own config as `themes/dotfiles.json`.

Edit `config/foot/pastel.ini` to change the palette. Run `./install --configs`
and open a new Foot window to load the updated colours. A fresh Linux virtual
console login also loads the updated palette.

## Text console

The full installer sets up the Iosevka bitmap for the system console on
Ubuntu, Alpine and OpenBSD. Bash applies Pastel at login on Linux.
On a console-only OpenBSD install, install Bash, Vim, fzf and ugrep from
packages, run `./install --configs` as your user, and run
`doas ./bin/x-install-console-font` for the console font. OpenBSD includes
tmux. If your login shell is ksh, start Bash with `bash -l` to load the Bash
config. See [console font installation and supported glyphs](config/console/README.md).

Start `tmux new-session -A -s main` in either console. New panels use
`tmux-256color`. The outer terminals keep their own capabilities. In tmux,
`Ctrl+b`, `Enter` opens copy mode and `Ctrl+b`, `]` pastes from the buffer.
Vim yanks also work across panes. Direct console logins use the native
`TERM`, and text navigation works with the keyboard.
`x-status --text` shows system status in the shell. On Ubuntu, `wifi` and `bt`
open their native CLI when iwd and BlueZ are installed.

## What `install` sets up

- **Base CLI tools** from apt: Bash, Git, tmux, GnuPG, fzf, jq, ugrep, fd,
  Vim, OpenSSH, pass and age, plus standard file/network utilities.
  The base sets Bash as the login shell and Caps Lock as Ctrl.
- **Development**: [`install`](install) on Ubuntu installs compilers, language servers, Universal Ctags,
  Node/npm, Go and Go tools, kubectl/d8, Docker, RTK, OpenVPN, QEMU/libvirt and the private agent setup.
  Its k9s config lives in [`dev/config/k9s`](dev/config/k9s).
  Android SDK and Studio are optional: `./install --android`.
- **the session**: Labwc (`config/labwc`), Foot, wmenu, Dunst, Swayidle, Swaylock and greetd
- **network**: iwd for Wi-Fi (NetworkManager's saved networks moved over), systemd-networkd for the wire,
  `bin/wifi` over `iwctl` for Wi-Fi and `bin/bt` selecting Bluetooth devices through `bluetoothctl`
- **VPN**: mihomo as the VLESS client (`bin/vpn-vless`: TUN or system proxy, rule mode with Russia direct or
  global, profiles from `private`). OpenVPN profiles and their systemd/polkit setup belong to `install`.
- **ssh** through the plain `ssh-agent` with a GTK askpass and a confirm per use, not gcr's agent
- **apps**: Firefox from Mozilla's signed APT repository. On Ubuntu the installer also adds Lolka X.
- **Fonts.** Iosevka in Foot, menus, window decorations, notifications, GTK and
  the Firefox interface. Noto Color Emoji provides emoji where installed.

Firefox's settings are in `etc/firefox/policies/policies.json` (DRM playback is enabled): vertical tabs, compact UI,
Google search, Patchtree/uBlock Origin/SponsorBlock, privacy settings and disabled AI features.
Tracking protection uses the native Strict category policy, including cookie isolation and fingerprinting protection.
Privacy and UI preferences outside the policy allowlist live in `config/firefox/user.js`; Safe Browsing stays enabled.
Firefox uses its standard interface; no custom stylesheet is installed.
`config/firefox/user.js` selects the Betterfox Smoothfox Zen scrolling preset, with the minimum line scroll amount reduced to 5.

`./debloat` then removes GNOME, GDM, CUPS, unused desktop tools and their unused dependencies.
It keeps the gaming profile and its package dependencies. If Steam is installed as a snap, it keeps snapd and
the installed snaps. `-n` previews the cleanup. Applying it requires greetd to be enabled.

## Layout

| Path | What |
|---|---|
| `install` | base system, user configs and optional desktop; `bin/dotfiles-update` is the same script |
| `debloat` | one-off: strip GNOME, snapd and the unused rest from a stock Ubuntu desktop |
| `etc/` | files `install` puts into `/etc`: iwd, netplan, greetd, Caps as Ctrl, polkit rules, Firefox's policies |
| `config/` | apps' configs, linked into `~/.config`; `config/labwc` holds the desktop session and `config/systemd` holds user units |
| `bin/x-term` | starts Foot and passes through its arguments |
| `bin/firefox-search` | search or open a URL in Firefox through our menu |
| `bin/firefox-bookmarks` | pick exported Firefox bookmarks; supports current and legacy profile paths |
| `bin/x-lock` | Swaylock with duplicate-launch protection |
| `bin/x-run` | the launcher (`super+d`): desktop applications or typed shell commands |
| `bin/x-menu` | the menu x-run, x-ctl and x-drives pick from, wmenu; a second argument makes a vertical list of that many rows |
| `bin/web-url` | what a browser loads for a line: an address as it is, a bang (`!yt` goes to DuckDuckGo, which resolves it), or a DuckDuckGo search |
| `bin/x-ctl` | quick settings (`super+x`) |
| `bin/wifi` | Wi-Fi in `bin/x-menu` over `iwctl`: connect, disconnect, rescan, the address |
| `bin/bt` | Bluetooth connect/disconnect/pairing menu, also opened from `super+x` → `bluetooth` |
| `bin/x-status` | status card (`super+i`); `battery` checks warning thresholds once |
| `bin/x-fnkeys` | media and HONOR Fn keys with dunst OSD cards |
| `bin/x-drives` | removable drives: mount, or unmount and power off |
| `bin/vpn-vless` | the VLESS client (mihomo) |
| `dev/bin/vpn-openvpn` | an OpenVPN profile up or down |
| `bin/x-askpass` | ssh's and sudo's password prompt, showing the command, each prompt logged |
| `bin/clip` | stdin to the clipboard (tmux, Vim) |
| `bin/k`, `bin/kaf`, `bin/kad`, `bin/ll` | `kubectl`, `apply -f`, `delete -f`, `ls -lah` as commands available to scripts and noninteractive shells |
| `bin/tmux-extract` | `prefix Tab`: fuzzy-pick a word, path or URL from the pane |
| `bin/tmux-ru-keys` | the tmux bindings on the Russian layout too |
| `bin/tmux-agent-watch` | `prefix A`: watch another tmux session in a split |

## Running Labwc

Ubuntu uses the package's Labwc session in greetd. On Alpine 3.24,
`./install` enables greetd for the next boot. Log in on the VM or machine
console to start Labwc. On OpenBSD 8.0, run `./install` as your desktop
user, log in again for seatd, then run `~/dotfiles/bin/start-labwc` from a
local console. The same command also works from a text console on Alpine.

On Chimera Linux, install the desktop packages for your session and
`fonts-iosevka-ttf` from the `user` repository, then run `./install --configs`.

Ubuntu installs Steam from Flathub into the same Labwc desktop. See
[`game/README.md`](game/README.md) for the gaming tools.

## Desktop themes

`x-theme light` selects the warm paper palette (#f2e8d2, text #33322e); `x-theme dark` restores
dark backgrounds and a warm terminal palette. Toggle with Super+Shift+T or
choose `theme` in Super+X. The selection survives logout.

Foot, wmenu, GTK, notifications, window borders and the lock screen follow the
selection. Labwc uses swaybg with a random painting on theme changes
and login. Run `wallpapers-fetch` to download the light and dark collections;
images stay in `~/.local/share/wallpapers/paintings`, outside dotfiles. Without
the collection, Turner and Whistler remain as fallbacks (sources and details in
config/themes/README.md). The light
terminal palette adds muted olive, ochre and terracotta accents. Firefox uses a small light-mode CSS palette for its interface and built-in
pages; restart Firefox once after enabling it. Websites keep their own colors.
Vim updates on theme changes. Interactive Codex sessions launched from
Bash use the Foot palette, which follows the desktop theme while Codex is open.
Open a new Foot window once after installing this configuration; subsequent
switches update its palette without closing the terminal. Other applications
may need reopening to reload their GTK CSS.
