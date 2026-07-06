vim9script

# yegappan/lsp lives in pack/plugins/opt and is packadd'd lazily on the first
# code filetype. The plugin supports late packadd (enables immediately when
# loaded after VimEnter), so servers register and attach on that first file.

var lspOpts = {
  autoHighlightDiags: true,
  useQuickfixForLocations: true,
  semanticHighlight: true,
  showInlayHints: false,
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
  nnoremap [d :LspDiag prev<cr>
  nnoremap ]d :LspDiag next<cr>

  autocmd! BufWritePre *.go call execute('LspFormat')
enddef
autocmd User LspAttached call On_lsp_buffer_enabled()

# lazy: load the plugin only when a supported code file is first opened
autocmd FileType go,gomod,c,cpp ++once packadd lsp
