return {
  {
    "projekt0n/github-nvim-theme",
    lazy = false,
    priority = 1000,
    opts = {},
    config = function ()
        vim.opt.background = "light"
        vim.cmd("colorscheme github_light_high_contrast")
    end
  },
}
