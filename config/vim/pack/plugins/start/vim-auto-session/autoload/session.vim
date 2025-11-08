" =============================================================================
" File:          plugin/vim-auto-session.vim
" Description:   Auto load and save sessions of different dir.
" Author:        Weilong Wang <github.com/wilon>
" =============================================================================

function! session#MakeSession()
    if ! exists("v:servername")
        return
    endif
    if (filewritable(g:sessiondir) != 2)
        exe 'silent !mkdir -p ' g:sessiondir
        redraw!
    endif
    let g:netrw_liststyle = 1
    exe "mksession! " . g:sessionfile
endfunction

function! session#LoadSession()
    if ! exists("v:servername")
        return
    endif
    if (filereadable(g:sessionfile))
        exe 'source ' g:sessionfile
    endif
endfunction

