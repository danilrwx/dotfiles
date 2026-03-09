vim.opt.expandtab = true
vim.opt.lazyredraw = true
vim.opt.ttyfast = true
vim.opt.number = true
vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.smarttab = true
vim.opt.smartindent = true
vim.opt.softtabstop = 2
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.scrolloff = 3
vim.opt.undodir = '/tmp/.vim/backups'
vim.opt.undofile = true
vim.opt.cursorline = true
vim.opt.termguicolors = true
vim.opt.clipboard = 'unnamedplus'
vim.opt.langmap = "ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯ;ABCDEFGHIJKLMNOPQRSTUVWXYZ,фисвуапршолдьтщзйкыегмцчня;abcdefghijklmnopqrstuvwxyz"
vim.g.mapleader = " "

-- Ranger
vim.g.rnvimr_presets = { { width = 0.950, height = 0.950 } }
vim.g.rnvimr_enable_picker = 1
vim.g.rnvimr_enable_bw = 1

-- Git blame
vim.g.blamer_enabled = 1

-- Coq
vim.g.coq_settings = {
    auto_start = true
}
