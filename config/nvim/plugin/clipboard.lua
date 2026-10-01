-- Every plain yank is mirrored to the desktop clipboard, so there is no
-- <leader>y: bin/clip (wl-copy under sway, xclip under i3). Without a display
-- (a server over ssh) yanks stay in nvim's registers.
if not ((vim.env.WAYLAND_DISPLAY or vim.env.DISPLAY) and vim.fn.executable("clip") == 1) then
  return
end

local function copy(lines, regtype)
  local text = table.concat(lines, "\n") .. (regtype == "V" and "\n" or "")
  vim.system({ "clip" }, { stdin = text, detach = true })
end

-- only real yanks (not deletes) to the unnamed or clipboard registers
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("clipboard_copy", { clear = true }),
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
