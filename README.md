# dotfiles

Personal dotfiles for macOS and Ubuntu.

## Requirements

- **macOS**, or **Ubuntu** (`install` exits on other distros)
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

- system CLIs from `apt` on Ubuntu or `brew` on macOS: `zsh`, `git`, `tmux`,
  `gnupg`, `fzf`, `jq`, `ripgrep`, `ugrep`, `htop`, `clangd`, `go`, `neovim`
  (a GitHub tarball when the archive's build is older than 0.11)
- Go-based CLIs and dev tools via `go install` through proxy.golang.org:
  `gh`, `glab`, `helm`, `k9s`, `yq`, `lazygit`, `crane`, `task`,
  `golangci-lint`, `gopls`, `gofumpt`, `goimports`, `dlv`, `moq`, `ginkgo`,
  `helm-ls`, `golangci-lint-langserver`

`kubectl` comes from dl.k8s.io on Linux, `d8` and `claude` use their own
installers. The script also sets `zsh` as the login shell.

On a HONOR MagicBook Pro 14 2026 (`ZQC-P`) it also clones
[honor-magicbook-pro-14-2026-ubuntu](https://github.com/danilrwx/honor-magicbook-pro-14-2026-ubuntu)
into `~/w` and runs its `apply_patch.sh`, which is a no-op once a revision has
been applied. From a running GNOME session it also sets two-finger click as
right click on the touchpad and Caps Lock as Ctrl.

`./install --desktop` adds virt-manager, Telegram and Discord from their
self-updating official tarballs, Steam from Valve's .deb, and the VM guest
agents when running inside a VM.

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
| `install` | host setup (symlinks, packages, go tools) |
| `bin/clip` | pipe stdin to the local clipboard over OSC 52 |
| `server/install.sh` | base vim/tmux config + clipboard (OSC 52) for any server |
