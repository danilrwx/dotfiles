# osc52 — clipboard over SSH

Copy from a remote vim/tmux to the local (host) clipboard using OSC 52 escape
sequences — no xclip/pbcopy, no X server. Works through tmux and SSH.

## Install on a server

```sh
scp -r osc52 server:~/           # copy the bundle
ssh server 'bash ~/osc52/install.sh'
```

`install.sh` drops the files into `~/.osc52` and adds one `source` line to
`~/.vimrc` and `~/.tmux.conf`. Then on the server: `tmux kill-server` and restart
vim.

## What it does

- `clip` — `some-command | clip` puts stdin on the host clipboard.
- `vimrc` — mirrors every yank (`yy`, `yw`, visual `y`) to the host clipboard.
- `tmux.conf` — makes tmux forward OSC 52 to the outer terminal.

## Requirements

- Vim 8+ (needs `TextYankPost`).
- The local terminal must allow OSC 52 writes (alacritty/kitty/iTerm2/WezTerm/
  ghostty do, mostly by default).
- GNU or BSD `base64` (both fine).
- tmux < 3.2: see the note in `tmux.conf`.

Paste from the host into the server is plain Cmd+V (terminal paste); OSC 52 read
is normally disabled, so the clipboard cannot be read back.
