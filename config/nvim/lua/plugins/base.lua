return {
  {
    "mbbill/undotree",
    keys = { { "<Leader>u", vim.cmd.UndotreeToggle } },
  },
  {
    "echasnovski/mini.nvim",
    version = false,
    config = function()
      require("mini.bracketed").setup()
      require("mini.diff").setup({ view = { style = 'sign' } })
      require("mini.surround").setup()
      require("mini.trailspace").setup()
    end
  },
  {
    "tpope/vim-fugitive",
    dependencies = { "shumphrey/fugitive-gitlab.vim", "tpope/vim-rhubarb" },
    config = function()
      vim.keymap.set("n", "<Leader>gs", ":tab Git<CR>", { desc = "Open Fugitive" })
      vim.keymap.set("n", "<Leader>gl", ":tab Git log --follow -p %<CR>", { desc = "Open Git log" })
      vim.keymap.set("n", "<Leader>gL", ":tab Git log<CR>", { desc = "Open Git log" })
      vim.keymap.set("n", "<Leader>gK", ":tab Git log -p<CR>", { desc = "Open Git log" })
      vim.keymap.set("n", "<Leader>gb", ":tab Git blame<CR>", { desc = "Open Git blame" })
      vim.keymap.set("n", "<Leader>gB", ":GBrowse<CR>", { desc = "Open Git browse" })
      vim.keymap.set("n", "<Leader>gd", ":tab Git diff<CR>", { desc = "Open Git diff" })
      vim.keymap.set("n", "<Leader>gP", ":Git push<CR>", { desc = "Git push" })
      vim.keymap.set("n", "<Leader>gp", ":Git pull --rebase<CR>", { desc = "Git pull with rebase" })

      vim.g.fugitive_gitlab_domains = { "https://rscz.ru" }
    end
  },
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require "telescope".setup {
        defaults = { layout_config = { horizontal = { width = 0.95 } } },
        pickers = { colorscheme = { enable_preview = true } },
      }

      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<Leader>f", builtin.find_files, { desc = "Find files" })
      vim.keymap.set("n", "<Leader>/", builtin.live_grep, { desc = "Grep files" })
      vim.keymap.set("x", "<Leader>/", builtin.grep_string, { desc = "Grep visual string" })
      vim.keymap.set("n", "<Leader>b", builtin.buffers, { desc = "Find buffers" })
      vim.keymap.set("n", "<Leader>r", builtin.registers, { desc = "Find registers" })
    end
  },
  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = {
      "RRethy/nvim-treesitter-endwise",
      "Wansmer/treesj",
    },
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "lua", "vimdoc", "ruby", "go" },
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
        endwise = { enable = true },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = '<C-Space>',
            node_incremental = '<C-Space>',
            node_decremental = '<C-s>',
          },
        },
      })

      require("treesj").setup()
      vim.keymap.set("n", "<Leader>m", require("treesj").toggle, { desc = "toggle split treesitter object" })
    end
  },
  {
    "chrisgrieser/nvim-various-textobjs",
    lazy = false,
    opts = { useDefaultKeymaps = true },
  },
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
    }
  },
  { "slim-template/vim-slim", },
}
