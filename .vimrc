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

set clipboard=unnamed,unnamedplus

set laststatus=1
set showcmd

set mouse=a
filetype plugin on

syntax enable

if filereadable(expand("~/.vim/autoload/plug.vim"))
	call plug#begin('~/.vim/plugged')

	Plug 'sheerun/vim-polyglot'

	Plug 'tpope/vim-endwise'

	Plug 'tpope/vim-commentary'

	Plug 'mbbill/undotree'

	Plug 'markonm/traces.vim'

	Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
	Plug 'junegunn/fzf.vim'

	call plug#end()
endif

let mapleader = "\<Space>"

nnoremap <Leader>gg :!lazygit<CR>

nnoremap <Leader>pp :Ex<CR>

nnoremap <Tab> :Buffers<CR>
nnoremap <C-p> :GFiles<CR>
nnoremap <Leader>gl :GFiles?<CR>
nnoremap <Leader>pf :Files<CR>
nnoremap <Leader>ps :RG<CR>

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
nnoremap <Leader>d "_d

nnoremap <Leader>s :%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>

nnoremap <C-L> <Cmd>nohlsearch<Bar>diffupdate<CR><C-L>

highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/
nnoremap <Leader>ds :%s/\s\+$//gi

command! -nargs=+ Grep execute 'silent grep! <args>' | copen

nnoremap [q :cprev<CR>
nnoremap ]q :cnext<CR>
nnoremap <Leader>co :copen<CR>
nnoremap <Leader>cc :cclose<CR>

function! QuickfixMapping()
  nnoremap <buffer> K :cprev<CR>zz<C-w>w
  nnoremap <buffer> J :cnext<CR>zz<C-w>w
  nnoremap <buffer> <leader>u :set modifiable<CR>
  nnoremap <buffer> <leader>w :cgetbuffer<CR>:cclose<CR>:copen<CR>
  nnoremap <buffer> <leader>r :cdo s/// \| update<C-Left><C-Left><Left><Left><Left>
endfunction

augroup quickfix_group
	autocmd!
	autocmd filetype qf call QuickfixMapping()
	autocmd filetype qf setlocal errorformat+=%f\|%l\ col\ %c\|%m
augroup END

