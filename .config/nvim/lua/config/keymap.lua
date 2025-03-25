vim.keymap.set("n", "<Tab>", ":buffers<CR>:buffer<Space>")
vim.keymap.set("n", "<Leader>q", ":bd<CR>")
vim.keymap.set("n", "<Leader>pp", ":Ex<CR>")

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set("x", "<Leader>p", [["_dP]])

vim.keymap.set({ "n", "v" }, "<Leader>y", [["+y]])
vim.keymap.set("n", "<Leader>Y", [["+Y]])

vim.keymap.set({ "n", "v" }, "<Leader>d", [["_d]])

vim.keymap.set("n", "<Leader>ff", vim.lsp.buf.format)

vim.keymap.set("n", "<Leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

vim.keymap.set("n", "<Esc>", ":noh<Return><Esc>")
