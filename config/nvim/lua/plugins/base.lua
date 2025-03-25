return {

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "github_light",
    },
  },

  {
    "nvim-lualine/lualine.nvim",
    opts = {
      sections = {
        lualine_a = { "mode" },
        lualine_b = {},
        lualine_y = {},
        lualine_z = { "branch" },
        lualine_c = { { "filename", path = 1 } },
      },
    },
  },

  {
    "tpope/vim-fugitive",
    lazy = false,
    dependencies = { "shumphrey/fugitive-gitlab.vim", "tpope/vim-rhubarb" },
  },

  {
    "lewis6991/gitsigns.nvim",
    event = "LazyFile",
    opts = {
      signcolumn = true,
      current_line_blame = true,
      current_line_blame_opts = {
        delay = 300,
        virt_text_pos = "right_align",
      },
    },
  },

  -- {
  --   "akinsho/git-conflict.nvim",
  --   version = "*",
  --   config = true,
  -- },

  {
    "projekt0n/github-nvim-theme",
    lazy = false,
    priority = 1000,
    config = function()
      require("github-theme").setup({ options = { transparent = true } })
    end,
  },

  {
    "chrisgrieser/nvim-various-textobjs",
    lazy = false,
    opts = { useDefaults = true },
  },

  {
    "Wansmer/treesj",
    keys = { "<space>m", { "<space>j", false }, { "<space>s", false } },
    dependencies = { "nvim-treesitter/nvim-treesitter" }, -- if you install parsers with `nvim-treesitter`
    opts = {},
  },

  {
    "echasnovski/mini.files",
    opts = {
      windows = { width_preview = 60 },
      options = { use_as_default_explorer = true },
    },
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      document_highlight = {
        enabled = false,
      },
      codelens = {
        enabled = true,
      },
      inlay_hints = {
        enabled = false,
      },
    },
  },

  {
    "Wansmer/symbol-usage.nvim",
    event = "LspAttach", -- need run before LspAttach if you use nvim 0.9. On 0.10 use 'LspAttach'
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
  --
  -- {
  --   "SCJangra/table-nvim",
  --   ft = "markdown",
  --   opts = {},
  -- },

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
    dependencies = {
      "folke/snacks.nvim",
      --- The below dependencies are optional
      "catppuccin/nvim",
      "nvim-tree/nvim-tree.lua",
    },
    config = true,
  },
}
