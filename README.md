# dotfiles

Personal dotfiles plus **devbox** — a global dev container run through
[DevPod](https://devpod.sh) (Docker locally, Kubernetes remotely).

The split is deliberate:

- **Thin host** — a launcher and GUI shell. It has only what must live on the
  host: `docker` + `devpod`, the ssh/gpg agents, GUI apps (terminal, browser,
  fonts) and a few ops CLIs (`kubectl`, `d8`, `gh`, `claude`) plus shell
  basics (`zsh`, `git`, `tmux`, `fzf`, …).
- **Lean container** — the whole dev/build toolchain: Go, `kubectl`/`helm`/`k9s`/
  `werf`/`d8`, linters and language servers, `claude`, etc. Built from Ubuntu in
  CI (no Homebrew) and published to `ghcr.io/danilrwx/devbox`.

Development happens **inside the container**; the host just starts it. The host
ssh-agent and gpg-agent are forwarded in, so git auth and signed commits use the
host keys with no key material copied into the container.

## Requirements

- Linux or macOS, `git`
- Docker (Docker Desktop on macOS)

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
devbox help       # full usage
```

Locally `~/w` is bind-mounted into the container. Run `devbox help` for the
full command list.

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

## Layout

| Path | What |
|---|---|
| `install` | host setup (symlinks, host tools, devpod) |
| `bin/devbox` | the DevPod wrapper |
| `devcontainer/Dockerfile` | the container image (built in CI) |
| `devcontainer/tools/*.sh` | container tool install phases (apt / binaries / docker / go) |
| `devcontainer/devcontainer*.json` | Docker and Kubernetes devcontainer configs |
| `devcontainer/{links,shell-setup,bootstrap}.sh` | config symlinks, completions, repo clone |

The image is built and pushed by CI (`.github/workflows/devbox.yml`) — it cannot
be built locally on Apple Silicon (the amd64 build needs a native runner).
