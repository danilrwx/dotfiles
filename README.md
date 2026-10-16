# dotfiles

**A whole Ubuntu laptop from one command.** A light Wayland desktop, sway, 24 colour themes that repaint
*everything* at once — terminal, editor, notifications, GTK apps, Chrome, Claude Code — and a Neovim without a
single plugin. Made for a HONOR MagicBook Pro 14 2026 at 3120×2080, at home on any Ubuntu.

```sh
git clone https://github.com/danilrwx/dotfiles ~/dotfiles
cd ~/dotfiles && ./install --desktop
```

## Why it is nice to live in

- **One theme, everywhere, live.** `prefix T` in tmux opens a picker; move the cursor and the terminal
  repaints as you go. Enter, and the notifications, the launcher, GTK windows (already open ones too),
  lazygit, k9s, bat, Chrome's toolbar, the lock screen and Claude Code's diffs follow. 16 dark themes and 8
  light ones; whether a theme is dark or light is read off its colours, so GTK, Chrome and Claude switch
  mode with it.
- **Light where it counts.** sway from Ubuntu's archive with my old i3 keys, foot as the terminal; swaybar with
  a plain-words status line; the session's daemons are a few lines of `exec` in its config.
- **HiDPI, crisp.** Every screen at 2x by sway's own output settings; GTK, Chrome and Telegram draw natively at it.
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
cd ~/dotfiles && ./install --desktop  # plus the sway desktop and the GUI apps
./debloat -n && ./debloat             # once, after --desktop: GNOME and snapd gone
```

`--skip-go` and `--skip-ts` leave the Go tools and the treesitter parsers as they are, for a quick rerun
after a config change.

## The desktop

| Key | Does |
|---|---|
| `super+Return` | terminal (foot in the theme, `bin/x-term`) |
| `super+d` | run: apps by name, `2+2` calculated and copied, `s`/`g`/`?` web searches, else a command |
| `super+x` | quick settings (`bin/x-ctl`) |
| `super+i` | the status: time, battery, sound, brightness |
| `super+h/j/k/l`, `+shift` | focus, move |
| `super+v` / `super+c` | the next window below / beside |
| `super+e` / `super+w` / `super+s` | split direction / tabbed / stacking |
| `super+r` | resize mode: h/j/k/l, out by Enter or Esc |
| `super+space` / `super+a` | focus floating or tiled / the parent |
| `super+1..0`, `+shift` | workspace, send to it |
| `super+Tab` / `super+.`, `+shift` | the previous workspace / the next screen, send to it |
| `super+f` / `super+shift+space` | fullscreen / float |
| `super+shift+q` | close |
| `super+b` | the bar, hidden or shown |
| `Print`, `super+shift+s` | screenshot of a region to the clipboard |
| `super+n`, `+shift` | dismiss a notification, all of them |
| `super+shift+x` | lock |
| `super+shift+c` / `super+shift+e` | reload the config / quit, after a yes |
| media and HONOR Fn keys | volume, mic, brightness, camera, power profile, with an OSD |

The rest of the session: greetd with tuigreet to log in; swaybar on top with the status line (`bin/x-status`),
`super+b` hiding it and `super+i` showing the status as a card, a card at 10% and 5% battery; Telegram opens on
workspace 9 and Discord on 10; dunst for notifications; swayidle locking with swaylock on the theme's ground at
10 min, the screens off at 15; a night light from 21:00 to 07:00 (wlsunset); the monitors by sway's output
settings; lxpolkit; screen sharing through xdg-desktop-portal-wlr; thunar for files.

## Themes

```sh
theme                          # the themes, the current one marked
theme gruvbox-light            # set one
theme pick                     # an fzf with a live preview (tmux: prefix T)
theme set bg plain|theme       # the ground black (white on a light theme) or the theme's own
theme set opacity 0.85|cycle   # see-through terminal, over a wallpaper
theme set wallpaper FILE|none  # under the see-through terminal, as sway's background
```

What takes the terminal's 16 colours — foot, nvim, tmux, fzf, bat, k9s — follows by the ANSI slots; what
wants hex — Claude Code, GTK, dunst, wmenu, lazygit, k9s's skin, Chrome, swaylock — is
written from the theme. The themes are plain TOML in [`config/themes`](config/themes).

## What `install` sets up

- **CLI tools** from apt: `zsh`, `git`, `tmux`, `gnupg`, `fzf`, `bat`, `jq`, `ripgrep`, `ugrep`, `fd`,
  `htop`, `fastfetch`, `go`, `clangd`, `neovim`, `nodejs`/`npm`
- **Go tools** via `go install`: `gh`, `glab`, `helm`, `k9s`, `yq`, `lazygit`, `crane`, `task`,
  `golangci-lint`, `gopls`, `gofumpt`, `goimports`, `dlv`, `moq`, `ginkgo`, `helm-ls`,
  `golangci-lint-langserver`
- `kubectl` from dl.k8s.io (checked against its sha256); `d8` and `claude` by their own installers;
  Docker from the archive, with the `docker` group; `zsh` as the login shell; Caps Lock as Ctrl
- on a HONOR MagicBook Pro 14 2026 (`ZQC-P`), the
  [hardware fixes](https://github.com/danilrwx/honor-magicbook-pro-14-2026-ubuntu)

With `--desktop`, also:

- **the session**: sway (`config/sway`), foot, wmenu, dunst, greetd
- **network**: iwd for Wi-Fi (NetworkManager's saved networks moved over), systemd-networkd for the wire,
  impala and bluetui as the Wi-Fi and Bluetooth TUIs
- **VPN**: mihomo as the VLESS client (`bin/vpn-vless`: TUN or system proxy, rule mode with Russia direct or
  global, profiles from `private`); OpenVPN profiles as `openvpn-client` units, started without sudo (a
  polkit rule), their DNS for systemd-resolved
- **ssh** through the plain `ssh-agent` with a GTK askpass and a confirm per use, not gcr's agent
- **apps**: Google Chrome (default browser, hardware video encode on), Telegram, Discord, virt-manager,
  Steam, thunar
- **fonts**: Iosevka for text, Noto Color Emoji for the rest

`./debloat` then removes snapd and every snap, GNOME, GDM, Xorg and the ~350 packages only the desktop
metapackages pulled in, keeping what the session needs (iwd, Bluetooth, sound, fingerprint, power
profiles, the keyring). `-n` shows all of it first; it refuses to run before greetd is enabled.

## Layout

| Path | What |
|---|---|
| `install` | host setup: symlinks, packages, Go tools, the desktop; `bin/dotfiles-update` is the same script |
| `debloat` | one-off: strip GNOME, snapd and the unused rest from a stock Ubuntu desktop |
| `etc/` | files `install` puts into `/etc`: iwd, netplan, greetd, Caps as Ctrl, polkit rules, Chrome's Memory Saver |
| `config/` | the apps' configs, linked into `~/.config`; `config/sway` the session, `config/systemd` the user units (mihomo, ssh-agent's askpass) |
| `bin/theme` | the colour theme, its options and the picker |
| `bin/x-term` | foot in the theme: its opacity and palette |
| `bin/x-lock` | swaylock on the theme's ground |
| `bin/x-run` | the launcher (`super+d`) |
| `bin/x-menu` | the menu x-run, x-ctl and x-drives pick from (wmenu) |
| `bin/x-ctl` | quick settings (`super+x`) |
| `bin/x-status` | the bar's status line, the low battery cards; the status as a card (`super+i`) |
| `bin/x-fnkeys` | media and HONOR Fn keys with dunst OSD cards |
| `bin/x-drives` | removable drives: mount, or unmount and power off |
| `bin/vpn-vless` | the VLESS client (mihomo) |
| `bin/vpn-openvpn` | an OpenVPN profile up or down |
| `bin/x-askpass` | ssh's and sudo's password prompt, showing the command, each prompt logged |
| `bin/clip` | stdin to the clipboard (tmux, nvim) |
| `bin/tmux-extract` | `prefix Tab`: fuzzy-pick a word, path or URL from the pane |
| `bin/tmux-ru-keys` | the tmux bindings on the Russian layout too |
| `bin/tmux-agent-watch` | `prefix A`: watch another tmux session in a split |
