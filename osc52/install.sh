#!/usr/bin/env bash

# Install the OSC 52 clipboard bundle into ~/.osc52 and wire it into ~/.vimrc and
# ~/.tmux.conf with a single source line each. Idempotent — safe to re-run.
set -euo pipefail

src="$(cd "$(dirname "$0")" && pwd)"
dst="$HOME/.osc52"

mkdir -p "$dst"
install -m 755 "$src/clip" "$dst/clip"
install -m 644 "$src/vimrc" "$dst/vimrc"
install -m 644 "$src/tmux.conf" "$dst/tmux.conf"

# Append a line to a file only if it is not already present.
wire() {
  touch "$1"
  grep -qxF "$2" "$1" || printf '%s\n' "$2" >> "$1"
}
wire "$HOME/.vimrc"     'source ~/.osc52/vimrc'
wire "$HOME/.tmux.conf" 'source-file ~/.osc52/tmux.conf'

echo "Installed to $dst."
echo "Reload:  tmux kill-server   (or: tmux source-file ~/.tmux.conf)"
echo "         restart vim"
echo "Test:    in vim yy  ->  Cmd+V on the host"
