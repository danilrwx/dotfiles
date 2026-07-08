-- Clipboard for the devbox (nvim over SSH, no X server). There is no <leader>y:
-- every plain yank is mirrored to the host clipboard by the `clip` helper (a
-- subprocess that writes the OSC 52 sequence to /dev/tty). Writing the escape
-- from inside nvim itself does not reach tmux/the terminal — same reason the
-- vim config used clip rather than echoraw. No + register involved.
local function osc52(text)
  vim.system({ "clip" }, { stdin = text })
end

-- only real yanks (not deletes) to the unnamed or clipboard registers
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    local e = vim.v.event
    if e.operator ~= "y" or not (e.regname == "" or e.regname == "+" or e.regname == "*") then
      return
    end
    local text = table.concat(e.regcontents, "\n")
    if (e.regtype or ""):sub(1, 1) == "V" then
      text = text .. "\n"
    end
    osc52(text)
  end,
})

vim.keymap.set("n", "<leader>dd", function()
  osc52(vim.fn.expand("%") .. ":" .. vim.fn.line("."))
end, { silent = true })
