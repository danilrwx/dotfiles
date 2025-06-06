return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "lua", "vimdoc" },
        auto_install = true,
        highlight = { enable = true },
        folds = { enable = true },
        indent = { enable = true },
        incremental_selection = {
          enable = true,
          keymaps = { init_selection = "<C-Space>", node_incremental = "<C-Space>", node_decremental = "<C-s>" },
        },
      })
    end,
  },

  {
    "Wansmer/treesj",
    keys = { "<space>m", { "<space>j", false }, { "<space>s", false } },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {},
  },
}
