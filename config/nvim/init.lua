vim.pack.add({
  { src = "https://github.com/ibhagwan/fzf-lua" },
  { src = "https://github.com/laktak/tome" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter" },
  { src = "https://github.com/rmagatti/auto-session" },
  { src = "https://github.com/supermaven-inc/supermaven-nvim" },
  { src = "https://github.com/vim-test/vim-test" },
  { src = "https://github.com/tpope/vim-fugitive" },
  { src = "https://github.com/lewis6991/gitsigns.nvim" },
  { src = "https://github.com/stevearc/oil.nvim" },
})

require("oil").setup({ view_options = { show_hidden = true } })

require("auto-session").setup({ suppressed_dirs = { "~/", "~/Downloads", "/" } })

require("fzf-lua").setup({ winopts = { fullscreen = true, preview = { layout = "vertical", vertical = "up:55%", border = "single" } } })
require("fzf-lua").register_ui_select()

require("supermaven-nvim").setup({})

require("user.pack").setup()
require("user.autocmds").setup()

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.completeopt = "menuone,noselect,noinsert,fuzzy,popup"

vim.opt.termguicolors = true

vim.opt.undodir = os.getenv("HOME") .. "/.local/nvim/undo"
vim.opt.undofile = true

vim.opt.number = true
vim.opt.numberwidth = 2
vim.opt.relativenumber = true

vim.opt.expandtab = true
vim.opt.smarttab = true
vim.opt.smartindent = true
vim.opt.softtabstop = 2
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2

vim.opt.signcolumn = "auto"
vim.opt.laststatus = 0
vim.opt.cmdheight = 1

vim.opt.updatetime = 500

if vim.fn.executable("ugrep") == 1 then
  vim.opt.grepprg = 'ugrep -nk --tabs=1 --ignore-files --exclude="zz_generated*" --exclude-dir="generated"'
else
  vim.opt.grepprg = 'grep -RIn --exclude="zz_generated*" --exclude-dir="generated"'
end

vim.o.diffopt = 'internal,filler,closeoff,inline:word,linematch:40'

vim.cmd.packadd("cfilter")

vim.filetype.add({ extension = { yaml = "helm", tpl = "helm" } })

vim.lsp.enable("gopls")
vim.lsp.enable("golangci_lint_ls")
vim.lsp.enable("lua_ls")
vim.lsp.enable("helm_ls")
vim.lsp.enable("clangd")
vim.lsp.enable("rust_analyzer")

vim.diagnostic.config({ virtual_text = { prefix = "🐗", }, signs = false })

vim.keymap.set("n", "<leader>gg", "<cmd>!tmux neww lazygit<cr>")
vim.keymap.set("n", "<leader>gl", "<cmd>tab Git log --follow -p %<cr>")
vim.keymap.set("n", "<leader>gL", "<cmd>tab Git log --follow %<cr>")
vim.keymap.set("n", "<leader>gb", "<cmd>tab Git blame<cr>")

vim.keymap.set("n", "<c-[>", "<cmd>noh<Return><esc>")

vim.keymap.set("n", "<c-d>", "<c-d>zz")
vim.keymap.set("n", "<c-u>", "<c-u>zz")

vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>p", "+p")
vim.keymap.set("n", "<leader>Y", [["+Y]])

vim.keymap.set("n", "<leader>dd", "<cmd>let @+ = expand('%') . ':' . line('.')<CR>")

vim.keymap.set("n", "<A-q>", "<cmd>bd<cr>")

vim.keymap.set("n", "-", "<cmd>Oil<cr>")

vim.keymap.set("n", "<leader>f", require('fzf-lua').files)
vim.keymap.set("n", "<leader>/", require('fzf-lua').live_grep)
vim.keymap.set("n", "<leader>'", require('fzf-lua').resume)
vim.keymap.set("n", "<leader>b", require('fzf-lua').buffers)
vim.keymap.set("n", "<leader>D", require('fzf-lua').lsp_workspace_diagnostics)

vim.keymap.set('n', 'ghs', require('gitsigns').stage_hunk)
vim.keymap.set('n', 'ghr', require('gitsigns').reset_hunk)
vim.keymap.set("n", "]c",  require("gitsigns").next_hunk)
vim.keymap.set("n", "[c",  require("gitsigns").prev_hunk)
vim.keymap.set("n", "ghp", require("gitsigns").preview_hunk_inline)

vim.keymap.set("n", "<leader>q", require("user.functions").toggle_quickfix)

vim.cmd.colorscheme("torte")
