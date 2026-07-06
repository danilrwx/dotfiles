#!/usr/bin/env bash

# Set up the k8s dev pod: pull the private dotfiles submodule and clone the work
# repos into ~/w. Host binds do not work in k8s, so everything is fetched
# server-side over the forwarded ssh-agent. Idempotent. go.mod replace
# directives are relative, so all repos must be siblings under ~/w.
set -euo pipefail

export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=accept-new"

# PVC repos are owned by a different uid than the dev user, so git rejects them
# as "dubious ownership" and skips their config — including the ~/w includeIf
# that sets the work email. Trust them.
git config --global --add safe.directory '*'

# Freshly provisioned PVCs mount root-owned; take the go cache so the dev user
# (GOMODCACHE/GOCACHE point here) can write it.
if [ -d "$HOME/gocache" ]; then
  sudo chown "$(id -u):$(id -g)" "$HOME/gocache" 2>/dev/null || true
fi

# The image clones dotfiles without the private submodule (it needs auth). Pull
# it now over the forwarded ssh-agent so ~/dotfiles/private is complete: work
# git identity, the repo list, shell env. The submodule URL is git@, so the
# agent is used directly.
git -C "$HOME/dotfiles" submodule update --init --recursive

W="$HOME/w"
list="$HOME/dotfiles/private/devbox-repos"
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

if [ -x "$HOME/dotfiles/private/bootstrap" ]; then
  "$HOME/dotfiles/private/bootstrap" || true
fi
