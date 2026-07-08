-- Self-contained fuzzy picker (no fzf, no plugin). This file only wires the
-- engine to commands and keymaps; the implementation lives in lua/picker/:
--   search.lua  fuzzy matcher + grep parsing
--   ui.lua      floating windows + rendering
--   init.lua    orchestrator (state, keymaps, MRU history)
--   sources.lua Files/GFiles/Buffers/LiveGrep
local picker = require("picker")
require("picker.sources") -- populates picker.launchers
local L = picker.launchers

vim.api.nvim_create_user_command("Files", function() L.files() end, {})
vim.api.nvim_create_user_command("GFiles", function() L.gfiles() end, {})
vim.api.nvim_create_user_command("Buffers", function() L.buffers() end, {})
vim.api.nvim_create_user_command("LiveGrep", function(o) L.livegrep({ query = o.args }) end, { nargs = "*" })
vim.api.nvim_create_user_command("Diagnostics", function(o) L.diagnostics({ buf = o.bang }) end, { bang = true })

vim.keymap.set("n", "<leader>F", function() L.files() end, { silent = true })
vim.keymap.set("n", "<leader>f", function() L.gfiles() end, { silent = true })
vim.keymap.set("n", "<leader>b", function() L.buffers() end, { silent = true })
vim.keymap.set("n", "<leader>D", function() L.diagnostics() end, { silent = true })
vim.keymap.set("n", "<leader>/", function() L.livegrep() end, { silent = true })
vim.keymap.set("n", "<leader>?", function() L.livegrep({ query = vim.fn.expand("<cword>") }) end, { silent = true })
vim.keymap.set("x", "<leader>/", function()
  vim.cmd('normal! "zy')
  L.livegrep({ query = (vim.fn.getreg("z"):gsub("\n.*", "")) })
end, { silent = true })
-- <leader>' reopens the most recent picker; <leader>" the one before it.
vim.keymap.set("n", "<leader>'", function() picker.resume(0) end, { silent = true })
vim.keymap.set("n", '<leader>"', function() picker.resume(1) end, { silent = true })
