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

vim.cmd.colorscheme("retrobox")
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#1C1C1C" })
vim.api.nvim_set_hl(0, "Visual", { fg = nil, bg = "#2F2F2F" })

vim.api.nvim_set_hl(0, "Pmenu", { bg = "#1C1C1C" })
vim.api.nvim_set_hl(0, "PmenuKind", { fg = "#83A598", bg = "#1C1C1C" })
vim.api.nvim_set_hl(0, "PmenuKindSel", { fg = "#1C1C1C", bg = "#83A598" })
vim.api.nvim_set_hl(0, "PmenuExtra", { bg = "#1C1C1C" })

vim.api.nvim_set_hl(0, "Added", { fg = "#B8BB26" })
vim.api.nvim_set_hl(0, "Changed", { fg = "#83A598" })
vim.api.nvim_set_hl(0, "Removed", { fg = "#FB4934" })

vim.api.nvim_set_hl(0, "Identifier", { fg = "#EBDBB2" })
vim.api.nvim_set_hl(0, "Delimiter", { fg = "#EBDBB2" })
vim.api.nvim_set_hl(0, "@variable", { fg = "#83A598" })
vim.api.nvim_set_hl(0, "@variable.parameter", { fg = "#83A598" })

vim.api.nvim_set_hl(0, "DiagnosticError", { fg = "#FB4934" })
vim.api.nvim_set_hl(0, "DiagnosticWarn", { fg = "#FE8019" })
vim.api.nvim_set_hl(0, "DiagnosticInfo", { fg = "#EBDBB2" })
vim.api.nvim_set_hl(0, "DiagnosticHint", { fg = "#EBDBB2" })
vim.api.nvim_set_hl(0, "DiagnosticOk", { fg = "#B8BB26" })

vim.cmd.packadd("cfilter")

vim.filetype.add({
  extension = { yaml = "helm" },
  -- filename = { ["werf.inc.yaml"] = "helm" },
})
