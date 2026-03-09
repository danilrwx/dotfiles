local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out,                            "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("lazy").setup({
  spec = {
    { "laktak/tome" },

    {
      "kyoh86/vim-go-coverage",
      lazy = false,
      keys = {
        { "<leader>tc", "<cmd>GoCover<cr>" },
        { "<leader>tC", "<cmd>GoCoverClear<cr>" },
      },
    },

    {
      "tpope/vim-fugitive",
      lazy = false,
      keys = {
        { "<leader>g=", "<cmd>tab Git<cr>" },
        { "<leader>gl", "<cmd>tab Git log --follow -p %<cr>" },
        { "<leader>gL", "<cmd>tab Git log<cr>" },
        { "<leader>gb", "<cmd>tab Git blame<cr>" },
      },
    },

    {
      "ellisonleao/gruvbox.nvim",
      priority = 1000,
      opts = {
        italic = {
          strings = false,
          emphasis = false,
          comments = false,
          operators = false,
          folds = false,
        },
      }
    },

    {
      'mrjones2014/smart-splits.nvim',
      lazy = false,
      keys = {
        { "<A-h>", "<cmd>SmartResizeLeft<cr>" },
        { "<A-j>", "<cmd>SmartResizeDown<cr>" },
        { "<A-k>", "<cmd>SmartResizeUp<cr>" },
        { "<A-l>", "<cmd>SmartResizeRight<cr>" },
        { "<C-h>", "<cmd>SmartCursorMoveLeft<cr>" },
        { "<C-j>", "<cmd>SmartCursorMoveDown<cr>" },
        { "<C-k>", "<cmd>SmartCursorMoveUp<cr>" },
        { "<C-l>", "<cmd>SmartCursorMoveRight<cr>" },
      },
    },

    {
      "vim-test/vim-test",
      keys = {
        { "<leader>tr", "<cmd>TestNearest<cr>" },
        { "<leader>tt", "<cmd>TestFile<cr>" },
      },
    },

    {
      "chrisgrieser/nvim-origami",
      opts = { foldKeymaps = { setup = false }, autoFold = { enabled = false } },
    },

    {
      'stevearc/oil.nvim',
      dependencies = { "nvim-tree/nvim-web-devicons", "benomahony/oil-git.nvim" },
      opts = { view_options = { show_hidden = true } },
      keys = { { "-", "<cmd>Oil<cr>" } },
      lazy = false,
    },

    {
      "rmagatti/auto-session",
      opts = { suppressed_dirs = { "~/", "~/Downloads", "/" } },
    },

    {
      "SCJangra/table-nvim",
      opts = { next = 'right', prev = 'left' },
    },

    {
      "supermaven-inc/supermaven-nvim",
      event = "InsertEnter",
      cmd = { "SupermavenUseFree", "SupermavenUsePro" },
      opts = {},
    },

    {
      "nvim-treesitter/nvim-treesitter",
      build = ":TSUpdate",
      config = function()
        require("nvim-treesitter.configs").setup({
          ensure_installed = { "lua", "vimdoc" },
          auto_install = true,
          highlight = { enable = true },
          folds = { enable = true },
          indent = { enable = true },
        })
      end,
    },

    {
      "Wansmer/treesj",
      keys = { "<space>m", { "<space>j", false }, { "<space>s", false } },
      dependencies = { "nvim-treesitter/nvim-treesitter" },
      opts = {},
    },

    {
      "sebdah/vim-delve",
      keys = {
        { "<leader>td", "<cmd>DlvTestCurrent<cr>" },
        { "<leader>db", "<cmd>DlvToggleBreakpoint<cr>" },
        { "<leader>dc", "<cmd>DlvConnect :2345<cr>" },
      },
    },

    {
      "daliusd/ghlite.nvim",
      lazy = false,
      opts = {
        view_split = "tabnew",
        diff_split = "tabnew",
        comment_split = "tabnew",
      },
      keys = {
        { "<leader>gS", "<cmd>GHLitePRSelect<cr>" },
      },
    },

    {
      "romgrk/barbar.nvim",
      lazy = false,
      dependencies = { 'lewis6991/gitsigns.nvim', 'nvim-tree/nvim-web-devicons' },
      opts = {
        animation = false,
        icons = {
          button = "",
          modified = { button = "🔸" },
          pinned = { button = "📌", filename = true },
          diagnostics = { [vim.diagnostic.severity.ERROR] = { enabled = true, icon = "🔥" }, },
        },
      },
      keys = {
        { "<s-h>",   "<cmd>BufferPrevious<cr>" },
        { "<a-s-h>", "<cmd>BufferMovePrevious<cr>" },

        { "<s-l>",   "<cmd>BufferNext<cr>" },
        { "<a-s-l>", "<cmd>BufferMoveNext<cr>" },

        { "<a-q>",   "<cmd>BufferClose<cr>" },
        { "<a-s-q>", "<cmd>BufferCloseAllButCurrent<cr>" },
      }
    },

    {
      "ibhagwan/fzf-lua",
      lazy = false,
      dependencies = {
        "nvim-tree/nvim-web-devicons",
      },
      opts = {
        winopts = {
          fullscreen = true,
          preview = {
            layout = "vertical",
            vertical = "up:55%",
            border = "single",
          },
        },
      },
      keys = {
        { "<leader>f", "<cmd>lua require('fzf-lua').files()<cr>" },
        { "<leader>/", "<cmd>lua require('fzf-lua').live_grep()<cr>" },
        { "<leader>'", "<cmd>lua require('fzf-lua').resume()<cr>" },
        { "<leader>b", "<cmd>lua require('fzf-lua').buffers()<cr>" },
        { "<leader>D", "<cmd>lua require('fzf-lua').lsp_workspace_diagnostics()<cr>" },
      }
    },

    {
      "saghen/blink.cmp",
      dependencies = { "xzbdmw/colorful-menu.nvim" },
      opts = {
        keymap = { preset = "enter" },
        signature = { enabled = true },
        appearance = { nerd_font_variant = "normal" },
        completion = {
          accept = { auto_brackets = { enabled = true } },
          -- menu = { draw = { treesitter = { "lsp" } } },
          menu = {
            draw = {
              columns = { { "kind_icon" }, { "label", gap = 1 } },
              components = {
                label = {
                  text = function(ctx) return require("colorful-menu").blink_components_text(ctx) end,
                  highlight = function(ctx) return require("colorful-menu").blink_components_highlight(ctx) end,
                },
              },
            },
          },
          documentation = { auto_show = true, auto_show_delay_ms = 200 },
        },
        fuzzy = { prebuilt_binaries = { force_version = "v1.6.0" } },
        sources = { default = { "lsp", "path", "snippets", "buffer" } },
      }
    },

    {
      "Wansmer/symbol-usage.nvim",
      opts = {
        kinds = {
          vim.lsp.protocol.SymbolKind.Function,
          vim.lsp.protocol.SymbolKind.Method,
          vim.lsp.protocol.SymbolKind.Interface,
          vim.lsp.protocol.SymbolKind.Constant,
        },
        definition = { enabled = true },
        implementation = { enabled = true },
        vt_position = "end_of_line",
      }
    },

    {
      "nvimtools/none-ls.nvim",
      dependencies = { "nvim-lua/plenary.nvim" },
      config = function()
        local nls = require("null-ls")
        nls.setup({
          debug = true,
          sources = {
            nls.builtins.code_actions.gomodifytags,
            nls.builtins.code_actions.impl,
            nls.builtins.formatting.gofumpt,
            nls.builtins.formatting.goimports,
          },
        })
      end,
    },

    {
      'stevearc/conform.nvim',
      opts = { format_on_save = { timeout_ms = 500, lsp_format = "fallback" } },
    },

    {
      "lewis6991/gitsigns.nvim",
      opts = {
        numhl = true,
        signcolumn = false,
        on_attach = function(bufnr)
          local gitsigns = require("gitsigns")
          local opts = { buffer = bufnr }

          vim.keymap.set("n", "]c",
            function() if vim.wo.diff then vim.cmd.normal({ "]c", bang = true }) else gitsigns.nav_hunk("next") end end,
            opts)
          vim.keymap.set("n", "[c",
            function() if vim.wo.diff then vim.cmd.normal({ "[c", bang = true }) else gitsigns.nav_hunk("prev") end end,
            opts)

          vim.keymap.set("n", "ghs", gitsigns.stage_hunk, opts)
          vim.keymap.set("n", "ghu", gitsigns.reset_hunk, opts)
          vim.keymap.set("v", "ghs", function() gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, opts)
          vim.keymap.set("v", "ghu", function() gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, opts)
          vim.keymap.set("n", "ghS", gitsigns.stage_buffer, opts)
          vim.keymap.set("n", "ghU", gitsigns.reset_buffer, opts)
          vim.keymap.set("n", "ghp", gitsigns.preview_hunk_inline, opts)
          vim.keymap.set("n", "ghd", gitsigns.diffthis, opts)
          vim.keymap.set("n", "ghD", function() gitsigns.diffthis("~") end, opts)

          vim.keymap.set({ "o", "x" }, "ih", gitsigns.select_hunk, opts)
        end
      }
    },

    {
      "coder/claudecode.nvim",
      dependencies = { "folke/snacks.nvim" },
      config = true,
      opts = { terminal = { split_width_percentage = 0.50 } },
      keys = {
        { "<leader>a",  nil,                              desc = "AI/Claude Code" },
        { "<leader>ac", "<cmd>ClaudeCode<cr>",            desc = "Toggle Claude" },
        { "<leader>af", "<cmd>ClaudeCodeFocus<cr>",       desc = "Focus Claude" },
        { "<leader>ar", "<cmd>ClaudeCode --resume<cr>",   desc = "Resume Claude" },
        { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
        { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
        { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>",       desc = "Add current buffer" },
        { "<leader>as", "<cmd>ClaudeCodeSend<cr>",        mode = "v",                  desc = "Send to Claude" },
        {
          "<leader>as",
          "<cmd>ClaudeCodeTreeAdd<cr>",
          desc = "Add file",
          ft = { "NvimTree", "neo-tree", "oil", "minifiles" },
        },
        -- Diff management
        { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
        { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>",   desc = "Deny diff" },
      },
    },

  },
  checker = { enabled = false },
})


vim.o.termguicolors = true
vim.cmd.colorscheme("gruvbox")

-- vim.api.nvim_set_hl(0, "Normal", { bg = nil })
-- vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#1C1C1C" })
-- vim.api.nvim_set_hl(0, "Visual", { bg = "#252525" })
-- vim.api.nvim_set_hl(0, "SignColumn", { bg = nil })
--
-- vim.api.nvim_set_hl(0, "Pmenu", { bg = "#1C1C1C" })
-- vim.api.nvim_set_hl(0, "PmenuSel", { bg = "#303030" })
--
-- vim.api.nvim_set_hl(0, "PmenuKind", { fg = "#83A598", bg = "#1C1C1C" })
-- vim.api.nvim_set_hl(0, "PmenuKindSel", { bg = "#303030" })
--
-- vim.api.nvim_set_hl(0, "PmenuExtra", { bg = "#1C1C1C" })
-- vim.api.nvim_set_hl(0, "PmenuExtraSel", { bg = "#303030" })
--
-- vim.api.nvim_set_hl(0, "PmenuMatch", { fg = "#B16286", bg = "#1C1C1C" })
-- vim.api.nvim_set_hl(0, "PmenuMatchSel", { bg = "#303030" })
--
-- vim.api.nvim_set_hl(0, "Added", { fg = "#B8BB26" })
-- vim.api.nvim_set_hl(0, "Changed", { fg = "#83A598" })
-- vim.api.nvim_set_hl(0, "Removed", { fg = "#FB4934" })
--
-- vim.api.nvim_set_hl(0, "DiffAdd", { bg = "#282808" })
-- vim.api.nvim_set_hl(0, "DiffChange", { bg = "#19231f" })
-- vim.api.nvim_set_hl(0, "DiffDelete", { bg = "#420801" })
-- vim.api.nvim_set_hl(0, "DiffText", { bg = "#522500" })
--
-- vim.api.nvim_set_hl(0, "OilGitAdded", { fg = "#B8BB26" })
-- vim.api.nvim_set_hl(0, "OilGitModified", { fg = "#83A598" })
-- vim.api.nvim_set_hl(0, "OilGitRenamed", { fg = "#522500" })
-- vim.api.nvim_set_hl(0, "OilGitUntracked", { fg = "#FB4934" })
--
-- vim.api.nvim_set_hl(0, "Identifier", { fg = "#EBDBB2" })
-- vim.api.nvim_set_hl(0, "Delimiter", { fg = "#EBDBB2" })
-- vim.api.nvim_set_hl(0, "@variable", { fg = "#83A598" })
-- vim.api.nvim_set_hl(0, "@variable.parameter", { fg = "#83A598" })
--
-- vim.api.nvim_set_hl(0, "DiagnosticError", { fg = "#FB4934" })
-- vim.api.nvim_set_hl(0, "DiagnosticWarn", { fg = "#FE8019" })
-- vim.api.nvim_set_hl(0, "DiagnosticInfo", { fg = "#EBDBB2" })
-- vim.api.nvim_set_hl(0, "DiagnosticHint", { fg = "#EBDBB2" })
-- vim.api.nvim_set_hl(0, "DiagnosticOk", { fg = "#B8BB26" })

require("fzf-lua").register_ui_select()

vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

vim.opt.completeopt = "menuone,noselect,noinsert,fuzzy,popup"

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

vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99

vim.opt.signcolumn = "auto"
vim.opt.laststatus = 1
vim.opt.cmdheight = 1

vim.opt.updatetime = 500

if vim.fn.executable("ugrep") == 1 then
  vim.opt.grepprg = 'ugrep -nk --tabs=1 --ignore-files --exclude="zz_generated*" --exclude-dir="generated"'
else
  vim.opt.grepprg = 'grep -RIn --exclude="zz_generated*" --exclude-dir="generated"'
end

if vim.fn.has('nvim-0.12') == 1 then
  vim.o.diffopt = 'internal,filler,closeoff,inline:word,linematch:40'
elseif vim.fn.has('nvim-0.11') == 1 then
  vim.o.diffopt = 'internal,filler,closeoff,linematch:40'
end

vim.cmd.packadd("cfilter")

vim.filetype.add({
  extension = {
    yaml = "helm",
    tpl = "helm",
  }
})

vim.lsp.enable("gopls")
vim.lsp.enable("golangci_lint_ls")
vim.lsp.enable("lua_ls")
vim.lsp.enable("helm_ls")

vim.diagnostic.config({ virtual_text = { prefix = "🐗", }, signs = false })

vim.fn.sign_define("DapBreakpoint", { text = "✊", texthl = "", linehl = "", numhl = "" })
vim.fn.sign_define("DapBreakpointCondition", { text = "🫸", texthl = "", linehl = "", numhl = "" })
vim.fn.sign_define("DapLogPoint", { text = "📄", texthl = "", linehl = "", numhl = "" })
vim.fn.sign_define("DapStopped", { text = "👉", texthl = "", linehl = "", numhl = "" })
vim.fn.sign_define("DapBreakpointRejected", { text = "🚫", texthl = "", linehl = "", numhl = "" })

---@diagnostic disable-next-line: param-type-mismatch
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

    -- if not client:supports_method("textDocument/willSaveWaitUntil")
    --     and client:supports_method("textDocument/formatting") then
    --   vim.api.nvim_create_autocmd("BufWritePre", {
    --     group = vim.api.nvim_create_augroup("my.lsp", { clear = false }),
    --     buffer = event.buf,
    --     callback = function()
    --      vim.lsp.buf.format({ bufnr = event.buf, id = client.id, timeout_ms = 1000 })
    --     end,
    --   })
    -- end

    if client.server_capabilities.codeLensProvider then
      ---@diagnostic disable-next-line: param-type-mismatch
      vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold" },
        { callback = function() vim.lsp.codelens.refresh() end })
      vim.keymap.set("n", "grc", "<cmd>lua vim.lsp.codelens.run()<cr>", opts)
    end

    -- if client:supports_method("textDocument/formatting") then
    --   vim.keymap.set({ "n", "x" }, "grf", "<cmd>lua vim.lsp.buf.format({async = true})<cr>", opts)
    -- end
  end,
})

local toggle_quickfix = function()
  local quickfix_wins = vim.tbl_filter(function(win_id)
    return vim.fn.getwininfo(win_id)[1].quickfix == 1
  end, vim.api.nvim_tabpage_list_wins(0))

  local command = #quickfix_wins == 0 and "copen" or "cclose"
  vim.cmd(command)
end
vim.keymap.set("n", "<leader>q", toggle_quickfix)

vim.keymap.set("n", "<leader>gg", "<cmd>tabnew term://lazygit<cr>")

-- vim.keymap.set("n", "<c-k>", "<cmd>cprev<cr>")
-- vim.keymap.set("n", "<c-j>", "<cmd>cnext<cr>")

vim.keymap.set("n", "<c-[>", "<cmd>noh<Return><esc>")

vim.keymap.set("n", "<c-d>", "<c-d>zz")
vim.keymap.set("n", "<c-u>", "<c-u>zz")

vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>p", "+p")
vim.keymap.set("n", "<leader>Y", [["+Y]])
