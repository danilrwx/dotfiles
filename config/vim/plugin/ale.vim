vim9script

# POC: ALE (dense-analysis/ale) as the single linter + LSP client, replacing the
# yegappan/lsp setup in lsp.vim (which finishes early once g:loaded_ale_poc is set).
# ALE lives in pack/plugins/start (not opt+lazy like lsp): it doesn't retroactively
# lint the buffer already open when packadd'd, so it must load at startup.
g:loaded_ale_poc = 1

# don't lint every filetype ALE ships with; only what this config uses. gopls
# gives LSP features (hover/refs/rename/goto/completion) AND compile diagnostics,
# golangci_lint adds the project's lint rules. clangd covers c/cpp.
g:ale_linters_explicit = 1
g:ale_linters = {
  go: ['gopls', 'golangci-lint'],
  c: ['clangd'],
  cpp: ['clangd'],
}

# format-on-save mirrors the old `autocmd BufWritePre *.go LspFormat`. Only go has
# fixers configured, so fix_on_save is a no-op elsewhere.
g:ale_fixers = {
  go: ['goimports', 'gofmt'],
}
g:ale_fix_on_save = 1

# golangci-lint per-package (its default) — single-file mode misses cross-file rules.
g:ale_go_golangci_lint_package = 1

# omnifunc-driven completion, same popup UX as the native completeopt already set.
g:ale_completion_enabled = 1

# inline diagnostic on the cursor line only; full text via <c-w>d (ALEDetail).
g:ale_virtualtext_cursor = 'current'
g:ale_echo_cursor = 0

# whole-workspace diagnostics: LSP/linters skip unopened files, so run the project
# checker async and parse into quickfix. golangci-lint if present, else `go vet`.
var ws_out: list<string>
def OnDiagWs(title: string)
  var save = &errorformat
  &errorformat = '%-G#%.%#,%f:%l:%c:\ %m,%f:%l:\ %m'
  setqflist([], ' ', {title: title, lines: ws_out})
  &errorformat = save
  var items = getqflist()->filter((_, i) => i.valid)
  if empty(items)
    echo 'workspace: no diagnostics'
    return
  endif
  setqflist([], 'r', {title: title, items: items})
  copen
  cfirst
enddef
def DiagWs()
  var cmd = executable('golangci-lint') ? ['golangci-lint', 'run', './...']
    : executable('go') ? ['go', 'vet', './...'] : []
  if empty(cmd)
    echo 'no golangci-lint / go'
    return
  endif
  ws_out = []
  echo $'running {cmd->join(" ")} ...'
  job_start(cmd, {
    out_cb: (_, l) => add(ws_out, l),
    err_cb: (_, l) => add(ws_out, l),
    exit_cb: (_, _) => OnDiagWs(cmd->join(' ')),
  })
enddef
command! LspDiagWs DiagWs()
nnoremap <silent> <leader>D <cmd>LspDiagWs<cr>

def OnFileType()
  nnoremap <buffer> grr <cmd>ALEFindReferences<cr>
  nnoremap <buffer> gri <cmd>ALEGoToImplementation<cr>
  nnoremap <buffer> gd  <cmd>ALEGoToDefinition<cr>
  nnoremap <buffer> K   <cmd>ALEHover<cr>
  nnoremap <buffer> grS :ALESymbolSearch<space>
  nnoremap <buffer> gra <cmd>ALECodeAction<cr>
  nnoremap <buffer> grn <cmd>ALERename<cr>
  nnoremap <buffer> grf <cmd>ALEFix<cr>
  nnoremap <buffer> grI <cmd>ALEOrganizeImports<cr>
  nnoremap <buffer> <c-w>d <cmd>ALEDetail<cr>
  nnoremap <buffer> [d <cmd>ALEPreviousWrap<cr>
  nnoremap <buffer> ]d <cmd>ALENextWrap<cr>
enddef

autocmd FileType go,gomod,c,cpp OnFileType()
