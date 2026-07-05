#!/usr/bin/env bash

# Shell extras shared by the host (dotfiles/install) and the devbox container:
# zsh completions (sourced from .zshrc) and the tmux plugin manager.
set -euo pipefail

COMP="$HOME/.local/share/completions"
mkdir -p "$COMP"
command -v fzf     >/dev/null && fzf --zsh                 > "$COMP/fzf.zsh"     2>/dev/null || true
command -v kubectl >/dev/null && kubectl completion zsh    > "$COMP/kubectl.zsh" 2>/dev/null || true
command -v flint   >/dev/null && flint completion --shell=zsh > "$COMP/flint.zsh" 2>/dev/null || true

TPM="$HOME/.tmux/plugins/tpm"
[ -d "$TPM" ] || git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM"
