# Global dev container image, built for linux/amd64 in CI and pushed to
# ghcr.io/danilrwx/devbox. Projects reference it via image: in devcontainer.json.
FROM golang:1.25-bookworm

SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

ARG NODE_MAJOR=22
ARG USERNAME=v12n
ARG UID=1000
ARG GID=1000

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl git openssh-client jq make gnupg unzip sudo vim tmux \
 && install -m0755 -d /etc/apt/keyrings \
 && curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc \
 && chmod a+r /etc/apt/keyrings/docker.asc \
 && arch="$(dpkg --print-architecture)" \
 && echo "deb [arch=${arch} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian bookworm stable" \
      > /etc/apt/sources.list.d/docker.list \
 && curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash - \
 && apt-get install -y --no-install-recommends docker-ce-cli docker-buildx-plugin nodejs \
 && rm -rf /var/lib/apt/lists/*

# task, yq, werf, kubectl, d8, claude-code, helm, golangci-lint, gh
RUN arch="$(dpkg --print-architecture)" \
 && sh -c "$(curl -fsSL https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin \
 && curl -fsSL "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${arch}" -o /usr/local/bin/yq \
 && chmod +x /usr/local/bin/yq \
 && werf_ver="$(curl -fsSL https://tuf.werf.io/targets/channels/2/stable)" \
 && curl -fsSL "https://tuf.werf.io/targets/releases/${werf_ver}/linux-${arch}/bin/werf" -o /usr/local/bin/werf \
 && chmod +x /usr/local/bin/werf \
 && kube_ver="$(curl -fsSL https://dl.k8s.io/release/stable.txt)" \
 && curl -fsSL "https://dl.k8s.io/release/${kube_ver}/bin/linux/${arch}/kubectl" -o /usr/local/bin/kubectl \
 && chmod +x /usr/local/bin/kubectl \
 && d8_ver="$(curl -fsSL https://api.github.com/repos/deckhouse/deckhouse-cli/releases/latest | grep '"tag_name"' | cut -d'"' -f4)" \
 && d8_tmp="$(mktemp -d)" \
 && curl -fsSL "https://github.com/deckhouse/deckhouse-cli/releases/download/${d8_ver}/d8-${d8_ver}-linux-${arch}.tar.gz" | tar -xz -C "$d8_tmp" \
 && install "$(find "$d8_tmp" -type f -name d8)" /usr/local/bin/d8 \
 && npm install -g @anthropic-ai/claude-code \
 && curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash \
 && curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/HEAD/install.sh | sh -s -- -b /usr/local/bin \
 && mkdir -p -m0755 /etc/apt/keyrings \
 && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o /etc/apt/keyrings/githubcli.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list \
 && apt-get update && apt-get install -y --no-install-recommends gh && rm -rf /var/lib/apt/lists/*

# Go dev tools (into /usr/local/bin so all users see them).
RUN GOBIN=/usr/local/bin go install github.com/onsi/ginkgo/v2/ginkgo@v2.14.0 \
 && GOBIN=/usr/local/bin go install mvdan.cc/gofumpt@latest \
 && GOBIN=/usr/local/bin go install golang.org/x/tools/cmd/goimports@latest \
 && GOBIN=/usr/local/bin go install golang.org/x/tools/gopls@latest \
 && GOBIN=/usr/local/bin go install github.com/matryer/moq@latest \
 && GOBIN=/usr/local/bin go install github.com/google/go-containerregistry/cmd/crane@latest

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
RUN arch="$(dpkg --print-architecture)" \
 && tmp="$(mktemp -d)" \
 && curl -fsSL "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew-linux_${arch}.tar.gz" | tar -xz -C "$tmp" \
 && "$tmp/krew-linux_${arch}" install krew \
 && export PATH="${HOME}/.krew/bin:$PATH" \
 && kubectl krew install ctx ns df-pv
