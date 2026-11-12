# dotfiles

**A whole Ubuntu laptop from one command.** A light Wayland desktop, Hyprland, one colour theme — pastel — in
*everything*: terminal, editor, notifications, GTK apps, Helium, Claude Code; and a Neovim without a single
plugin. Made for a HONOR MagicBook Pro 14 2026 at 3120×2080, at home on any Ubuntu.

```sh
git clone https://github.com/danilrwx/dotfiles ~/dotfiles
cd ~/dotfiles && ./install --desktop
```

## Why it is nice to live in

- **One theme, everywhere, and it is in the repo.** Pastel: 16 soft ANSI colours, a black ground and white text.
  The palette is one file ([`config/kitty/theme.conf`](config/kitty/theme.conf)), which nvim, tmux, fzf, bat and
  k9s take theirs from by the ANSI slots; the apps that want hex — GTK, dunst, hyprlock, wmenu, lazygit, Claude
  Code, maki — have their colours next to their own config. Nothing is generated, so nothing drifts.
- **Light where it counts.** Hyprland from Ubuntu's archive with my old i3 keys and dwindle (the manual splits kept),
  kitty as the terminal; no bar at all, the status is a card on `super+i`; the session's daemons are a few
  lines of its config.
- **HiDPI, each screen its own.** The panel at 2x and the 240 Hz monitor at 1.5x, one `monitor` line each; X apps
  (Steam) at the panel's real resolution, scaling themselves. GTK4, Qt6 and Helium draw natively at it.
- **Neovim, plugin-free.** Fuzzy picker, live grep, git signs and blame, a file manager, sessions,
  LSP completion — native Lua on built-in Neovim. Nothing to update, nothing to break.
  See [`config/nvim`](config/nvim/README.md).
- **Quick settings in one key.** `super+x`: Wi-Fi, Bluetooth, drives, sound in and out, the headset's
  profile, VLESS, OpenVPN, the power profile.
- **Every root password prompt says what it is for.** `sudo -A` shows the command it will run, and whether
  Claude Code is the one asking.
- **Safe to rerun.** `./install` checks before it changes anything; `dotfiles-update` is the same script
  on your PATH.

## Requirements

- **Ubuntu** (`install` exits on anything else)
- `git`, `curl` and `sudo`
- Optional: an SSH key in `~/.ssh`. With one, `install` switches the repo to SSH and pulls the private
  submodule; without one both are skipped.

## Install

```sh
cd ~/dotfiles && ./install            # the CLI tools only
cd ~/dotfiles && ./install --desktop  # plus the desktop (Hyprland) and the GUI apps
cd ~/dotfiles && ./install --android  # plus the Android SDK, the JDK and Android Studio in /opt
./install --check                     # what the machine lacks, has stale or undeclared; changes nothing
./debloat -n && ./debloat             # once, after --desktop: GNOME and snapd gone
```

`--skip-go` and `--skip-ts` leave the Go tools and the treesitter parsers as they are, for a quick rerun
after a config change.

`--android` is a flag of its own, nothing to do with the desktop: the SDK in `~/Android/Sdk` (the
command-line tools with `sdkmanager` and `avdmanager`, `platform-tools` for `adb`, the emulator, the newest
platform and build-tools), OpenJDK 21 for Gradle, the udev rules that make a phone on USB visible to `adb`,
`scrcpy`, and Android Studio in `/opt/android-studio` with a menu entry. `ANDROID_HOME` and the SDK's three
`bin` directories come from `.profile`. No version is pinned here: `sdkmanager` takes what Google calls
stable when the script runs, Studio comes from the tarball its download page links with a sha256, and a
rerun is the update. `--check` compares all of it only on a machine that has it, or with `--android`. The
emulator needs `/dev/kvm`: the script adds you to the `kvm` group, and that takes a new login.

## The desktop

| Key | Does |
|---|---|
| `super+Return` | terminal (kitty in the palette, `bin/x-term`) |
| `super+d` | run: apps by name, `2+2` calculated and copied; a command when its first word is one, else the browser (a URL, a bang, a search) |
| `super+s` / `super+b` | Firefox: search in our menu / its bookmarks (a tab; with `shift` a window) |
| `super+left` / `super+right` | previous / next track (`playerctl`) |
| `super+up` / `super+down` | volume up / down (`bin/x-fnkeys`); with `shift` the microphone |
| `super+x` | quick settings (`bin/x-ctl`) |
| `super+i` | the status: time, battery, sound, brightness |
| `super+h/j/k/l`, `+shift` | focus, move |
| `super+v` / `super+c` | the next window below / beside (preselect the split) |
| `super+e` / `super+w` | flip the split / group as tabs |
| `super+r` | resize mode: h/j/k/l, out by Enter or Esc |
| `super+space` / `super+shift+space` | focus the floating window / float it |
| `super+1..0`, `+shift` | workspace, send to it; `super+Tab` the last one |
| `super+.`, `+shift` | the other screen, send the window there |
| `super+f` | fullscreen |
| `super+shift+q` | close |
| `Print`, `super+shift+s` | screenshot of a region to the clipboard |
| `super+n`, `+shift` | dismiss a notification, all of them |
| `super+shift+x` | lock |
| `super+shift+c` / `super+shift+e` | reload the config / quit, after a yes |
| media and HONOR Fn keys | volume, mic, brightness, camera, power profile, with an OSD |

