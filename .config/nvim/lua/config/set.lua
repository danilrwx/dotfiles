vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = 'number'

vim.opt.hlsearch = true
vim.opt.ignorecase = true

vim.opt.expandtab = true
vim.opt.smarttab = true
vim.opt.smartindent = true
vim.opt.softtabstop = 2
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2

vim.opt.scrolloff = 3
vim.opt.undodir = '/tmp/.vim/backups'
vim.opt.undofile = true
vim.opt.wildmenu = true

vim.opt.langmap = "ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯ;ABCDEFGHIJKLMNOPQRSTUVWXYZ,фисвуапршолдьтщзйкыегмцчня;abcdefghijklmnopqrstuvwxyz"

vim.opt.path= ".,,**"
vim.opt.wildmenu = true
vim.opt.wildignore= "*/dist*/*,*/target/*,*/builds/*,*/node_modules/*"

vim.g.mapleader = ' '

vim.opt.termguicolors = true
vim.cmd("colorscheme gruvbox")
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
vim.api.nvim_set_hl(0, "StatusLine", { bg = "none" })
