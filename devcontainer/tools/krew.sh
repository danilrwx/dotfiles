#!/usr/bin/env bash

# krew + ctx/ns/df-pv plugins (user-scope ~/.krew). Run as the target user.
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

tmp="$(mktemp -d)"
tarcmd="tar -xz"; command -v bsdtar >/dev/null && tarcmd="bsdtar -xzf -"
curl -fsSL "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew-linux_${ARCH}.tar.gz" | $tarcmd -C "$tmp"
"$tmp/krew-linux_${ARCH}" install krew
export PATH="${HOME}/.krew/bin:$PATH"
kubectl krew install ctx ns df-pv
