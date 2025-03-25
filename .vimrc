if has("eval")             " vim-tiny lacks 'eval'
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

if v:version >= 900
  set termguicolors
  set background=dark
  colorscheme retrobox
else
  set notermguicolors
  highlight SignColumn ctermbg=NONE
  highlight CursorLine cterm=none ctermbg=250
  highlight CursorLineNr cterm=none ctermbg=250
endif

if has("gui_macvim")
    set guifont=Iosevka\ Nerd\ Font:h22
	  let macvim_hig_shift_movement = 1
endif

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

if executable('ugrep')
  nnoremap <leader>f :call FzyCommand("ugrep '' . -Rl -I --ignore-files --exclude='zz_generated*' --exclude-dir='generated'", ":e")<cr>
else
  nnoremap <leader>f :call FzyCommand("find . -type f", ":e")<cr>
endif

nnoremap <leader>sf :call FzyCommand("find . -type f", ":e")<cr>
nnoremap <leader>sg :call FzyCommand("git ls-files", ":e")<cr>

if filereadable(expand("~/.vim/autoload/plug.vim"))
  call plug#begin('~/.local/share/vim/plugins')
    Plug 'tpope/vim-commentary'
    Plug 'tpope/vim-fugitive'

    Plug 'airblade/vim-gitgutter'

    Plug 'mbbill/undotree'

    Plug 'charlespascoe/vim-go-syntax'
    Plug 'kyoh86/vim-go-coverage'
    Plug 'sebdah/vim-delve'

    Plug 'vim-test/vim-test'

    Plug 'prabirshrestha/vim-lsp'
    Plug 'mattn/vim-lsp-settings'

    Plug 'prabirshrestha/asyncomplete.vim'
    Plug 'prabirshrestha/asyncomplete-lsp.vim'
  call plug#end()

  let g:lsp_settings = {
        \  'golangci-lint-langserver': {
        \    'initialization_options': {'command': ['golangci-lint', 'run', '--out-format', 'json', '--issues-exit-code=1']}
        \   }
        \}

  let g:lsp_settings_filetype_go = ['golangci-lint-langserver', 'gopls']

  let g:lsp_semantic_enabled = 1

  let g:lsp_diagnostics_float_cursor = 1
  let g:lsp_diagnostics_virtual_text_enabled = 0
  let g:lsp_diagnostics_virtual_text_align = 'right'

  let g:lsp_document_code_action_signs_enabled = 0

  if v:version > 900
    let g:lsp_use_native_client = 1
    let g:lsp_format_sync_timeout = 1000
  endif

  augroup lsp_install
    au!
    autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
  augroup END

  function! s:on_lsp_buffer_enabled() abort
    setlocal omnifunc=lsp#complete
    if exists('+tagfunc') | setlocal tagfunc=lsp#tagfunc | endif

    nnoremap <buffer> gd <plug>(lsp-definition)
    nnoremap <buffer> gs <plug>(lsp-document-symbol-search)
    nnoremap <buffer> gS <plug>(lsp-workspace-symbol-search)
    nnoremap <buffer> gr <plug>(lsp-references)
    nnoremap <buffer> gI <plug>(lsp-implementation)
    nnoremap <buffer> gD <plug>(lsp-type-definition)

    nnoremap <buffer> [d <plug>(lsp-previous-diagnostic)
    nnoremap <buffer> ]d <plug>(lsp-next-diagnostic)

    nnoremap <buffer> K <plug>(lsp-hover)

    nnoremap <buffer> <expr><c-f> lsp#scroll(+4)
    nnoremap <buffer> <expr><c-b> lsp#scroll(-4)

    inoremap <buffer> <expr><c-f> lsp#scroll(+4)
    inoremap <buffer> <expr><c-d> lsp#scroll(-4)

    nnoremap <buffer> <leader>cr <plug>(lsp-rename)
    nnoremap <buffer> <leader>cc <plug>(lsp-code-lens)
    nnoremap <buffer> <leader>ca <plug>(lsp-code-action)

    autocmd! BufWritePre *.rs,*.go call execute('LspDocumentFormatSync')
  endfunction

  nnoremap <silent> <leader>tr :TestNearest<cr>
  nnoremap <silent> <leader>tt :TestFile<cr>
  nnoremap <silent> <leader>ta :TestSuite<cr>
  nnoremap <silent> <leader>tl :TestLast<cr>
  nnoremap <silent> <leader>tv :TestVisit<cr>

  nnoremap <silent> <leader>gl :tab Git log --follow -p %<cr>
  nnoremap <silent> <leader>gL :tab Git log<cr>
  nnoremap <silent> <leader>gb :tab Git blame<cr>
  nnoremap <silent> <leader>gd :tab Git diff %<cr>
  nnoremap <silent> <leader>gD :tab Git diff <cr>
  nnoremap <silent> <leader>gP :Git push<cr>
  nnoremap <silent> <leader>gp :Git pull --rebase<cr>

  nnoremap <silent> <leader>u :UndotreeToggle<cr>

  nnoremap ghs <plug>(GitGutterStageHunk)
  nnoremap ghu <plug>(GitGutterUndoHunk)
  nnoremap ghp <plug>(GitGutterPreviewHunk)
endif
