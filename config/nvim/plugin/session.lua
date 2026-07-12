-- Auto-save the cwd session on exit, auto-restore it on a bare `nvim` (no file
-- args). Implementation in lua/session.lua; picker of saved sessions is a
-- source in the picker (<leader>s).
local s = require("session")

-- no localoptions/options: window options like signcolumn/statuscolumn must come
-- from init.lua, not a stale session (else restoring re-applies old values).
vim.o.sessionoptions = "buffers,curdir,folds,tabpages,winsize,winpos,terminal"

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    s.save()
  end,
})

vim.api.nvim_create_autocmd("VimEnter", {
  nested = true, -- let the sourced session's own autocmds fire
  callback = function()
    if vim.fn.argc() == 0 then
      s.restore()
    end
  end,
})

vim.api.nvim_create_user_command("SessionSave", function() s.save() end, {})
vim.api.nvim_create_user_command("SessionRestore", function() s.restore() end, {})
vim.api.nvim_create_user_command("SessionDelete", function() s.delete() end, {})
