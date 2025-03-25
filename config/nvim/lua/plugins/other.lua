return {
  { "slim-template/vim-slim", },
  {
    "mbbill/undotree",
    config = function() vim.keymap.set("n", "<Leader>u", vim.cmd.UndotreeToggle, { desc = "Open UndoTree" }) end,
  },
  {
    "tpope/vim-fugitive",
    dependencies = { "shumphrey/fugitive-gitlab.vim", "tpope/vim-rhubarb" },
    config = function()
      vim.keymap.set("n", "<Leader>gs", ":tab Git<CR>", { desc = 'Open Fugitive' })
      vim.keymap.set("n", "<Leader>gl", ":tab Git log --follow -p %<CR>", { desc = 'Open Git log' })
      vim.keymap.set("n", "<Leader>gL", ":tab Git log<CR>", { desc = 'Open Git log' })
      vim.keymap.set("n", "<Leader>gK", ":tab Git log -p<CR>", { desc = 'Open Git log' })
      vim.keymap.set("n", "<Leader>gb", ":tab Git blame<CR>", { desc = 'Open Git blame' })
      vim.keymap.set("n", "<Leader>gB", ":GBrowse<CR>", { desc = 'Open Git browse' })
      vim.keymap.set("n", "<Leader>gd", ":tab Git diff<CR>", { desc = 'Open Git diff' })
      vim.keymap.set("n", "<leader>gp", ':Git push<CR>', { desc = 'Git push' })
      vim.keymap.set("n", "<leader>gP", ':Git pull --rebase<CR>', { desc = 'Git pull with rebase' })

      vim.g.fugitive_gitlab_domains = { "https://rscz.ru" }
    end
  },
}