Hyprland is the session (the panel 2x, the 240 Hz monitor 1.5x), with my old i3 keys, dwindle and ten
workspaces. greetd with tuigreet to log in; a status of memory, sound, battery, brightness and date, a card on
`super+i`, with the low battery cards at 10% and 5%; dunst for notifications; the lock and the idle at 10 min on
the black ground (hypridle with hyprlock), the screens off at 15; a night light from 21:00 to 07:00 (wlsunset);
hyprpolkitagent; thunar for files.

## Colours

One theme, pastel: soft 16 ANSI colours after Alabaster's, a black ground, white text. It is the terminal's
palette, [`config/kitty/theme.conf`](config/kitty/theme.conf), and everything that can takes its colours from
those slots — nvim, tmux, fzf, bat, k9s, maki. What wants a colour of its own has it in its own config: GTK's
named colours and `settings.ini` in [`config/gtk`](config/gtk), the borders in `config/hypr`, dunst's cards,
hyprlock's ground, wmenu's (`bin/x-menu`), lazygit's `theme.yml`, k9s's `skins/theme.yaml`, maki's
`themes/dotfiles.toml`, and Claude Code's, in `private` beside its own config as `themes/dotfiles.json`.

Helium is on the same side (`bin/helium`): its own UI follows GTK's Adwaita-dark, and `--force-dark-mode` gives
the web's `prefers-color-scheme` the dark it only takes from that flag.

There is no picker and no state: to change a colour, edit the file that has it. Pastel's 16 slots are one edit in
`theme.conf`; the rest follow.

## What `install` sets up

- **CLI tools** from apt: `zsh`, `git`, `tmux`, `gnupg`, `fzf`, `bat`, `jq`, `ripgrep`, `ugrep`, `fd`
  (`fd-find`), `htop`, `fastfetch`, `clangd`, `neovim`, `nodejs`/`npm`, `openssh-server`, `pass`, `vim-gtk3`
  (clipboard), `age`; the build base and small helpers they rest on: `build-essential`, `libcap2-bin`,
  `openssl`, `curl`, `wget`, `zip`/`unzip`, `file`, `procps`
- **dev tools** from apt: `clang`, `clang-format`, `bison`, `flex`, `meson`, `ninja-build`, `valac`, `valgrind`,
  `bear`, `tokei`, `shellcheck`, `scdoc`, `pkg-config`, `gobject-introspection`, `python3-pil`, `systemd-dev`,
  `glslang-tools`, `git-filter-repo`, `evtest`, `rust-clippy`
- **Go** from go.dev into `/usr/local/go`: the latest stable toolchain, checked against go.dev's sha256;
  the archive's `golang-go` is removed
- **Go tools** via `go install`: `gh`, `glab`, `helm`, `k9s`, `yq`, `lazygit`, `crane`, `task`,
  `golangci-lint`, `gopls`, `gofumpt`, `goimports`, `dlv`, `moq`, `ginkgo`, `helm-ls`,
  `golangci-lint-langserver`
- `kubectl` from dl.k8s.io (checked against its sha256); `d8` by its own installer;
  Docker from the archive, with the `docker` group; `zsh` as the login shell; Caps Lock as Ctrl
