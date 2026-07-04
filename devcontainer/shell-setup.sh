#!/usr/bin/env bash

# Shell extras shared by the host (dotfiles/install) and the devbox container:
# bash completions (sourced from .bashrc) and the tmux plugin manager.
set -euo pipefail

COMP="$HOME/.local/share/completions"
mkdir -p "$COMP"
command -v fzf     >/dev/null && fzf --bash                 > "$COMP/fzf.bash"     || true
command -v kubectl >/dev/null && kubectl completion bash    > "$COMP/kubectl.bash" || true
command -v flint   >/dev/null && flint completion --shell=bash > "$COMP/flint.bash" || true

TPM="$HOME/.tmux/plugins/tpm"
[ -d "$TPM" ] || git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM"
