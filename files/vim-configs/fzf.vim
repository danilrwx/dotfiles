nmap <leader><tab> <plug>(fzf-maps-n)
xmap <leader><tab> <plug>(fzf-maps-x)
omap <leader><tab> <plug>(fzf-maps-o)

command! -bang -nargs=* GGrep
  \ call fzf#vim#grep(
  \   'git grep --line-number -- '.shellescape(<q-args>), 0,
  \   fzf#vim#with_preview({'dir': systemlist('git rev-parse --show-toplevel')[0]}), <bang>0)

nnoremap <silent><nowait> <leader>b :Buffers<CR>
nnoremap <silent><nowait> <leader>p :GFiles --cached --others --exclude-standard<CR>
nnoremap <silent><nowait> <leader>gt :GGrep<CR>
nnoremap <silent><nowait> <leader>gc :Commits<CR>

let g:fzf_layout = { 'window': { 'width': 1, 'height': 1 } }

