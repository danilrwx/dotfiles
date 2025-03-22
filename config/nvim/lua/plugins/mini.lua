return {
  {
    "echasnovski/mini.nvim",
    version = false,
    dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },
    config = function()
      require("mini.bracketed").setup()
      require("mini.diff").setup()
      require("mini.notify").setup()
      require("mini.surround").setup()
      require("mini.trailspace").setup()
      require('mini.icons').setup()

      local MiniAi = require('mini.ai')
      MiniAi.setup({
        search_method = 'cover_or_nearest',
        custom_textobjects = {
          f = MiniAi.gen_spec.treesitter({ a = '@function.outer', i = '@function.inner' }),
          a = MiniAi.gen_spec.treesitter({ a = '@parameter.outer', i = '@parameter.inner' }),
          i = MiniAi.gen_spec.treesitter({ a = '@conditional.outer', i = '@conditional.inner' }),
          l = MiniAi.gen_spec.treesitter({ a = '@loop.outer', i = '@loop.inner' }),
        }
      })

      local MiniFiles = require("mini.files")
      MiniFiles.setup()
      vim.keymap.set("n", "<Leader>e",
        function() if not MiniFiles.close() then MiniFiles.open(vim.api.nvim_buf_get_name(0), true) end end, {})
    end
  }
}
