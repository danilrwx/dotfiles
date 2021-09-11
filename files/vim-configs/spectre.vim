nnoremap <leader>S :lua require('spectre').open()<CR>

nnoremap <leader>sw :lua require('spectre').open_visual({select_word=true})<CR>
vnoremap <leader>s :lua require('spectre').open_visual()<CR>
nnoremap <leader>sp viw:lua require('spectre').open_file_search()<cr>
