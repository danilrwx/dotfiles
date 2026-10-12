-- `:Grepq` -> quickfix via 'grepprg', and a quickfix toggle (<leader>q). Files,
-- buffers and live grep are the pickers' (lua/picker).

vim.api.nvim_create_user_command("Grepq", function(o)
  local cmd = vim.o.grepprg .. " " .. o.args
  vim.fn.setqflist({}, " ", { title = cmd, lines = vim.fn.systemlist(cmd), efm = vim.o.grepformat })
  vim.cmd("belowright cwindow")
end, { nargs = "+", bar = true })

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
