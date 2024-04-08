return {
  'nvim-telescope/telescope.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope-project.nvim',
    'ThePrimeagen/harpoon',
    'sato-s/telescope-rails.nvim',
    'OliverChao/telescope-picker-list.nvim'
  },
  config = function()
    local mark = require("harpoon.mark")
    local ui = require("harpoon.ui")

    vim.keymap.set("n", "<Leader>a", mark.add_file)
    vim.keymap.set("n", "<C-e>", ui.toggle_quick_menu)

    vim.keymap.set("n", "<C-h>", function() ui.nav_file(1) end)
    vim.keymap.set("n", "<C-j>", function() ui.nav_file(2) end)
    vim.keymap.set("n", "<C-k>", function() ui.nav_file(3) end)
    vim.keymap.set("n", "<C-l>", function() ui.nav_file(4) end)

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
    require("telescope").load_extension("rails")
    require("telescope").load_extension("picker_list")

    vim.keymap.set('n', '<Leader><Leader>', builtin.find_files, {})
    vim.keymap.set('n', '<Leader>fc', builtin.commands, {})
    vim.keymap.set('n', '<Leader>fs', builtin.live_grep, {})
    vim.keymap.set('x', '<Leader>fs', builtin.grep_string, {})
    vim.keymap.set('n', '<Leader>fds', builtin.lsp_document_symbols, {})
    vim.keymap.set('n', '<Leader>fws', builtin.lsp_workspace_symbols, {})
    vim.keymap.set('n', '<Leader>fg', builtin.git_commits, {})
    vim.keymap.set('n', '<Leader>fgb', builtin.git_bcommits, {})
    vim.keymap.set('x', '<Leader>fgb', builtin.git_bcommits_range, {})
    vim.keymap.set('n', '<Leader>b', builtin.buffers, {})
    vim.keymap.set('n', '<Leader>fq', builtin.quickfix, {})
    vim.keymap.set('n', '<Leader>fp', ext.project.project, {})
    vim.keymap.set('n', '<Leader>frm', ext.rails.models, {})
    vim.keymap.set('n', '<Leader>frc', ext.rails.controllers, {})
    vim.keymap.set('n', '<Leader>frv', ext.rails.views, {})
    vim.keymap.set('n', '<Leader>frs', ext.rails.specs, {})
  end
}
