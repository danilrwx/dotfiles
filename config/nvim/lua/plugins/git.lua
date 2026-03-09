return {
  {
    "tpope/vim-fugitive",
    dependencies = { "tpope/vim-rhubarb" },
    config = function()
      vim.keymap.set("n", "<leader>gs", "<cmd>tab Git<cr>")
      vim.keymap.set("n", "<leader>gl", "<cmd>tab Git log --follow -p %<cr>")
      vim.keymap.set("n", "<leader>gL", "<cmd>tab Git log<cr>")
      vim.keymap.set("n", "<leader>gb", "<cmd>tab Git blame<cr>")
      vim.keymap.set("n", "<leader>gd", "<cmd>tab Git diff %<cr>")
      vim.keymap.set("n", "<leader>gD", "<cmd>tab Git diff<cr>")
      vim.keymap.set("n", "<leader>gP", '<cmd>Git push<cr>')
      vim.keymap.set("n", "<leader>gp", '<cmd>Git pull --rebase<cr>')
    end
  }
}
