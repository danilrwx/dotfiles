return {
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
  }
}
