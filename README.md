# dotfiles

Personal dotfiles for macOS and Linux (Debian / Ubuntu / Fedora).

## Requirements

- **macOS**, or **Linux** (Debian / Ubuntu / Fedora — `install` exits on other distros)
- `git`, `curl`, and `sudo` on Linux
- macOS: Homebrew is bootstrapped by `install` if missing
- Optional: an SSH key in `~/.ssh` — with one, `install` switches the repo
  remote to SSH and pulls the private submodule; without one both are skipped

## Setup

```sh
git clone https://github.com/danilrwx/dotfiles ~/dotfiles
cd ~/dotfiles && ./install
```

`./install` symlinks the configs and installs the tool set from three sources,
the same on every OS:

- system CLIs from the distro (`apt` on Debian/Ubuntu, `dnf` on Fedora) or
  `brew` on macOS: `zsh`, `git`, `tmux`, `gnupg`, `fzf`, `jq`, `ripgrep`,
  `ugrep`, `htop`, `clangd`, `go`, `neovim` (a GitHub tarball on Debian, whose
  0.10 is too old for the config)
- Go-based CLIs and dev tools via `go install` through proxy.golang.org:
  `gh`, `glab`, `helm`, `k9s`, `yq`, `lazygit`, `crane`, `task`,
  `golangci-lint`, `gopls`, `gofumpt`, `goimports`, `dlv`, `moq`, `ginkgo`,
  `helm-ls`, `golangci-lint-langserver`

`kubectl` comes from dl.k8s.io on Linux, `d8` and `claude` use their own
installers. The script also sets `zsh` as the login shell.

`./install --nvidia` installs the NVIDIA driver with open kernel modules: from
NVIDIA's own Debian repo (Debian's packages stop at 550, too old for RTX 50xx),
`ubuntu-drivers` on Ubuntu, RPM Fusion on Fedora. With Secure Boot on it enrolls
the dkms/akmods signing key via `mokutil`; confirm it in MokManager on reboot.

On a bare Debian netinst (no desktop task selected) run `./install --desktop`
instead: it additionally installs X11, lightdm, and the i3 desktop stack mirroring
the Fedora i3 Spin comps group (i3status, nm-applet, mousepad, pavucontrol,
volumeicon, pipewire, fonts, firmware) and enables NetworkManager. lightdm is
installed only when no display manager is enabled yet, so a distro that already
ships a DE keeps its own.

## Base config on other servers

`server/install.sh` drops a minimal, plugin-free vim + tmux config onto any plain
server to make it feel like home — editing defaults and keymaps, `alt+1..9`
windows and pane nav, plus clipboard over SSH (OSC 52): vim yanks and tmux mouse
selections land on your local clipboard, with a `clip` command to pipe anything
there (`cmd | clip`). No X, no `pbcopy`/`xclip`. Self-contained — paste it into a
server shell, or:

```sh
curl -fsSL https://raw.githubusercontent.com/danilrwx/dotfiles/master/server/install.sh | bash
```

See `server/README.md` for what it installs and the requirements.

## Layout

| Path | What |
|---|---|
| `install` | host setup (symlinks, packages, go/npm tools) |
| `bin/clip` | pipe stdin to the local clipboard over OSC 52 |
| `server/install.sh` | base vim/tmux config + clipboard (OSC 52) for any server |
