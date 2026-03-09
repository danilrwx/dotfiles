vim.keymap.set("n", "<Leader>q", ":bd<CR>")

vim.keymap.set("n", "<C-d>", "<C-d>zz")

vim.keymap.set("n", "<C-u>", "<C-u>zz")

vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set("n", "<Leader>s", [[:s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
vim.keymap.set("n", "<Leader>S", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

vim.keymap.set("n", "<Esc>", ":noh<Return><Esc>")

vim.keymap.set("n", "<Leader>co", ":copen<CR>")
vim.keymap.set("n", "<Leader>cc", ":cclose<CR>")

vim.cmd([[
  function! QuickfixMapping()
    nnoremap <buffer> K :cprev<CR>zz<C-w>w
    nnoremap <buffer> J :cnext<CR>zz<C-w>w
    nnoremap <buffer> <leader>u :set modifiable<CR>
    nnoremap <buffer> <leader>w :cgetbuffer<CR>:cclose<CR>:copen<CR>
    nnoremap <buffer> <leader>r :cdo s/// \| update<C-Left><C-Left><Left><Left><Left>
  endfunction

  augroup quickfix_group
    autocmd!
    autocmd filetype qf call QuickfixMapping()
    autocmd filetype qf setlocal errorformat+=%f\|%l\ col\ %c\|%m
  augroup END
]])

