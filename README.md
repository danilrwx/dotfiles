# dotfiles

Personal dotfiles for macOS and Linux (RED OS / Ubuntu).

## Requirements

- **macOS**, or **Linux** (RED OS / Ubuntu — `install` exits on other distros)
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

`./install` symlinks the configs, installs the host tools (`zsh`, `git`, `tmux`,
`fzf`, `neovim`, `kubectl`, `gh`, `d8`, `claude`, the Go toolchain and dev tools)
and sets `zsh` as the login shell.

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
| `install` | host setup (symlinks, packages, host tools) |
| `bin/clip` | pipe stdin to the local clipboard over OSC 52 |
| `server/install.sh` | base vim/tmux config + clipboard (OSC 52) for any server |
