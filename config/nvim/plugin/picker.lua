-- Self-contained fuzzy picker (no fzf, no plugin). This file only wires the
-- engine to commands and keymaps; the implementation lives in lua/picker/:
--   search.lua  fuzzy matcher + grep parsing
--   ui.lua      floating windows + rendering
--   init.lua    orchestrator (state, keymaps, MRU history)
--   sources.lua Files/GFiles/Buffers/LiveGrep
local picker = require("picker")
require("picker.sources") -- populates picker.launchers
local L = picker.launchers

-- one entry point for every picker: `:Picker <name>` Tab-completes the launcher
-- names (files, gfiles, buffers, livegrep, git_hunks, git_commits, …), so a
-- forgotten picker is one <Tab> away. Trailing text seeds the query (live grep);
-- `:Picker! diagnostics` scopes diagnostics to the current buffer.
local function launcher_names()
  local names = vim.tbl_keys(L)
  table.sort(names)
  return names
end

vim.api.nvim_create_user_command("Picker", function(o)
  local parts = vim.split(o.args, " ", { trimempty = true })
  local name = table.remove(parts, 1)
  local launcher = name and L[name]
  if not launcher then
    vim.notify("Picker: unknown " .. vim.inspect(name) .. "\navailable: " .. table.concat(launcher_names(), ", "),
      vim.log.levels.WARN)
    return
  end
  local query = table.concat(parts, " ")
  launcher({ query = query ~= "" and query or nil, buf = o.bang or nil })
end, {
  nargs = "*",
  bang = true,
  desc = "Open a picker by name (Tab-completes)",
  complete = function(lead)
    return vim.tbl_filter(function(n)
      return n:find(lead, 1, true) == 1
    end, launcher_names())
  end,
})

vim.keymap.set("n", "<leader>F", function() L.files() end, { silent = true })
vim.keymap.set("n", "<leader>f", function() L.gfiles() end, { silent = true })
vim.keymap.set("n", "<leader>b", function() L.buffers() end, { silent = true })
vim.keymap.set("n", "<leader>D", function() L.diagnostics() end, { silent = true })
vim.keymap.set("n", "<leader>s", function() L.sessions() end, { silent = true })
vim.keymap.set("n", "<leader>gh", function() L.git_hunks() end, { silent = true })
vim.keymap.set("n", "<leader>/", function() L.livegrep() end, { silent = true })
vim.keymap.set("n", "<leader>?", function() L.livegrep({ query = vim.fn.expand("<cword>") }) end, { silent = true })
vim.keymap.set("x", "<leader>/", function()
  vim.cmd('normal! "zy')
  L.livegrep({ query = (vim.fn.getreg("z"):gsub("\n.*", "")) })
end, { silent = true })
-- <leader>' reopens the most recent picker; <leader>" the one before it.
vim.keymap.set("n", "<leader>'", function() picker.resume(0) end, { silent = true })
vim.keymap.set("n", '<leader>"', function() picker.resume(1) end, { silent = true })
