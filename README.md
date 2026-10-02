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
cd ~/dotfiles && ./install --desktop  # plus the i3 desktop and GUI apps
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
use their own installers. It also installs Docker from the archive (`docker.io`, compose, buildx) and joins the
`docker` group, sets `zsh` as the login shell, and installs the Caps Lock as Ctrl
hwdb rule (`etc/udev/hwdb.d`).

On a HONOR MagicBook Pro 14 2026 (`ZQC-P`) it also clones
[honor-magicbook-pro-14-2026-ubuntu](https://github.com/danilrwx/honor-magicbook-pro-14-2026-ubuntu)
into `~/w` and runs its `apply_patch.sh` without the DSC fix, which is a no-op
once a revision has been applied.

`./install --desktop` adds:

- i3 on X11 (`config/i3`) with `bin/wm-status` in i3bar: dmenu, dunst (`config/dunst`),
  i3lock/xss-lock, maim, xclip, the volume/brightness cards and HONOR Fn keys through
  `bin/wm-fnkeys`, `Xft.dpi` for the scale (`.Xresources`), the touchpad in xorg.conf.d
- st, my own build from github.com/danilrwx/st in `~/w`, as the terminal
- greetd with tuigreet as the login, starting i3 and remembering the user; the
  session environment comes from `.profile`
- iwd for Wi-Fi instead of NetworkManager (saved networks are moved over), systemd-networkd for
  the wire; `$mod+x` picks impala or bluetui (Wi-Fi, Bluetooth), the sound output or input,
  the Bluetooth headset mode (headphones or handsfree), the VPN, the theme or the power profile
- themes (`bin/theme`): dark, black and solid, or dark-wall, the same colours over a wallpaper from
  `~/Pictures/wallpapers` (a random one on each start of i3) with the terminal and the bar see-through
  under xcompmgr
- mihomo as the VLESS client (`bin/vless`, `config/mihomo`, the servers and subscriptions in `private`):
  through TUN or as the system proxy, the rule mode (Russia direct) or global, the profile; its state
  in the bar
- OpenVPN (`bin/openvpn-ctl`): the profiles from `private/config/openvpn` as openvpn-client units, started
  from ctl without sudo (a polkit rule), the server's DNS for systemd-resolved, the profile up in the bar
- fonts from the archive alone: Iosevka for the text, Noto Color Emoji for the bar's icons and the rest
- ssh through the plain `ssh-agent` with OpenSSH's GTK3 askpass
  (`ssh-askpass-gnome`, per-use confirm too) instead of gcr's agent
- Google Chrome from Google's .deb (their apt repo comes with it), set as the default
  browser; Telegram from its self-updating tarball in `~/.local/opt`, Discord from
  its .deb (a rerun updates it), virt-manager (and the `libvirt` group), Steam from
  multiverse's `steam-installer`

`./debloat` then removes every snap and snapd (pinned out of apt), GNOME, GDM and
the ~350 packages only the Ubuntu desktop metapackages pulled in, keeping what
the i3 session needs (iwd, Bluetooth, sound, fingerprint, power profiles,
the keyring). It also takes the old sway stack and kitty, NetworkManager, ibus and
the extra dictionaries, disables ModemManager, cups-browsed and the Ubuntu Pro and
MOTD timers, and clears what the removed apps left in `~/.config`. `-n` shows all of it without changing
anything; it refuses to run before greetd is enabled.

## Layout

| Path | What |
|---|---|
| `install` | host setup (symlinks, packages, go tools, the i3 desktop); `bin/dotfiles-update` is the same script on PATH |
| `etc/` | files `install` puts into `/etc` as they are: iwd, netplan, the touchpad, greetd, the Caps as Ctrl hwdb rule, the polkit rule for the VPN's DNS |
| `debloat` | one-off: strip GNOME, snapd and the unused rest from a stock Ubuntu desktop |
| `bin/tmux-extract` | `prefix Tab`: fuzzy-pick a word/path/url from the pane |
| `bin/tmux-ru-keys` | mirror tmux bindings onto the Russian layout |
| `bin/agent-watch` | `prefix A`: watch another tmux session in a split |
| `bin/wm-fnkeys` | volume/brightness as a dunst card, HONOR Fn-key actions and cards |
| `bin/wm-ctl` | `$mod+x`: Wi-Fi (impala), Bluetooth (bluetui), sound output and input, headset mode, power profile |
| `bin/vless` | the VLESS client: mihomo on through TUN or as the system proxy, off, rule/global, the profile |
| `bin/theme` | dark, or dark-wall: a wallpaper under a see-through terminal and bar; `shuffle` picks one at random |
| `bin/openvpn-ctl` | OpenVPN: a profile from `private/config/openvpn` up or down, its state for the bar |
| `bin/wm-status` | i3bar's status line: memory, volume, mic, battery, brightness, layout, date |
| `bin/wm-menu` | dmenu in the old colours: the launcher, and `pick` for the menus |
| `bin/clip` | stdin to the clipboard through xclip (tmux, nvim, screenshots) |
| `bin/x-autostart` | the X11 session setup: keyboard, Xresources, notifications, polkit agent, idle/lock |
| `bin/screenshot-select` | region screenshot into the clipboard |
| `bin/sys-notify`, `bin/cal-notify` | load/memory/battery and a calendar as a notification |
