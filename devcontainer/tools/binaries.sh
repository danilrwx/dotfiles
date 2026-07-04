#!/usr/bin/env bash

# kubectl/werf/d8 are not packaged (on macOS kubectl comes from brew in repo.sh).
# Needs root/sudo to write /usr/local/bin.
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

[ "$OS" = Linux ] || exit 0

kube_ver="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
curl -fsSL "https://dl.k8s.io/release/${kube_ver}/bin/linux/${ARCH}/kubectl" | $SUDO tee /usr/local/bin/kubectl >/dev/null
$SUDO chmod +x /usr/local/bin/kubectl

werf_ver="$(curl -fsSL "https://tuf.werf.io/targets/channels/${WERF_CHANNEL}")"
curl -fsSL "https://tuf.werf.io/targets/releases/${werf_ver}/linux-${ARCH}/bin/werf" | $SUDO tee /usr/local/bin/werf >/dev/null
$SUDO chmod +x /usr/local/bin/werf

d8_ver="$(basename "$(curl -fsSLo /dev/null -w '%{url_effective}' https://github.com/deckhouse/deckhouse-cli/releases/latest)")"
tmp="$(mktemp -d)"
curl -fsSL "https://github.com/deckhouse/deckhouse-cli/releases/download/${d8_ver}/d8-${d8_ver}-linux-${ARCH}.tar.gz" | bsdtar -xzf - -C "$tmp"
$SUDO install "$(find "$tmp" -type f -name d8)" /usr/local/bin/d8
