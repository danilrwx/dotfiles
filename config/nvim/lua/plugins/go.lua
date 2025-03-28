return {
  {
    "kyoh86/vim-go-coverage",
    lazy = false,
    keys = {
      { "<leader>tc", "<cmd>GoCover<cr>" },
      { "<leader>tC", "<cmd>GoCoverClear<cr>" },
    },
  },

  {
    "vim-test/vim-test",
    lazy = false,
    keys = {
      { "<leader>tr", "<cmd>TestNearest<cr>" },
      { "<leader>tt", "<cmd>TestFile<cr>" },
      { "<leader>ta", "<cmd>TestSuite<cr>" },
      { "<leader>tl", "<cmd>TestLast<cr>" },
      { "<leader>tv", "<cmd>TestVisit<cr>" },
    }
  },
}
