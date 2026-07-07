-- Clipboard for the devbox (nvim over SSH, no X server). There is no <leader>y:
-- every plain yank is mirrored to the host clipboard by sending an OSC 52 escape
-- straight to /dev/tty (same path as the `clip` helper; tmux forwards it out via
-- set-clipboard + the clipboard terminal-feature). No + register involved.
local function osc52(text)
  local tty = io.open("/dev/tty", "w")
  if not tty then
    return
  end
  tty:write("\27]52;c;" .. vim.base64.encode(text) .. "\7")
  tty:close()
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

vim.keymap.set("n", "<leader>p", '"+p')
vim.keymap.set("n", "<leader>dd", function()
  osc52(vim.fn.expand("%") .. ":" .. vim.fn.line("."))
end, { silent = true })
