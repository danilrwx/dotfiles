return {
  {
    "echasnovski/mini.nvim",
    version = false,
    dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },
    config = function()
      require("mini.bracketed").setup()
      require("mini.diff").setup()
      require("mini.extra").setup()
      require('mini.icons').setup()
      require("mini.move").setup()
      require("mini.pairs").setup()
      require("mini.surround").setup()
      require("mini.trailspace").setup()

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

      -- local MiniFiles = require("mini.files")
      -- MiniFiles.setup()
      -- vim.keymap.set("n", "<C-n>",
      --   function() if not MiniFiles.close() then MiniFiles.open(vim.api.nvim_buf_get_name(0), true) end end, {})

      local MiniHipatterns = require('mini.hipatterns')
      local MiniExtra = require('mini.extra')
      local hi_words = MiniExtra.gen_highlighter.words
      MiniHipatterns.setup({
        highlighters = {
          fixme = hi_words({ 'FIXME', 'Fixme', 'fixme' }, 'MiniHipatternsFixme'),
          hack = hi_words({ 'HACK', 'Hack', 'hack' }, 'MiniHipatternsHack'),
          todo = hi_words({ 'TODO', 'Todo', 'todo' }, 'MiniHipatternsTodo'),
          note = hi_words({ 'NOTE', 'Note', 'note' }, 'MiniHipatternsNote'),

          hex_color = MiniHipatterns.gen_highlighter.hex_color(),
        },
      })
    end
  }
}
