set nocompatible
"" set lazyredraw
set ttyfast
set number
set relativenumber
set hlsearch
set ignorecase
set nojoinspaces
set smarttab
set smartindent
set softtabstop=2
set tabstop=2
set shiftwidth=2
set signcolumn=yes
set scrolloff=3
set undodir=/tmp/.vim/backups
set undofile
set path+=**
set wildmenu
set langmap=ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯ;ABCDEFGHIJKLMNOPQRSTUVWXYZ,фисвуапршолдьтщзйкыегмцчня;abcdefghijklmnopqrstuvwxyz
syntax on
filetype plugin on

if has('mouse')
  set mouse=a
endif

if has("clipboard")
  set clipboard=unnamed " copy to the system clipboard

  if has("unnamedplus") " X11 support
    set clipboard+=unnamedplus
  endif
endif

if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')

Plug 'tpope/vim-endwise'
Plug 'tpope/vim-commentary'
Plug 'sheerun/vim-polyglot'
Plug 'dense-analysis/ale'
Plug 'jsit/disco.vim'

call plug#end()

colorscheme disco
hi SignColumn ctermbg=NONE ctermbg=NONE

let mapleader = "\<Space>"

nnoremap <expr> k (v:count == 0 ? 'gk' : 'k')
nnoremap <expr> j (v:count == 0 ? 'gj' : 'j')
nnoremap <expr> л (v:count == 0 ? 'gk' : 'k')
nnoremap <expr> о (v:count == 0 ? 'gj' : 'j')

map <C-k> <C-w><Up>
map <C-j> <C-w><Down>
map <C-l> <C-w><Right>
map <C-h> <C-w><Left>

vmap "y "*y
nmap "y "*y
nmap "Y "*Y
nmap "p "*p
nmap "P "*P

nnoremap gV `[v`]

nnoremap <Leader>gg :!lazygit<CR>

