# Neovim — native config

No plugin manager or third-party plugins. Files use fuzzy `:find`, buffers use
`:buffer`, and searches and LSP diagnostics use quickfix. Directory browsing uses
bundled netrw. `<leader>` is Space.

## Requirements

- `fd` / `fdfind` for file enumeration, with a `find` fallback.
- `ugrep` for text search, with a `grep` fallback.
- `gopls`, `clangd`, `helm-ls`: each server is enabled only if its binary exists.
- tmux for the playbook runner; `bin/clip` (`wl-copy`) for desktop copying.

## Files, search and buffers

| Key / command | Action |
|---|---|
| `<leader>f` / `<leader>F` | Start `:find `; type a fuzzy filename, Tab to complete, Enter to open |
| `<leader>b` | List buffers, then start `:buffer `; enter a number or complete a name |
| `<leader>/` | Start `:Grepq `; enter a pattern and press Enter |
| `<leader>/` in visual mode | Search the first line of the selection |
| `<leader>?` | Search the word under the cursor |
| `<leader>D` / `:Diagnostics` | All LSP diagnostics in quickfix |
| `:Diagnostics!` | Diagnostics for the current buffer |
| `<leader>q` | Toggle quickfix |
| `:cnext` / `:cprevious` | Next / previous quickfix result |
| `:colder` / `:cnewer` | Older / newer quickfix result list |
| `-` | Open netrw in the current file's directory |
| `<S-l>` / `<S-h>` | Next / previous buffer |
| `<A-q>` | Delete the current buffer |

File search starts in the current working directory. fd respects ignore files.
Text search runs after submission, without live updates or a preview window.
`:Grepq` takes a search pattern; spaces, quotes and shell characters are passed
to the search program rather than executed by the shell. Regex rules are those
of the configured search program. Enter opens a result in the quickfix window.

The former `:Picker` command, floating picker UI, preview, multi-selection and
picker history have been removed. Command-line history and quickfix history
are available through Neovim's standard commands.

## Editing and appearance

- Built-in `vim` theme and terminal colours; grey line numbers.
- Neutral completion menus, black LSP floating windows, rounded borders.
- Traditional Vim syntax, including code blocks inside LSP Markdown previews.
  Tree-sitter highlighting and LSP semantic highlighting are disabled.
- No statusline or bufferline. Manual folding.
- Two-space indentation, persistent undo, restoration of the saved cursor position.
- Brief highlight on yank; plain yanks also go to the Wayland clipboard.
  `<leader>dd` copies `path:line`.
- `<C-d>` / `<C-u>` scroll half a page and centre the cursor.
  `<C-l>` clears search highlighting and refreshes the display/diff.
- `.h` files use C. `.yaml` and `.tpl` intentionally use Helm.

Markdown uses bundled syntax, conceal outside the cursor line, word wrapping and
syntax highlighting in fenced code blocks. There is no separate renderer.

## LSP

Native completion opens automatically while typing. The menu shows names and
kinds without long signature columns. Go is formatted on save.

| Key | Action |
|---|---|
| `K` | Hover documentation |
| `grn` | Rename |
| `gra` | Code action |
| `grr` | References |
| `gri` | Implementation |
| `grt` | Type definition |
| `gO` | Document symbols |
| `<C-s>` in insert mode | Signature help |
| `grf` | Format buffer |
| `grc` | Run code lens, when supported |
| `[d` / `]d` | Previous / next diagnostic |

## Playbook

In `playbook.sh`, Enter sends the current line or visual selection to tmux and
runs it. `vim.g.playbook_target` selects the target (default `{last}`).

## Layout

- `init.lua`: options, common keymaps, grep settings and filetypes.
- `plugin/find.lua`: native fuzzy file search and buffer selection mappings.
- `plugin/quickfix.lua`: search, diagnostics commands and quickfix toggle.
- `plugin/diagnostics.lua`: diagnostic display and keymap.
- `plugin/lsp.lua`, `lsp/`: native LSP and server configuration.
- `plugin/hover.lua`, `plugin/ui.lua`: hover syntax and UI colours.
- `plugin/editing.lua`, `plugin/clipboard.lua`: cursor, yank and clipboard.
- `plugin/markdown.lua`, `plugin/syntax.lua`: traditional syntax.
- `plugin/playbook.lua`: tmux playbook runner.
