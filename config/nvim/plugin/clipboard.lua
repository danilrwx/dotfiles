-- Clipboard for the devbox (nvim over SSH, no X server). There is no <leader>y:
-- every plain yank is mirrored to the host clipboard with an OSC 52 escape,
-- emitted by neovim's builtin osc52 provider through nvim's own output channel.
-- Writing to /dev/tty (directly or via a subprocess) fails with ENXIO when nvim
-- has no controlling terminal (SSH/tmux) — that is why plain y/yy stopped
-- copying. tmux forwards it out via set-clipboard + the clipboard feature.
local copy = require("vim.ui.clipboard.osc52").copy("+")

-- only real yanks (not deletes) to the unnamed or clipboard registers
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("osc52_copy", { clear = true }),
  callback = function()
    local e = vim.v.event
    if e.operator == "y" and (e.regname == "" or e.regname == "+" or e.regname == "*") then
      copy(e.regcontents, e.regtype)
    end
  end,
})

vim.keymap.set("n", "<leader>dd", function()
  copy({ vim.fn.expand("%") .. ":" .. vim.fn.line(".") }, "v")
end, { silent = true })
