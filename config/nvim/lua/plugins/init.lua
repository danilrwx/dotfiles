return {
  { "slim-template/vim-slim", },
  { "nvim-tree/nvim-web-devicons", lazy = true },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      vim.cmd(
        "colorscheme catppuccin-mocha")
    end
  }
}
