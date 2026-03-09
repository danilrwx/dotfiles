local builtin = require('telescope.builtin')

require "telescope".setup {
  pickers = {
    colorscheme = {
      enable_preview = true
    }
  }
}

vim.keymap.set('n', '<C-p>', builtin.find_files, {})
vim.keymap.set('n', '<Leader>pg', builtin.git_files, {})
vim.keymap.set('n', '<Leader>ps', builtin.live_grep, {})
vim.keymap.set('n', '<Leader>ph', builtin.help_tags, {})
vim.keymap.set('n', '<Leader>pj', builtin.jumplist, {})
vim.keymap.set('n', '<Leader>pt', builtin.treesitter, {})
vim.keymap.set('n', '<Leader>pm', builtin.man_pages, {})
vim.keymap.set('n', '<Leader>pr', builtin.registers, {})
vim.keymap.set('n', '<Leader>pds', builtin.lsp_document_symbols, {})
vim.keymap.set('n', '<Leader>pws', builtin.lsp_workspace_symbols, {})
vim.keymap.set('n', '<Leader>pgs', builtin.git_status, {})
vim.keymap.set('n', '<Leader>pgl', builtin.git_commits, {})
vim.keymap.set('n', '<Tab>', builtin.buffers, {})
