-- Bundled Lua/help/query ftplugins start Tree-sitter themselves.
-- Restore traditional syntax after filetype plugins have run.
vim.g.query_lint_on = {}
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("traditional_syntax", { clear = true }),
  callback = function(ev)
    vim.treesitter.stop(ev.buf)
    local ft = vim.bo[ev.buf].filetype
    vim.bo[ev.buf].syntax = ft == "helm" and "yaml" or ft
    vim.wo.foldmethod = "manual"
    vim.wo.foldexpr = "0"
  end,
})
