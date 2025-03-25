syntax on
filetype plugin on

set langmap=ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯ;ABCDEFGHIJKLMNOPQRSTUVWXYZ,фисвуапршолдьтщзйкыегмцчня;abcdefghijklmnopqrstuvwxyz

colorscheme jellybeans-nvim
" let g:airline_theme = 'base16_default_dark'
let g:blamer_enabled = 1

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
set signcolumn=no
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

nnoremap <silent> <leader>= :res +5<CR>
nnoremap <silent> <leader>- :res -5<CR>
nnoremap <silent> <leader>0 :vertical res +5<CR>
nnoremap <silent> <leader>9 :vertical res -5<CR>

nnoremap <silent> <leader>sc :noh<cr>

" Двигать линии с шифтом
noremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv

noremap <silent> <leader>sh :terminal<CR>

noremap <leader>h :<C-u>split<CR>
noremap <leader>v :<C-u>vsplit<CR>

nmap <leader>w :update<CR>

map <leader>vl :vsp $MYVIMRC<CR>
map <leader>vr :source $MYVIMRC<CR>

vmap gcc <plug>NERDCommenterToggle
nmap gcc <plug>NERDCommenterToggle

" Открываем ranger
nmap <silent> <leader><leader> :RnvimrToggle<CR>
let g:rnvimr_presets = [{'width': 0.950, 'height': 0.950}]
let g:rnvimr_enable_picker = 1
let g:rnvimr_enable_bw = 1

" Открываем LazyGit
nnoremap <silent> <leader>gg :LazyGit<CR>

" Закрываем окрытый буфер
nmap <silent> <leader>q :bd<CR>
nmap <silent> <tab> :bn<CR>

nmap <silent> <leader>cr :SnipRun<CR>

" Плавный скролл
lua require('neoscroll').setup()

" https://github.com/tpope/vim-endwise/issues/11
execute "inoremap {<CR> {<CR>}<ESC>O"

autocmd FileType scss setl iskeyword+=@-@
nmap <leader>fr <Plug>CtrlSFPrompt
