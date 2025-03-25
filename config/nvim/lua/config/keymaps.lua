vim.keymap.set("n", "<C-t>", "<cmd>!topen-bash<Return><Esc>", { desc = "Open new tmux page by C-t" })
vim.keymap.set("n", "<A-q>", "<cmd>bd<CR>", { desc = "Close buffer by A-q" })

vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Center view after paging" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Center view after paging" })

vim.keymap.set("n", "<Leader>su", vim.cmd.UndotreeToggle, { desc = "Open UndoTree" })

vim.keymap.del("n", "<leader>e")
local MiniFiles = require("mini.files")
vim.keymap.set("n", "<leader>e", function()
  if not MiniFiles.close() then
    MiniFiles.open(vim.api.nvim_buf_get_name(0), true)
  end
end, {})
