#!/usr/bin/env bash

# Symlink the CLI/shell dotfiles configs into place. Shared by the host
# (dotfiles/install) and the devbox container (dotfiles mounted read-only).
# GUI-only configs (kitty/alacritty/ghostty/i3/…) and ~/.claude (bind-mounted in
# the container) are handled by the host install, not here.
set -euo pipefail

D="$HOME/dotfiles"
[ -d "$D" ] || exit 0
mkdir -p "$HOME/.config"

ln -sf "$D/.gitconfig" "$HOME/"
ln -sf "$D/.gitignore_global" "$HOME/"
ln -sf "$D/.tmux.conf" "$HOME/.tmux.conf"
ln -sf "$D/.profile" "$HOME/"
ln -sf "$D/.bash_profile" "$HOME/"
ln -sf "$D/.bashrc" "$HOME/"
ln -sf "$D/.zprofile" "$HOME/"
ln -sf "$D/.zshrc" "$HOME/"

for c in k9s htop lazygit vim nvim; do
  ln -snf "$D/config/$c" "$HOME/.config/"
done
ln -snf "$D/config/nvim" "$HOME/.config/nvimpager"
