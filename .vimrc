set nocompatible

filetype on
filetype plugin on
filetype indent on

set mouse=a

syntax on

set number
set relativenumber

set expandtab
set smarttab
set shiftwidth=2
set tabstop=2

set colorcolumn=120

set incsearch
set smartcase
set hlsearch

set showcmd
set showmode
set showmatch

set history=1000

set wildmenu
set wildmode=list:longest
set wildignore=*.docx,*.jpg,*.png,*.gif,*.pdf,*.pyc,*.exe,*.flv,*.img,*.xlsx

set autoread
au FocusGained,BufEnter * silent! checktime

" Set the space as the leader key.
let mapleader = " "

nnoremap <C-d> <C-d>zz
nnoremap <C-u> <C-u>zz
nnoremap <a-q> :bd<CR>
nnoremap <leader>b :buffers<CR>
nnoremap <tab> :Explore<CR>
map <silent> <esc> :noh<cr>

" Move a line of text using ALT+[jk]
nmap <M-j> mz:m+<cr>`z
nmap <M-k> mz:m-2<cr>`z
vmap <M-j> :m'>+<cr>`<my`>mzgv`yo`z
vmap <M-k> :m'<-2<cr>`>my`<mzgv`yo`z

