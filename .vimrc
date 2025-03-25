if has("eval")                               " vim-tiny lacks 'eval'
  let skip_defaults_vim = 1
endif

let mapleader=" "

set nocompatible
set autoindent
set expandtab
set noignorecase
set autowrite
set number
set ruler
set showmode
set noerrorbells
set visualbell
set vb t_vb=
set softtabstop=2
set shiftwidth=2
set tabstop=2
set smartindent
set smarttab
set nowrap

if v:version >= 800
  set nofixendofline
  set listchars=space:*,trail:*,nbsp:*,extends:>,precedes:<,tab:\|>
  set foldmethod=manual
  set nofoldenable
endif

set relativenumber

set spc=

set backup
set backupdir=~/.vim/.backup/,/tmp//
set directory=~/.vim/.swp/,/tmp//
set undofile
set undodir=~/.vim/.undo/,/tmp//

set icon

set scrolloff=999

" highlight search hits
set hlsearch
set incsearch
set linebreak

" avoid most of the 'Hit Enter ...' messages
set shortmess=aoOtTI

" prevents truncated yanks, deletes, etc.
set viminfo='20,<1000,s1000

if has("eval")
  let g:loaded_matchparen=1
endif

set showmatch

set wrapscan
set wrap

set hidden

set history=100

if has("syntax")
  syntax enable
endif

set ttyfast

filetype plugin on

set cinoptions+=:0

set laststatus=1

set wildmenu

set mouse=a

set path=.,,**

set signcolumn=number

set updatetime=100

" mark trailing spaces as errors
match errorMsg '\s\+$'

" auto set background on mac
let output =  system("defaults read -g AppleInterfaceStyle")
if v:shell_error != 0
    set background=light
else
    set background=dark
endif

set notermguicolors
highlight SignColumn ctermbg=NONE
" highlight ColorColumn ctermbg=238
highlight CursorLine cterm=none ctermbg=250
highlight CursorLineNr cterm=none ctermbg=250

" colorscheme retrobox
hi StatusLine ctermbg=NONE
hi StatusLineNC ctermbg=NONE
hi Normal ctermbg=NONE
hi LineNr ctermbg=NONE
hi SpecialKey ctermbg=NONE
hi ModeMsg cterm=NONE ctermbg=NONE
hi MoreMsg ctermbg=NONE
hi NonText ctermbg=NONE
hi vimGlobal ctermbg=NONE

set omnifunc=syntaxcomplete#Complete

nnoremap <S-l> :bn<cr>
nnoremap <S-h> :bp<cr>

nnoremap <C-j> :cnext<cr>
nnoremap <C-k> :cprev<cr>

nnoremap <C-l> :nohl<cr>

function! ToggleQuickFix()
    if empty(filter(getwininfo(), 'v:val.quickfix'))
        copen
    else
        cclose
    endif
endfunction
nnoremap <silent> <leader>q :call ToggleQuickFix()<cr>

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
    Plug 'sheerun/vim-polyglot'

    Plug 'tpope/vim-commentary'
    Plug 'tpope/vim-fugitive'
    Plug 'tpope/vim-obsession'

    Plug 'airblade/vim-gitgutter'

    Plug 'preservim/vimux'

    " Plug 'charlespascoe/vim-go-syntax'
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
        \          semanticTokens: v:true
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

  nnoremap <leader>gg :!lazygit<cr><cr>
  nnoremap <leader>gs :tab Git<cr>
  nnoremap <leader>gl :tab Git log --follow -p %<cr>
  nnoremap <leader>gL :tab Git log<cr>
  nnoremap <leader>gK :tab Git log -p<cr>
  nnoremap <leader>gb :tab Git blame<cr>
  nnoremap <leader>gd :tab Git diff %<cr>
  nnoremap <leader>gD :tab Git diff <cr>
  nnoremap <leader>gP :Git push<cr>
  nnoremap <leader>gp :Git pull --rebase<cr>

  nnoremap ghs <Plug>(GitGutterStageHunk)
  nnoremap ghu <Plug>(GitGutterUndoHunk)
  nnoremap ghp <Plug>(GitGutterPreviewHunk)
endif
