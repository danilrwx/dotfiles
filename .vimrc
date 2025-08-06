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
set paste                  " fix indenting when pasting.

set backspace=indent,eol,start " Make backspace work as you would expect.
set hidden                 " Switch between buffers without having to save first.
set laststatus=2           " Always show statusline.
set display=lastline       " Show as much as possible of the last line.

set showcmd                " Show already typed keys when more are expected.

set incsearch              " Highlight while searching with / or ?.
set hlsearch               " Keep matches highlighted.

set ttyfast                " Faster redrawing.
set lazyredraw             " Only redraw when necessary.

set laststatus=1           " Set minimal bottom statusline

set number                 " Set line numbers
set relativenumber         " Set relative linenumbers

set updatetime=100         " Fast redraw
set signcolumn=yes         " Always render signcolumn
set shortmess=aoOtTI       " Avoid most of the 'Hit Enter ...' messages
set wildmenu               " Better command-line completion
set mouse=a                " Enable mouse support

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

if has("patch-9.0.1488") || has("nvim")
	if has('termguicolors')
		set termguicolors
	endif

	set background=dark
	colorscheme retrobox
	highlight Normal guibg=NONE
	highlight SignColumn guibg=NONE
else
	set notermguicolors
	highlight SignColumn ctermbg=NONE
	highlight CursorLine cterm=none ctermbg=250
	highlight CursorLineNr cterm=none ctermbg=250
endif

if has("gui_macvim")
	set guifont=Iosevka\ Nerd\ Font:h20
	let macvim_hig_shift_movement = 1
endif

if has('patch-8.1.0311')
	packadd! cfilter
endif

if has('patch-9.1.0375')
	packadd! comment
endif

function! ToggleQuickFix()
	if empty(filter(getwininfo(), 'v:val.quickfix'))
		copen
	else
		cclose
	endif
endfunction

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

function! FzyBuffer()
	let bufnrs = filter(range(1, bufnr("$")), 'buflisted(v:val)')
	let buffers = map(bufnrs, 'bufname(v:val)')
	call FzyCommand('echo "' . join(buffers, "\n") . '"', ":b")
endfunction

function! Lf()
	let temp = tempname()
	exec 'silent !lf -selection-path=' . shellescape(temp) . ' ' . expand('%:p')
	if !filereadable(temp)
		redraw!
		return
	endif
	let names = readfile(temp)
	if empty(names)
		redraw!
		return
	endif
	exec 'edit ' . fnameescape(names[0])
	for name in names[1:]
		exec 'argadd ' . fnameescape(name)
	endfor
	redraw!
endfunction
command! -bar Lf call Lf()

let mapleader=" "

if executable('ugrep')
	nnoremap <leader>f :call FzyCommand("ugrep '' . -Rl -I --ignore-files --exclude='zz_generated*' --exclude-dir='generated'", ":e")<cr>
else
	nnoremap <leader>f :call FzyCommand("find . -type f", ":e")<cr>
endif

nnoremap <silent> - :Lf<cr>

nnoremap <leader>gg :!lazygit<cr><cr>

nnoremap <leader>b :call FzyBuffer()<cr>
nnoremap <leader>sf :call FzyCommand("find . -type f", ":e")<cr>
nnoremap <leader>sg :call FzyCommand("git ls-files", ":e")<cr>

nnoremap <silent> <leader>q :call ToggleQuickFix()<cr>
nnoremap <c-j> :cnext<cr>
nnoremap <c-k> :cprev<cr>

nnoremap <c-d> <c-d>zz<cr>
nnoremap <c-u> <c-u>zz<cr>

nnoremap <c-l> :nohl<cr>
