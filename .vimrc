if has("eval")                               " vim-tiny lacks 'eval'
  let skip_defaults_vim = 1
endif

let mapleader=" "

set nocompatible
set autoindent
set expandtab
set noignorecase
set autowrite
set number
set ruler
set showmode
set noerrorbells
set visualbell
set vb t_vb=
set softtabstop=2
set shiftwidth=2
set tabstop=2
set smartindent
set smarttab
set nowrap

if v:version >= 800
  set nofixendofline
  set listchars=space:*,trail:*,nbsp:*,extends:>,precedes:<,tab:\|>
  set foldmethod=manual
  set nofoldenable
endif

set relativenumber

set spc=

set backup
set backupdir=~/.vim/.backup/,/tmp//
set directory=~/.vim/.swp/,/tmp//
set undofile
set undodir=~/.vim/.undo/,/tmp//

set icon

set scrolloff=999

" highlight search hits
set hlsearch
set incsearch
set linebreak

" avoid most of the 'Hit Enter ...' messages
set shortmess=aoOtTI

" prevents truncated yanks, deletes, etc.
set viminfo='20,<1000,s1000

if has("eval")
  let g:loaded_matchparen=1
endif

set showmatch

set wrapscan
set wrap

set hidden

set history=100

if has("syntax")
  syntax enable
endif

set ttyfast

filetype plugin on

set cinoptions+=:0

set laststatus=0

set wildmenu

set mouse=a

" mark trailing spaces as errors
match errorMsg '\s\+$'

set notermguicolors
highlight SignColumn ctermbg=NONE
highlight ColorColumn ctermbg=238
highlight Visual ctermfg=none ctermbg=238
highlight CursorLine cterm=none ctermbg=238
highlight CursorLineNr cterm=none ctermbg=NONE

set omnifunc=syntaxcomplete#Complete
imap <tab><tab> <c-x><c-o>

nnoremap <C-d> <C-d>zz<CR>
nnoremap <C-u> <C-u>zz<CR>

nnoremap <C-s> :w<CR>

execute "set <A-q>=\eq"
nnoremap <A-q> :bd<CR>

nnoremap <S-l> :bn<CR>
nnoremap <S-h> :bp<CR>

nnoremap <C-j> :cnext<CR>
nnoremap <C-k> :cprev<CR>

nnoremap <C-l> :nohl<CR>

nnoremap <Leader>e :%s/<C-r><C-w>/<C-r><C-w>
nnoremap <Leader>E :%s/<C-r><C-w>/

nnoremap <Leader>l :ls<CR>:b<space>

map <leader>s :e %%

function! ToggleQuickFix()
    if empty(filter(getwininfo(), 'v:val.quickfix'))
        copen
    else
        cclose
    endif
endfunction
nnoremap <silent> <C-q> :call ToggleQuickFix()<cr>

function! TrimWhitespace()
    let l:save = winsaveview()
    keeppatterns %s/\s\+$//e
    call winrestview(l:save)
endfun
autocmd BufWritePre * call TrimWhitespace()

if filereadable(expand("~/.vim/autoload/plug.vim"))
  call plug#begin('~/.local/share/vim/plugins')
    Plug 'jasonccox/vim-wayland-clipboard'
    Plug 'tpope/vim-fugitive'
    Plug 'fatih/vim-go', { 'do': ':GoInstallBinaries' }
    Plug 'girishji/scope.vim'
    Plug 'ubaldot/vim-highlight-yanked'
    Plug 'yegappan/lsp'
  call plug#end()

  let lspOpts = #{
        \  autoHighlightDiags: v:true,
        \  useQuickfixForLocations: v:true,
        \ }

  autocmd User LspSetup call LspOptionsSet(lspOpts)

  " Go language server
  " let lspServers = [#{
  "       \    name: 'golang',
  "       \    filetype: ['go', 'gomod'],
  "       \    path: '/Users/danil/.asdf/shims/gopls',
  "       \    args: ['serve'],
  "       \    syncInit: v:true,
  "       \    workspaceConfig: #{
  "       \      gopls: #{
  "       \        hints: #{
  "       \          assignVariableTypes: v:true,
  "       \          compositeLiteralFields: v:true,
  "       \          compositeLiteralTypes: v:true,
  "       \          constantValues: v:true,
  "       \          functionTypeParameters: v:true,
  "       \          parameterNames: v:true,
  "       \          rangeVariableTypes: v:true
  "       \        }
  "       \      }
  "       \    }
  "       \ }]
  " autocmd User LspSetup call LspAddServer(lspServers)

  " let g:ale_set_signs = 1
  " let g:ale_linters = {'go': ['golangci-lint', 'gofmt','gobuild']}
  " let g:ale_linter_aliases = {'bash': 'sh'}
  " let g:ale_fixers = {
  "       \'sh': ['shfmt'],
  "       \'bash': ['shfmt'],
  "       \}
  " let g:ale_fix_on_save = 0

  " golang
  let g:go_fmt_fail_silently = 0
  let g:go_fmt_command = 'goimports'
  let g:go_list_type = "quickfix"
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

  let g:go_code_completion_enabled = 1
  let g:go_auto_type_info = 1 " forces 'Press ENTER' too much
  let g:go_auto_sameids = 0
  let g:go_gopls_analyses = { 'composites' : v:false }
  let g:go_metalinter_enabled = ['vet', 'golint', 'errcheck']
  let g:go_metalinter_autosave = 1
  let g:go_metalinter_autosave_enabled = ['vet', 'golint', 'golangci-lint']
  let g:go_metalinter_deadline = "5s"
  set updatetime=100

  autocmd FileType go nmap <leader>t  <Plug>(go-test)
  autocmd FileType go nmap <leader>b  <Plug>(go-build)
  autocmd FileType go nmap gr :GoReferrers<CR>
  autocmd FileType go nmap gI :GoImplements<CR>

  function! s:build_go_files()
    let l:file = expand('%')
    if l:file =~# '^\f\+_test\.go$'
      call go#test#Test(0, 1)
    elseif l:file =~# '^\f\+\.go$'
      call go#cmd#Build(0)
    endif
  endfunction

  autocmd FileType go nmap <leader>b :<C-u>call <SID>build_go_files()<CR>
  autocmd FileType go nmap <Leader>n iif err != nil {<ESC>==

  nnoremap <leader>fb :FuzzyBuffers<CR>
  nnoremap <leader>ff :Scope File<CR>
  nnoremap <leader>fg :Scope Grep<CR>

  nnoremap <leader>gg :!lazygit<CR><CR>
  nnoremap <leader>gs :tab Git<CR>
  nnoremap <leader>gl :tab Git log --follow -p %<CR>
  nnoremap <leader>gL :tab Git log<CR>
  nnoremap <leader>gK :tab Git log -p<CR>
  nnoremap <leader>gb :tab Git blame<CR>
  nnoremap <leader>gd :tab Git diff %<CR>
  nnoremap <leader>gD :tab Git diff <CR>
  nnoremap <leader>gP :Git push<CR>
  nnoremap <leader>gp :Git pull --rebase<CR>
else
  autocmd vimleavepre *.go !gofmt -w % " backup if fatih fails
endif
