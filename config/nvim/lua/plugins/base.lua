return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "github_dark",
    },
  },
  {
    "catppuccin/nvim",
    enabled = false,
  },
  {
    "folke/tokyonight.nvim",
    enabled = false,
    opts = {},
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
    "nvimdev/dashboard-nvim",
    enabled = false,
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

  {
    "projekt0n/github-nvim-theme",
    lazy = false,
    priority = 1000,
    config = function()
      require("github-theme").setup({ options = { transparent = true } })
    end,
  },
  {
    "f-person/auto-dark-mode.nvim",
    opts = {
      update_interval = 1000,
      set_dark_mode = function()
        vim.opt.background = "dark"
        vim.cmd("colorscheme github_dark_default")
      end,
      set_light_mode = function()
        vim.opt.background = "light"
        vim.cmd("colorscheme github_light")
      end,
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
  },

  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = "cd app && yarn install",
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
    end,
    ft = { "markdown" },
  },

  {
    "Wansmer/treesj",
    keys = { "<space>m", "<space>j", "<space>s" },
    dependencies = { "nvim-treesitter/nvim-treesitter" }, -- if you install parsers with `nvim-treesitter`
    opts = {},
  },

  { import = "lazyvim.plugins.extras.editor.mini-files" },
  {
    "echasnovski/mini.files",
    opts = {
      windows = { width_preview = 60 },
      options = { use_as_default_explorer = true },
    },
  },

  {
    "nvim-telescope/telescope.nvim",
    keys = { { "<leader>gc", false }, { "<leader>gs", false } },
  },

  { "mbbill/undotree" },
  { import = "lazyvim.plugins.extras.coding.mini-surround" },
  { import = "lazyvim.plugins.extras.coding.neogen" },
  { import = "lazyvim.plugins.extras.dap.core" },
  { import = "lazyvim.plugins.extras.editor.refactoring" },
  { import = "lazyvim.plugins.extras.lang.docker" },
  { import = "lazyvim.plugins.extras.lang.git" },
  { import = "lazyvim.plugins.extras.lang.go" },
  { import = "lazyvim.plugins.extras.lang.helm" },
  { import = "lazyvim.plugins.extras.lang.json" },
  { import = "lazyvim.plugins.extras.lang.python" },
  { import = "lazyvim.plugins.extras.lang.ruby" },
  { import = "lazyvim.plugins.extras.lang.sql" },
  { import = "lazyvim.plugins.extras.lang.yaml" },
  { import = "lazyvim.plugins.extras.test.core" },
}
