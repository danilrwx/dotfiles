#!/usr/bin/env bash

# Shell extras shared by the host (dotfiles/install) and the devbox container:
# zsh completions (sourced from .zshrc). tmux needs no plugin manager — the
# former TPM plugins are now native binds in .tmux.conf (fzf-only).
set -euo pipefail

COMP="$HOME/.local/share/completions"
mkdir -p "$COMP"
command -v fzf     >/dev/null && fzf --zsh                 > "$COMP/fzf.zsh"     2>/dev/null || true
command -v kubectl >/dev/null && kubectl completion zsh    > "$COMP/kubectl.zsh" 2>/dev/null || true

# vim plugins via native packages (~/.config/vim is in packpath by default; gitignored)
# start/ auto-loads; opt/ is packadd'd on demand (lsp is lazy — see plugin/lsp.vim)
VIM_START="$HOME/.config/vim/pack/plugins/start"
VIM_OPT="$HOME/.config/vim/pack/plugins/opt"
mkdir -p "$VIM_START" "$VIM_OPT"
[ -d "$VIM_START/traces.vim" ] || git clone --depth 1 https://github.com/markonm/traces.vim "$VIM_START/traces.vim"
[ -d "$VIM_OPT/lsp" ]         || git clone --depth 1 https://github.com/yegappan/lsp "$VIM_OPT/lsp"
