#!/usr/bin/env bash
# OSC 52 clipboard over SSH — self-contained installer. Copy this whole file and
# paste it into a server shell (or: clip < setup.sh, then paste; or
# ssh host 'bash -s' < setup.sh). It installs the `clip` command and wires vim +
# tmux so yanks and mouse selections land on your local clipboard. Idempotent.
# Wrapped in a subshell so a failure won't drop an interactive shell.
#
# clip goes to ~/.local/bin by default; override with BIN, e.g.
#   BIN=/usr/local/bin bash setup.sh   (needs write access there)
( set -eu

bin="${BIN:-$HOME/.local/bin}"
cfg="$HOME/.osc52"
mkdir -p "$bin" "$cfg"

cat > "$bin/clip" <<'CLIP'
#!/usr/bin/env bash
# stdin -> local clipboard via OSC 52. Usage: some-command | clip
set -eu
printf '\033]52;c;%s\a' "$(base64 | tr -d '\n')" > /dev/tty
CLIP
chmod +x "$bin/clip"

cat > "$cfg/vimrc" <<'VIMRC'
" Mirror yanks to the local clipboard over OSC 52 via the clip command.
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

cat > "$cfg/tmux.conf" <<'TMUX'
# Forward OSC 52 to the outer terminal; mouse drag-select copies on release.
set -g set-clipboard on
set -as terminal-features ',*:clipboard'
set -g mouse on
# tmux < 3.2: replace the terminal-features line with:
# set -ag terminal-overrides ',*:Ms=\E]52;%p1%s;%p2%s\007'
TMUX

wire() { touch "$1"; grep -qxF "$2" "$1" || printf '%s\n' "$2" >> "$1"; }
wire "$HOME/.vimrc"     'source ~/.osc52/vimrc'
wire "$HOME/.tmux.conf" 'source-file ~/.osc52/tmux.conf'

# Put the bin dir on PATH (so `clip` resolves) if it is not already there.
case ":${PATH:-}:" in
  *":$bin:"*) ;;
  *)
    rc="$HOME/.profile"
    case "${SHELL:-}" in *zsh) rc="$HOME/.zshrc";; *bash) rc="$HOME/.bashrc";; esac
    wire "$rc" "export PATH=\"$bin:\$PATH\""
    echo "added $bin to PATH in $rc (open a new shell to pick it up)"
    ;;
esac

echo "osc52 installed: clip -> $bin/clip, config -> $cfg"
echo "reload: tmux kill-server (or tmux source-file ~/.tmux.conf); restart vim."
echo "test:   in vim yy -> paste locally"
)
