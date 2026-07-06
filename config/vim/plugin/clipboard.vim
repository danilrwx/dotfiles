" Clipboard integration for the devbox (vim over SSH, no X server).
"
" Maps: on +clipboard vim (the host, incl. GUI) use the + register directly; in
" the devbox vim (no +clipboard over SSH) leader-y is a plain yank — the OSC 52
" hook below mirrors it to the host clipboard — and leader-dd pushes the path
" through the clip helper. Paste from the host is Cmd+V (terminal paste); OSC 52
" read is not available, so there is no paste map without the + register.
if has('clipboard')
  nnoremap <leader>y "+y
  xnoremap <leader>y "+y
  nnoremap <leader>p "+p
  nnoremap <silent> <leader>dd <cmd>let @+ = expand('%') .. ':' .. line('.')<cr>
else
  nnoremap <leader>y y
  xnoremap <leader>y y
  nnoremap <silent> <leader>dd <cmd>call system('clip', expand('%') .. ':' .. line('.'))<cr>
endif

" OSC 52 copy: on every yank ask the terminal (not the container) to set the host
" clipboard — works over SSH and tmux. Terminal vim only; GUI vim has a real +
" register and no terminal to write the escape sequence to.
if has('gui_running')
  finish
endif

function! s:Osc52(text) abort
  let l:b64 = system('base64 | tr -d "\n"', a:text)
  let l:seq = "\e]52;c;" . l:b64 . "\a"
  if exists('*echoraw')
    call echoraw(l:seq)
  else
    silent! call writefile([l:seq], '/dev/tty', 'b')
  endif
endfunction

" Only real yanks (not deletes) to the unnamed or clipboard registers.
function! s:YankToClipboard() abort
  if v:event.operator !=# 'y' || v:event.regname !~# '^[+*]\=$'
    return
  endif
  let l:text = join(v:event.regcontents, "\n")
  if get(v:event, 'regtype', '')[0] ==# 'V'
    let l:text .= "\n"
  endif
  call s:Osc52(l:text)
endfunction

augroup osc52_clipboard
  autocmd!
  autocmd TextYankPost * call s:YankToClipboard()
augroup END
