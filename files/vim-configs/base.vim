syntax on
filetype plugin on

set langmap=ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯ;ABCDEFGHIJKLMNOPQRSTUVWXYZ,фисвуапршолдьтщзйкыегмцчня;abcdefghijklmnopqrstuvwxyz

colorscheme onedark
let g:airline_theme='onedark'

let $NVIM_TUI_ENABLE_TRUE_COLOR=1

if (has("termguicolors"))
 set termguicolors
endif

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
set cursorline

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

nnoremap <silent> <Leader>= :res +2<CR>
nnoremap <silent> <Leader>- :res -2<CR>
nnoremap <silent> <Leader>0 :vertical res +2<CR>
nnoremap <silent> <Leader>9 :vertical res -2<CR>

nnoremap <silent> <leader>sc :noh<cr>

noremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv

noremap <silent> <leader>sh :terminal<CR>

noremap <Leader>h :<C-u>split<CR>
noremap <Leader>v :<C-u>vsplit<CR>

noremap <Leader>s :update<CR>

map <leader>vl :vsp $MYVIMRC<CR>
map <leader>vr :source $MYVIMRC<CR>

vmap gcc <plug>NERDCommenterToggle
nmap gcc <plug>NERDCommenterToggle

let g:NERDDefaultAlign = 'left'
let g:NERDSpaceDelims = 1

" https://github.com/tpope/vim-endwise/issues/11
execute "inoremap {<CR> {<CR>}<ESC>O"

autocmd FileType scss setl iskeyword+=@-@
nmap <leader>fr <Plug>CtrlSFPrompt
