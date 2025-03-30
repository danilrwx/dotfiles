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

vim.cmd.colorscheme("retrobox")
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#1C1C1C" })
vim.api.nvim_set_hl(0, "Pmenu", { bg = "#1C1C1C" })
vim.api.nvim_set_hl(0, "PmenuKind", { fg = "#83a598", bg = "#1C1C1C" })
vim.api.nvim_set_hl(0, "PmenuKindSel", { fg = "#1C1C1C", bg = "#83a598" })
vim.api.nvim_set_hl(0, "PmenuExtra", { bg = "#1C1C1C" })

vim.cmd.packadd("cfilter")

vim.filetype.add({
  filename = {
    ["werf.inc.yaml"] = "helm",
  },
})
