# dotfiles

Personal dotfiles for Ubuntu.

## Requirements

- **Ubuntu** (`install` exits on anything else)
- `git`, `curl`, and `sudo`
- Optional: an SSH key in `~/.ssh` — with one, `install` switches the repo
  remote to SSH and pulls the private submodule; without one both are skipped

## Setup

```sh
git clone https://github.com/danilrwx/dotfiles ~/dotfiles
cd ~/dotfiles && ./install            # CLI tools only
cd ~/dotfiles && ./install --desktop  # plus the i3 and dwm desktop and GUI apps
./debloat -n && ./debloat             # once, after --desktop: drop GNOME and snapd
```

`--skip-go` and `--skip-ts` leave the Go tools and the treesitter parsers as they
are, for a quick rerun after a config change.

`./install` can be run from any directory and again at any time; it symlinks
the configs and installs the tool set:

- system CLIs from `apt`: `zsh`, `git`, `tmux`, `gnupg`, `fzf`, `jq`, `ripgrep`,
  `ugrep`, `fd`, `htop`, `fastfetch`, `go`, `clangd`, `neovim`, `nodejs`/`npm`
- Go-based CLIs and dev tools via `go install` through proxy.golang.org:
  `gh`, `glab`, `helm`, `k9s`, `yq`, `lazygit`, `crane`, `task`,
  `golangci-lint`, `gopls`, `gofumpt`, `goimports`, `dlv`, `moq`, `ginkgo`,
  `helm-ls`, `golangci-lint-langserver`

`kubectl` comes from dl.k8s.io (checked against its sha256); `d8` and `claude`
use their own installers. It also installs Docker (get.docker.com) and joins the
`docker` group, sets `zsh` as the login shell, and installs the Caps Lock as Ctrl
hwdb rule (`config/hwdb`).

On a HONOR MagicBook Pro 14 2026 (`ZQC-P`) it also clones
[honor-magicbook-pro-14-2026-ubuntu](https://github.com/danilrwx/honor-magicbook-pro-14-2026-ubuntu)
into `~/w` and runs its `apply_patch.sh` without the DSC fix, which is a no-op
once a revision has been applied.

`./install --desktop` adds:

- i3 on X11 (`config/i3`) with `bin/wm-status` in i3bar: dmenu, dunst (`config/dunst`),
  i3lock/xss-lock, maim, xclip, the volume/brightness cards and HONOR Fn keys through
  `bin/wm-fnkeys`, `Xft.dpi` for the scale (`.Xresources`), the touchpad in xorg.conf.d
- dwm and st, my own builds from github.com/danilrwx/{dwm,st} in `~/w`, as the second
  session: the X11 setup of i3 and `bin/wm-status` as the status text; dwm's own
  config binds the media, Fn and menu keys to the same `bin/` scripts. st is the terminal in both
- Openbox (`config/openbox`) as a stacking third session: dwm's keys, `$mod+h/l` for the screen
  halves, no titlebars (theme in `config/openbox-theme`) and a dzen2 bar (`bin/ob-bar`) with the
  desktops, `bin/wm-status` and stalonetray
- greetd with tuigreet as the login, offering i3, dwm and Openbox and remembering the pick; the
  session environment comes from `.profile`
- iwd for Wi-Fi instead of NetworkManager (saved networks are moved over), systemd-networkd for
  the wire; `$mod+x` picks impala or bluetui (Wi-Fi, Bluetooth), the sound output or input,
  the Bluetooth headset mode (headphones or handsfree) or the power profile
- Iosevka (fonts-iosevka), Symbols Nerd Font Mono and Apple Color Emoji
- ssh through the plain `ssh-agent` with OpenSSH's GTK3 askpass
  (`ssh-askpass-gnome`, per-use confirm too) instead of gcr's agent
- Google Chrome from Google's .deb (their apt repo comes with it), set as the default
  browser; Telegram from its self-updating tarball in `~/.local/opt`, Discord from
  its .deb (a rerun updates it), virt-manager (and the `libvirt` group), Steam from
  multiverse's `steam-installer`

`./debloat` then removes every snap and snapd (pinned out of apt), GNOME, GDM and
the ~350 packages only the Ubuntu desktop metapackages pulled in, keeping what
the i3 and dwm sessions need (iwd, Bluetooth, sound, fingerprint, power profiles,
the keyring). It also takes the old sway stack and kitty, NetworkManager, ibus and
the extra dictionaries, disables ModemManager, cups-browsed and the Ubuntu Pro and
MOTD timers, and clears what the removed apps left in `~/.config`. `-n` shows all of it without changing
anything; it refuses to run before greetd is enabled.

## Layout

| Path | What |
|---|---|
| `install` | host setup (symlinks, packages, go tools, the i3 and dwm desktop); `bin/dotfiles-update` is the same script on PATH |
| `debloat` | one-off: strip GNOME, snapd and the unused rest from a stock Ubuntu desktop |
| `bin/tmux-extract` | `prefix Tab`: fuzzy-pick a word/path/url from the pane |
| `bin/tmux-ru-keys` | mirror tmux bindings onto the Russian layout |
| `bin/agent-watch` | `prefix A`: watch another tmux session in a split |
| `bin/wm-fnkeys` | volume/brightness as a dunst card, HONOR Fn-key actions and cards |
| `bin/wm-ctl` | `$mod+x`: Wi-Fi (impala), Bluetooth (bluetui), sound output and input, headset mode, power profile |
| `bin/wm-status` | i3bar and dwm status line: memory, volume, mic, battery, brightness, layout, date |
| `bin/wm-menu` | dmenu in the old colours: the launcher, and `pick` for the menus |
| `bin/clip` | stdin to the clipboard through xclip (tmux, nvim, screenshots) |
| `bin/x-autostart` | the X11 session setup: keyboard, Xresources, notifications, polkit agent, idle/lock |
| `bin/ob-bar` | the Openbox bar: dzen2 with the desktops and `wm-status`, stalonetray as the tray |
| `bin/dwm-session` | the dwm session: `x-autostart`, `wm-status` as the status text, dwm |
| `bin/screenshot-select` | region screenshot into the clipboard |
| `bin/sys-notify`, `bin/cal-notify` | load/memory/battery and a calendar as a notification |
