#!/usr/bin/env bash

# Docker client (CLI + buildx + compose) from Docker's apt repo, no daemon.
# Local provider talks to the host's mounted docker.sock; the k8s provider talks
# to a DinD sidecar via DOCKER_HOST. Runs as root in the build.
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

[ "$OS" = Linux ] || exit 0

$SUDO install -m0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $SUDO tee /etc/apt/keyrings/docker.asc >/dev/null
$SUDO chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | $SUDO tee /etc/apt/sources.list.d/docker.list >/dev/null
$SUDO apt-get update
$SUDO apt-get install -y --no-install-recommends docker-ce-cli docker-buildx-plugin docker-compose-plugin
$SUDO rm -rf /var/lib/apt/lists/*
