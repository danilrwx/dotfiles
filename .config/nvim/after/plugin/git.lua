vim.keymap.set("n", "<Leader>gg", ":LazyGit<CR>")

require('gitsigns').setup({
  current_line_blame = true
})
