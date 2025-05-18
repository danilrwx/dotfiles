vim.opt.undodir = os.getenv("HOME") .. "/.vim/nfiles/undo"
vim.opt.undofile = true

vim.opt.number = false
vim.opt.numberwidth = 2
vim.opt.relativenumber = true

vim.opt.expandtab = true
vim.opt.smarttab = true
vim.opt.smartindent = true
vim.opt.softtabstop = 2
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2

vim.opt.signcolumn = "yes"
vim.opt.laststatus = 1

if vim.fn.executable("ugrep") == 1 then
  vim.opt.grepprg = "ugrep -RInk --tabs=1 --ignore-files --exclude='zz_generated*' --exclude-dir='generated'"
else
  vim.opt.grepprg = "grep -RIn --exclude='zz_generated*' --exclude-dir='generated'"
end

vim.o.winborder = "single"

vim.opt.signcolumn = "auto"
-- vim.opt.statuscolumn = "%l%s"

vim.opt.background = "dark"
vim.opt.termguicolors = false
vim.cmd.colorscheme("lunaperche")

vim.cmd.packadd("cfilter")

vim.filetype.add({
  extension = { yaml = "helm" },
})
