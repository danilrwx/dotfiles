return {
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "github_dark_default" },
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
    "projekt0n/github-nvim-theme",
    name = "github-theme",
    lazy = false,
    priority = 1000,
    config = function()
      require("github-theme").setup({
        options = {
          transparent = true,
        },
      })

      vim.cmd("colorscheme github_dark_default")
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
    "GeorgesAlkhouri/nvim-aider",
    cmd = {
      "AiderTerminalToggle",
      "AiderHealth",
    },
    keys = {
      { "<leader>a/", "<cmd>AiderTerminalToggle<cr>", desc = "Open Aider" },
      { "<leader>as", "<cmd>AiderTerminalSend<cr>", desc = "Send to Aider", mode = { "n", "v" } },
      { "<leader>ac", "<cmd>AiderQuickSendCommand<cr>", desc = "Send Command To Aider" },
      { "<leader>ab", "<cmd>AiderQuickSendBuffer<cr>", desc = "Send Buffer To Aider" },
      { "<leader>a+", "<cmd>AiderQuickAddFile<cr>", desc = "Add File to Aider" },
      { "<leader>a-", "<cmd>AiderQuickDropFile<cr>", desc = "Drop File from Aider" },
      { "<leader>ar", "<cmd>AiderQuickReadOnlyFile<cr>", desc = "Add File as Read-Only" },
      -- Example nvim-tree.lua integration if needed
      { "<leader>a+", "<cmd>AiderTreeAddFile<cr>", desc = "Add File from Tree to Aider", ft = "NvimTree" },
      { "<leader>a-", "<cmd>AiderTreeDropFile<cr>", desc = "Drop File from Tree from Aider", ft = "NvimTree" },
    },
    dependencies = { "folke/snacks.nvim" },
    config = true,
  },
}
