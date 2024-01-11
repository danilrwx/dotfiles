local builtin = require('telescope.builtin')
local ext = require('telescope').extensions

local project_actions = require('telescope._extensions.project.actions')
require 'telescope'.setup {
  pickers = {
    colorscheme = {
      enable_preview = true
    }
  },
  extensions = {
    project = {
      base_dirs = {
        '~/w',
        '~/dotfiles'
      },
      hidden_files = true, -- default: false
      theme = 'dropdown',
      order_by = 'asc',
      search_by = 'title',
      on_project_selected = function(prompt_bufnr)
        project_actions.change_working_directory(prompt_bufnr, false)
        require('harpoon.ui').nav_file(1)
      end
    }
  },
}

require('telescope').load_extension('project')

vim.keymap.set('n', '<Leader><Space>', builtin.find_files, {})
vim.keymap.set('n', '<Leader>fc', builtin.commands, {})
vim.keymap.set('n', '<Leader>fs', builtin.live_grep, {})
vim.keymap.set('n', '<Leader>fh', builtin.help_tags, {})
vim.keymap.set('n', '<Leader>fj', builtin.jumplist, {})
vim.keymap.set('n', '<Leader>ft', builtin.treesitter, {})
vim.keymap.set('n', '<Leader>fm', builtin.man_pages, {})
vim.keymap.set('n', '<Leader>r', builtin.registers, {})
vim.keymap.set('n', '<Leader>fds', builtin.lsp_document_symbols, {})
vim.keymap.set('n', '<Leader>fws', builtin.lsp_workspace_symbols, {})
vim.keymap.set('n', '<Leader>gf', builtin.git_files, {})
vim.keymap.set('n', '<Leader>gs', builtin.git_status, {})
vim.keymap.set('n', '<Leader>gl', builtin.git_commits, {})
vim.keymap.set('n', '<Leader>b', builtin.buffers, {})
vim.keymap.set('n', '<Leader>fp', ext.project.project, {})
