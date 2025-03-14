return {
  {
    "projekt0n/github-nvim-theme",
    name = "github-theme",
    lazy = false,
    priority = 1000,
    opts = { options = { transparent = true } },
  },

  {
    "f-person/auto-dark-mode.nvim",
    opts = {
      set_dark_mode = function()
        vim.api.nvim_set_option_value("background", "dark", {})
        vim.cmd("colorscheme github_dark")
      end,
      set_light_mode = function()
        vim.api.nvim_set_option_value("background", "light", {})
        vim.cmd("colorscheme github_light")
      end,
    },
  },

  {
    "tpope/vim-fugitive",
    lazy = false,
  },

  {
    "Wansmer/treesj",
    keys = { "<space>m", { "<space>j", false }, { "<space>s", false } },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {},
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
    "folke/snacks.nvim",
    opts = {
      dashboard = { enabled = false },
    },
  },

  {
    "Wansmer/symbol-usage.nvim",
    event = "LspAttach",
    opts = {
      kinds = {
        vim.lsp.protocol.SymbolKind.Function,
        vim.lsp.protocol.SymbolKind.Method,
        vim.lsp.protocol.SymbolKind.Interface,
        vim.lsp.protocol.SymbolKind.Constant,
      },
      definition = { enabled = true },
      implementation = { enabled = true },
      vt_position = "end_of_line",
    },
  },

  { "mbbill/undotree" },

  {
    "olimorris/codecompanion.nvim",
    config = true,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {
      strategies = {
        chat = {
          adapter = "openai",
        },
        inline = {
          adapter = "openai",
        },
      },
    },
  },
}
