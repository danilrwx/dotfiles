#!/usr/bin/env bash

# Shared settings for the container tool-install scripts (sourced, not run
# directly). Bump versions here.
set -euo pipefail

GO_VERSION="1.25.11"
GINKGO_VERSION="v2.14.0"
WERF_CHANNEL="2/stable"

OS="$(uname -s)"
ARCH="$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')"
SUDO=""; if [ "$(id -u)" -ne 0 ]; then SUDO="sudo"; fi
