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

vim.keymap.set('n', '<C-p>', builtin.find_files, {})
vim.keymap.set('n', '<Leader>pc', builtin.commands, {})
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
vim.keymap.set('n', '<Leader>pb', builtin.buffers, {})
vim.keymap.set('n', '<Leader>pp', ext.project.project, {})
