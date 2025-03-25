return {
  {
    "vim-lualine/lualine.nvim",
    enabled = false,
  },

  {
    "folke/noice.nvim",
    enabled = false,
  },

  {
    "echasnovski/mini.files",
    opts = {
      windows = {
        width_focus = 50,
        width_nofocus = 35,
        preview = false,
      },
      options = {
        use_as_default_explorer = true,
      },
    },
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      document_highlight = { enabled = false },
      codelens = { enabled = true },
      inlay_hints = { enabled = false },
    },
  },

  {
    "lewis6991/gitsigns.nvim",
    event = "LazyFile",
    opts = {
      current_line_blame = true,
    },
  },

  {
    "saghen/blink.cmp",
    opts = {
      completion = {
        -- menu = { border = "single" },
        -- documentation = { window = { border = "single" } },
        -- trigger = { prefetch_on_insert = false },
      },
      -- sources = {
      --   -- default = { "lsp", "path", "snippets", "buffer" },
      --   default = { "lsp", "path", "buffer", "minuet" },
      --   providers = {
      --     minuet = {
      --       name = "minuet",
      --       module = "minuet.blink",
      --       score_offset = 8, -- Gives minuet higher priority among suggestions
      --     },
      --   },
      -- },
    },
  },

  {
    "folke/snacks.nvim",
    opts = {
      dashboard = { enabled = false },
      indent = {
        only_scope = true,
        only_current = true,
      },
      picker = {
        formatters = { file = { truncate = 160 } },
        layout = {
          layout = {
            backdrop = false,
            width = 0,
            min_width = 80,
            height = 0,
            min_height = 30,
            box = "vertical",
            { win = "preview", border = "bottom", height = 0.6 },
            { win = "input", height = 1 },
            { win = "list", height = 0.3, border = "top", title = "{preview} {title} {live} {flags}" },
          },
        },
      },
    },
  },

  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "nvim-neotest/nvim-nio" },
    keys = {
      {
        "<leader>du",
        function()
          require("dapui").toggle({ reset = true })
        end,
        desc = "Dap UI",
      },
    },
  },
}
