" Mirror yanks to the system clipboard over OSC 52. The devbox runs vim over SSH
" with no X server, so xclip/pbcopy cannot reach the host clipboard; the terminal
" emulator owns the clipboard and honours OSC 52 (tmux forwards it, see
" set-clipboard in .tmux.conf). Works the same for the docker and k8s devbox.
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
