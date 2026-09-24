# dotfiles

Personal dotfiles for macOS and Linux (Debian / Ubuntu).

## Requirements

- **macOS**, or **Linux** (Debian / Ubuntu — `install` exits on other distros)
- `git`, `curl`, and `sudo` on Linux
- macOS: Homebrew is bootstrapped by `install` if missing. Linux uses the distro
  packages only
- Optional: an SSH key in `~/.ssh` — with one, `install` switches the repo
  remote to SSH and pulls the private submodule; without one both are skipped

## Setup

```sh
git clone https://github.com/danilrwx/dotfiles ~/dotfiles
cd ~/dotfiles && ./install
```

`./install` symlinks the configs, installs the system CLIs (`zsh`, `git`, `tmux`,
`fzf`, `jq`, `gnupg`) from brew/apt, and everything else (Go, Node, `neovim`,
`kubectl`, `helm`, `gh`, `glab`, `golangci-lint`, `gopls`, the LSP servers, …)
through [mise](https://mise.jdx.dev) from `config/mise/config.toml`. `d8` and
`claude` use their own installers. It also sets `zsh` as the login shell.

On a bare Debian netinst (no desktop task selected) run `./install --desktop`
instead: it additionally installs X11, lightdm, and the i3 desktop stack mirroring
the Fedora i3 Spin comps group (i3status, nm-applet, mousepad, pavucontrol,
volumeicon, firefox, pipewire, fonts, firmware) and enables lightdm and
NetworkManager.

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
| `install` | host setup (symlinks, packages, mise tools) |
| `config/mise/config.toml` | languages and CLIs pinned for mise |
| `bin/clip` | pipe stdin to the local clipboard over OSC 52 |
| `server/install.sh` | base vim/tmux config + clipboard (OSC 52) for any server |
