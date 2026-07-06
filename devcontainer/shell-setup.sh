#!/usr/bin/env bash

# Shell extras shared by the host (dotfiles/install) and the devbox container:
# zsh completions (sourced from .zshrc). tmux needs no plugin manager — the
# former TPM plugins are now native binds in .tmux.conf (fzf-only).
set -euo pipefail

COMP="$HOME/.local/share/completions"
mkdir -p "$COMP"
command -v fzf     >/dev/null && fzf --zsh                 > "$COMP/fzf.zsh"     2>/dev/null || true
command -v kubectl >/dev/null && kubectl completion zsh    > "$COMP/kubectl.zsh" 2>/dev/null || true

# vim plugins via native packages (~/.vim/pack/*/start auto-loads, no plugin manager)
VIM_PACK="$HOME/.vim/pack/plugins/start"
mkdir -p "$VIM_PACK"
for repo in \
  markonm/traces.vim \
  airblade/vim-gitgutter \
  yegappan/lsp; do
  dst="$VIM_PACK/${repo##*/}"
  [ -d "$dst" ] || git clone --depth 1 "https://github.com/$repo" "$dst"
done
