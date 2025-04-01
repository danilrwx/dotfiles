vim.keymap.set("n", "<c-l>", "<cmd>noh<Return><esc>")

vim.keymap.set("n", "<a-q>", "<cmd>bd<cr>")
-- vim.keymap.set("n", "<s-h>", "<cmd>bp<cr>")
-- vim.keymap.set("n", "<s-l>", "<cmd>bn<cr>")

vim.keymap.set("n", "<c-d>", "<c-d>zz")
vim.keymap.set("n", "<c-u>", "<c-u>zz")

vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>p", "+p")
vim.keymap.set("n", "<leader>Y", [["+Y]])

vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])

vim.keymap.set("n", "<c-j>", "<cmd>cnext<cr>zz")
vim.keymap.set("n", "<c-k>", "<cmd>cprev<cr>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lnext<cr>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lprev<cr>zz")

vim.keymap.set("n", "<c-t>l", "<cmd>tabnext<cr>")
vim.keymap.set("n", "<c-t>h", "<cmd>tabprev<cr>")
vim.keymap.set("n", "<c-t>n", "<cmd>tabnew<cr>")
vim.keymap.set("n", "<c-t>c", "<cmd>tabclose<cr>")

vim.keymap.set("n", "<leader>gg", "<cmd>!tmux neww lazygit<cr>")

vim.keymap.set("n", "<leader>q", Funcs.toggle_quickfix)
