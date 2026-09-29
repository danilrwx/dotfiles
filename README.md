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

`./install` can be run from any directory and again at any time; it symlinks
the configs and installs the tool set:

- system CLIs from `apt` on Ubuntu or `brew` on macOS: `tmux`, `gnupg`, `fzf`,
  `jq`, `ripgrep`, `ugrep`, `fd`, `htop`, `go`, `neovim`, `nodejs`/`npm`; on
  Ubuntu also `zsh`, `git`, `clangd` (macOS has them), and `neovim` from a
  GitHub tarball when the archive's build is older than 0.11
- Go-based CLIs and dev tools via `go install` through proxy.golang.org:
  `gh`, `glab`, `helm`, `k9s`, `yq`, `lazygit`, `crane`, `task`,
  `golangci-lint`, `gopls`, `gofumpt`, `goimports`, `dlv`, `moq`, `ginkgo`,
  `helm-ls`, `golangci-lint-langserver`

`kubectl` comes from dl.k8s.io on Linux (checked against its sha256), brew on
macOS; `d8` and `claude` use their own installers. On Linux it also installs
Docker (get.docker.com) and joins the `docker` group, sets `zsh` as the login
shell, and installs the Caps Lock as Ctrl hwdb rule (`config/hwdb`).

On a HONOR MagicBook Pro 14 2026 (`ZQC-P`) it also clones
[honor-magicbook-pro-14-2026-ubuntu](https://github.com/danilrwx/honor-magicbook-pro-14-2026-ubuntu)
into `~/w` and runs its `apply_patch.sh` without the headset-mic and DSC fixes,
which is a no-op once a revision has been applied. From a running GNOME session
it also sets two-finger click as right click on the touchpad.

`./install --desktop` is Ubuntu-only and adds:

- wl-clipboard for `bin/tmux-clip-sync` (Ptyxis drops OSC 52), the Iosevka Nerd
  Font for Ptyxis and Apple Color Emoji
- virt-manager (and the `libvirt` group), Telegram and Discord from snap, Steam
  from multiverse's `steam-installer`, the VM guest agents inside a VM
- the vanilla "GNOME" session with the stock Adwaita look and a dark theme
  (pick it in the GDM gear once); the tray extension is added to the enabled ones
- ssh through the plain `ssh-agent` with a GTK4 askpass (`bin/askpass`, zenity) instead of gcr's agent,
  pinned by a `Match` block appended to `~/.ssh/config`

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
| `install` | host setup (symlinks, packages, go tools); `bin/dotfiles-update` is the same script on PATH |
| `bin/clip` | pipe stdin to the local clipboard over OSC 52 |
| `bin/tmux-extract` | `prefix Tab`: fuzzy-pick a word/path/url from the pane |
| `bin/tmux-ru-keys` | mirror tmux bindings onto the Russian layout |
| `bin/askpass` | ssh-askpass on zenity (GTK4): passphrase, per-use confirm, security-key notice |
| `bin/tmux-clip-sync` | every tmux buffer into the desktop clipboard (wl-copy, pbcopy), since Ptyxis/VTE and Terminal.app drop OSC 52 |
| `bin/agent-watch` | `prefix A`: watch another tmux session in a split |
| `bin/sway-fnkeys` | HONOR Fn-key actions and OSD under sway |
| `server/install.sh` | base vim/tmux config + clipboard (OSC 52) for any server |
