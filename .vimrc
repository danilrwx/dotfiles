if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')

Plug 'catppuccin/vim', { 'as': 'catppuccin' }
Plug 'tpope/vim-endwise'
Plug 'mnishz/colorscheme-preview.vim'

call plug#end()

let mapleader = "\<Space>"

syntax on
filetype plugin on

set langmap=ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯ;ABCDEFGHIJKLMNOPQRSTUVWXYZ,фисвуапршолдьтщзйкыегмцчня;abcdefghijklmnopqrstuvwxyz

colorscheme catppuccin_frappe
set termguicolors
hi Normal guibg=NONE ctermbg=NONE

if has('mouse')
  set mouse=a
endif

if has("clipboard")
  set clipboard=unnamed " copy to the system clipboard

  if has("unnamedplus") " X11 support
    set clipboard+=unnamedplus
  endif
endif

set lazyredraw
set ttyfast
set number
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

