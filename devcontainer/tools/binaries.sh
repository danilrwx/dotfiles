#!/usr/bin/env bash

# Go toolchain and static ops binaries into /usr/local (container image only).
# Runs as root in the build.
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

[ "$OS" = Linux ] || exit 0

latest_tag() { basename "$(curl -fsSLo /dev/null -w '%{url_effective}' "https://github.com/$1/releases/latest")"; }
tmp="$(mktemp -d)"

# go (exact version so it matches go.mod without a toolchain download)
curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz" | $SUDO tar -C /usr/local -xzf -

# kubectl
kube_ver="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
curl -fsSL "https://dl.k8s.io/release/${kube_ver}/bin/linux/${ARCH}/kubectl" | $SUDO tee /usr/local/bin/kubectl >/dev/null
$SUDO chmod +x /usr/local/bin/kubectl

# helm
helm_ver="$(latest_tag helm/helm)"
curl -fsSL "https://get.helm.sh/helm-${helm_ver}-linux-${ARCH}.tar.gz" | tar -xzf - -C "$tmp"
$SUDO install "$tmp/linux-${ARCH}/helm" /usr/local/bin/helm

# k9s
curl -fsSL "https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_${ARCH}.tar.gz" | tar -xzf - -C "$tmp"
$SUDO install "$tmp/k9s" /usr/local/bin/k9s

# yq
curl -fsSL "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${ARCH}" -o "$tmp/yq"
$SUDO install "$tmp/yq" /usr/local/bin/yq

# gh (github release; asset unpacks into gh_<ver>_linux_<arch>/bin/gh)
gh_ver="$(latest_tag cli/cli)"
curl -fsSL "https://github.com/cli/cli/releases/download/${gh_ver}/gh_${gh_ver#v}_linux_${ARCH}.tar.gz" | tar -xzf - -C "$tmp"
$SUDO install "$tmp/gh_${gh_ver#v}_linux_${ARCH}/bin/gh" /usr/local/bin/gh

# glab (gitlab release; asset unpacks into bin/glab)
glab_ver="$(basename "$(curl -fsSLo /dev/null -w '%{url_effective}' https://gitlab.com/gitlab-org/cli/-/releases/permalink/latest)")"
curl -fsSL "https://gitlab.com/gitlab-org/cli/-/releases/${glab_ver}/downloads/glab_${glab_ver#v}_linux_${ARCH}.tar.gz" | tar -xzf - -C "$tmp"
$SUDO install "$tmp/bin/glab" /usr/local/bin/glab

# werf
werf_ver="$(curl -fsSL "https://tuf.werf.io/targets/channels/${WERF_CHANNEL}")"
curl -fsSL "https://tuf.werf.io/targets/releases/${werf_ver}/linux-${ARCH}/bin/werf" | $SUDO tee /usr/local/bin/werf >/dev/null
$SUDO chmod +x /usr/local/bin/werf

# d8 / deckhouse-cli (official installer; default INSTALL_DIR is /opt not on PATH)
INSTALL_DIR=/usr/local/bin UNATTENDED=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/deckhouse/deckhouse-cli/main/tools/install.sh)"
