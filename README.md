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
cd ~/dotfiles && ./install --desktop  # plus the bspwm desktop and GUI apps
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

- bspwm on Xorg (`config/bspwm`, keys by sxhkd in `config/sxhkd`, started by `bin/x-session`), the panel
  at 2x by `Xft.dpi` (`.Xresources`): polybar (`config/polybar`) with `bin/x-status` and the tray (snixembed
  for the StatusNotifierItem ones), dmenu as the launcher (`bin/x-run`, `$mod+d`), the quick settings
  (`bin/x-ctl`, `$mod+x`: Wi-Fi, Bluetooth, drives, sound, headset, VLESS, OpenVPN, power), dunst for
  notifications and the media and HONOR Fn keys' OSD (`bin/x-fnkeys`), xss-lock with i3lock, redshift as
  the night light (`bin/x-night`), polkit-gnome as the polkit agent
- the colour themes (`bin/theme`, `config/alacritty/colors`): alacritty, tmux, fzf, bat, nvim, k9s, Claude
  by the ANSI slots; bspwm, polybar, dunst, dmenu, Chrome and the root by hex; GTK black, white and grey
  (`config/gtk-3.0/gtk.css`)
- alacritty as the terminal (`config/alacritty`); emoji from Noto Color Emoji after Iosevka
  (`config/fontconfig`)
- greetd with tuigreet as the login, starting bspwm and remembering the user; the
  session environment comes from `.profile`
- iwd for Wi-Fi instead of NetworkManager (saved networks are moved over), systemd-networkd for
  the wire; impala and bluetui as the Wi-Fi and Bluetooth TUIs
- mihomo as the VLESS client (`bin/vless`, `config/mihomo`, the servers and subscriptions in `private`):
  through TUN or as the system proxy, the rule mode (Russia direct) or global, the profile; `$mod+x`
  drives it
- OpenVPN (`bin/openvpn-ctl`): the profiles from `private/config/openvpn` as openvpn-client units, started
  from `$mod+x` without sudo (a polkit rule), the server's DNS for systemd-resolved
- fonts from the archive alone: Iosevka for the text, Noto Color Emoji for the rest
- ssh through the plain `ssh-agent` with OpenSSH's GTK3 askpass
  (`ssh-askpass-gnome`, per-use confirm too) instead of gcr's agent
- Google Chrome from Google's .deb (their apt repo comes with it), set as the default
  browser; Telegram from its self-updating tarball in `~/.local/opt`, Discord from
  its .deb (a rerun updates it), virt-manager (and the `libvirt` group), Steam from
  multiverse's `steam-installer`

`./debloat` then removes every snap and snapd (pinned out of apt), GNOME, GDM and
the ~350 packages only the Ubuntu desktop metapackages pulled in, keeping what
the session needs (iwd, Bluetooth, sound, fingerprint, power profiles,
the keyring). It also takes the other terminals (kitty and the rest), NetworkManager, ibus and
the extra dictionaries, disables ModemManager, cups-browsed and the Ubuntu Pro and
MOTD timers, and clears what the removed apps left in `~/.config`. `-n` shows all of it without changing
anything; it refuses to run before greetd is enabled.

## Layout

| Path | What |
|---|---|
| `install` | host setup (symlinks, packages, go tools, the bspwm desktop); `bin/dotfiles-update` is the same script on PATH |
| `etc/` | files `install` puts into `/etc` as they are: iwd, netplan, greetd, Xorg's touchpad, the Caps as Ctrl hwdb rule and polkit rules |
| `debloat` | one-off: strip GNOME, snapd and the unused rest from a stock Ubuntu desktop |
| `bin/tmux-extract` | `prefix Tab`: fuzzy-pick a word/path/url from the pane |
| `bin/tmux-ru-keys` | mirror tmux bindings onto the Russian layout |
| `bin/agent-watch` | `prefix A`: watch another tmux session in a split |
| `bin/vless` | the VLESS client: mihomo on through TUN or as the system proxy, off, rule/global, the profile |
| `bin/openvpn-ctl` | OpenVPN: a profile from `private/config/openvpn` up or down, its state |
| `bin/clip` | stdin to the clipboard through xclip (tmux, nvim) |
| `bin/x-run` | the dmenu launcher (`$mod+d`): apps by name, `2+2` copied, `s`/`g`/`?` web searches, else a command |
| `bin/x-night` | the night light, 21:00 to 07:00, by redshift's one-shot mode |
| `bin/x-drives` | removable drives in dmenu: mount, or unmount and power off, by udisksctl |
| `bin/x-session` | the session: bspwm (`config/bspwm`) with sxhkd, polybar, dunst, xss-lock with i3lock, picom only for the theme's opacity; `bin/x-status` polybar's text |
| `bin/x-ctl` | `$mod+x`: Wi-Fi, Bluetooth, drives, sound output and input, headset, VLESS, OpenVPN, power profile |
| `bin/x-fnkeys` | the media and HONOR Fn keys, their levels and states as dunst cards |
| `bin/askpass` | ssh's askpass: OpenSSH's GTK3 one, each prompt logged |
