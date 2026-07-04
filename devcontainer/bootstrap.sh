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

W="$HOME/w"
export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=accept-new"

list="$(dirname "$0")/repos"
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
