vim.g.mapleader = " "

vim.o.autoindent = true
vim.o.expandtab = true
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.softtabstop = 2
vim.o.smartindent = true
vim.o.number = true
vim.o.updatetime = 100
vim.o.signcolumn = "number"
vim.o.laststatus = 0
vim.o.completeopt = "menuone,noselect,noinsert,fuzzy,popup"
vim.o.winborder = "rounded"

vim.o.undofile = true
vim.o.undodir = vim.fn.stdpath("state") .. "/undo"
vim.fn.mkdir(vim.o.undodir, "p")

if vim.fn.executable("ugrep") == 1 then
  vim.o.grepprg = "ugrep -RInk --tabs=1 --ignore-files --exclude='zz_generated*' --exclude-dir='generated'"
  vim.o.grepformat = "%f:%l:%c:%m,%f+%l+%c+%m,%-G%f|%l|%c|%m"
else
  vim.o.grepprg = "grep -RIn --exclude='*zz_generated*' --exclude-dir='generated'"
end

vim.filetype.add({ extension = { yaml = "helm", tpl = "helm" } })

-- source plugins from the private submodule (not tracked in this repo)
local private = vim.fn.expand("~/dotfiles/private/config/nvim")
if vim.fn.isdirectory(private) == 1 then
  vim.opt.runtimepath:append(private)
end

vim.keymap.set("n", "<c-d>", "<c-d>zz")
vim.keymap.set("n", "<c-u>", "<c-u>zz")
vim.keymap.set("n", "<c-l>", "<cmd>nohlsearch<cr>")
vim.keymap.set("n", "-", "<cmd>Oil<cr>", { silent = true })
vim.keymap.set("n", "<leader>gg", "<cmd>silent execute '!tmux neww lazygit'<bar>redraw!<cr>", { silent = true })
vim.keymap.set("n", "<A-q>", "<cmd>bd<cr>", { silent = true })
vim.keymap.set("n", "<S-l>", "<cmd>bn<cr>", { silent = true })
vim.keymap.set("n", "<S-h>", "<cmd>bp<cr>", { silent = true })
