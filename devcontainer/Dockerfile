# Global dev container image (Fedora base — most tools come from dnf), built for
# linux/amd64 in CI and pushed to ghcr.io/danilrwx/devbox.
FROM fedora:44

SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

ARG NODE_MAJOR=22
ARG USERNAME=v12n
ARG UID=1000
ARG GID=1000

# Most tools straight from dnf.
RUN dnf install -y --setopt=install_weak_deps=False \
      golang go-task yq helm golangci-lint k9s gh gopls \
      golang-x-tools-goimports delve \
      docker-cli git-core tmux vim-enhanced jq make gnupg2 unzip sudo \
      openssh-clients bsdtar findutils procps-ng which \
 && dnf clean all \
 && ln -sf /usr/bin/go-task /usr/local/bin/task

# node (nodesource) + claude-code
RUN curl -fsSL "https://rpm.nodesource.com/setup_${NODE_MAJOR}.x" | bash - \
 && dnf install -y nodejs \
 && dnf clean all \
 && npm install -g @anthropic-ai/claude-code

# Not in dnf: kubectl, werf, d8; plus go-installed ginkgo (pinned), gofumpt, moq, crane.
RUN arch="$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')" \
 && kube_ver="$(curl -fsSL https://dl.k8s.io/release/stable.txt)" \
 && curl -fsSL "https://dl.k8s.io/release/${kube_ver}/bin/linux/${arch}/kubectl" -o /usr/local/bin/kubectl \
 && chmod +x /usr/local/bin/kubectl \
 && werf_ver="$(curl -fsSL https://tuf.werf.io/targets/channels/2/stable)" \
 && curl -fsSL "https://tuf.werf.io/targets/releases/${werf_ver}/linux-${arch}/bin/werf" -o /usr/local/bin/werf \
 && chmod +x /usr/local/bin/werf \
 && d8_ver="$(curl -fsSL https://api.github.com/repos/deckhouse/deckhouse-cli/releases/latest | grep '"tag_name"' | cut -d'"' -f4)" \
 && d8_tmp="$(mktemp -d)" \
 && curl -fsSL "https://github.com/deckhouse/deckhouse-cli/releases/download/${d8_ver}/d8-${d8_ver}-linux-${arch}.tar.gz" | bsdtar -xzf - -C "$d8_tmp" \
 && install "$(find "$d8_tmp" -type f -name d8)" /usr/local/bin/d8 \
 && GOBIN=/usr/local/bin go install github.com/onsi/ginkgo/v2/ginkgo@v2.14.0 \
 && GOBIN=/usr/local/bin go install mvdan.cc/gofumpt@latest \
 && GOBIN=/usr/local/bin go install github.com/matryer/moq@latest \
 && GOBIN=/usr/local/bin go install github.com/google/go-containerregistry/cmd/crane@latest \
 && rm -rf /root/go /root/.cache

# Match the module's go version (Fedora ships a newer go; the toolchain is
# fetched on first build into the persistent home). Set after the go installs
# above so they use Fedora's go directly.
ENV GOTOOLCHAIN=go1.25.11

# Unprivileged user; gid 0 for docker.sock and the forwarded ssh-agent (both
# exposed by Docker Desktop as root:root 0660). Passwordless sudo.
RUN groupadd -g "${GID}" "${USERNAME}" \
 && useradd -m -u "${UID}" -g "${GID}" -s /bin/bash "${USERNAME}" \
 && usermod -aG root "${USERNAME}" \
 && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/"${USERNAME}" \
 && chmod 0440 /etc/sudoers.d/"${USERNAME}"

USER ${USERNAME}

# Working dir mirrors the host ~/w layout so relative go-replace paths match.
RUN mkdir -p "/home/${USERNAME}/w"

# krew + ctx/ns/df-pv plugins (user-scope ~/.krew; PATH set via remoteEnv).
RUN arch="$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')" \
 && tmp="$(mktemp -d)" \
 && curl -fsSL "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew-linux_${arch}.tar.gz" | bsdtar -xzf - -C "$tmp" \
 && "$tmp/krew-linux_${arch}" install krew \
 && export PATH="${HOME}/.krew/bin:$PATH" \
 && kubectl krew install ctx ns df-pv
