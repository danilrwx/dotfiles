#!/usr/bin/env bash

# Shell extras shared by the host (dotfiles/install) and the devbox container:
# zsh completions (sourced from .zshrc) and the tmux plugin manager.
set -euo pipefail

COMP="$HOME/.local/share/completions"
mkdir -p "$COMP"
command -v fzf     >/dev/null && fzf --zsh                 > "$COMP/fzf.zsh"     2>/dev/null || true
command -v kubectl >/dev/null && kubectl completion zsh    > "$COMP/kubectl.zsh" 2>/dev/null || true

TPM="$HOME/.tmux/plugins/tpm"
[ -d "$TPM" ] || git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM"

# vim plugins via native packages (~/.vim/pack/*/start auto-loads, no plugin manager)
VIM_PACK="$HOME/.vim/pack/plugins/start"
mkdir -p "$VIM_PACK"
for repo in \
  markonm/traces.vim \
  tpope/vim-fugitive \
  airblade/vim-gitgutter \
  yegappan/lsp \
  vim-test/vim-test \
  habamax/vim-dir \
  laktak/tome \
  vim-fuzzbox/fuzzbox.vim; do
  dst="$VIM_PACK/${repo##*/}"
  [ -d "$dst" ] || git clone --depth 1 "https://github.com/$repo" "$dst"
done
