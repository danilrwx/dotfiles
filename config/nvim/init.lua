--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
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

vim.opt.signcolumn = 'yes'
vim.opt.laststatus = 1

vim.opt.updatetime = 100
vim.opt.completeopt = 'menuone,noselect,noinsert,fuzzy,popup'

if vim.fn.executable("ugrep") == 1 then
  vim.opt.grepprg = "ugrep -RInk --tabs=1 --ignore-files --exclude='zz_generated*' --exclude-dir='generated'"
else
  vim.opt.grepprg = "grep -RIn --exclude='zz_generated*' --exclude-dir='generated'"
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

vim.cmd.packadd('cfilter')

vim.filetype.add({ extension = { yaml = 'helm' } })

vim.lsp.enable('gopls')
vim.lsp.enable('golangci_lint_ls')
vim.lsp.enable('lua_ls')
vim.lsp.enable('helm_ls')

vim.diagnostic.config({ virtual_text = { prefix = '🐗', }, signs = false })

vim.fn.sign_define('DapBreakpoint', { text = '✊', texthl = '', linehl = '', numhl = '' })
vim.fn.sign_define('DapBreakpointCondition', { text = '🫸', texthl = '', linehl = '', numhl = '' })
vim.fn.sign_define('DapLogPoint', { text = '📄', texthl = '', linehl = '', numhl = '' })
vim.fn.sign_define('DapStopped', { text = '👉', texthl = '', linehl = '', numhl = '' })
vim.fn.sign_define('DapBreakpointRejected', { text = '🚫', texthl = '', linehl = '', numhl = '' })

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

vim.g.gitgutter_set_sign_backgrounds = 1
vim.g.gitgutter_sign_priority = 0
vim.g.gitgutter_preview_win_floating = 1

vim.pack.add({
  { src = 'https://github.com/nvim-lua/plenary.nvim', },

  { src = 'https://github.com/rmagatti/auto-session' },
  { src = 'https://github.com/stevearc/oil.nvim' },
  { src = 'https://github.com/ibhagwan/fzf-lua' },

  { src = 'https://github.com/nvim-treesitter/nvim-treesitter' },
  { src = 'https://github.com/Wansmer/treesj' },

  { src = 'https://github.com/tpope/vim-fugitive' },

  { src = 'https://github.com/kyoh86/vim-go-coverage' },
  { src = 'https://github.com/mfussenegger/nvim-dap' },
  { src = 'https://github.com/leoluz/nvim-dap-go' },
  { src = 'https://github.com/Wansmer/symbol-usage.nvim' },

  { src = 'https://github.com/vim-test/vim-test' },

  { src = 'https://github.com/laktak/tome' },

  { src = 'https://github.com/supermaven-inc/supermaven-nvim' },
  { src = 'https://github.com/airblade/vim-gitgutter' },

  { src = 'https://github.com/ellisonleao/gruvbox.nvim' },
})

require('supermaven-nvim').setup({})

require('oil').setup({
  view_options = { show_hidden = true },
})

require('auto-session').setup({
  suppressed_dirs = { '~/', '~/Downloads', '/' },
})

require('nvim-treesitter.configs').setup({
  auto_install = true,
  highlight = { enable = true },
})

require('fzf-lua').setup({
  winopts = {
    fullscreen = true,
    preview = { layout = "vertical", vertical = "up:55%", border = "single" },
  }
})

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

require('treesj').setup({ use_default_keymaps = false, })

require('dap-go').setup({})

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

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

    if client:supports_method('textDocument/completion') then
      local chars = {}; for i = 32, 126 do table.insert(chars, string.char(i)) end
      client.server_capabilities.completionProvider.triggerCharacters = chars
      vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = true })
    end

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
      vim.api.nvim_create_autocmd({ 'BufEnter', 'CursorHold' },
        { callback = function() vim.lsp.codelens.refresh() end })
      vim.keymap.set('n', 'grc', '<cmd>lua vim.lsp.codelens.run()<cr>', opts)
    end

    if client:supports_method('textDocument/formatting') then
      vim.keymap.set({ 'n', 'x' }, 'grf', '<cmd>lua vim.lsp.buf.format({async = true})<cr>', opts)
    end
  end,
})

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

vim.keymap.set("n", "<c-l>", "<cmd>noh<Return><esc>")

vim.keymap.set("n", "<a-q>", "<cmd>bd<cr>")
vim.keymap.set("n", "<s-h>", "<cmd>bp<cr>")
vim.keymap.set("n", "<s-l>", "<cmd>bn<cr>")

vim.keymap.set("n", "<c-d>", "<c-d>zz")
vim.keymap.set("n", "<c-u>", "<c-u>zz")

vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>p", "+p")
vim.keymap.set("n", "<leader>Y", [["+Y]])

vim.keymap.set("n", "-", "<cmd>Oil<cr>")

vim.keymap.set("n", "<c-j>", "<cmd>cnext<cr>zz")
vim.keymap.set("n", "<c-k>", "<cmd>cprev<cr>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lnext<cr>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lprev<cr>zz")

vim.keymap.set("n", "<c-t>l", "<cmd>tabnext<cr>")
vim.keymap.set("n", "<c-t>h", "<cmd>tabprev<cr>")
vim.keymap.set("n", "<c-t>n", "<cmd>tabnew<cr>")
vim.keymap.set("n", "<c-t>c", "<cmd>tabclose<cr>")

vim.keymap.set("n", "<leader>gg", "<cmd>!tmux neww lazygit<cr>")

local toggle_quickfix = function()
  local quickfix_wins = vim.tbl_filter(function(win_id)
    return vim.fn.getwininfo(win_id)[1].quickfix == 1
  end, vim.api.nvim_tabpage_list_wins(0))

  local command = #quickfix_wins == 0 and "copen" or "cclose"
  vim.cmd(command)
end
vim.keymap.set("n", "<leader>q", toggle_quickfix)

vim.keymap.set("n", "<leader>tc", "<cmd>GoCover<cr>")
vim.keymap.set("n", "<leader>tC", "<cmd>GoCoverClear<cr>")

vim.keymap.set("n", "<leader>tr", "<cmd>TestNearest<cr>")
vim.keymap.set("n", "<leader>tt", "<cmd>TestFile<cr>")
vim.keymap.set("n", "<leader>ta", "<cmd>TestSuite<cr>")
vim.keymap.set("n", "<leader>tl", "<cmd>TestLast<cr>")
vim.keymap.set("n", "<leader>tv", "<cmd>TestVisit<cr>")

vim.keymap.set("n", "<leader>b", "<cmd>lua require('fzf-lua').buffers()<cr>")
vim.keymap.set("n", "<leader>f", "<cmd>lua require('fzf-lua').files()<cr>")
vim.keymap.set("n", "<leader>/", "<cmd>lua require('fzf-lua').live_grep()<cr>")
vim.keymap.set("n", "<leader>'", "<cmd>lua require('fzf-lua').resume()<cr>")
vim.keymap.set("n", "<leader>sb", "<cmd>lua require('fzf-lua').buffers()<cr>")
vim.keymap.set("n", "<leader>gs", "<cmd>lua require('fzf-lua').git_status()<cr>")
vim.keymap.set("n", "<leader>gB", "<cmd>lua require('fzf-lua').git_branches()<cr>")
vim.keymap.set("n", "<leader>ss", "<cmd>lua require('fzf-lua').git_branches()<cr>")
vim.keymap.set("n", "<leader>D", "<cmd>lua require('fzf-lua').lsp_workspace_diagnostics()<cr>")

vim.keymap.set("n", "<leader>dB", '<cmd>lua require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))<cr>')
vim.keymap.set("n", "<leader>db", '<cmd>lua require("dap").toggle_breakpoint()<cr>')
vim.keymap.set("n", "<leader>dc", '<cmd>lua require("dap").continue()<cr>')
vim.keymap.set("n", "<leader>dC", '<cmd>lua require("dap").run_to_cursor()<cr>')
vim.keymap.set("n", "<leader>dg", '<cmd>lua require("dap").goto_()<cr>')
vim.keymap.set("n", "<leader>di", '<cmd>lua require("dap").step_into()<cr>')
vim.keymap.set("n", "<leader>dj", '<cmd>lua require("dap").down()<cr>')
vim.keymap.set("n", "<leader>dk", '<cmd>lua require("dap").up()<cr>')
vim.keymap.set("n", "<leader>dl", '<cmd>lua require("dap").run_last()<cr>')
vim.keymap.set("n", "<leader>do", '<cmd>lua require("dap").step_out()<cr>')
vim.keymap.set("n", "<leader>dO", '<cmd>lua require("dap").step_over()<cr>')
vim.keymap.set("n", "<leader>dP", '<cmd>lua require("dap").pause()<cr>')
vim.keymap.set("n", "<leader>dr", '<cmd>lua require("dap").repl.toggle()<cr>')
vim.keymap.set("n", "<leader>ds", '<cmd>lua require("dap").session()<cr>')
vim.keymap.set("n", "<leader>dt", '<cmd>lua require("dap").terminate()<cr>')
vim.keymap.set("n", "<leader>dw", '<cmd>lua require("dap.ui.widgets").hover()<cr>')

vim.keymap.set("n", "<leader>g=", "<cmd>tab Git<cr>")
vim.keymap.set("n", "<leader>gl", "<cmd>tab Git log --follow -p %<cr>")
vim.keymap.set("n", "<leader>gL", "<cmd>tab Git log<cr>")
vim.keymap.set("n", "<leader>gb", "<cmd>tab Git blame<cr>")
vim.keymap.set("n", "<leader>gd", "<cmd>tab Git diff %<cr>")
vim.keymap.set("n", "<leader>gD", "<cmd>tab Git diff<cr>")
vim.keymap.set("n", "<leader>gP", '<cmd>Git push<cr>')
vim.keymap.set("n", "<leader>gp", '<cmd>Git pull --rebase<cr>')

vim.keymap.set("n", "<leader>m", '<cmd>lua require("treesj").toggle()<cr>')

vim.keymap.set("n", "ghs", "<cmd>GitGutterStageHunk<cr>")
vim.keymap.set("n", "ghu", "<cmd>GitGutterUndoHunk<cr>")
vim.keymap.set("n", "ghp", "<cmd>GitGutterPreviewHunk<cr>")
