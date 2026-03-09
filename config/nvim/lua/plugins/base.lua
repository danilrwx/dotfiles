return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "torte",
    },
  },
  {
    "catppuccin/nvim",
    enabled = false,
  },
  {
    "folke/tokyonight.nvim",
    enabled = false,
  },
  {
    "folke/noice.nvim",
    enabled = false,
  },
  {
    "folke/flash.nvim",
    enabled = false,
  },
  {
    "folke/persistence.nvim",
    enabled = false,
  },
  {
    "stevearc/dressing.nvim",
    enabled = false,
  },
  {
    "akinsho/bufferline.nvim",
    enabled = false,
  },
  {
    "nvim-lualine/lualine.nvim",
    enabled = false,
  },
  {
    "MagicDuck/grug-far.nvim",
    enabled = false,
  },
  {
    "rcarriga/nvim-notify",
    enabled = false,
  },
  {
    "nvimdev/dashboard-nvim",
    enabled = false,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      document_highlight = {
        enabled = false,
      },
      codelens = {
        enabled = false,
      },
      inlay_hints = {
        enabled = false,
      },
    },
  },
  {
    "lewis6991/gitsigns.nvim",
    event = "LazyFile",
    opts = {
      signcolumn = true,
      numhl = true,
      current_line_blame = true,
    },
  },

  {
    "ibhagwan/fzf-lua",
    keys = {
      { "<leader>gc", false },
      { "<leader>gs", false },
    },
    opts = {
      winopts = {
        fullscreen = true,
      },
    },
  },

  {
    "ray-x/lsp_signature.nvim",
    event = "VeryLazy",
    config = function(_, opts)
      require("lsp_signature").setup(opts)
    end,
  },

  {
    "chrisgrieser/nvim-various-textobjs",
    lazy = false,
    opts = { useDefaultKeymaps = true },
  },

  {
    "tpope/vim-fugitive",
    lazy = false,
    dependencies = { "shumphrey/fugitive-gitlab.vim", "tpope/vim-rhubarb" },
    config = function()
      vim.g.fugitive_gitlab_domains = { "https://rscz.ru" }
    end,
  },

  { import = "lazyvim.plugins.extras.editor.fzf" },
  { import = "lazyvim.plugins.extras.dap.core" },
  { import = "lazyvim.plugins.extras.editor.refactoring" },
  { import = "lazyvim.plugins.extras.test.core" },
  { import = "lazyvim.plugins.extras.dap.core" },
  { import = "lazyvim.plugins.extras.coding.neogen" },
  { import = "lazyvim.plugins.extras.coding.mini-surround" },
  { import = "lazyvim.plugins.extras.lang.docker" },
  { import = "lazyvim.plugins.extras.lang.go" },
  { import = "lazyvim.plugins.extras.lang.json" },
  { import = "lazyvim.plugins.extras.lang.ruby" },
  { import = "lazyvim.plugins.extras.lang.sql" },
  { import = "lazyvim.plugins.extras.lang.yaml" },
}
