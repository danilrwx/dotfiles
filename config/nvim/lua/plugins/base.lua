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
    opts = {
      hint_enable = false,
      handler_opts = {
        border = "rounded", -- double, rounded, single, shadow, none, or a table of borders
      },
    },
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

  {
    "ray-x/go.nvim",
    dependencies = { -- optional packages
      "ray-x/guihua.lua",
      "neovim/nvim-lspconfig",
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {
      lsp_inlay_hints = {
        enable = false,
      },
    },
    event = { "CmdlineEnter" },
    ft = { "go", "gomod" },
    build = ':lua require("go.install").update_all_sync()', -- if you need to install/update all binaries
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
  { import = "lazyvim.plugins.extras.lang.python" },
  { import = "lazyvim.plugins.extras.lang.json" },
  { import = "lazyvim.plugins.extras.lang.ruby" },
  { import = "lazyvim.plugins.extras.lang.sql" },
  { import = "lazyvim.plugins.extras.lang.yaml" },
}
