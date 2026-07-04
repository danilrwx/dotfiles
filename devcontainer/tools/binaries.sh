#!/usr/bin/env bash

# Binaries not available (or not current) in brew: werf and d8/deckhouse-cli.
# Installed into /usr/local/bin. Linux only (the container); needs root/sudo.
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

[ "$OS" = Linux ] || exit 0

werf_ver="$(curl -fsSL "https://tuf.werf.io/targets/channels/${WERF_CHANNEL}")"
curl -fsSL "https://tuf.werf.io/targets/releases/${werf_ver}/linux-${ARCH}/bin/werf" | $SUDO tee /usr/local/bin/werf >/dev/null
$SUDO chmod +x /usr/local/bin/werf

d8_ver="$(basename "$(curl -fsSLo /dev/null -w '%{url_effective}' https://github.com/deckhouse/deckhouse-cli/releases/latest)")"
tmp="$(mktemp -d)"
curl -fsSL "https://github.com/deckhouse/deckhouse-cli/releases/download/${d8_ver}/d8-${d8_ver}-linux-${ARCH}.tar.gz" | tar -xzf - -C "$tmp"
$SUDO install "$(find "$tmp" -type f -name d8)" /usr/local/bin/d8
