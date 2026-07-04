# Global dev container image (Fedora base — most tools come from dnf), built for
# linux/amd64 in CI and pushed to ghcr.io/danilrwx/devbox. Tool installs are
# delegated to tools/*.sh (shared with dotfiles/install). Each phase is COPYed
# right before its RUN so editing one script only rebuilds that layer.
FROM fedora:44

SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

ARG NODE_MAJOR=22
ARG USERNAME=v12n
ARG UID=1000
ARG GID=1000

ENV LIB=/usr/local/lib/devbox
COPY tools/common.sh ${LIB}/common.sh

# Repo packages, then non-packaged binaries — separate COPY+RUN so a change to
# one does not invalidate the other's cached layer.
COPY tools/repo.sh ${LIB}/repo.sh
RUN bash ${LIB}/repo.sh
COPY tools/binaries.sh ${LIB}/binaries.sh
RUN bash ${LIB}/binaries.sh

# node (nodesource) + claude-code — container-specific.
RUN curl -fsSL "https://rpm.nodesource.com/setup_${NODE_MAJOR}.x" | bash - \
 && dnf install -y nodejs \
 && dnf clean all \
 && npm install -g @anthropic-ai/claude-code

# GPG needs a tty for the pinentry passphrase prompt. The agent itself is
# forwarded from the host by DevPod, so no keys are copied into the image.
RUN echo 'export GPG_TTY=$(tty)' > /etc/profile.d/gpg.sh

COPY links.sh /usr/local/lib/devbox-links.sh

# Unprivileged user; gid 0 for docker.sock and the forwarded ssh-agent (both
# exposed by Docker Desktop as root:root 0660). Passwordless sudo.
RUN groupadd -g "${GID}" "${USERNAME}" \
 && useradd -m -u "${UID}" -g "${GID}" -s /bin/bash "${USERNAME}" \
 && usermod -aG root "${USERNAME}" \
 && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/"${USERNAME}" \
 && chmod 0440 /etc/sudoers.d/"${USERNAME}"

USER ${USERNAME}

# go-installed tools (~/go/bin) and krew plugins (~/.krew) — separate layers.
COPY tools/go.sh ${LIB}/go.sh
RUN bash ${LIB}/go.sh
COPY tools/krew.sh ${LIB}/krew.sh
RUN bash ${LIB}/krew.sh

# Clone dotfiles (public, shallow, no private submodules) and symlink the
# CLI/shell configs. Refreshed on image rebuild; recreate the home volume to pick
# up changes.
COPY shell-setup.sh /usr/local/lib/devbox-shell-setup.sh
RUN git clone --depth 1 https://github.com/danilrwx/dotfiles.git "/home/${USERNAME}/dotfiles" \
 && bash /usr/local/lib/devbox-links.sh \
 && bash /usr/local/lib/devbox-shell-setup.sh

# Working dir mirrors the host ~/w layout so relative go-replace paths match.
RUN mkdir -p "/home/${USERNAME}/w"

# Match the module's go version (Fedora ships newer go); toolchain is fetched on
# first build. Set after go installs above so they use Fedora's go directly.
ENV GOTOOLCHAIN=go1.25.11
