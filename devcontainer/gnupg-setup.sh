#!/usr/bin/env bash

# Copy the host GnuPG keys (mounted read-only at /mnt/host-gnupg) into the
# user's ~/.gnupg with a container-local agent config: the host uses
# pinentry-mac which does not exist here, so use a tty pinentry with loopback.
# Passphrase is entered in the terminal on first sign and cached by the agent.
set -euo pipefail

SRC=/mnt/host-gnupg
DST="$HOME/.gnupg"
[ -d "$SRC" ] || exit 0

mkdir -p "$DST"
chmod 700 "$DST"
for item in private-keys-v1.d public-keys.d openpgp-revocs.d trustdb.gpg common.conf pubring.kbx pubring.gpg; do
  [ -e "$SRC/$item" ] && cp -r "$SRC/$item" "$DST/" 2>/dev/null || true
done

# Drop stale lock/socket files copied from the host — else keyboxd waits forever.
find "$DST" -name '*.lock' -delete 2>/dev/null || true

pinentry="$(command -v pinentry-curses || command -v pinentry-tty || command -v pinentry)"
cat > "$DST/gpg-agent.conf" <<EOF
allow-loopback-pinentry
pinentry-program ${pinentry}
EOF

find "$DST" -type d -exec chmod 700 {} +
find "$DST" -type f -exec chmod 600 {} +
gpgconf --kill gpg-agent 2>/dev/null || true