- on a HONOR MagicBook Pro 14 2026 (`ZQC-P`), the
  [hardware fixes](https://github.com/danilrwx/honor-magicbook-pro-14-2026-ubuntu)

With `--desktop`, also:

- **the session**: Hyprland (`config/hypr`), kitty, wmenu, dunst, greetd
- **network**: iwd for Wi-Fi (NetworkManager's saved networks moved over), systemd-networkd for the wire,
  `bin/wifi` and `bin/bt` as the Wi-Fi and Bluetooth pickers over `iwctl` and `bluetoothctl`
- **VPN**: mihomo as the VLESS client (`bin/vpn-vless`: TUN or system proxy, rule mode with Russia direct or
  global, profiles from `private`); OpenVPN profiles as `openvpn-client` units, started without sudo (a
  polkit rule), their DNS for systemd-resolved
- **ssh** through the plain `ssh-agent` with a GTK askpass and a confirm per use, not gcr's agent
- **apps**: Firefox from Mozilla's own apt repo (default browser; its `/etc/firefox/policies` carry what the
  Chromium ones do — no telemetry, studies, Pocket or sponsored tiles, no saved passwords, HTTPS only, geo off,
  DoH off for systemd-resolved's sake, VA-API on — and force-install uBlock Origin, Google as the search engine);
  Helium beside it (ungoogled Chromium with its own policies); Lolka (an Electron messenger, its .deb from Yandex
  Cloud), Steam, thunar; the VMs through libvirt/qemu (`virsh`, `tigervnc-viewer` for their screens), without the
  `virt-manager` GUI; Brave from its own apt repo — Chromium with Shields, and a policy file that turns off every
  Brave service (Rewards, Wallet, VPN, Talk, News, Leo, Playlist, P3A) and sets the adblock, fingerprinting, HTTPS and
  referrer defaults; Firefox stays the default browser
- **fonts**: Iosevka Term Nerd Font in the terminal (its icons), Iosevka in the apps, Noto Color Emoji for
  the emoji

`./debloat` then removes snapd and every snap, GNOME, GDM, Xorg and the X session's tools, and the ~350 packages
only the desktop metapackages pulled in, keeping what the session needs (Xwayland for Steam, iwd, Bluetooth,
sound, fingerprint, power profiles, the keyring). `-n` shows all of it first; it refuses to run before greetd is
enabled.

## Layout

| Path | What |
|---|---|
| `install` | host setup: symlinks, packages, Go tools, the desktop; `bin/dotfiles-update` is the same script |
| `debloat` | one-off: strip GNOME, snapd and the unused rest from a stock Ubuntu desktop |
| `etc/` | files `install` puts into `/etc`: iwd, netplan, greetd, Caps as Ctrl, polkit rules, Firefox's policies and Mozilla's apt key pin, Brave's policies, Helium's policies (Memory Saver, privacy) |
| `config/` | the apps' configs, linked into `~/.config`; `config/hypr` the session, `config/systemd` the user units (mihomo, ssh-agent's askpass) |
| `bin/x-term` | kitty in the palette (black ground, white text, its configs linked on first run) |
| `bin/firefox-search` | a search in `bin/x-menu` opened in Firefox (`super+s`); words given skip the menu |
| `bin/firefox-bookmarks` | Firefox's own bookmarks in `bin/x-menu`, opened at once: a tab (`super+b`), a window (`super+shift+b`); Ctrl+D saves. A line matching no bookmark goes to the browser as an address, bang or search |
| `bin/helium` | Helium on the theme's side: `--force-dark-mode`, the dark it cannot take from GTK |
| `bin/helium-search` | a search in `bin/x-menu` opened in Helium (`super+s`); words given skip the menu, and a bang (`!yt`, `!5`) works for the browser |
| `bin/helium-bookmarks` | Helium's own bookmarks in `bin/x-menu`, opened at once: a tab (`super+b`), a window (`super+shift+b`); Ctrl+D saves. A line matching no bookmark goes to the browser as an address, bang or search |
| `bin/helium-bookmarks-export` | Helium's `Bookmarks` into `private/helium/bookmarks.tsv`, by the systemd path unit on change |
| `bin/x-lock` | the lock on the black ground, hyprlock |
| `bin/x-run` | the launcher (`super+d`): apps, arithmetic; a command when its first word is one, otherwise the browser (a URL, a bang, a search) |
| `bin/x-menu` | the menu x-run, x-ctl and x-drives pick from, wmenu; a second argument makes a vertical list of that many rows |
| `bin/web-url` | what a browser loads for a line: an address as it is, Helium's own engine (`!5`, `@gemini` from its Web Data), a bang (`!yt` goes to DuckDuckGo, which resolves it), or a DuckDuckGo search |
| `bin/x-ctl` | quick settings (`super+x`) |
| `bin/wifi` | Wi-Fi in `bin/x-menu` over `iwctl`: connect, disconnect, rescan, the address |
| `bin/bt` | Bluetooth in `bin/x-menu` over `bluetoothctl`: connect, disconnect, power, scan and pair |
| `bin/x-status` | the status as a card (`super+i`), the low battery cards |
| `bin/x-fnkeys` | media and HONOR Fn keys with dunst OSD cards |
| `bin/x-drives` | removable drives: mount, or unmount and power off |
| `bin/vpn-vless` | the VLESS client (mihomo) |
| `bin/vpn-openvpn` | an OpenVPN profile up or down |
| `bin/x-askpass` | ssh's and sudo's password prompt, showing the command, each prompt logged |
| `bin/clip` | stdin to the clipboard (tmux, nvim) |
| `bin/k`, `bin/kaf`, `bin/kad`, `bin/ll` | `kubectl`, `apply -f`, `delete -f`, `ls -lah` as commands: maki's `!` runs bash and never reads `.zshrc`'s aliases |
| `bin/tmux-extract` | `prefix Tab`: fuzzy-pick a word, path or URL from the pane |
| `bin/tmux-ru-keys` | the tmux bindings on the Russian layout too |
| `bin/tmux-agent-watch` | `prefix A`: watch another tmux session in a split |
