-- Auto-save the cwd session on exit, auto-restore it on a bare `nvim` (no file
-- args). Implementation in lua/session.lua; picker of saved sessions is a
-- source in the picker (<leader>s).
local s = require("session")

-- no localoptions/options: window options like signcolumn/statuscolumn must come
-- from init.lua, not a stale session (else restoring re-applies old values).
vim.o.sessionoptions = "buffers,curdir,folds,tabpages,winsize,winpos,terminal"

local grp = vim.api.nvim_create_augroup("session", { clear = true })

-- only a bare `nvim` owns the cwd session: `nvim file.go` or `cmd | nvim -` would
-- overwrite the project's session with that one buffer on exit
local owns_session = vim.fn.argc() == 0
vim.api.nvim_create_autocmd("StdinReadPre", {
  group = grp,
  callback = function()
    owns_session = false
  end,
})

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = grp,
  callback = function()
    if owns_session then
      s.save()
    end
  end,
})

vim.api.nvim_create_autocmd("VimEnter", {
  group = grp,
  nested = true, -- let the sourced session's own autocmds fire
  callback = function()
    if not owns_session then
      return
    end
    s.restore()
  end,
})

vim.api.nvim_create_user_command("SessionSave", function() s.save() end, {})
vim.api.nvim_create_user_command("SessionRestore", function() s.restore() end, {})
vim.api.nvim_create_user_command("SessionDelete", function() s.delete() end, {})
