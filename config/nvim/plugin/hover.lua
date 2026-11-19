-- Render LSP Markdown with bundled Vim syntax, matching regular code buffers.
-- Neovim's default Markdown preview starts Tree-sitter after FileType hooks.
local util = vim.lsp.util
local open_preview = util.open_floating_preview
util.open_floating_preview = function(contents, syntax, opts)
  if syntax ~= "markdown" then
    return open_preview(contents, syntax, opts)
  end

  local buf, win = open_preview(contents, nil, opts)
  if not buf or not win or not vim.api.nvim_win_is_valid(win) then
    return buf, win
  end
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_call(buf, function()
    vim.cmd("syntax clear")
    util.stylize_markdown(buf, contents, opts)
  end)
  vim.bo[buf].modifiable = false
  vim.wo[win].conceallevel = 2
  vim.wo[win].concealcursor = "n"
  local height = vim.api.nvim_win_text_height(win, {}).all
  vim.api.nvim_win_set_height(win, math.min(vim.api.nvim_win_get_height(win), math.max(1, height)))
  return buf, win
end
