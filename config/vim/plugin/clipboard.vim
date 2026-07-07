" Clipboard integration for the devbox (vim over SSH, no X server).
"
" There is no <leader>y: every plain yank is mirrored to the host clipboard by
" the hook below (OSC 52 straight to /dev/tty via clip). leader-dd pushes the
" path the same way. Paste from the host is Cmd+V (terminal paste); OSC 52 read
" is not available, so there is a paste map only where the + register works.
if has('clipboard')
  nnoremap <leader>p "+p
  nnoremap <silent> <leader>dd <cmd>let @+ = expand('%') .. ':' .. line('.')<cr>
else
  nnoremap <silent> <leader>dd <cmd>call system('clip', expand('%') .. ':' .. line('.'))<cr>
endif

" Mirror every yank to the host clipboard via the clip helper (a subprocess that
" writes the OSC 52 sequence to /dev/tty — the path that actually reaches
" tmux/the terminal; vim's own echoraw did not). Terminal vim only; GUI vim has a
" real + register.
if has('gui_running')
  finish
endif

" Only real yanks (not deletes) to the unnamed or clipboard registers.
function! s:YankToClipboard() abort
  if v:event.operator !=# 'y' || v:event.regname !~# '^[+*]\=$'
    return
  endif
  let l:text = join(v:event.regcontents, "\n")
  if get(v:event, 'regtype', '')[0] ==# 'V'
    let l:text .= "\n"
  endif
  call system('clip', l:text)
endfunction

augroup osc52_clipboard
  autocmd!
  autocmd TextYankPost * call s:YankToClipboard()
augroup END
