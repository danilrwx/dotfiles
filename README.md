# dotfiles

**A whole Ubuntu laptop from one command.** A light bspwm desktop that starts in a blink, 24 colour themes
that repaint *everything* at once — terminal, editor, bar, GTK apps, Chrome, Claude Code — and a Neovim
without a single plugin. Made for a HONOR MagicBook Pro 14 2026 at 3120×2080, at home on any Ubuntu.

```sh
git clone https://github.com/danilrwx/dotfiles ~/dotfiles
cd ~/dotfiles && ./install --desktop
```

## Why it is nice to live in

- **One theme, everywhere, live.** `prefix T` in tmux opens a picker; move the cursor and the terminal
  repaints as you go. Enter, and the bar, the notifications, dmenu, GTK windows (already open ones too),
  lazygit, k9s, bat, Chrome's toolbar, the lock screen and Claude Code's diffs follow. 16 dark themes and 8
  light ones; whether a theme is dark or light is read off its colours, so GTK, Chrome and Claude switch
  mode with it.
- **Light where it counts.** The terminal is [my st build](https://github.com/danilrwx/st), about 28 MB a
  window where alacritty took over 100; the compositor (xcompmgr) runs only while you ask for
  see-through windows; the session's daemons are systemd user units that restart on a crash and stop with
  the session.
- **HiDPI done the GNOME way.** XSETTINGS at 2x (xsettingsd): GTK, Chrome, Discord and other Electron apps
  are all exactly 2x, crisp, no per-app flags.
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
cd ~/dotfiles && ./install --desktop  # plus the bspwm desktop and the GUI apps
./debloat -n && ./debloat             # once, after --desktop: GNOME and snapd gone
```

`--skip-go` and `--skip-ts` leave the Go tools and the treesitter parsers as they are, for a quick rerun
after a config change.

## The desktop

| Key | Does |
|---|---|
| `super+Return` | terminal (st in the theme, `bin/term`) |
| `super+d` | run: apps by name, `2+2` calculated and copied, `s`/`g`/`?` web searches, else a command |
| `super+x` | quick settings (`bin/x-ctl`) |
| `super+h/j/k/l`, `+shift` | focus, move |
| `super+alt+h/j/k/l`, `+shift` | grow, shrink |
| `super+1..0`, `+shift` | desktop, send to it |
| `super+f` / `super+shift+space` / `super+w` | fullscreen / float / monocle |
| `super+shift+q` | close |
| `Print`, `super+shift+s` | screenshot of a region to the clipboard |
| `super+n`, `+shift` | dismiss a notification, all of them |
| `super+shift+x` | lock |
| `super+shift+r` / `super+shift+e` | restart bspwm / quit, after a yes |
| media and HONOR Fn keys | volume, mic, brightness, touchpad, camera, power profile, with an OSD |

The rest of the session: greetd with tuigreet to log in; polybar with a plain-words status line
(`bin/x-status`) and a tray that keeps Electron apps alive on close (snixembed); dunst for notifications;
xss-lock with i3lock on the theme's ground; a night light from 21:00 to 07:00 (redshift); lxpolkit;
thunar for files.

## Themes

```sh
theme                          # the themes, the current one marked
theme gruvbox-light            # set one
theme pick                     # an fzf with a live preview (tmux: prefix T)
theme set bg plain|theme       # the ground black (white on a light theme) or the theme's own
theme set opacity 0.85|cycle   # see-through terminal and bar, over a wallpaper
theme set wallpaper FILE|none  # under the see-through terminal; bspwm picks a random one at each start
```

What takes the terminal's 16 colours — st, nvim, tmux, fzf, bat, k9s — follows by the ANSI slots; what
wants hex — Claude Code, GTK, bspwm, polybar, dunst, dmenu, lazygit, k9s's skin, Chrome, i3lock — is
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

- **the session**: bspwm on Xorg with sxhkd, polybar, dunst, xsettingsd, greetd; st built from my fork
- **network**: iwd for Wi-Fi (NetworkManager's saved networks moved over), systemd-networkd for the wire,
  impala and bluetui as the Wi-Fi and Bluetooth TUIs
- **VPN**: mihomo as the VLESS client (`bin/vless`: TUN or system proxy, rule mode with Russia direct or
  global, profiles from `private`); OpenVPN profiles as `openvpn-client` units, started without sudo (a
  polkit rule), their DNS for systemd-resolved
- **ssh** through the plain `ssh-agent` with a GTK askpass and a confirm per use, not gcr's agent
- **apps**: Google Chrome (default browser, hardware video encode on), Telegram, Discord, virt-manager,
  Steam, thunar
- **fonts**: Iosevka for text, Noto Color Emoji for the rest

`./debloat` then removes snapd and every snap, GNOME, GDM and the ~350 packages only the desktop
metapackages pulled in, keeping what the session needs (iwd, Bluetooth, sound, fingerprint, power
profiles, the keyring). `-n` shows all of it first; it refuses to run before greetd is enabled.

## Layout

| Path | What |
|---|---|
| `install` | host setup: symlinks, packages, Go tools, the desktop; `bin/dotfiles-update` is the same script |
| `debloat` | one-off: strip GNOME, snapd and the unused rest from a stock Ubuntu desktop |
| `etc/` | files `install` puts into `/etc`: iwd, netplan, greetd, the touchpad, Caps as Ctrl, polkit rules |
| `config/` | the apps' configs, linked into `~/.config`; `config/systemd` the session's user units |
| `bin/theme` | the colour theme, its options and the picker |
| `bin/term` | st in the theme: its opacity and palette |
| `bin/x-session` | the session: the theme, the user units, bspwm |
| `bin/x-run` | the dmenu launcher (`super+d`) |
| `bin/x-ctl` | quick settings (`super+x`) |
| `bin/x-status` | polybar's status text |
| `bin/x-fnkeys` | media and HONOR Fn keys with dunst OSD cards |
| `bin/x-night` | the night light by the hour |
| `bin/x-drives` | removable drives: mount, or unmount and power off |
| `bin/vless` | the VLESS client (mihomo) |
| `bin/openvpn-ctl` | an OpenVPN profile up or down |
| `bin/askpass` | ssh's and sudo's password prompt, showing the command, each prompt logged |
| `bin/clip` | stdin to the clipboard (tmux, nvim) |
| `bin/tmux-extract` | `prefix Tab`: fuzzy-pick a word, path or URL from the pane |
| `bin/tmux-ru-keys` | the tmux bindings on the Russian layout too |
| `bin/agent-watch` | `prefix A`: watch another tmux session in a split |
