return {
  {
    'kyoh86/vim-go-coverage',
  },
  {
    'sebdah/vim-delve',
    config = function()
      vim.keymap.set('n', '<leader>db', '<cmd>DlvToggleBreakpoint<cr>')
      vim.keymap.set('n', '<leader>dt', '<cmd>DlvTest<cr>')
      vim.keymap.set('n', '<leader>dr', '<cmd>DlvTestCurrent<cr>')
      vim.keymap.set('n', '<leader>dc', '<cmd>DlvConnect :2345<cr>')
    end
  },
  {
    'vim-test/vim-test',
    config = function()
      vim.keymap.set('n', '<leader>tr', '<cmd>TestNearest<cr>')
      vim.keymap.set('n', '<leader>tt', '<cmd>TestFile<cr>')
      vim.keymap.set('n', '<leader>ta', '<cmd>TestSuite<cr>')
      vim.keymap.set('n', '<leader>tl', '<cmd>TestLast<cr>')
      vim.keymap.set('n', '<leader>tv', '<cmd>TestVisit<cr>')
    end
  },
}
