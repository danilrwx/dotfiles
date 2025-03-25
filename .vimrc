if has("eval")                               " vim-tiny lacks 'eval'
  let skip_defaults_vim = 1
endif

set nocompatible

filetype plugin indent on  " Load plugins according to detected filetype.
syntax on                  " Enable syntax highlighting.

set autoindent             " Indent according to previous line.
set expandtab              " Use spaces instead of tabs.
set tabstop=2              " Use 2 spaces for indenting.
set softtabstop=2          " Tab key indents by 2 spaces.
set shiftwidth =2          " >> indents by 2 spaces.
set shiftround             " >> indents to next multiple of 'shiftwidth'.

set backspace=indent,eol,start " Make backspace work as you would expect.
set hidden                 " Switch between buffers without having to save first.
set laststatus=2           " Always show statusline.
set display=lastline       " Show as much as possible of the last line.

set showmode               " Show current mode in command-line.
set showcmd                " Show already typed keys when more are expected.

set incsearch              " Highlight while searching with / or ?.
set hlsearch               " Keep matches highlighted.

set ttyfast                " Faster redrawing.
set lazyredraw             " Only redraw when necessary.

set splitbelow             " Open new windows below the current window.
set splitright             " Open new windows right of the current window.

set nocursorline           " Disable current line highlight.
set wrapscan               " Searches wrap around end-of-file.
set report=0               " Always report changed lines.
set synmaxcol=200          " Only highlight the first 200 columns.

set laststatus=1           " Set minimal bottom statusline

set number                 " Set line numbers
set relativenumber         " Set relative linenumbers

set updatetime=100         " Fast redraw
set signcolumn=yes         " Always render signcolumn
set shortmess=aoOtTI       " Avoid most of the 'Hit Enter ...' messages
set wildmenu               " Better command-line completion
set mouse=a                " Enable mouse support

set complete-=i            " disable scanning included files
set complete-=t            " disable searching tags

" The fish shell is not very compatible to other shells and unexpectedly
" breaks things that use 'shell'.
if &shell =~# 'fish$'
  set shell=/bin/bash
endif

" Put all temporary files under the same directory.
" https://github.com/mhinz/vim-galore#temporary-files
set backup
set backupdir=$HOME/.vim/files/backup/
set backupext=-vimbackup
set backupskip=
set directory=$HOME/.vim/files/swap/
set updatecount=100
set undofile
set undodir=$HOME/.vim/files/undo/
set viminfo='100,n$HOME/.vim/files/info/viminfo

" mark trailing spaces as errors
match errorMsg '\s\+$'

if v:version >= 1200
  set termguicolors
  colorscheme retrobox
else
  set notermguicolors
  highlight SignColumn ctermbg=NONE
  highlight CursorLine cterm=none ctermbg=250
  highlight CursorLineNr cterm=none ctermbg=250
endif

set omnifunc=syntaxcomplete#Complete

let mapleader=" "

nnoremap <S-l> :bn<cr>
nnoremap <S-h> :bp<cr>

nnoremap <C-l> :nohl<cr>

function! ToggleQuickFix()
    if empty(filter(getwininfo(), 'v:val.quickfix'))
        copen
    else
        cclose
    endif
endfunction
nnoremap <silent> <leader>q :call ToggleQuickFix()<cr>
nnoremap <C-j> :cnext<cr>
nnoremap <C-k> :cprev<cr>

function! TrimWhitespace()
    let l:save = winsaveview()
    keeppatterns %s/\s\+$//e
    call winrestview(l:save)
endfun
autocmd BufWritePre * call TrimWhitespace()

function! FzyCommand(choice_command, vim_command)
  try
    let output = system(a:choice_command . " | fzy ")
  catch /Vim:Interrupt/
    " Swallow errors from ^C, allow redraw! below
  endtry
  redraw!
  if v:shell_error == 0 && !empty(output)
    exec a:vim_command . ' ' . output
  endif
endfunction

