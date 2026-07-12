# Neovim — plugin-free config

A hand-rolled Neovim setup with **no plugin manager and no third-party plugins**.
Everything below (fuzzy picker, git signs, git helper, file manager, sessions,
completion) is native Lua on top of built-in Neovim + a few external CLIs. Fast
to start, nothing to lock or break on update.

`<leader>` is <kbd>Space</kbd>.

## Requirements

| Tool | Used for |
|------|----------|
| `git`, `bash` | git signs, git helper, blame |
| `ugrep` (or `grep`) | live grep picker and `:Grepq` (ugrep preferred, falls back to grep) |
| `fd` (optional) | `<leader>F` file list (falls back to `git ls-files`) |
| `gh` / `glab` (optional) | open PR/MR for a commit (GitHub / GitLab) |
| `tmux` (optional) | `<leader>gg` lazygit, playbook runner |
| `lazygit` (optional) | `<leader>gg` |
| `cc`, `curl`, `tar` | `:TSBuild` (compile treesitter parsers) |
| language servers | `gopls`, `lua_ls`, `clangd`, `rust_analyzer`, `ts_ls`, `bashls`, `helm_ls`, `golangci_lint_ls` — auto-skipped if the binary is absent |

## Layout

```
init.lua            options, leader, global maps, grepprg, undo, private rtp
plugin/             feature modules, auto-sourced on start
  picker.lua          fuzzy picker keymaps/commands (Files/Grep/Buffers/…)
  git.lua             git helper keymaps/commands (log/blame/status/PR)
  gitsigns.lua        native git signs + hunk actions
  lsp.lua             enable servers, completion, format-on-save
  diagnostics.lua     workspace diagnostics -> quickfix
  find.lua            :find / :Grepq / quickfix toggle
  oil.lua             file manager (edit the dir like a buffer)
  session.lua         auto save/restore per-cwd sessions
  playbook.lua        run playbook.sh lines in a tmux pane
  clipboard.lua       OSC 52 yank mirroring (works over SSH)
  colors.lua          dark-ansi palette (terminal ANSI colours)
  treesitter.lua      enable TS + :TSBuild parser compiler
lua/                engine code (picker/*, git.lua, session.lua)
lsp/                per-server configs (mostly vendored from nvim-lspconfig)
```

## Keymaps

### General / editing

| Key | Action |
|-----|--------|
| `<C-d>` / `<C-u>` | half-page down/up, centred (`zz`) |
| `<C-l>` | clear search highlight |
| `-` | open Oil in the current file's directory |
| `<leader>gg` | lazygit in a new tmux window |

### Buffers & windows

| Key | Action |
|-----|--------|
| `<S-l>` / `<S-h>` | next / previous buffer |
| `<A-q>` | delete current buffer |
| `<leader>b` | buffer picker (`<C-d>` deletes in-list) |

### Files & search (picker)

| Key | Action |
|-----|--------|
| `<leader>f` | git-tracked files (`git ls-files`) |
| `<leader>F` | all files (`fd`, else git) |
| `<leader>/` | live grep (normal); in visual mode greps the selection |
| `<leader>?` | live grep the word under the cursor |
| `<leader>'` | resume last picker (query + list position restored) |
| `<leader>"` | resume the picker before that |
| `<leader>e` | `:find ` (native, prompt-completed) |

### In-picker keys

| Key | Action |
|-----|--------|
| `<C-n>`/`<Down>`, `<C-p>`/`<Up>` | move selection |
| `<C-g>` | jump to top |
| `<CR>` | open |
| `<C-s>` / `<C-v>` / `<C-t>` | open in split / vsplit / tab |
| `<C-x>` | mark row (multi-select) |
| `<Tab>` | send results (or marks) to quickfix |
| `<C-f>` / `<C-b>` | page down / up |
| `<A-f>` / `<A-b>` | scroll the preview |
| `<C-/>` | toggle preview pane |
| `<C-o>` | previous picker (history) |
| `<Esc>` / `<C-c>` | close |
| `<C-d>` | delete (buffers / sessions pickers) |
| `<A-g>` | live grep: toggle grep-pattern / file-filter mode |
| `<A-r>` | live grep: toggle regex (ERE) / fixed-string |

### Git — signs & hunks (`gitsigns.lua`)

| Key | Action |
|-----|--------|
| `]c` / `[c` | next / previous hunk (native `]c`/`[c` in diff mode) |
| `ghp` | preview hunk (inline float) |
| `ghs` / `ghS` | stage hunk / stage whole buffer |
| `ghu` / `ghU` | undo hunk (revert in buffer) / reset buffer to index |
| `ghd` / `ghD` | diff split vs index / vs HEAD (`q` closes) |
| `ih` | hunk text object (`dih`, `yih`, `Vih`) |

