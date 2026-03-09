return {
  {
    "mbbill/undotree",
    keys = { { "<leader>u", "<cmd>UndotreeToggle<cr>" } },
  },
  {
    'rmagatti/auto-session',
    lazy = false,
    opts = {
      suppressed_dirs = { '~/', '~/Downloads', '/' },
    }
  },
  {
    'stevearc/oil.nvim',
    opts = {},
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = { { "-", "<cmd>Oil<cr>" } },
    lazy = false,
  },
  -- {
  --   'romgrk/barbar.nvim',
  --   lazy = false,
  --   dependencies = {
  --     'lewis6991/gitsigns.nvim',
  --     'nvim-tree/nvim-web-devicons',
  --   },
  --   keys = {
  --     { "<s-h>", "<cmd>BufferPrevious<cr>" },
  --     { "<s-l>", "<cmd>BufferNext<cr>" },
  --   },
  --   init = function() vim.g.barbar_auto_setup = false end,
  --   opts = {
  --     animation = false,
  --     icons = {
  --       button = '',
  --       modified = { button = '🔸' },
  --       pinned = { button = '📌', filename = true },
  --       diagnostics = {
  --         [vim.diagnostic.severity.ERROR] = { enabled = true, icon = '🔥' },
  --       }
  --     },
  --   },
  --   version = '^1.0.0',
  -- },
}
