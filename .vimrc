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

	Plug 'tpope/vim-sensible'

	Plug 'tpope/vim-unimpaired'

	Plug 'tpope/vim-endwise'

	Plug 'tpope/vim-commentary'

	Plug 'mbbill/undotree'

	Plug 'markonm/traces.vim'

	Plug 'jiangmiao/auto-pairs'

	Plug 'fatih/vim-go'

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

nnoremap <Leader>s :s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>
nnoremap <Leader>S :%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>

nnoremap <C-L> <Cmd>nohlsearch<Bar>diffupdate<CR><C-L>

highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/
nnoremap <Leader>ds :%s/\s\+$//gi<CR>

command! -nargs=+ Grep execute 'silent grep! <args>' | copen

let g:go_fmt_fail_silently = 0
let g:go_fmt_command = 'goimports'
let g:go_fmt_autosave = 1
let g:go_gopls_enabled = 1
let g:go_highlight_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
let g:go_highlight_function_calls = 1
let g:go_highlight_operators = 1
let g:go_highlight_extra_types = 1
let g:go_highlight_variable_declarations = 1
let g:go_highlight_variable_assignments = 1
let g:go_highlight_build_constraints = 1
let g:go_highlight_diagnostic_errors = 1
let g:go_highlight_diagnostic_warnings = 1
let g:go_auto_sameids = 0
set updatetime=100
