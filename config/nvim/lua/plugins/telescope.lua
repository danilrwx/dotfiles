return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "sato-s/telescope-rails.nvim",
    "nvim-telescope/telescope-project.nvim",
    "OliverChao/telescope-picker-list.nvim",
  },
  config = function()
    local builtin = require("telescope.builtin")
    local ext = require("telescope").extensions

    local project_actions = require("telescope._extensions.project.actions")
    require "telescope".setup {
      defaults = {
        layout_config = {
          horizontal = { width = 0.95 }
        },
      },
      pickers = {
        colorscheme = {
          enable_preview = true
        }
      },
      extensions = {
        project = {
          base_dirs = {
            "~/w",
            "~/dotfiles"
          },
          hidden_files = true, -- default: false
          theme = "dropdown",
          order_by = "asc",
          search_by = "title",
          on_project_selected = function(prompt_bufnr)
            project_actions.change_working_directory(prompt_bufnr, false)
          end
        }
      },
    }

    require("telescope").load_extension("project")
    require("telescope").load_extension("rails")
    require("telescope").load_extension("picker_list")

    vim.keymap.set("n", "<Leader>f", builtin.find_files, { desc = 'Find files' })
    vim.keymap.set("n", "<Leader>/", builtin.live_grep, { desc = 'Grep files' })
    vim.keymap.set("x", "<Leader>/", builtin.grep_string, { desc = 'Grep visual string' })
    vim.keymap.set("n", "<Leader>b", builtin.buffers, { desc = 'Find buffers' })
    vim.keymap.set("n", "<Leader>r", builtin.registers, { desc = 'Find registers' })
    vim.keymap.set("n", "<Leader>\\", ext.project.project, { desc = 'Change project' })
    vim.keymap.set("n", "<Leader>rm", ext.rails.models, { desc = 'Find Rails models' })
    vim.keymap.set("n", "<Leader>rc", ext.rails.controllers, { desc = 'Find Rails controlles' })
    vim.keymap.set("n", "<Leader>rv", ext.rails.views, { desc = 'Find Rails views' })
    vim.keymap.set("n", "<Leader>rs", ext.rails.specs, { desc = 'Find Rails specs' })
  end
}
