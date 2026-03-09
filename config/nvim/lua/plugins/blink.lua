return {
  {
    'saghen/blink.compat',
    version = '*',
    lazy = true,
    opts = {},
  },

  {
    'saghen/blink.cmp',
    dependencies = {
      "supermaven-nvim",
      "saghen/blink.compat",
      'rafamadriz/friendly-snippets',
    },
    version = '*',
    opts = {
      keymap = { preset = 'enter' },
      signature = { enabled = true },
      appearance = { nerd_font_variant = 'mono' },
      completion = {
        accept = { auto_brackets = { enabled = true } },
        menu = { draw = { treesitter = { "lsp" } } },
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
      },
      fuzzy = { implementation = "prefer_rust_with_warning" },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer', 'supermaven' },
        providers = {
          supermaven = {
            module = 'blink.compat.source',
            name = "supermaven",
            score_offset = 100,
            async = true,
          },
        }
      },
    },
    opts_extend = { "sources.default" }
  },

  {
    "supermaven-inc/supermaven-nvim",
    event = "InsertEnter",
    cmd = {
      "SupermavenUseFree",
      "SupermavenUsePro",
    },
    opts = {
      keymaps = {
        accept_suggestion = nil,
      },
      disable_inline_completion = vim.g.ai_cmp,
      ignore_filetypes = { "bigfile", "snacks_input", "snacks_notif" },
    },
  },
}
