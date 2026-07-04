# Global dev container image (Debian base + Homebrew/linuxbrew — the same tools
# as the macOS host come from brew). Built for linux/amd64 in CI (a native amd64
# runner, since Homebrew's Portable Ruby has no build for the QEMU-emulated
# processor) and pushed to ghcr.io/danilrwx/devbox. Tool installs are delegated
# to tools/*.sh (shared with dotfiles/install); each phase is COPYed right before
# its RUN so editing one script only rebuilds that layer.
FROM debian:bookworm-slim

SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

ARG USERNAME=v12n
ARG UID=1000
ARG GID=1000

# Homebrew/linuxbrew prerequisites + runtime essentials.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential procps curl file git ca-certificates sudo locales less \
 && sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen && locale-gen \
 && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8

# Unprivileged user; gid 0 for the Docker Desktop docker.sock and ssh-agent
# socket (both root:root 0660). Passwordless sudo.
RUN groupadd -g "${GID}" "${USERNAME}" \
 && useradd -m -u "${UID}" -g "${GID}" -s /bin/bash "${USERNAME}" \
 && usermod -aG root "${USERNAME}" \
 && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/"${USERNAME}" \
 && chmod 0440 /etc/sudoers.d/"${USERNAME}"

USER ${USERNAME}
ENV HOME=/home/${USERNAME}

# Homebrew on Linux, then put it (and go/krew bin dirs) on PATH for later layers.
RUN NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
ENV PATH=/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${HOME}/go/bin:${HOME}/.krew/bin:${PATH}

ENV LIB=/usr/local/lib/devbox
COPY tools/common.sh ${LIB}/common.sh

# brew tools, then the few non-brew binaries — separate COPY+RUN so a change to
# one does not invalidate the other's cached layer.
COPY tools/repo.sh ${LIB}/repo.sh
RUN bash ${LIB}/repo.sh
COPY tools/binaries.sh ${LIB}/binaries.sh
RUN bash ${LIB}/binaries.sh

# go-installed tools (~/go/bin) and krew plugins (~/.krew) — separate layers.
COPY tools/go.sh ${LIB}/go.sh
RUN bash ${LIB}/go.sh
COPY tools/krew.sh ${LIB}/krew.sh
RUN bash ${LIB}/krew.sh

# claude-code via the brew-provided node.
RUN npm install -g @anthropic-ai/claude-code

# GPG needs a tty for the pinentry passphrase prompt. The agent itself is
# forwarded from the host by DevPod, so no keys are copied into the image.
RUN echo 'export GPG_TTY=$(tty)' | sudo tee /etc/profile.d/gpg.sh

# Clone dotfiles (public, shallow, no private submodules) and symlink the
# CLI/shell configs. Refreshed on image rebuild; recreate the home volume to pick
# up changes.
COPY links.sh /usr/local/lib/devbox-links.sh
COPY shell-setup.sh /usr/local/lib/devbox-shell-setup.sh
RUN git clone --depth 1 https://github.com/danilrwx/dotfiles.git "${HOME}/dotfiles" \
 && bash /usr/local/lib/devbox-links.sh \
 && bash /usr/local/lib/devbox-shell-setup.sh

# Working dir mirrors the host ~/w layout so relative go-replace paths match.
RUN mkdir -p "${HOME}/w"

# Match the module's go version (brew ships newer go); toolchain is fetched on
# first build. Set after the go installs above so they use brew's go directly.
ENV GOTOOLCHAIN=go1.25.11
