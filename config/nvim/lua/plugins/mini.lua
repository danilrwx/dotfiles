return {
  {
    "echasnovski/mini.nvim",
    version = false,
    dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },
    config = function()
      require("mini.notify").setup()
      require("mini.surround").setup({
        mappings = {
          add = "gsa",            -- Add surrounding in Normal and Visual modes
          delete = "gsd",         -- Delete surrounding
          find = "gsf",           -- Find surrounding (to the right)
          find_left = "gsF",      -- Find surrounding (to the left)
          highlight = "gsh",      -- Highlight surrounding
          replace = "gsr",        -- Replace surrounding
          update_n_lines = "gsn", -- Update `n_lines`

          suffix_last = "l",      -- Suffix to search with "prev" method
          suffix_next = "n",      -- Suffix to search with "next" method
        },
      })
      require("mini.trailspace").setup()
      require("mini.icons").setup()
      require("mini.tabline").setup()
      require("mini.extra").setup()
      require("mini.sessions").setup()

      require("mini.pick").setup()
      vim.keymap.set("n", "<leader>f", "<cmd>Pick files<cr>")
      vim.keymap.set("n", "<leader>/", "<cmd>Pick grep_live<cr>")
      vim.keymap.set("n", "<leader>'", "<cmd>Pick resume<cr>")
      vim.keymap.set("n", "<leader>b", "<cmd>Pick buffers<cr>")
      vim.keymap.set("n", "<leader>sh", "<cmd>Pick git_hunks<cr>")
      vim.keymap.set("n", "<leader>sd", "<cmd>Pick diagnostic<cr>")

      local MiniAi = require("mini.ai")
      MiniAi.setup({
        search_method = "cover_or_nearest",
        custom_textobjects = {
          f = MiniAi.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
          a = MiniAi.gen_spec.treesitter({ a = "@parameter.outer", i = "@parameter.inner" }),
          i = MiniAi.gen_spec.treesitter({ a = "@conditional.outer", i = "@conditional.inner" }),
          l = MiniAi.gen_spec.treesitter({ a = "@loop.outer", i = "@loop.inner" }),
        },
      })

      local MiniFiles = require("mini.files")
      MiniFiles.setup({
        windows = { width_focus = 50, width_nofocus = 35, preview = false },
        options = { use_as_default_explorer = true },
      })

      vim.keymap.set("n", "<leader>e", function()
        if not MiniFiles.close() then
          MiniFiles.open(vim.api.nvim_buf_get_name(0), true)
        end
      end, {})
    end,
  },
}
