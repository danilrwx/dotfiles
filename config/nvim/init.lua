vim.g.mapleader = " "

-- Vim's default theme, using the terminal palette.
vim.o.termguicolors = false
vim.cmd.colorscheme("vim")

-- Treat .h files as C rather than C++.
vim.g.c_syntax_for_h = true

vim.o.autoindent = true
vim.o.expandtab = true
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.softtabstop = 2
vim.o.smartindent = true

vim.o.number = true
vim.o.laststatus = 0

vim.o.completeopt = "menuone,noselect,noinsert,fuzzy,popup"
vim.o.pumheight = 12
vim.o.winborder = "rounded"

vim.o.undofile = true
vim.o.undodir = vim.fn.stdpath("state") .. "/undo"
vim.fn.mkdir(vim.o.undodir, "p")

if vim.fn.executable("ugrep") == 1 then
  vim.o.grepprg = "ugrep -RInk --tabs=1 --ignore-files --exclude='zz_generated*' --exclude-dir='generated'"
  vim.o.grepformat = "%f:%l:%c:%m,%f+%l+%c+%m,%-G%f|%l|%c|%m"
else
  vim.o.grepprg = "grep -RInH --exclude-dir=.git --exclude='*zz_generated*' --exclude-dir='generated'"
  vim.o.grepformat = "%f:%l:%m"
end

vim.filetype.add({ extension = { yaml = "helm", tpl = "helm" } })

vim.keymap.set("n", "<c-d>", "<c-d>zz")
vim.keymap.set("n", "<c-u>", "<c-u>zz")
vim.keymap.set("n", "<c-l>", "<cmd>nohlsearch<bar>diffupdate<bar>normal! <c-l><cr>")

vim.g.netrw_banner = 0

vim.keymap.set("n", "-", "<cmd>Explore %:p:h<cr>", { silent = true })

vim.keymap.set("n", "<A-q>", "<cmd>bd<cr>", { silent = true })
vim.keymap.set("n", "<S-l>", "<cmd>bn<cr>", { silent = true })
vim.keymap.set("n", "<S-h>", "<cmd>bp<cr>", { silent = true })
