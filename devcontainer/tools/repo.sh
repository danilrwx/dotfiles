#!/usr/bin/env bash

# Base CLI packages from apt (container image only). Runs as root in the build.
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

[ "$OS" = Linux ] || exit 0

$SUDO apt-get update
$SUDO apt-get install -y --no-install-recommends \
  git tmux vim jq fzf ripgrep less zsh bash-completion htop lazygit \
  gnupg2 pinentry-curses openssh-client nodejs npm \
  build-essential file procps ca-certificates curl uuid-runtime \
  man-db manpages manpages-dev
$SUDO rm -rf /var/lib/apt/lists/*
