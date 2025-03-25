return {
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "moonfly" },
  },

  {
    "vim-lualine/lualine.nvim",
    enabled = false,
  },

  {
    "echasnovski/mini.pairs",
    enabled = false,
  },

  {
    "folke/noice.nvim",
    enabled = false,
  },

  {
    "bluz71/vim-moonfly-colors",
    name = "moonfly",
    lazy = false,
    priority = 1000,
    config = function()
      vim.g.moonflyTransparent = true
    end,
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
  -- {
  --   "yetone/avante.nvim",
  --   event = "VeryLazy",
  --   lazy = false,
  --   version = false,
  --   opts = {
  --     provider = "openai",
  --     openai = {
  --       endpoint = "https://api.openai.com/v1",
  --       model = "gpt-4o",
  --       timeout = 30000,
  --       temperature = 0,
  --       max_tokens = 4096,
  --       -- reasoning_effort = "high" -- only supported for reasoning models (o1, etc.)
  --     },
  --   },
  --   build = "make",
  --   dependencies = {
  --     "nvim-treesitter/nvim-treesitter",
  --     "stevearc/dressing.nvim",
  --     "nvim-lua/plenary.nvim",
  --     "MunifTanjim/nui.nvim",
  --     "echasnovski/mini.pick", -- for file_selector provider mini.pick
  --     -- "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
  --     -- "hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
  --     -- "ibhagwan/fzf-lua", -- for file_selector provider fzf
  --     -- "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
  --     -- "zbirenbaum/copilot.lua", -- for providers='copilot'
  --     {
  --       -- Make sure to set this up properly if you have lazy=true
  --       "MeanderingProgrammer/render-markdown.nvim",
  --       opts = {
  --         file_types = { "markdown", "Avante" },
  --       },
  --       ft = { "markdown", "Avante" },
  --     },
  --   },
  -- },
}
