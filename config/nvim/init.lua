vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

vim.opt.undodir = os.getenv('HOME') .. '/.local/nvim/undo'
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

vim.opt.signcolumn = 'auto'
vim.opt.laststatus = 1

vim.opt.updatetime = 100
vim.opt.completeopt = 'menuone,noselect,noinsert,fuzzy,popup'

if vim.fn.executable("ugrep") == 1 then
  vim.opt.grepprg = "ugrep -nk --tabs=1 --ignore-files --exclude='zz_generated*' --exclude-dir='generated'"
else
  vim.opt.grepprg = "grep -RIn --exclude='zz_generated*' --exclude-dir='generated'"
end

vim.cmd.packadd('cfilter')

vim.filetype.add({ extension = { yaml = 'helm' } })

vim.lsp.enable('gopls')
-- vim.lsp.enable('golangci_lint_ls')
vim.lsp.enable('lua_ls')
vim.lsp.enable('helm_ls')

vim.diagnostic.config({ virtual_text = { prefix = '🐗', }, signs = false })

vim.fn.sign_define('DapBreakpoint', { text = '✊', texthl = '', linehl = '', numhl = '' })
vim.fn.sign_define('DapBreakpointCondition', { text = '🫸', texthl = '', linehl = '', numhl = '' })
vim.fn.sign_define('DapLogPoint', { text = '📄', texthl = '', linehl = '', numhl = '' })
vim.fn.sign_define('DapStopped', { text = '👉', texthl = '', linehl = '', numhl = '' })
vim.fn.sign_define('DapBreakpointRejected', { text = '🚫', texthl = '', linehl = '', numhl = '' })

vim.pack.add({
  { src = 'https://github.com/deparr/tairiki.nvim' },

  { src = 'http://github.com/saghen/blink.cmp' },

  { src = 'https://github.com/nvim-tree/nvim-web-devicons' },
  { src = 'https://github.com/romgrk/barbar.nvim' },

  { src = 'https://github.com/rmagatti/auto-session' },
  { src = 'https://github.com/stevearc/oil.nvim' },
  { src = 'https://github.com/ibhagwan/fzf-lua' },

  { src = 'https://github.com/nvim-treesitter/nvim-treesitter' },

  { src = 'https://github.com/lewis6991/gitsigns.nvim' },
  { src = 'https://github.com/tpope/vim-fugitive' },

  { src = 'https://github.com/miroshQa/debugmaster.nvim' },
  { src = 'https://github.com/mfussenegger/nvim-dap' },
  { src = 'https://github.com/leoluz/nvim-dap-go' },

  { src = 'https://github.com/Wansmer/symbol-usage.nvim' },

  { src = 'https://github.com/kyoh86/vim-go-coverage' },
  { src = 'https://github.com/vim-test/vim-test' },

  -- { src = 'https://github.com/christoomey/vim-tmux-navigator' },
  { src = 'https://github.com/laktak/tome' },

  { src = 'https://github.com/daliusd/ghlite.nvim' },

  { src = 'https://github.com/supermaven-inc/supermaven-nvim' },
})

require('supermaven-nvim').setup({})

require('oil').setup({ view_options = { show_hidden = true } })

require('auto-session').setup({ suppressed_dirs = { '~/', '~/Downloads', '/' } })

require('nvim-treesitter.configs').setup({ auto_install = true, highlight = { enable = true } })

require('fzf-lua').setup({ winopts = { fullscreen = true, preview = { layout = "vertical", vertical = "up:55%", border = "single" } } })
require('fzf-lua').register_ui_select()

require('ghlite').setup({ view_split = 'tabnew', diff_split = 'tabnew', comment_split = 'tabnew' })

require('dap-go').setup({})

require('symbol-usage').setup({
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

vim.cmd.colorscheme("retrobox")

vim.api.nvim_set_hl(0, "Normal", { bg = nil })
vim.api.nvim_set_hl(0, "SignColumn", { bg = nil })
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#1C1C1C" })
vim.api.nvim_set_hl(0, "Visual", { fg = nil, bg = "#1C1C1C" })
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


require('barbar').setup({
  animation = false,
  icons = {
    button = '',
    modified = { button = '🔸' },
    pinned = { button = '📌', filename = true },
    diagnostics = { [vim.diagnostic.severity.ERROR] = { enabled = true, icon = '🔥' }, }
  },
})

require('blink.cmp').setup({
  keymap = { preset = 'enter' },
  signature = { enabled = true },
  appearance = { nerd_font_variant = 'normal' },
  completion = {
    accept = { auto_brackets = { enabled = true } },
    menu = { draw = { treesitter = { "lsp" } } },
    documentation = { auto_show = true, auto_show_delay_ms = 200 },
  },
  fuzzy = { prebuilt_binaries = { force_version = "v1.6.0" } },
  sources = { default = { 'lsp', 'path', 'snippets', 'buffer' } },
})

require('gitsigns').setup({
  numhl = true,
  signcolumn = false,
  on_attach = function(bufnr)
    local gitsigns = require("gitsigns")

    vim.keymap.set("n", "]c", function()
      if vim.wo.diff then vim.cmd.normal({ "]c", bang = true }) else gitsigns.nav_hunk("next") end
    end)
    vim.keymap.set("n", "[c", function()
      if vim.wo.diff then vim.cmd.normal({ "[c", bang = true }) else gitsigns.nav_hunk("prev") end
    end)

    vim.keymap.set("n", "ghs", gitsigns.stage_hunk)
    vim.keymap.set("n", "ghu", gitsigns.reset_hunk)
    vim.keymap.set("v", "ghs", function() gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end)
    vim.keymap.set("v", "ghu", function() gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end)
    vim.keymap.set("n", "ghS", gitsigns.stage_buffer)
    vim.keymap.set("n", "ghU", gitsigns.reset_buffer)
    vim.keymap.set("n", "ghp", gitsigns.preview_hunk_inline)
    vim.keymap.set("n", "ghd", gitsigns.diffthis)
    vim.keymap.set("n", "ghD", function() gitsigns.diffthis("~") end)

    vim.keymap.set({ "o", "x" }, "ih", gitsigns.select_hunk)
  end
})


---@diagnostic disable-next-line: param-type-mismatch
vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('highlight_yank', {}),
  pattern = '*',
  callback = function()
    vim.highlight.on_yank({ higroup = 'IncSearch', timeout = 200 })
  end,
})

vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = '*',
  callback = function()
    local save_cursor = vim.fn.getpos('.')
    pcall(function() vim.cmd([[%s/\s\+$//e]]) end)
    vim.fn.setpos('.', save_cursor)
  end,
})

vim.api.nvim_create_autocmd('LspAttach', {
  desc = 'LSP actions',
  callback = function(event)
    local opts = { buffer = event.buf }
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client == nil then return end

    if not client:supports_method('textDocument/willSaveWaitUntil')
        and client:supports_method('textDocument/formatting') then
      vim.api.nvim_create_autocmd('BufWritePre', {
        group = vim.api.nvim_create_augroup('my.lsp', { clear = false }),
        buffer = event.buf,
        callback = function()
          vim.lsp.buf.format({ bufnr = event.buf, id = client.id, timeout_ms = 1000 })
        end,
      })
    end

    if client.server_capabilities.codeLensProvider then
      ---@diagnostic disable-next-line: param-type-mismatch
      vim.api.nvim_create_autocmd({ 'BufEnter', 'CursorHold' },
        { callback = function() vim.lsp.codelens.refresh() end })
      vim.keymap.set('n', 'grc', '<cmd>lua vim.lsp.codelens.run()<cr>', opts)
    end

    if client:supports_method('textDocument/formatting') then
      vim.keymap.set({ 'n', 'x' }, 'grf', '<cmd>lua vim.lsp.buf.format({async = true})<cr>', opts)
    end
  end,
})

vim.keymap.set("n", "<c-l>", "<cmd>noh<Return><esc>")

vim.keymap.set("n", "<c-d>", "<c-d>zz")
vim.keymap.set("n", "<c-u>", "<c-u>zz")

vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>p", "+p")
vim.keymap.set("n", "<leader>Y", [["+Y]])

vim.keymap.set("n", "-", "<cmd>Oil<cr>")

vim.keymap.set("n", "<c-j>", "<cmd>cnext<cr>zz")
vim.keymap.set("n", "<c-k>", "<cmd>cprev<cr>zz")

local toggle_quickfix = function()
  local quickfix_wins = vim.tbl_filter(function(win_id)
    return vim.fn.getwininfo(win_id)[1].quickfix == 1
  end, vim.api.nvim_tabpage_list_wins(0))

  local command = #quickfix_wins == 0 and "copen" or "cclose"
  vim.cmd(command)
end
vim.keymap.set("n", "<leader>q", toggle_quickfix)

vim.keymap.set("n", "<leader>tr", "<cmd>TestNearest<cr>")
vim.keymap.set("n", "<leader>tt", "<cmd>TestFile<cr>")

vim.keymap.set("n", "<leader>b", require('fzf-lua').buffers)
vim.keymap.set("n", "<leader>f", require('fzf-lua').files)
vim.keymap.set("n", "<leader>'", require('fzf-lua').resume)
vim.keymap.set("n", "<leader>D", require('fzf-lua').lsp_workspace_diagnostics)

vim.keymap.set({ "n", "v" }, "<leader>d", require("debugmaster").mode.toggle, { nowait = true })

vim.keymap.set("n", "<leader>gl", "<cmd>tab Git log --follow -p %<cr>")
vim.keymap.set("n", "<leader>gL", "<cmd>tab Git log<cr>")
vim.keymap.set("n", "<leader>gb", "<cmd>tab Git blame<cr>")

vim.keymap.set("n", "<leader>gS", "<cmd>GHLitePRSelect<cr>")

vim.keymap.set("n", "<a-q>", "<cmd>bd<cr>")
vim.keymap.set("n", "<s-h>", "<cmd>BufferPrevious<cr>")
vim.keymap.set("n", "<s-l>", "<cmd>BufferNext<cr>")

vim.keymap.set("n", "ghs", "<cmd>GitGutterStageHunk<cr>")
vim.keymap.set("n", "ghu", "<cmd>GitGutterUndoHunk<cr>")
vim.keymap.set("n", "ghp", "<cmd>GitGutterPreviewHunk<cr>")
