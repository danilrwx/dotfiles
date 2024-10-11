return {
  { "slim-template/vim-slim", },
  { "tpope/vim-dadbod", },
  { "kristijanhusak/vim-dadbod-ui", },
  {
    "mbbill/undotree",
    config = function() vim.keymap.set("n", "<Leader>u", vim.cmd.UndotreeToggle, { desc = "Open UndoTree" }) end,
  },
  {
    "chrisgrieser/nvim-various-textobjs",
    lazy = false,
    opts = { useDefaultKeymaps = true },
  },
}
