# dotfiles

**A whole Ubuntu laptop from one command.** A light Wayland desktop, Hyprland, 24 colour themes that repaint
*everything* at once — terminal, editor, notifications, GTK apps, Helium, Claude Code — and a Neovim without a
single plugin. Made for a HONOR MagicBook Pro 14 2026 at 3120×2080, at home on any Ubuntu.

```sh
git clone https://github.com/danilrwx/dotfiles ~/dotfiles
cd ~/dotfiles && ./install --desktop
```

## Why it is nice to live in

- **One theme, everywhere, live.** `prefix T` in tmux opens a picker; move the cursor and the terminal
  repaints as you go. Enter, and the notifications, the launcher, GTK windows (already open ones too),
  lazygit, k9s, bat, herdr, the lock screen and Claude Code's diffs follow. 16 dark themes and 8
  light ones; whether a theme is dark or light is read off its colours, so GTK, Helium and Claude switch
  mode with it.
- **Light where it counts.** Hyprland from Ubuntu's archive with my old i3 keys and dwindle (the manual splits kept),
  alacritty as the terminal; no bar at all, the status is a card on `super+i`; the session's daemons are a few
  lines of its config.
- **HiDPI, each screen its own.** The panel at 2x and the 240 Hz monitor at 1.5x, one `monitor` line each; X apps
  (Steam) at the panel's real resolution, scaling themselves. GTK4, Qt6, Helium and Telegram draw natively at it.
- **Neovim, plugin-free.** Fuzzy picker, live grep, git signs and blame, a file manager, sessions,
  LSP completion — native Lua on built-in Neovim. Nothing to update, nothing to break.
  See [`config/nvim`](config/nvim/README.md).
- **Quick settings in one key.** `super+x`: Wi-Fi, Bluetooth, drives, sound in and out, the headset's
  profile, VLESS, OpenVPN, the power profile, the theme.
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
cd ~/dotfiles && ./install --open-pencil  # plus OpenPencil desktop and its MCP bridge
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

`--open-pencil` installs OpenPencil 0.16.0 from the official amd64 `.deb`, verified with SHA-256,
and `@open-pencil/mcp` of the same version under `~/.local`. Maki uses the stdio bridge configured in
`config/maki/mcp.toml`; it discovers the desktop app's local MCP server automatically. Open OpenPencil,
load a document and enable its local MCP server in Settings → MCP before connecting Maki. No Docker,
cloud account or systemd service is needed. File operations are scoped to the agent's working directory;
`eval` stays disabled. Restart or reconnect Maki's MCP server after installation. `--check` compares the
pinned versions when OpenPencil is installed, or when `--open-pencil` is explicitly passed.

## The desktop

| Key | Does |
|---|---|
| `super+Return` | terminal (alacritty in the theme, `bin/x-term`) |
| `super+d` | run: apps by name, `2+2` calculated and copied, `s`/`g`/`?` web searches, else a command |
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
the theme's ground (swayidle with swaylock), the screens off at 15; a night light from 21:00 to 07:00 (wlsunset);
lxpolkit; thunar for files; Telegram on workspace 9 and Discord on 10.

## Themes

```sh
theme                          # the themes, the current one marked
theme gruvbox-light            # set one
theme pick                     # an fzf with a live preview (tmux: prefix T)
theme set bg plain|theme       # the ground black (white on a light theme) or the theme's own
theme set opacity 0.85|cycle   # see-through terminal, over a wallpaper
theme set wallpaper FILE|none  # under the see-through terminal, as the session's background
```

What takes the terminal's 16 colours — alacritty, nvim, tmux, fzf, bat, k9s, herdr — follows by the ANSI slots; what
wants hex — Claude Code, GTK, dunst, wmenu, lazygit, k9s's skin, swaylock — is
written from the theme. The themes are plain TOML in [`config/themes`](config/themes).

## What `install` sets up

- **CLI tools** from apt: `zsh`, `git`, `tmux`, `gnupg`, `fzf`, `bat`, `jq`, `ripgrep`, `ugrep`, `fd`,
  `htop`, `fastfetch`, `clangd`, `neovim`, `nodejs`/`npm`
