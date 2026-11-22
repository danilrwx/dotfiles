# Vim without LSP

The dotfiles configuration for recent Vim 9.1/9.2, focused on C and Zig, with occasional
Go reading. No ALE, plugin manager, external plugins or language servers.

Run from a project directory:

```sh
vim -u ~/dotfiles/experiments/vim/vimrc
```

Open files after startup; options are applied to their native Vim filetypes.
The standalone configuration uses fd for file search and ugrep for text search,
with a grep fallback.

## OpenBSD

Use package Vim rather than the base system's vi (nvi). On OpenBSD-current the
terminal Vim build is the default flavour:

```sh
doas pkg_add vim-- fd
```

Use packages for your installed OpenBSD release; availability and versions can
vary with release and architecture. Text search uses `ugrep` when installed,
otherwise `grep`. Optional: `universal-ctags` for project navigation,
`zig` for Zig builds, and `go` for Go documentation/builds.
The OpenBSD Universal Ctags executable is named `uctags`:

```sh
uctags -R --languages=C,C++,Go,Zig --exclude=.git --exclude=build .
```

Run this explicitly from the project root and rerun when declarations change.
Vim searches for `tags` up the current file's directory tree.
OpenBSD's base ctags is a different implementation; do not assume it accepts `-R`.

## Project navigation

`install` installs Universal Ctags; the base configuration links `config/ctags`
to `~/.config/ctags`. The small Zig rules index ordinary `fn`, `const` and `var`
declarations. They do not understand scopes, imports, quoted identifiers or comptime
resolution; local declarations can also appear in results.

Run `:Tags` (Space Shift-T) from the project root to generate or refresh `tags`.
The command covers C/C++ headers and sources, Go and Zig, excluding build directories.
Ctrl-] jumps to a definition; Ctrl-T returns; Space t selects among matching tags.
Dependencies outside the indexed directory must be indexed separately. There are
no editor plugins or background indexing processes.

For Go, `gd` or Ctrl-] uses one-shot `godef` through Vim's native `tagfunc`;
Ctrl-T returns through the native tag stack. Unsaved buffer contents are supplied
to godef. Insert-mode tag completion and explicit tag searches still use `tags`.
Without godef installed, Ctrl-] falls back to the tags file.

`install` builds godef using `dev/godef/go.mod`, which updates the analysis
dependency for Go 1.27 without changing upstream source. To build it separately:

```sh
cd ~/dotfiles/dev/godef
GOWORK=off go build -mod=readonly -o ~/go/bin/godef github.com/rogpeppe/godef
```

## Themes

Dark is the default, using the terminal palette. `:ThemeLight` switches to an
e-ink-style light theme: an off-white background, grayscale syntax and bold
keywords. `:ThemeDark` restores the dark theme locally. Space u t toggles the
whole desktop using x-theme. Open Vim sessions follow desktop theme changes within a second.
The light theme uses true color in Foot.

## Keys and workflow

Command-line completion uses a vertical popup menu. Tab opens it; Up/Down select a match.

| Key | Action |
|---|---|
| Space f / Space F | Fuzzy `:find`; type, Tab, Enter |
| Space b | List buffers, then choose with `:buffer` |
| Space / | Search pattern with ugrep/grep, results in quickfix |
| Space / in visual mode | Search the first selected line |
| Space ? | Search the word under the cursor |
| Space q | Toggle quickfix |
| Space m | `:make` using the current buffer's compiler settings |
| Space t | Choose a matching tag for the word under the cursor |
| Space Shift-T | Generate/update the project's tags file |
| Ctrl-] / Ctrl-T | Jump to tag / return |
| gd / Ctrl-] in Go | Go to definition with one-shot godef |
| - | Browse the file's directory using netrw |
| Shift-H / Shift-L | Previous / next buffer |
| Alt-Q | Delete buffer |
| Space dd | Copy path:line, when a clipboard tool is available |
| K in Go | Best-effort `go doc` popup |

In the Go documentation popup, Ctrl-D/Ctrl-U scroll half a page and PageDown/PageUp
scroll a full page. Esc or q closes it. With Vim mouse support enabled, the scrollbar
also accepts mouse-wheel events.

- Native autocomplete suggests words/tags, not types or project API members.
  Ctrl-N / Ctrl-P also trigger word completion. In C, Ctrl-X Ctrl-O uses Vim's
  built-in `ccomplete`, based on includes/tags; it is not compiler-accurate.
- C: run from the project root, provide a Makefile, then `:make`.
- Zig: bundled Vim syntax/ftplugin/compiler support selects `zig build`.
  Use `:compiler zig_test` followed by `:make` to test the current file;
  `:compiler zig_build` restores project builds. Zig must be installed separately.
- Go: `:make` runs `go build`; `gq` uses the bundled gofmt integration.
- `:cnext` / `:cprevious` navigate build/search errors. The two share quickfix;
  `:colder` / `:cnewer` navigate earlier result lists.
- Syntax and indentation use Vim's bundled files. YAML/TPL intentionally remain
  Helm filetypes with YAML syntax; Markdown keeps conceal and word wrapping.
- Plain yanks also copy through wl-copy on Wayland or xclip on X11, if present.
  Yanks remain in Vim registers when those tools/displays are absent.
- In playbook.sh, Enter sends a line/selection to tmux. The target is
  `g:playbook_target` or `{last}`.

## Go documentation limits

`go doc` is a one-shot command, not a resident server. `:GoDoc os.Open` and
`:GoDoc strings.Builder.WriteString` work for standard library declarations.
`K` supplies the dotted expression at the cursor; `:GoDoc TypeName` looks in the
current file's package. Imported aliases and local variable types are not
resolved. For `cpu.Model`, explicitly supply the package/type, e.g.
`:GoDoc example.org/project/pkg CPU.Model`. The popup command accepts explicit package and symbol arguments as well.

No inline type errors, semantic rename, semantic references, code lens, signature
help or type-aware completion. Compiler/build errors appear only when requested.
