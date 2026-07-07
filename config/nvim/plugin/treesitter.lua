-- treesitter only for parsers nvim ships (c/lua/vim/markdown/query/...); other
-- filetypes fall back to regex syntax. No nvim-treesitter, so no extra parsers.
vim.api.nvim_create_autocmd("FileType", {
  callback = function()
    if vim.treesitter.get_parser(nil, nil, { error = false }) then
      vim.treesitter.start()
      vim.wo.foldmethod = "expr"
      vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
      vim.wo.foldlevel = 99
    end
  end,
})
