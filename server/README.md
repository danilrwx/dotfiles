# server — base vim/tmux config for a fresh box

A minimal, plugin-free vim + tmux config to make a bare server feel like home,
including clipboard over SSH (OSC 52) — copy from a remote vim/tmux to your
**local** clipboard, no xclip/pbcopy, no X server.

## Install on a server

`install.sh` is self-contained — no scp needed. Either:

```sh
# paste into the server shell
clip < server/install.sh          # copies it to your clipboard, then paste on the server

# or pipe it over ssh
ssh server 'bash -s' < server/install.sh
```

It installs the `clip` command into `~/.local/bin` (adding that dir to `PATH` if
missing), writes `~/.osc52/{vimrc,tmux.conf}`, and adds one `source` line to
`~/.vimrc` and `~/.tmux.conf`. Idempotent. Then on the server: open a new shell
(for `PATH`), `tmux kill-server`, and restart vim.

Install `clip` elsewhere with `BIN` (e.g. a dir already on `PATH`, no `PATH`
edit then):

```sh
BIN=/usr/local/bin bash install.sh     # needs write access there
```

## What you get

**clipboard**

- `clip` — `some-command | clip` puts stdin on your clipboard.
- vim — every yank (`yy`, `yw`, visual `y`) copies to your clipboard.
- tmux — OSC 52 forwarded out; mouse drag-select copies on release.

**vim** (legacy vimscript, no plugins)

- editing defaults: `expandtab` ts/sw=2, `hidden`, `incsearch`, `hlsearch`,
  `number`; trailing-whitespace highlight; transparent background.
- keymaps: `-` netrw, `<A-q>` close buffer, `S-l`/`S-h` next/prev buffer,
  `<C-l>` clear search, `<C-d>`/`<C-u>` half-page + recenter, `leader`=space.
- built-in packages if present: `comment` (gc), `cfilter`, `hlyank`.

**tmux**

- `alt+1..9` select window; `prefix h/j/k/l` pane nav; `</>` swap pane.
- defaults: `escape-time 0`, `base-index 1`, `renumber-windows`,
  `history-limit 100000`, `focus-events`; truecolor.

## Requirements

- Vim 8+ (needs `TextYankPost`).
- Your local terminal must allow OSC 52 writes (alacritty/kitty/iTerm2/WezTerm/
  ghostty do, mostly by default).
- GNU or BSD `base64`.
- tmux < 3.2: see the note in the generated `~/.osc52/tmux.conf`.

Paste from local into the server is plain Cmd+V (terminal paste); OSC 52 read is
normally disabled, so the clipboard cannot be read back.
