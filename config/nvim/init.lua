local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("functions")
require("options")
require("lazy").setup("plugins")
require("autocmds")
require("keymaps")

vim.cmd("colorscheme torte")
vim.cmd("hi Normal guibg=None")
vim.cmd("hi NonText guifg=Gray")
