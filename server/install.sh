#!/usr/bin/env bash
# Base vim + tmux config for a fresh server, incl. clipboard over SSH (OSC 52) —
# self-contained. Copy this whole file and paste it into a server shell (or:
# clip < install.sh, then paste; or ssh host 'bash -s' < install.sh). Idempotent:
# the config is written into ~/.vimrc and ~/.tmux.conf inside marked blocks that
# are replaced (not duplicated) on re-run. Wrapped in a subshell so a failure
# won't drop an interactive shell.
#
# clip goes to ~/.local/bin by default; override with BIN, e.g.
#   BIN=/usr/local/bin bash install.sh   (needs write access there)
( set -eu

bin="${BIN:-$HOME/.local/bin}"
mkdir -p "$bin"

cat > "$bin/clip" <<'CLIP'
#!/usr/bin/env bash
# stdin -> local clipboard via OSC 52. Usage: some-command | clip
set -eu
printf '\033]52;c;%s\a' "$(base64 | tr -d '\n')" > /dev/tty
CLIP
chmod +x "$bin/clip"

# Replace (or add) a marked block in a file. Reads the block body from stdin.
#   inject <file> <comment-char> <name>
inject() {
  f="$1"; c="$2"; b="$c >>> $3 >>>"; e="$c <<< $3 <<<"
  body="$(cat)"
  touch "$f"
  if grep -qxF "$b" "$f"; then
    awk -v b="$b" -v e="$e" '$0==b{s=1} !s{print} $0==e{s=0}' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  fi
  { printf '%s\n' "$b"; printf '%s\n' "$body"; printf '%s\n' "$e"; } >> "$f"
}

inject "$HOME/.vimrc" '"' 'server config' <<'VIMRC'
" Editing defaults.
filetype plugin indent on
syntax on
set autoindent expandtab tabstop=2 shiftwidth=2
set hidden incsearch hlsearch number updatetime=100

" Built-in plugins (safe if the vim build lacks them).
silent! packadd! cfilter
silent! packadd! comment
silent! packadd! hlyank

" Colors: transparent background, dim line numbers, dark popup menu, and a
" trailing-whitespace highlight.
highlight Normal ctermbg=none
highlight SignColumn ctermbg=none
highlight LineNr ctermfg=244 guifg=#808080
highlight Pmenu ctermbg=black ctermfg=252 guibg=#000000 guifg=#d0d0d0
highlight PmenuSel ctermbg=252 ctermfg=black guibg=#d0d0d0 guifg=#000000
match errorMsg '\s\+$'

" Keymaps.
let mapleader = ' '
nnoremap <C-d> <C-d>zz
nnoremap <C-u> <C-u>zz
nnoremap <C-l> :nohl<CR>
nnoremap <silent> - :Explore<CR>
execute "set <A-q>=\eq"
nnoremap <silent> <A-q> :bd<CR>
nnoremap <silent> <S-l> :bn<CR>
nnoremap <silent> <S-h> :bp<CR>

" Clipboard over OSC 52 via the clip command: mirror every yank to the local
" clipboard (vim over SSH has no working + register).
if exists('##TextYankPost')
  function! s:Osc52Yank() abort
    if v:event.operator !=# 'y' || v:event.regname !~# '^[+*]\=$'
      return
    endif
    let l:text = join(v:event.regcontents, "\n")
    if get(v:event, 'regtype', '')[0] ==# 'V'
      let l:text .= "\n"
    endif
    call system('clip', l:text)
  endfunction
  autocmd TextYankPost * call s:Osc52Yank()
endif
VIMRC

inject "$HOME/.tmux.conf" '#' 'server config' <<'TMUX'
# Clipboard (OSC 52) + mouse.
set -g set-clipboard on
set -g mouse on
# Forward OSC 52 to the outer terminal: terminal-features on tmux >= 3.2, else
# the Ms terminal-override on older tmux — picked from the running version.
if-shell -b '[ "$(tmux -V | sed -E "s/^tmux[^0-9]*([0-9]+)\.([0-9]+).*/\1\2/")" -ge 32 ]' \
  "set -as terminal-features ',*:clipboard'" \
  "set -ag terminal-overrides ',*:Ms=\\E]52;%p1%s;%p2%s\\007'"

# Defaults.
set -sg escape-time 0
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on
set -g history-limit 100000
set-option -g focus-events on

# Truecolor.
set -g default-terminal "xterm-256color"
set-option -ga terminal-overrides ",xterm-256color:Tc"

# alt+1..9 -> select window.
bind -n M-1 select-window -t 1
bind -n M-2 select-window -t 2
bind -n M-3 select-window -t 3
bind -n M-4 select-window -t 4
bind -n M-5 select-window -t 5
bind -n M-6 select-window -t 6
bind -n M-7 select-window -t 7
bind -n M-8 select-window -t 8
bind -n M-9 select-window -t 9

# vi-style pane nav + swap.
bind -r h select-pane -L
bind -r j select-pane -D
bind -r k select-pane -U
bind -r l select-pane -R
bind > swap-pane -D
bind < swap-pane -U
TMUX

# Put the bin dir on PATH (so `clip` resolves) if it is not already there.
case ":${PATH:-}:" in
  *":$bin:"*) ;;
  *)
    rc="$HOME/.profile"
    case "${SHELL:-}" in *zsh) rc="$HOME/.zshrc";; *bash) rc="$HOME/.bashrc";; esac
    if ! grep -qxF "export PATH=\"$bin:\$PATH\"" "$rc" 2>/dev/null; then
      printf '%s\n' "export PATH=\"$bin:\$PATH\"" >> "$rc"
    fi
    echo "added $bin to PATH in $rc (open a new shell to pick it up)"
    ;;
esac

echo "installed: clip -> $bin/clip, config -> ~/.vimrc + ~/.tmux.conf"
echo "reload: tmux kill-server (or tmux source-file ~/.tmux.conf); restart vim."
)
