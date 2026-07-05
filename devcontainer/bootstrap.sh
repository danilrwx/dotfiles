#!/usr/bin/env bash

# Clone the work repos into ~/w inside the k8s dev pod (host binds do not work
# there, so the code is cloned server-side over the forwarded ssh-agent rather
# than uploaded). Idempotent. go.mod replace directives are relative, so all
# repos must be siblings under ~/w.
#
# The repo list is NOT kept here (this image is public). It is provided out of
# band on the host at ~/.config/devbox/repos (one git URL per line, # comments
# allowed) and copied next to this script by the devbox helper.
set -euo pipefail

here="$(dirname "$0")"

# Freshly provisioned PVCs mount root-owned; take the go cache so the dev user
# (GOMODCACHE/GOCACHE point here) can write it.
if [ -d "$HOME/gocache" ]; then
  sudo chown "$(id -u):$(id -g)" "$HOME/gocache" 2>/dev/null || true
fi

# The public image clones dotfiles without the private submodule, so the
# includeIf in .gitconfig (work email for ~/w commits) has no target. The
# helper copies work.gitconfig next to this script; put it where includeIf
# expects it.
if [ -f "$here/work.gitconfig" ]; then
  mkdir -p "$HOME/dotfiles/private"
  cp "$here/work.gitconfig" "$HOME/dotfiles/private/work.gitconfig"
fi

W="$HOME/w"
export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=accept-new"

list="$here/repos"
if [ -f "$list" ]; then
  while read -r url; do
    [ -n "$url" ] || continue
    case "$url" in \#*) continue ;; esac
    name="$(basename "$url" .git)"
    if [ -d "$W/$name/.git" ]; then
      echo "have $name"
    else
      echo "clone $name"
      git clone "$url" "$W/$name"
    fi
  done < "$list"
fi
