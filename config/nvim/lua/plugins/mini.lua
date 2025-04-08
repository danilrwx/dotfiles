return {
  {
    "echasnovski/mini.nvim",
    version = false,
    dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },
    lazy = false,
    keys = {
    },
    config = function()
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
    end,
  },
}
