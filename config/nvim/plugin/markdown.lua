-- Use the Markdown syntax bundled with Vim; no parser or renderer.
vim.g.markdown_syntax_conceal = 1
vim.g.markdown_fenced_languages = {
  "bash=sh", "sh", "go", "lua", "python", "json", "yaml", "vim", "c", "rust",
}

local group = vim.api.nvim_create_augroup("markdown_syntax", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "markdown",
  callback = function()
    vim.wo.conceallevel = 2
    vim.wo.concealcursor = ""
    vim.wo.wrap = true
    vim.wo.linebreak = true
  end,
})
