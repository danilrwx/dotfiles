return {
  {
    "kyoh86/vim-go-coverage",
  },
  {
    "vim-test/vim-test",
    keys = {
      { "<leader>tr", "<cmd>TestNearest<cr>" },
      { "<leader>tt", "<cmd>TestFile<cr>" },
      { "<leader>ta", "<cmd>TestSuite<cr>" },
      { "<leader>tl", "<cmd>TestLast<cr>" },
      { "<leader>tv", "<cmd>TestVisit<cr>" },
    }
  },
}
