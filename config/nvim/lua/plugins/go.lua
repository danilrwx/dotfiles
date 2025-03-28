return {
  {
    "kyoh86/vim-go-coverage",
  },
  {
    "sebdah/vim-delve",
    keys = {
      { "<leader>db", "<cmd>DlvToggleBreakpoint<cr>" },
      { "<leader>dt", "<cmd>DlvTest<cr>" },
      { "<leader>dr", "<cmd>DlvTestCurrent<cr>" },
      { "<leader>dc", "<cmd>DlvConnect :2345<cr>" },
    }
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
