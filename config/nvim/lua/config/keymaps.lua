vim.keymap.set("n", "<Esc>", "<cmd>noh<Return><Esc>", { desc = "Hide highlights by Esc" })
vim.keymap.set("n", "<C-t>", "<cmd>!topen-bash<Return><Esc>", { desc = "Open new tmux page by C-t" })
vim.keymap.set("n", "<A-q>", "<cmd>bd<CR>", { desc = "Close buffer by A-q" })

vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Center view after paging" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Center view after paging" })

vim.keymap.set(
  "n",
  "<leader>re",
  [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
  { desc = "Change word by cursor over all buffer" }
)

-- vim.keymap.set("n", "<C-j>", "<cmd>cnext<CR>zz")
-- vim.keymap.set("n", "<C-k>", "<cmd>cprev<CR>zz")

vim.keymap.set("n", "<C-q>", Funcs.toggle_quickfix)

vim.keymap.del("n", "<leader>gg")
vim.keymap.del("n", "<leader>gG")
vim.keymap.del("n", "<leader>gf")
vim.keymap.del("n", "<leader>gB")

vim.keymap.set("n", "<leader>gg", "<cmd>!topen-git<Return><Esc>", { desc = "Open LazyGit" })

vim.keymap.set("n", "<leader>gs", "<cmd>tab Git<CR>", { desc = "Fugitive" })

vim.keymap.set("n", "<leader>gl", "<cmd>tab Git log -p --follow %<CR>", { desc = "Git detailed file log" })
vim.keymap.set("n", "<leader>gL", "<cmd>tab Git log<CR>", { desc = "Git log" })

vim.keymap.set("n", "<leader>gb", "<cmd>tab Git blame<CR>", { desc = "Git blame" })

vim.keymap.set("n", "<leader>go", "<cmd>GBrowse<CR>", { desc = "Git browse" })

vim.keymap.set("n", "<leader>gd", "<cmd>Gvdiffsplit<CR>", { desc = "Git diff file" })
vim.keymap.set("n", "<leader>gD", "<cmd>Gvdiffsplit HEAD<CR>", { desc = "Git diff with staged" })

vim.keymap.set("n", "<leader>gS", "<cmd>Telescope git_status<CR>", { desc = "Pick git status" })

vim.keymap.set("n", "<Leader>su", vim.cmd.UndotreeToggle, { desc = "Open UndoTree" })

-- vim.keymap.set("n", "<C-f>", "<cmd>Oil<CR>")
local MiniFiles = require("mini.files")
vim.keymap.set("n", "<C-f>", function()
  if not MiniFiles.close() then
    MiniFiles.open(vim.api.nvim_buf_get_name(0), true)
  end
end, {})