### Git — history & blame (`git.lua`)

| Key | Action |
|-----|--------|
| `<leader>gc` | repo log picker (preview commit diff) |
| `<leader>gs` | status picker (`<C-s>` stage / `<C-u>` unstage) |
| `<leader>gf` | current file's commit history (picker) |
| `<leader>gl` | current file's full log with patches (fugitive-style, in a tab) |
| `<leader>gh` | changed hunks across the repo (picker) |
| `ghb` | detailed blame float for the current line |
| `ghB` | toggle full-file blame annotations |
| `gho` | open the PR/MR for the line's commit (browser) |

In blame floats / git log buffers: `<CR>` opens the commit under the cursor,
`o` opens its PR/MR, `q`/`<Esc>` closes.

Current-line blame is always on (subtle right-aligned virtual text); toggle with
`:GitLineBlameToggle`.

### LSP

Uses Neovim's **built-in** LSP defaults, plus one added map:

| Key | Action |
|-----|--------|
| `K` | hover |
| `grn` | rename |
| `gra` | code action (normal & visual) |
| `grr` | references |
| `gri` | implementation |
| `grt` | type definition |
| `gO` | document symbols |
| `<C-s>` (insert) | signature help |
| `grf` | format buffer (added; also runs on save for Go) |
| `[d` / `]d` | previous / next diagnostic |

Completion is native (`vim.lsp.completion`, autotrigger) with
`completeopt=menuone,noselect,noinsert,fuzzy,popup`.

### Diagnostics & quickfix

| Key | Action |
|-----|--------|
| `<leader>D` | diagnostics picker (all buffers) |
| `<leader>q` | toggle the quickfix window |

`:LspDiagWs` fills the quickfix with workspace diagnostics (severity-sorted).

### Oil (file manager)

Open with `-`. Edit the directory listing like a normal buffer, then `:w` to
apply (creates/deletes/renames/copies; asks to confirm).

| Key | Action |
|-----|--------|
| `<CR>` | open file / enter directory |
| `-` | go up a directory |
| `cc` / `S` | rename the entry on the current line |
| `:w` | apply the pending changes |

### Playbook

In a `playbook.sh` buffer, `<CR>` sends the current line (or the visual
selection) to the neighbouring tmux pane and runs it. Target overridable via
`vim.g.playbook_target` (default `{last}`).

### Sessions

Auto-saved per cwd on exit, auto-restored on a bare `nvim` (no file args).

| Key | Action |
|-----|--------|
| `<leader>s` | session picker (`<C-d>` deletes) |

Commands: `:SessionSave`, `:SessionRestore`, `:SessionDelete`.

### Clipboard

Every yank is mirrored to the host clipboard via **OSC 52** (works over
SSH/tmux, no X server). `<leader>dd` copies `path:line` of the current position.

## Commands

| Command | Action |
|---------|--------|
| `:Files` / `:GFiles` / `:Buffers` | pickers |
| `:LiveGrep [pattern]` | live grep, optional initial pattern |
| `:Diagnostics[!]` | diagnostics picker (`!` = current buffer only) |
| `:GitHunks` | repo hunks picker |
| `:GitCommits` / `:GitStatus` / `:GitFileHistory` / `:GitFileLog` | git helper views |
| `:GitBlame` / `:GitBlameLine` / `:GitLineBlameToggle` / `:GitOpenPR` | blame / PR |
| `:Grepq {pattern}` | grep into quickfix (uses `grepprg`) |
| `:LspDiagWs` | workspace diagnostics into quickfix |
| `:Session{Save,Restore,Delete}` | sessions |
| `:Oil [dir]` | file manager |
| `:TSBuild` | download + compile treesitter parsers into `site/parser` |

## Treesitter

Highlighting/folding turn on automatically for any filetype whose parser is
present. Parsers are **not** auto-installed — run `:TSBuild` to fetch and compile
the pinned grammars (list in `plugin/treesitter.lua`) with `cc`. Queries are
vendored under `queries/`.

## Notes

- Colours come from the terminal's 16 ANSI slots (`termguicolors` off), matching
  Claude Code's `dark-ansi`: keywords/builtins magenta, strings green, comments
  grey, types cyan. See `plugin/colors.lua`.
- No statusline (`laststatus=0`) and no bufferline — deliberately minimal. The
  line number column doubles as the git-sign column (`statuscolumn`).
- Git signs diff the **live buffer** against the index, so they update before you
  save. Symlinks are skipped (git blames the target, not the followed content).
- `private/config/nvim` (a submodule, if present) is appended to `runtimepath`
  for machine-specific tooling not tracked here.
