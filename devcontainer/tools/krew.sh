#!/usr/bin/env bash

# krew plugins (user-scope ~/.krew). krew itself comes from brew (repo.sh). Run
# as the target user.
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

export PATH="${HOME}/.krew/bin:$PATH"
kubectl krew install ctx ns df-pv
