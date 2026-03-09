return {
  {
    "projekt0n/github-nvim-theme",
    lazy = false,
    priority = 1000,
    opts = {},
    config = function ()
        vim.opt.background = "dark"
        vim.cmd("colorscheme github_dark_high_contrast")
    end
  },
}
