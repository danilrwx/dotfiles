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

# Import public keys so gpg knows what to sign with; the secret operations come
# from the forwarded gpg-agent. DevPod's own public-key import is unreliable here.
pubkeys="$(dirname "$0")/pubkeys.asc"
[ -s "$pubkeys" ] && gpg --import "$pubkeys" 2>/dev/null && echo "imported gpg public keys"
