set nocompatible

set number
set relativenumber
set signcolumn=number

set hlsearch
set ignorecase

set smarttab
set smartindent
set softtabstop=2
set tabstop=2
set shiftwidth=2

set undodir=/tmp/.vim/backups
set undofile

set langmap=ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯ;ABCDEFGHIJKLMNOPQRSTUVWXYZ,фисвуапршолдьтщзйкыегмцчня;abcdefghijklmnopqrstuvwxyz

set path=.,,**
set wildmenu
set wildignore=*/dist*/*,*/target/*,*/builds/*,*/node_modules/*

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

Plug 'sheerun/vim-polyglot'

Plug 'tpope/vim-endwise'

Plug 'tpope/vim-commentary'

Plug 'jsit/disco.vim'

Plug 'mbbill/undotree'

Plug 'markonm/traces.vim'

Plug 'fatih/vim-go'

call plug#end()

colorscheme disco
let mapleader = "\<Space>"

nnoremap <Leader>gg :!lazygit<CR>
nnoremap <Leader>pp :Ex<CR>
nnoremap <Leader><Leader> :find 
nnoremap <Tab> :buffers<CR>:buffer<Space>

nnoremap <Leader>q :bd<CR>
nnoremap <Leader>u :UndotreeToggle<CR>

vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv

nnoremap J mzJ`z
nnoremap <C-d> <C-d>zz
nnoremap <C-u> <C-u>zz
nnoremap n nzzzv
nnoremap N Nzzzv

xnoremap <Leader>p "_dP

vnoremap <Leader>d "_d
nnoremap <Leader>d "_d

nnoremap <Leader>s :%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>

nnoremap <esc> :noh<return><esc>

