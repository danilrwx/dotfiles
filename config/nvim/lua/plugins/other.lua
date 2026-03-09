return {
  {
    "mbbill/undotree",
    keys = { { "<leader>u", "<cmd>UndotreeToggle<cr>" } },
  },
  {
    'stevearc/oil.nvim',
    opts = {},
    dependencies = {
      -- "nvim-tree/nvim-web-devicons",
    },
    keys = { { "-", "<cmd>Oil<cr>" } },
    lazy = false,
  },
}
