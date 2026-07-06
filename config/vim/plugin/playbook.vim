" Minimal replacement for the tome plugin: in a playbook buffer, <CR> sends the
" current line (or the visual selection) to the neighbouring tmux pane and runs
" it. Depends on tmux only. Enabled for files named playbook.sh.

if exists('g:loaded_playbook') || &compatible
  finish
endif
let g:loaded_playbook = 1

" tmux target: the last active pane, i.e. the shell the playbook split from.
let s:target = get(g:, 'playbook_target', '{last}')

function! s:Send(lines) abort
  if empty($TMUX)
    echohl WarningMsg | echo 'playbook: not inside tmux' | echohl None
    return
  endif
  for l:line in a:lines
    if l:line =~# '^\s*$' | continue | endif
    call system('tmux send-keys -t ' . s:target . ' -l -- ' . shellescape(l:line))
    call system('tmux send-keys -t ' . s:target . ' Enter')
  endfor
endfunction

function! s:SendLine() abort
  call s:Send([getline('.')])
  if line('.') < line('$') | normal! j | endif
endfunction

function! s:SendVisual() abort
  call s:Send(getline(line("'<"), line("'>")))
endfunction

function! s:Enable() abort
  nnoremap <buffer> <silent> <CR> :call <SID>SendLine()<CR>
  xnoremap <buffer> <silent> <CR> :<C-u>call <SID>SendVisual()<CR>
endfunction

augroup playbook
  autocmd!
  autocmd BufRead,BufNewFile playbook.sh call s:Enable()
augroup END
