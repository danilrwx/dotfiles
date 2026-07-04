# Global dev container image (Debian base; tools from apt + static binaries + go
# install — no Homebrew, so the image stays small). Built for linux/amd64 in CI
# and pushed to ghcr.io/danilrwx/devbox. Tool installs are split into tools/*.sh;
# each phase is COPYed right before its RUN so editing one only rebuilds its
# layer. This image is the dev/build environment — the host stays thin.
FROM debian:trixie-slim

SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

ARG USERNAME=v12n
ARG UID=1000
ARG GID=1000

ENV LIB=/usr/local/lib/devbox
ENV PATH=/usr/local/go/bin:/home/${USERNAME}/go/bin:${PATH}

# Bootstrap: enough to run the tool scripts and set the locale.
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl sudo locales \
 && sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen && locale-gen \
 && rm -rf /var/lib/apt/lists/*
ENV LANG=en_US.UTF-8

COPY tools/common.sh ${LIB}/common.sh

# apt CLI packages, then the go toolchain + static ops binaries — separate
# COPY+RUN so a change to one does not invalidate the other's cached layer.
COPY tools/repo.sh ${LIB}/repo.sh
RUN bash ${LIB}/repo.sh
COPY tools/binaries.sh ${LIB}/binaries.sh
RUN bash ${LIB}/binaries.sh

# node (apt) + claude-code + npm-based language servers.
RUN apt-get update \
 && apt-get install -y --no-install-recommends nodejs npm \
 && rm -rf /var/lib/apt/lists/* \
 && npm install -g @anthropic-ai/claude-code bash-language-server typescript-language-server

# Unprivileged user; gid 0 for the Docker Desktop docker.sock and ssh-agent
# socket (both root:root 0660). Passwordless sudo.
RUN groupadd -g "${GID}" "${USERNAME}" \
 && useradd -m -u "${UID}" -g "${GID}" -s /bin/bash "${USERNAME}" \
 && usermod -aG root "${USERNAME}" \
 && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/"${USERNAME}" \
 && chmod 0440 /etc/sudoers.d/"${USERNAME}"

# GPG needs a tty for the pinentry passphrase prompt. The agent itself is
# forwarded from the host by DevPod, so no keys are copied into the image.
RUN echo 'export GPG_TTY=$(tty)' > /etc/profile.d/gpg.sh

USER ${USERNAME}
ENV HOME=/home/${USERNAME}

# go-installed tools (~/go/bin). Run as the target user.
COPY tools/go.sh ${LIB}/go.sh
RUN bash ${LIB}/go.sh

# Clone dotfiles (public, shallow) and symlink the CLI/shell configs. Refreshed
# on image rebuild; recreate the home volume to pick up changes.
COPY links.sh /usr/local/lib/devbox-links.sh
COPY shell-setup.sh /usr/local/lib/devbox-shell-setup.sh
RUN git clone --depth 1 https://github.com/danilrwx/dotfiles.git "${HOME}/dotfiles" \
 && bash /usr/local/lib/devbox-links.sh \
 && bash /usr/local/lib/devbox-shell-setup.sh

# Working dir mirrors the host ~/w layout so relative go-replace paths match.
RUN mkdir -p "${HOME}/w"
