-- Search and LSP diagnostics use the native quickfix list.

vim.api.nvim_create_user_command("Grepq", function(o)
  local cmd = vim.o.grepprg .. " -- " .. vim.fn.shellescape(o.args)
  local lines = vim.fn.systemlist(cmd)
  if vim.v.shell_error > 1 then
    vim.notify(table.concat(lines, "\n"), vim.log.levels.ERROR)
    return
  end
  vim.fn.setqflist({}, " ", { title = cmd, lines = lines, efm = vim.o.grepformat })
  vim.cmd("belowright cwindow")
end, { nargs = "+" })

-- toggle the quickfix window (<leader>q): open sized to content, skip when empty
local function toggle_qf()
  local open = vim.tbl_filter(function(w)
    return w.quickfix == 1 and w.loclist == 0
  end, vim.fn.getwininfo())
  if #open > 0 then
    vim.cmd("cclose")
  elseif #vim.fn.getqflist() == 0 then
    vim.notify("quickfix is empty")
  else
    vim.cmd("botright copen " .. math.min(10, #vim.fn.getqflist()))
  end
end

vim.keymap.set("n", "<leader>q", toggle_qf, { silent = true })

-- ! limits diagnostics to the current buffer.
vim.api.nvim_create_user_command("Diagnostics", function(o)
  local diagnostics = vim.diagnostic.get(o.bang and 0 or nil)
  vim.fn.setqflist({}, " ", { title = "Diagnostics", items = vim.diagnostic.toqflist(diagnostics) })
  vim.cmd("belowright cwindow")
end, { bang = true })

vim.keymap.set("n", "<leader>/", ":Grepq ")
vim.keymap.set("n", "<leader>?", function()
  vim.api.nvim_cmd({ cmd = "Grepq", args = { vim.fn.expand("<cword>") } }, {})
end, { silent = true })
vim.keymap.set("x", "<leader>/", function()
  vim.cmd('normal! "zy')
  local text = vim.fn.getreg("z"):gsub("\n.*", "")
  if text ~= "" then
    vim.api.nvim_cmd({ cmd = "Grepq", args = { text } }, {})
  end
end, { silent = true })
