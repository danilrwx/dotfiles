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
cd ~/dotfiles && ./install --desktop  # plus the sway desktop and GUI apps
./debloat -n && ./debloat             # once, after --desktop: drop GNOME and snapd
```

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

- sway with the old i3 config ported to Wayland (`config/sway`): swaybar with
  `bin/swaybar-status`, wmenu, mako (`config/mako`), swaylock/swayidle, wob as
  the volume/brightness bar and the HONOR Fn keys through `bin/sway-fnkeys`,
  grim+slurp screenshots, foot as the terminal (`config/foot`, one server)
- greetd with tuigreet as the login, starting sway
- the Iosevka Nerd Font and Apple Color Emoji
- ssh through the plain `ssh-agent` with OpenSSH's GTK3 askpass
  (`ssh-askpass-gnome`, per-use confirm too) instead of gcr's agent
- Google Chrome from Google's .deb (their apt repo comes with it), set as the default
  browser; Telegram from its self-updating tarball in `~/.local/opt`, Discord from
  its .deb (a rerun updates it), virt-manager (and the `libvirt` group), Steam from
  multiverse's `steam-installer`

`./debloat` then removes every snap and snapd (pinned out of apt), GNOME, GDM and
the ~350 packages only the Ubuntu desktop metapackages pulled in, keeping what
the sway session needs (network, Bluetooth, sound, fingerprint, power profiles,
Xwayland, the keyring). `-n` shows the list without changing
anything; it refuses to run before greetd is enabled.

## Layout

| Path | What |
|---|---|
| `install` | host setup (symlinks, packages, go tools, the sway desktop); `bin/dotfiles-update` is the same script on PATH |
| `debloat` | one-off: strip GNOME and snapd from a stock Ubuntu desktop |
| `bin/tmux-extract` | `prefix Tab`: fuzzy-pick a word/path/url from the pane |
| `bin/tmux-ru-keys` | mirror tmux bindings onto the Russian layout |
| `bin/agent-watch` | `prefix A`: watch another tmux session in a split |
| `bin/sway-fnkeys` | volume/brightness to wob, HONOR Fn-key actions and mako cards under sway |
| `bin/sway-autostart` | sway session daemons: mako, foot server, wob, polkit agent, nm-applet, swayidle |
| `bin/swaybar-status` | swaybar line: memory, volume, mic, battery, brightness, layout, date |
| `bin/sway-menu` | wmenu-run with the dmenu colours and the full PATH |
| `bin/screenshot-select` | region screenshot into the clipboard |
| `bin/sys-notify`, `bin/cal-notify` | load/memory/battery and a calendar as a notification |
