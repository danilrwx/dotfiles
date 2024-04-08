return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require('nvim-treesitter.configs').setup({
        ensure_installed = { 'lua', 'vimdoc', 'ruby', 'go' },
        auto_install = true,
        highlight = { enable = true },
      })
    end
  }
}
