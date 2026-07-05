#!/usr/bin/env bash

# Base CLI packages from apt (container image only). Runs as root in the build.
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

[ "$OS" = Linux ] || exit 0

$SUDO apt-get update
$SUDO apt-get install -y --no-install-recommends \
  git tmux vim jq fzf ripgrep ugrep less zsh htop lazygit tree \
  gnupg2 openssh-client nodejs npm \
  build-essential file procps ca-certificates curl uuid-runtime \
  wget unzip zip xz-utils openssl \
  iputils-ping dnsutils netcat-openbsd socat iproute2 net-tools lsof strace \
  man-db manpages manpages-dev
$SUDO rm -rf /var/lib/apt/lists/*
