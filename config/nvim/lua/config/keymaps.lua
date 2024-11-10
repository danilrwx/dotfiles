-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

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

-- vim.keymap.set
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])
vim.keymap.set("n", "<leader>p", [["+p]])
vim.keymap.set("n", "<leader>P", [["+P]])
vim.keymap.set("x", "<leader>p", [["_d"+p]])
vim.keymap.set("x", "<leader>P", [["_d"+P]])
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])

vim.keymap.set("n", "<C-j>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-k>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lprev<CR>zz")

vim.keymap.set("n", "<Tab>", "<cmd>bn<CR>")
vim.keymap.set("n", "<S-Tab>", "<cmd>bp<CR>")

vim.keymap.set("n", "<C-q>", Funcs.toggle_quickfix)

vim.keymap.del("n", "<leader>gg")
vim.keymap.del("n", "<leader>gG")
vim.keymap.del("n", "<leader>gf")

vim.keymap.set("n", "<leader>gl", "<cmd>tab Git log -p --follow %<CR>", { desc = "Git detailed file log" })
vim.keymap.set("n", "<leader>gs", "<cmd>tab Git<CR>", { desc = "Fugitive" })

vim.keymap.set("n", "<leader>gl", "<cmd>tab Git log -p --follow %<CR>", { desc = "Git detailed file log" })
vim.keymap.set("n", "<leader>gL", "<cmd>tab Gclog<CR>", { desc = "Git log" })

vim.keymap.set("n", "<leader>gb", "<cmd>tab Git blame<CR>", { desc = "Git blame" })

vim.keymap.set("n", "<leader>go", "<cmd>GBrowse<CR>", { desc = "Git browse" })

vim.keymap.set("n", "<leader>gd", "<cmd>Gvdiffsplit<CR>", { desc = "Git diff file" })
vim.keymap.set("n", "<leader>gD", "<cmd>Gvdiffsplit HEAD<CR>", { desc = "Git diff with staged" })
vim.keymap.set("n", "<leader>gc", "<cmd>git diff<CR>", { desc = "Git diff with staged" })

vim.keymap.set("n", "<leader>gP", "<cmd>Git push<CR>", { desc = "Git push" })
vim.keymap.set("n", "<leader>gp", "<cmd>Git pull --rebase<CR>", { desc = "Git pull with rebase" })

vim.keymap.set("n", "<leader>gS", "<cmd>Telescope git_status<CR>", { desc = "Pick git status" })

vim.keymap.set("n", "<Leader>u", vim.cmd.UndotreeToggle, { desc = "Open UndoTree" })

local MiniFiles = require("mini.files")
vim.keymap.set("n", "<C-f>", function()
  if not MiniFiles.close() then
    MiniFiles.open(vim.api.nvim_buf_get_name(0), true)
  end
end, {})