- **Go** from go.dev into `/usr/local/go`: the latest stable toolchain, checked against go.dev's sha256;
  the archive's `golang-go` is removed
- **Go tools** via `go install`: `gh`, `glab`, `helm`, `k9s`, `yq`, `lazygit`, `crane`, `task`,
  `golangci-lint`, `gopls`, `gofumpt`, `goimports`, `dlv`, `moq`, `ginkgo`, `helm-ls`,
  `golangci-lint-langserver`
- `kubectl` from dl.k8s.io (checked against its sha256); `d8` and `claude` by their own installers;
  Docker from the archive, with the `docker` group; `zsh` as the login shell; Caps Lock as Ctrl
- on a HONOR MagicBook Pro 14 2026 (`ZQC-P`), the
  [hardware fixes](https://github.com/danilrwx/honor-magicbook-pro-14-2026-ubuntu)

With `--desktop`, also:

- **the session**: Hyprland (`config/hypr`), alacritty, wmenu, dunst, greetd
- **network**: iwd for Wi-Fi (NetworkManager's saved networks moved over), systemd-networkd for the wire,
  impala and bluetui as the Wi-Fi and Bluetooth TUIs
- **VPN**: mihomo as the VLESS client (`bin/vpn-vless`: TUN or system proxy, rule mode with Russia direct or
  global, profiles from `private`); OpenVPN profiles as `openvpn-client` units, started without sudo (a
  polkit rule), their DNS for systemd-resolved
- **ssh** through the plain `ssh-agent` with a GTK askpass and a confirm per use, not gcr's agent
- **apps**: Helium (default browser, ungoogled Chromium with uBlock Origin, privacy policies, hardware video encode on), Telegram, Discord, virt-manager,
  Steam, thunar
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
| `etc/` | files `install` puts into `/etc`: iwd, netplan, greetd, Caps as Ctrl, polkit rules, Helium's policies (Memory Saver, privacy) |
| `config/` | the apps' configs, linked into `~/.config`; `config/hypr` the session, `config/systemd` the user units (mihomo, ssh-agent's askpass) |
| `bin/theme` | the colour theme, its options and the picker |
| `bin/x-term` | alacritty in the theme: its opacity and palette |
| `bin/x-lock` | the lock on the theme's ground, swaylock |
| `bin/x-run` | the launcher (`super+d`) |
| `bin/x-menu` | the menu x-run, x-ctl and x-drives pick from, wmenu |
| `bin/x-ctl` | quick settings (`super+x`) |
| `bin/x-status` | the status as a card (`super+i`), the low battery cards |
| `bin/x-fnkeys` | media and HONOR Fn keys with dunst OSD cards |
| `bin/x-drives` | removable drives: mount, or unmount and power off |
| `bin/vpn-vless` | the VLESS client (mihomo) |
| `bin/vpn-openvpn` | an OpenVPN profile up or down |
| `bin/x-askpass` | ssh's and sudo's password prompt, showing the command, each prompt logged |
| `bin/clip` | stdin to the clipboard (tmux, nvim, herdr) |
| `bin/k`, `bin/kaf`, `bin/kad`, `bin/ll` | `kubectl`, `apply -f`, `delete -f`, `ls -lah` as commands: maki's `!` runs bash and never reads `.zshrc`'s aliases |
| `bin/tmux-extract` | `prefix Tab`: fuzzy-pick a word, path or URL from the pane |
| `bin/tmux-ru-keys` | the tmux bindings on the Russian layout too |
| `bin/tmux-agent-watch` | `prefix A`: watch another tmux session in a split |
| `bin/herdr-extract` | `prefix Tab` in herdr: the same picker, Tab inserts, Enter copies |
| `bin/herdr-kill` | `prefix *`: SIGKILL the pane's foreground process, its shell staying |
| `bin/herdr-playbook` | `prefix alt p`: `playbook.sh` in a small split above, `<CR>` runs the line below |
| `bin/herdr-worktree-open` | opens the repo's linked worktrees herdr does not have yet (run by the Maki plugin after `git worktree add`) |