nnoremap <leader>f :call FzyCommand("find . -type f", ":e")<cr>
nnoremap <leader>g :call FzyCommand("git ls-files", ":e")<cr>

if filereadable(expand("~/.vim/autoload/plug.vim"))
  call plug#begin('~/.local/share/vim/plugins')
    Plug 'tpope/vim-commentary'
    Plug 'tpope/vim-fugitive'
    Plug 'tpope/vim-obsession'

    Plug 'airblade/vim-gitgutter'

    Plug 'mbbill/undotree'

    Plug 'charlespascoe/vim-go-syntax'
    Plug 'kyoh86/vim-go-coverage'
    Plug 'sebdah/vim-delve'

    Plug 'vim-test/vim-test'
    Plug 'yegappan/lsp'
  call plug#end()

  let lspOpts = #{
        \  autoHighlightDiags: v:true,
        \  useQuickfixForLocations: v:true,
        \  semanticHighlight: v:true,
        \  showInlayHints: v:false,
        \ }

  autocmd User LspSetup call LspOptionsSet(lspOpts)

  " Go language server
  let lspServers = [#{
        \    name: 'clangd',
        \    filetype: ['c', 'cpp'],
        \    path: '/usr/bin/clangd',
        \    args: ['--background-index']
        \  },
        \ #{
        \    name: 'golang',
        \    filetype: ['go', 'gomod'],
        \    path: '/Users/danil/go/bin/gopls',
        \    args: ['serve'],
        \    syncInit: v:true,
        \    workspaceConfig: #{
        \      gopls: #{
        \        hints: #{
        \          assignVariableTypes: v:true,
        \          compositeLiteralFields: v:true,
        \          compositeLiteralTypes: v:true,
        \          constantValues: v:true,
        \          functionTypeParameters: v:true,
        \          parameterNames: v:true,
        \          rangeVariableTypes: v:true,
        \          semanticTokens: v:false
        \        }
        \      }
        \    }
        \ }]
  autocmd User LspSetup call LspAddServer(lspServers)

  nnoremap gr :LspPeekReferences<cr>
  nnoremap gd :LspGotoDefinition<cr>
  nnoremap gD :LspGotoDeclaration<cr>
  nnoremap gI :LspPeekImpl<cr>
  nnoremap <leader>k  :LspHover<cr>

  nnoremap <leader>cs :LspDocumentSymbol<cr>
  nnoremap <leader>cS :LspSymbolSearch<cr>

  nnoremap <leader>co :LspOutgoingCalls<cr>
  nnoremap <leader>ci :LspIncomingCalls<cr>

  nnoremap <leader>ca :LspCodeAction<cr>
  nnoremap <leader>cc :LspCodeLens<cr>
  nnoremap <leader>cr :LspRename<cr>
  nnoremap <leader>cf :LspFormat<cr>

  nnoremap <c-w>d :LspDiag current<cr>
  nnoremap [d :LspDiag prev<cr>
  nnoremap ]d :LspDiag next<cr>

  nnoremap <silent> <leader>tr :TestNearest<cr>
  nnoremap <silent> <leader>tt :TestFile<cr>
  nnoremap <silent> <leader>ta :TestSuite<cr>
  nnoremap <silent> <leader>tl :TestLast<cr>
  nnoremap <silent> <leader>tv :TestVisit<cr>

  nnoremap <leader>gl :tab Git log --follow -p %<cr>
  nnoremap <leader>gL :tab Git log<cr>
  nnoremap <leader>gb :tab Git blame<cr>
  nnoremap <leader>gd :tab Git diff %<cr>
  nnoremap <leader>gD :tab Git diff <cr>
  nnoremap <leader>gP :Git push<cr>
  nnoremap <leader>gp :Git pull --rebase<cr>

  nnoremap <leader>u :UndotreeToggle<cr>

  nnoremap ghs <Plug>(GitGutterStageHunk)
  nnoremap ghu <Plug>(GitGutterUndoHunk)
  nnoremap ghp <Plug>(GitGutterPreviewHunk)
endif
