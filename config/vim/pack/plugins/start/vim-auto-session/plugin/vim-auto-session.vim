" =============================================================================
" File:          plugin/vim-auto-session.vim
" Description:   Auto load and save sessions of different dir.
" Author:        Weilong Wang <github.com/wilon>
" =============================================================================

" Sessiondir config.
if !exists('g:sessiondir')
    let g:sessiondir = $HOME . "/.vim/sessions"
endif

if !exists('g:sessionfile')
    let b:file = expand('%:p')
    if empty(b:file)
        let b:filename = getcwd() . '/'
    else
        let b:filename = expand('%:p')
    endif
    let g:sessionfile = g:sessiondir . '/' . substitute(b:filename, '/', '_', 'g') . '.vim'
endif

" Auto make and load.
au VimLeave * :call session#MakeSession()
au VimEnter * nested :call session#LoadSession()