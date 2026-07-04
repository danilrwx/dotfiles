#!/usr/bin/env bash

# Dev tools from Homebrew — the same list on the macOS host and the linuxbrew
# container. Requires brew to be installed already.
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

brew install \
  go go-task yq helm golangci-lint k9s gh delve jq fzf tmux vim \
  gnupg pinentry kubectl krew node gopls gofumpt bash-completion@2
