return {
  {
    "projekt0n/github-nvim-theme",
    lazy = false,
    priority = 1000,
    opts = {},
    config = function ()

    end
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
}
