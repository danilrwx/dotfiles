return {
  "nvim-telescope/telescope.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local builtin = require("telescope.builtin")
    -- local ext = require("telescope").extensions

    require "telescope".setup {
      defaults = { layout_config = { horizontal = { width = 0.95 } } },
      pickers = { colorscheme = { enable_preview = true } },
      extensions = {},
    }

    vim.keymap.set("n", "<Leader>f", builtin.find_files, { desc = 'Find files' })
    vim.keymap.set("n", "<Leader>/", builtin.live_grep, { desc = 'Grep files' })
    vim.keymap.set("x", "<Leader>/", builtin.grep_string, { desc = 'Grep visual string' })
    vim.keymap.set("n", "<Leader>b", builtin.buffers, { desc = 'Find buffers' })
    vim.keymap.set("n", "<Leader>r", builtin.registers, { desc = 'Find registers' })
  end
}
