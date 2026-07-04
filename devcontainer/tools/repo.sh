#!/usr/bin/env bash

# Dev tools available from the system package manager (brew on macOS, dnf on
# Fedora). Needs root/sudo on Linux.
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

case "$OS" in
  Darwin)
    brew install go go-task yq helm golangci-lint k9s gh delve git tmux jq kubectl krew gnupg pinentry
    ;;
  Linux)
    $SUDO dnf install -y --setopt=install_weak_deps=False \
      golang go-task yq helm golangci-lint k9s gh delve \
      docker-cli git-core tmux vim-enhanced jq bsdtar findutils procps-ng which \
      gnupg2 pinentry
    $SUDO ln -sf /usr/bin/go-task /usr/local/bin/task
    ;;
esac
