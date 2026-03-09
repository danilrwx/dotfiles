if has("eval")             " vim-tiny lacks 'eval'
  let skip_defaults_vim = 1
endif

if filereadable(expand("~/.vim/autoload/plug.vim"))
  call plug#begin('~/.local/share/vim/plugins')
  Plug 'markonm/traces.vim'
  Plug 'sheerun/vim-polyglot'

  " Plug 'tpope/vim-fugitive'
  Plug 'airblade/vim-gitgutter'

  Plug 'yegappan/lsp'

  Plug 'christoomey/vim-tmux-navigator'
  Plug 'preservim/vimux'
  Plug 'vim-test/vim-test'
  Plug 'sebdah/vim-delve'
  Plug 'charlespascoe/vim-go-syntax'

  Plug 'habamax/vim-dir'

  Plug 'laktak/tome'
  call plug#end()
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
set paste                  " fix indenting when pasting.

set backspace=indent,eol,start " Make backspace work as you would expect.
set hidden                 " Switch between buffers without having to save first.
set laststatus=2           " Always show statusline.
set display=lastline       " Show as much as possible of the last line.

set showcmd                " Show already typed keys when more are expected.

set incsearch              " Highlight while searching with / or ?.
set hlsearch               " Keep matches highlighted.

set ttyfast                " Faster redrawing.
set lazyredraw             " Only redraw when necessary.

set laststatus=1           " Set minimal bottom statusline

set number                 " Set line numbers
set relativenumber         " Set relative linenumbers

set updatetime=100         " Fast redraw
set signcolumn=yes         " Always render signcolumn
set shortmess=aoOtTI       " Avoid most of the 'Hit Enter ...' messages
set wildmenu               " Better command-line completion
set mouse=a                " Enable mouse support

" The fish shell is not very compatible to other shells and unexpectedly
" breaks things that use 'shell'.
if &shell =~# 'fish$'
  set shell=/bin/bash
endif

" Made grep great again
if executable('ugrep')
  set grepprg=ugrep\ -RInk\ --tabs=1\ --ignore-files\ --exclude='zz_generated*'\ --exclude-dir='generated'
  set grepformat=%f:%l:%c:%m,%f+%l+%c+%m,%-G%f\\\|%l\\\|%c\\\|%m
else
  set grepprg=grep\ --exclude='*zz_generated*'\ --exclude-dir='generated'
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

" colorscheme koehler
highlight SignColumn ctermbg=none
highlight LineNr ctermfg=243
highlight Pmenu ctermbg=16 ctermfg=7
highlight PmenuSel ctermbg=7 ctermfg=16
highlight SpellBad ctermfg=16
highlight SpellCap ctermfg=16
highlight SpellRare ctermfg=16
highlight SpellLocal ctermfg=16
highlight DiffAdd ctermfg=16
highlight DiffChange ctermfg=16
highlight DiffDelete ctermfg=16

if has("gui_macvim")
  set guifont=Iosevka\ Nerd\ Font:h20
  let macvim_hig_shift_movement = 1
endif

if has('patch-8.1.0311')
  packadd! cfilter
endif

if has('patch-9.1.0375')
  packadd! comment
endif

if has('patch-9.1.1230')
  packadd! hlyank
endif

if has('patch-9.0.1799')
  packadd! editorconfig
endif

let mapleader=" "

if executable('ugrep')
  nnoremap <leader>f :call FzyCommand("ugrep '' . -Rl -I --ignore-files --exclude='zz_generated*' --exclude-dir='generated'", ":e")<cr>
else
  nnoremap <leader>f :call FzyCommand("find . -type f", ":e")<cr>
endif

nnoremap <leader>b :call FzyBuffer()<cr>
nnoremap <leader>sf :call FzyCommand("find . -type f", ":e")<cr>
nnoremap <leader>sg :call FzyCommand("git ls-files", ":e")<cr>

nnoremap <silent> <leader>q :call ToggleQuickFix()<cr>
nnoremap <c-j> :cnext<cr>
nnoremap <c-k> :cprev<cr>

nnoremap <c-d> <c-d>zz<cr>
nnoremap <c-u> <c-u>zz<cr>

nnoremap <c-l> :nohl<cr>

nnoremap <silent> <leader>tr :TestNearest<cr>
nnoremap <silent> <leader>tt :TestFile<cr>
nnoremap <silent> <leader>td :DlvTestCurrent<cr>

nnoremap <silent> <leader>db :DlvToggleBreakpoint<cr>
nnoremap <silent> <leader>dc :DlvConnect :2345<cr>

nnoremap <silent> <leader>gl :tab Git log --follow -p %<cr>
nnoremap <silent> <leader>gL :tab Git log<cr>
nnoremap <silent> <leader>gb :tab Git blame<cr>

nnoremap <silent> ghs <cmd>GitGutterStageHunk<cr>
nnoremap <silent> ghu <cmd>GitGutterUndoHunk<cr>
nnoremap <silent> ghp <cmd>GitGutterPreviewHunk<cr>

nnoremap <silent> - <cmd>Dir<cr>

let g:VimuxHeight = "30%"
let g:delve_use_vimux = 1
let test#strategy = "vimux"

let g:gitgutter_sign_priority = 0
let g:gitgutter_preview_win_floating = 1

let lspOpts = #{
      \  autoHighlightDiags: v:true,
      \  useQuickfixForLocations: v:true,
      \  semanticHighlight: v:false,
      \  showInlayHints: v:false,
      \ }

autocmd User LspSetup call LspOptionsSet(lspOpts)

let lspServers = [
      \ #{
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
      \    syncInit: v:false,
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
      \ }
      \]
autocmd User LspSetup call LspAddServer(lspServers)

function! s:on_lsp_buffer_enabled()
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
endfunction
autocmd User LspAttached call s:on_lsp_buffer_enabled()

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

function! FzyBuffer()
  let bufnrs = filter(range(1, bufnr("$")), 'buflisted(v:val)')
  let buffers = map(bufnrs, 'bufname(v:val)')
  call FzyCommand('echo "' . join(buffers, "\n") . '"', ":b")
endfunction

function! ToggleQuickFix()
  if empty(filter(getwininfo(), 'v:val.quickfix'))
    copen
  else
    cclose
  endif
endfunction

function! TrimWhitespace()
  let l:save = winsaveview()
  keeppatterns %s/\s\+$//e
  call winrestview(l:save)
endfun
autocmd BufWritePre * call TrimWhitespace()
