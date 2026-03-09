vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.number = true
vim.opt.numberwidth = 2
vim.opt.relativenumber = true

vim.opt.expandtab = true
vim.opt.smarttab = true
vim.opt.smartindent = true
vim.opt.softtabstop = 2
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2

vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99

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

vim.opt.completeopt = "menuone,noselect,noinsert,fuzzy,popup"

vim.opt.undodir = os.getenv("HOME") .. "/.local/nvim/undo"
vim.opt.undofile = true

vim.pack.add({
  { src = "https://github.com/nvim-treesitter/nvim-treesitter" },
  { src = "https://github.com/supermaven-inc/supermaven-nvim" },
  { src = "https://github.com/chrisgrieser/nvim-origami" },
  { src = "https://github.com/laktak/tome" },

  { src = "https://github.com/sebdah/vim-delve" },
  { src = "https://github.com/vim-test/vim-test" },
  { src = "https://github.com/kyoh86/vim-go-coverage" },

  { src = "https://github.com/Wansmer/symbol-usage.nvim" },

  { src = "https://github.com/rmagatti/auto-session" },

  { src = "https://github.com/stevearc/oil.nvim" },

  { src = "https://github.com/ibhagwan/fzf-lua" },

  { src = "https://github.com/nvim-mini/mini.nvim" },

  { src = "https://github.com/catppuccin/nvim" },
})

require('nvim-treesitter.config').setup({
  ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "go" },
  auto_install = true,
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
})

require("oil").setup({ view_options = { show_hidden = true } })

require("auto-session").setup({ suppressed_dirs = { "~/", "~/Downloads", "/" } })

require("origami").setup({ foldKeymaps = { setup = false }, autoFold = { enabled = false } })

require("supermaven-nvim").setup({})

require("fzf-lua").setup({ winopts = { fullscreen = true, preview = { layout = "vertical", vertical = "up:55%", border = "single" } } })
require("fzf-lua").register_ui_select()

require("symbol-usage").setup({
  kinds = {
    vim.lsp.protocol.SymbolKind.Function,
    vim.lsp.protocol.SymbolKind.Method,
    vim.lsp.protocol.SymbolKind.Interface,
    vim.lsp.protocol.SymbolKind.Constant,
  },
  definition = { enabled = true },
  implementation = { enabled = true },
  vt_position = "end_of_line",
})

require("mini.extra").setup()
require("mini.diff").setup()
require("mini.git").setup()

require("mini.trailspace").setup()
require("mini.icons").setup()

vim.opt.termguicolors = true
vim.cmd.colorscheme("catppuccin")

vim.api.nvim_set_hl(0, "Added", { fg = "#00cd00" })
vim.api.nvim_set_hl(0, "Changed", { fg = "#00cdcd" })
vim.api.nvim_set_hl(0, "Removed", { fg = "#cd0000" })

vim.api.nvim_set_hl(0, "DiffAdded", { fg = "#00cd00" })
vim.api.nvim_set_hl(0, "DiffChanged", { fg = "#00cdcd" })
vim.api.nvim_set_hl(0, "DiffRemoved", { fg = "#cd0000" })

vim.cmd.packadd("cfilter")

vim.filetype.add({ extension = { yaml = "helm", tpl = "helm" } })

vim.lsp.enable("gopls")
vim.lsp.enable("golangci_lint_ls")
vim.lsp.enable("lua_ls")
vim.lsp.enable("helm_ls")
vim.lsp.enable("clangd")
vim.lsp.enable("rust_analyzer")

vim.diagnostic.config({ virtual_text = { prefix = "🐗", }, signs = false })

vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("highlight_yank", {}),
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    local save_cursor = vim.fn.getpos(".")
    pcall(function() vim.cmd([[%s/\s\+$//e]]) end)
    vim.fn.setpos(".", save_cursor)
  end,
})

vim.api.nvim_create_autocmd("LspAttach", {
  desc = "LSP actions",
  callback = function(event)
    local opts = { buffer = event.buf }
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client == nil then return end

    if client.server_capabilities.codeLensProvider then
      ---@diagnostic disable-next-line: param-type-mismatch
      vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold" },
        { callback = function() vim.lsp.codelens.refresh() end })
      vim.keymap.set("n", "grc", "<cmd>lua vim.lsp.codelens.run()<cr>", opts)
    end

    if client:supports_method("textDocument/formatting") then
      vim.keymap.set({ "n", "x" }, "grf", "<cmd>lua vim.lsp.buf.format({async = true})<cr>", opts)
    end
  end,
})

local toggle_quickfix = function()
  local quickfix_wins = vim.tbl_filter(function(win_id)
    return vim.fn.getwininfo(win_id)[1].quickfix == 1
  end, vim.api.nvim_tabpage_list_wins(0))

  local command = #quickfix_wins == 0 and "copen" or "cclose"
  vim.cmd(command)
end

vim.keymap.set("n", "<leader>gg", "<cmd>!tmux neww lazygit<cr>")

vim.keymap.set("n", "<c-[>", "<cmd>noh<Return><esc>")

vim.keymap.set("n", "<c-d>", "<c-d>zz")
vim.keymap.set("n", "<c-u>", "<c-u>zz")

vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>p", "+p")
vim.keymap.set("n", "<leader>Y", [["+Y]])

vim.keymap.set("n", "<leader>dd", "<cmd>let @+ = expand('%') . ':' . line('.')<CR>")

vim.keymap.set("n", "<A-q>", "<cmd>bd<cr>")
vim.keymap.set("n", "<A-q>", "<cmd>bd<cr>")

vim.keymap.set("n", "<leader>tc", "<cmd>GoCover<cr>")
vim.keymap.set("n", "<leader>tC", "<cmd>GoCoverClear<cr>")

vim.keymap.set("n", "<leader>gl", "<cmd>Git log --follow -p %<cr>")
vim.keymap.set("n", "<leader>gL", "<cmd>Git log<cr>")
vim.keymap.set("n", "<leader>gb", "<cmd>Git blame<cr>")

vim.keymap.set("n", "<leader>tr", "<cmd>TestNearest<cr>")
vim.keymap.set("n", "<leader>tt", "<cmd>TestFile<cr>")

vim.keymap.set("n", "<leader>f", "<cmd>lua require('fzf-lua').files()<cr>")
vim.keymap.set("n", "<leader>/", "<cmd>lua require('fzf-lua').live_grep()<cr>")
vim.keymap.set("n", "<leader>'", "<cmd>lua require('fzf-lua').resume()<cr>")
vim.keymap.set("n", "<leader>b", "<cmd>lua require('fzf-lua').buffers()<cr>")
vim.keymap.set("n", "<leader>D", "<cmd>lua require('fzf-lua').lsp_workspace_diagnostics()<cr>")

vim.keymap.set("n", "<leader>td", "<cmd>DlvTestCurrent<cr>")
vim.keymap.set("n", "<leader>db", "<cmd>DlvToggleBreakpoint<cr>")
vim.keymap.set("n", "<leader>dc", "<cmd>DlvConnect :2345<cr>")

vim.keymap.set({ 'n', 'x' }, '<leader>gs', "<cmd>lua require('mini.git').show_at_cursor()<cr>")

vim.keymap.set('n', 'ghp', "<cmd>lua require('mini.diff').toggle_overlay()<cr>")

vim.keymap.set("n", "-", "<cmd>Oil<cr>")

vim.keymap.set("n", "<leader>q", toggle_quickfix)
