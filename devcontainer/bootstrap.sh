#!/usr/bin/env bash

# Clone the work repos into ~/w inside the k8s dev pod (host binds do not work
# there, so the code is cloned server-side over the forwarded ssh-agent rather
# than uploaded). Idempotent. go.mod replace directives are relative, so all
# repos must be siblings under ~/w.
set -euo pipefail

W="$HOME/w"
export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=accept-new"

repos=(
  ***REMOVED***
  ***REMOVED***
  ***REMOVED***
  ***REMOVED***
)

for url in "${repos[@]}"; do
  name="$(basename "$url" .git)"
  if [ -d "$W/$name/.git" ]; then
    echo "have $name"
  else
    echo "clone $name"
    git clone "$url" "$W/$name"
  fi
done
