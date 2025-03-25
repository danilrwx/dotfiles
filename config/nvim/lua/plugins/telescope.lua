return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope-project.nvim",
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
          hidden_files = true,
          theme = "dropdown",
          order_by = "asc",
          search_by = "title",
          on_project_selected = function(prompt_bufnr)
            project_actions.change_working_directory(prompt_bufnr, false)
          end
        }
      },
    }

    -- require("telescope").load_extension("project")

    vim.keymap.set("n", "<Leader>f", builtin.find_files, { desc = 'Find files' })
    vim.keymap.set("n", "<Leader>/", builtin.live_grep, { desc = 'Grep files' })
    vim.keymap.set("x", "<Leader>/", builtin.grep_string, { desc = 'Grep visual string' })
    vim.keymap.set("n", "<Leader>b", builtin.buffers, { desc = 'Find buffers' })
    vim.keymap.set("n", "<Leader>r", builtin.registers, { desc = 'Find registers' })
    vim.keymap.set("n", "<Leader>\\", ext.project.project, { desc = 'Change project' })
  end
}
