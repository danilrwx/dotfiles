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
  `jq`, `ripgrep`, `ugrep`, `fd`, `htop`, `fastfetch`, `go`, `neovim`, `nodejs`/`npm`; on
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
it also sets two-finger click as right click on the touchpad and `Super+Shift+S`
for the screenshot UI and `Super+Shift+M` for mic mute, as in the old i3 config.

`./install --desktop` is Ubuntu-only and adds:

- wl-clipboard for tmux and nvim copies, the Iosevka Nerd
  Font for Ptyxis and Apple Color Emoji
- Google Chrome from Google's .deb (their apt repo comes with it), set as the default
  browser
- Kontur.Talk from its .deb (no apt repo, the app updates itself)
- virt-manager (and the `libvirt` group), Telegram and Discord from snap, Steam
  from multiverse's `steam-installer`, the VM guest agents inside a VM
- the vanilla "GNOME" session with the stock Adwaita look and a dark theme
  (pick it in the GDM gear once); the tray extension is added to the enabled ones
- ssh through the plain `ssh-agent` with a GTK4 askpass (`bin/askpass`, zenity) instead of gcr's agent,
  pinned by a `Match` block appended to `~/.ssh/config`

## Layout

| Path | What |
|---|---|
| `install` | host setup (symlinks, packages, go tools); `bin/dotfiles-update` is the same script on PATH |
| `bin/tmux-extract` | `prefix Tab`: fuzzy-pick a word/path/url from the pane |
| `bin/tmux-ru-keys` | mirror tmux bindings onto the Russian layout |
| `bin/askpass` | ssh-askpass on zenity (GTK4): passphrase, per-use confirm, security-key notice |
| `bin/agent-watch` | `prefix A`: watch another tmux session in a split |
| `bin/sway-fnkeys` | HONOR Fn-key actions and OSD under sway |
