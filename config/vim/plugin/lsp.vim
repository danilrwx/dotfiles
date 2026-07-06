vim9script

# yegappan/lsp lives in pack/plugins/opt and is packadd'd lazily on the first
# code filetype. The plugin supports late packadd (enables immediately when
# loaded after VimEnter), so servers register and attach on that first file.

# the plugin drops diagnostics for files without a buffer (push model), so this
# aggregates every loaded buffer's diagnostics into one quickfix list. The heavy
# lifting lives in autoload/localdiag.vim, which imports lsp internals and so
# must load after packadd — packadd here guarantees that when called directly.
import autoload 'localdiag.vim'
def DiagAll()
  silent! packadd lsp
  localdiag.All()
enddef
command! LspDiagAll DiagAll()

# whole-workspace diagnostics: LSP can't (drops unopened files), so run the
# project checker async and parse into quickfix. golangci-lint if present, else
# `go vet` (which also type-checks, so compile errors surface too).
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

var lspOpts = {
  autoHighlightDiags: true,
  useQuickfixForLocations: true,
  semanticHighlight: true,
  showInlayHints: false,
  ignoreMissingServer: true,
}
autocmd User LspSetup call LspOptionsSet(lspOpts)

var lspServers = [{
  name: 'golang',
  filetype: ['go', 'gomod'],
  path: exepath('gopls'),
  args: ['serve'],
  syncInit: false,
  workspaceConfig: {
    gopls: {
      hints: {
        assignVariableTypes: true,
        compositeLiteralFields: true,
        compositeLiteralTypes: true,
        constantValues: true,
        functionTypeParameters: true,
        parameterNames: true,
        rangeVariableTypes: true,
        semanticTokens: false
      }
    }
  }
},
{
  name: 'clangd',
  filetype: ['c', 'cpp'],
  path: exepath('clangd'),
  args: ['--background-index']
},
]
autocmd User LspSetup call LspAddServer(lspServers)

def On_lsp_buffer_enabled()
  setlocal omnifunc=g:LspOmniFunc
  setlocal tagfunc=lsp#lsp#TagFunc
  setlocal formatexpr=lsp#lsp#FormatExpr()

  nnoremap grr :LspShowReferences<cr>
  nnoremap gri :LspPeekImpl<cr>
  nnoremap K   :LspHover<cr>
  nnoremap grs :LspDocumentSymbol<cr>
  nnoremap grS :LspSymbolSearch<cr>
  nnoremap gra :LspCodeAction<cr>
  nnoremap grc :LspCodeLens<cr>
  nnoremap grn :LspRename<cr>
  nnoremap grf :LspFormat<cr>
  nnoremap <c-w>d :LspDiag current<cr>
  nnoremap grd :LspDiagAll<cr>
  nnoremap grD :LspDiagWs<cr>
  nnoremap [d :LspDiag prev<cr>
  nnoremap ]d :LspDiag next<cr>

  autocmd! BufWritePre *.go call execute('LspFormat')
enddef
autocmd User LspAttached call On_lsp_buffer_enabled()

# lazy: load the plugin only when a supported code file is first opened
autocmd FileType go,gomod,c,cpp ++once packadd lsp
