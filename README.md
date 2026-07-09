# dotfiles

Personal dotfiles plus **devbox** — a global dev container run through
[DevPod](https://devpod.sh) (Docker locally, Kubernetes remotely).

The split is deliberate:

- **Thin host** — a launcher and GUI shell. It has only what must live on the
  host: `docker` + `devpod`, the ssh/gpg agents, GUI apps (terminal, browser,
  fonts), a few ops CLIs (`kubectl`, `d8`, `gh`, `claude`), the Go toolchain +
  dev tools (`gopls`, `golangci-lint`, `dlv`, …) and shell basics (`zsh`,
  `git`, `tmux`, `fzf`, …).
- **Lean container** — the whole dev/build toolchain: Go, `kubectl`/`helm`/`k9s`/
  `werf`/`d8`, linters and language servers, `claude`, etc. Built from Ubuntu in
  CI (no Homebrew) and published to `ghcr.io/danilrwx/devbox`.

Development happens **inside the container**; the host just starts it. The host
ssh-agent and gpg-agent are forwarded in, so git auth and signed commits use the
host keys with no key material copied into the container.

## Requirements

- **macOS**, or **Linux** (Ubuntu / Fedora — `install` exits on other distros)
- `git`, `curl`, and `sudo` on Linux
- **Docker** running — Docker Desktop on macOS; on Linux `install` sets it up
- **Homebrew** — the host CLIs come from `brew`. macOS: `install` bootstraps it if
  missing. Linux: install it first (<https://brew.sh>)
- An SSH key added to GitHub — the repo remote and the container's git auth use
  SSH, with the host ssh-agent forwarded in

The remote Kubernetes flow (`devbox -k`) also needs `kubectl` and a configured
kube context.

## Setup

```sh
git clone https://github.com/danilrwx/dotfiles ~/dotfiles
cd ~/dotfiles && ./install
```

`./install` symlinks the configs, installs the host tools listed above and the
`devpod` CLI, registers the Docker provider, and sets `zsh` as the login shell
(the container uses `zsh` too). The shell config (`.zshrc`/`.zprofile`) is shared
by the host and the container.

## Using the dev container

```sh
devbox            # shell into the local (Docker) container; creates it if needed
devbox up         # start it without attaching
devbox update     # pull the latest image and recreate
devbox down       # stop (data is kept)
devbox delete     # remove the workspace
devbox check      # check the registry for a newer image
devbox help       # full usage
```

Locally `~/w` is bind-mounted into the container. Run `devbox help` for the
full command list.

`up` and `shell` check the registry (throttled to once every 12h) and print a
notice when a newer `:latest` image is published, so you know to run `devbox
update`. `devbox check` forces the check immediately.

### On a remote Kubernetes cluster

Prefix any command with `-k` to use the Kubernetes provider instead of Docker:

```sh
devbox -k provider   # one-time: register the provider for the current kube context
devbox -k shell      # shell into the remote pod
```

The k8s pod has no host bind mounts, so the workspace repos are cloned into a PVC
on first `up`, the kubeconfig is mounted from a Secret, and `~/.ssh/config` is
pushed from the host on each connect. The repos to clone are read from the
private dotfiles submodule (`private/devbox-repos`, one git URL per line) so they
stay out of this public repo. Knobs (env): `DEVBOX_K8S_NS` (default `devbox`),
`DEVBOX_K8S_DISK` (`50Gi`), `DEVBOX_K8S_SC` (storage class).

The container has the `docker` CLI (client only, no daemon in the image).
Locally it uses the host's Docker Desktop via the mounted `/var/run/docker.sock`;
in k8s a privileged `docker:dind` sidecar provides the daemon and `DOCKER_HOST`
points at it — so the cluster must allow privileged pods.

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
| `install` | host setup (symlinks, host tools, devpod) |
| `bin/devbox` | the DevPod wrapper |
| `bin/clip` | pipe stdin to the local clipboard over OSC 52 |
| `server/install.sh` | base vim/tmux config + clipboard (OSC 52) for any server |
| `devcontainer/Dockerfile` | the container image (built in CI) |
| `devcontainer/tools/*.sh` | container tool install phases (apt / binaries / docker / go) |
| `devcontainer/devcontainer*.json` | Docker and Kubernetes devcontainer configs |
| `devcontainer/{links,shell-setup,bootstrap}.sh` | config symlinks, completions, repo clone |

The image is built and pushed by CI (`.github/workflows/devbox.yml`) — it cannot
be built locally on Apple Silicon (the amd64 build needs a native runner).
