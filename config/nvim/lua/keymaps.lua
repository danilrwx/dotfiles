vim.keymap.set("n", "<Esc>", "<cmd>noh<Return><Esc>", { desc = "Hide highlights by Esc" })
vim.keymap.set("n", "<C-t>", "<cmd>!topen-bash<Return><Esc>", { desc = "Open new tmux page by C-t" })
vim.keymap.set("n", "<A-q>", "<cmd>bd<CR>", { desc = "Close buffer by A-q" })

vim.keymap.set("n", "<C-s>", "<cmd>w<cr><esc>", { desc = "Save buffer by C-s" })

vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Center view after paging" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Center view after paging" })

vim.keymap.set("i", "<C-c>", "<Esc>", { desc = "Escape from insert mode" })

vim.keymap.set("n", "<Leader>e", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
  { desc = "Change word by cursor over all buffer" })

vim.keymap.set("x", "<leader>p", [["_dP]])
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])

vim.keymap.set("n", "<S-l>", "<cmd>bn<CR>")
vim.keymap.set("n", "<S-h>", "<cmd>bp<CR>")

vim.keymap.set("n", "<C-j>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-k>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<Leader>j", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<Leader>k", "<cmd>lprev<CR>zz")

vim.keymap.set("n", "<Leader>tl", "<cmd>tabnext<CR>")
vim.keymap.set("n", "<Leader>th", "<cmd>tabprev<CR>")
vim.keymap.set("n", "<Leader>tn", "<cmd>tabnew<CR>")
vim.keymap.set("n", "<Leader>tc", "<cmd>tabclose<CR>")

vim.keymap.set("n", "<C-q>", Funcs.toggle_quickfix)

vim.keymap.set("n", "<C-n>", function()
  if vim.bo.filetype == "netrw" then
    vim.cmd("bwipeout")
  else
    vim.cmd("Explore")
  end
end, { silent = true })

local builtin = require("telescope.builtin")
vim.keymap.set("n", "<Leader>f", builtin.find_files, { desc = "Find files" })
vim.keymap.set("n", "<Leader>/", builtin.live_grep, { desc = "Grep files" })
vim.keymap.set("x", "<Leader>/", builtin.grep_string, { desc = "Grep visual string" })
vim.keymap.set("n", "<Leader>b", builtin.buffers, { desc = "Find buffers" })
vim.keymap.set("n", "<Leader>r", builtin.registers, { desc = "Find registers" })

vim.keymap.set("n", "<leader>gg", "<cmd>!topen-git<CR>", { desc = "LazyGit" })
vim.keymap.set("n", "<leader>gs", "<cmd>tab Git<CR>", { desc = "Fugitive" })
vim.keymap.set("n", "<leader>gl", "<cmd>tab Git log --follow -p %<CR>", { desc = "Git detailed file log" })
vim.keymap.set("n", "<leader>gL", "<cmd>tab Git log<CR>", { desc = "Git log" })
vim.keymap.set("n", "<leader>gK", "<cmd>tab Git log -p<CR>", { desc = "Git detailed log" })
vim.keymap.set("n", "<leader>gb", "<cmd>tab Git blame<CR>", { desc = "Git blame" })
vim.keymap.set("n", "<leader>gB", "<cmd>GBrowse<CR>", { desc = "Git browse" })
vim.keymap.set("n", "<leader>gd", "<cmd>tab Git diff %<CR>", { desc = "Git diff file" })
vim.keymap.set("n", "<leader>gD", "<cmd>tab Git diff <CR>", { desc = "Git diff" })
vim.keymap.set("n", "<leader>gP", "<cmd>Git push<CR>", { desc = "Git push" })
vim.keymap.set("n", "<leader>gp", "<cmd>Git pull --rebase<CR>", { desc = "Git pull with rebase" })
