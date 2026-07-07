vim.g.mapleader = " "

vim.o.autoindent = true
vim.o.expandtab = true
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.softtabstop = 2
vim.o.smartindent = true
vim.o.number = true
vim.o.updatetime = 100
vim.o.signcolumn = "number"
vim.o.laststatus = 0
vim.o.completeopt = "menuone,noselect,noinsert,fuzzy,popup"
vim.o.winborder = "rounded"

vim.o.undofile = true
vim.o.undodir = vim.fn.stdpath("state") .. "/undo"
vim.fn.mkdir(vim.o.undodir, "p")

if vim.fn.executable("ugrep") == 1 then
  vim.o.grepprg = "ugrep -RInk --tabs=1 --ignore-files --exclude='zz_generated*' --exclude-dir='generated'"
  vim.o.grepformat = "%f:%l:%c:%m,%f+%l+%c+%m,%-G%f|%l|%c|%m"
else
  vim.o.grepprg = "grep -RIn --exclude='*zz_generated*' --exclude-dir='generated'"
end

vim.filetype.add({ extension = { yaml = "helm", tpl = "helm" } })

vim.keymap.set("n", "<c-d>", "<c-d>zz")
vim.keymap.set("n", "<c-u>", "<c-u>zz")
vim.keymap.set("n", "<c-l>", "<cmd>nohlsearch<cr>")
vim.keymap.set("n", "-", "<cmd>Oil<cr>", { silent = true })
vim.keymap.set("n", "<leader>gg", "<cmd>silent execute '!tmux neww lazygit'<bar>redraw!<cr>", { silent = true })
vim.keymap.set("n", "<A-q>", "<cmd>bd<cr>", { silent = true })
vim.keymap.set("n", "<S-l>", "<cmd>bn<cr>", { silent = true })
vim.keymap.set("n", "<S-h>", "<cmd>bp<cr>", { silent = true })

-- nvim ships an OSC 52 clipboard provider, so "+ reaches the host over ssh/tmux
-- without the clip-helper wiring the vim config needs.
vim.keymap.set({ "n", "x" }, "<leader>y", '"+y')
vim.keymap.set("n", "<leader>p", '"+p')
vim.keymap.set("n", "<leader>dd", function()
  vim.fn.setreg("+", vim.fn.expand("%") .. ":" .. vim.fn.line("."))
end, { silent = true })

vim.diagnostic.config({ virtual_text = { prefix = "🐗" }, signs = false })

-- native LSP, no plugin. Skip servers whose binary is absent (mirrors the vim
-- config's ignoreMissingServer) so opening a file never spams start errors.
for _, name in ipairs({
  "gopls",
  "golangci_lint_ls",
  "lua_ls",
  "helm_ls",
  "clangd",
  "ts_ls",
  "rust_analyzer",
  "bashls",
}) do
  local cfg = vim.lsp.config[name]
  local exe = cfg and cfg.cmd and cfg.cmd[1]
  if not exe or vim.fn.executable(exe) == 1 then
    vim.lsp.enable(name)
  end
end

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client then
      return
    end
    vim.lsp.completion.enable(true, ev.data.client_id, ev.buf, { autotrigger = true })
    if client:supports_method("textDocument/formatting") then
      vim.keymap.set({ "n", "x" }, "grf", function()
        vim.lsp.buf.format({ async = true })
      end, { buffer = ev.buf })
      if vim.bo[ev.buf].filetype == "go" then
        vim.api.nvim_create_autocmd("BufWritePre", {
          buffer = ev.buf,
          callback = function()
            vim.lsp.buf.format()
          end,
        })
      end
    end
  end,
})

-- whole-workspace diagnostics: LSP drops unopened files, so run the project
-- checker (golangci-lint, else `go vet`) async and parse into quickfix.
local function diag_ws()
  local cmd = vim.fn.executable("golangci-lint") == 1 and { "golangci-lint", "run", "./..." }
    or vim.fn.executable("go") == 1 and { "go", "vet", "./..." }
    or nil
  if not cmd then
    vim.notify("no golangci-lint / go")
    return
  end
  vim.notify("running " .. table.concat(cmd, " ") .. " ...")
  vim.system(cmd, { text = true }, function(res)
    local lines = vim.split((res.stdout or "") .. (res.stderr or ""), "\n")
    vim.schedule(function()
      vim.fn.setqflist({}, " ", {
        title = table.concat(cmd, " "),
        lines = lines,
        efm = [[%-G#%.%#,%f:%l:%c: %m,%f:%l: %m]],
      })
      local valid = vim.tbl_filter(function(i)
        return i.valid == 1
      end, vim.fn.getqflist())
      if #valid == 0 then
        vim.notify("workspace: no diagnostics")
        return
      end
      vim.cmd("copen")
      vim.cmd("cfirst")
    end)
  end)
end
vim.api.nvim_create_user_command("LspDiagWs", diag_ws, {})
vim.keymap.set("n", "<leader>D", diag_ws, { silent = true })

vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.hl.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

-- treesitter only for parsers nvim ships (c/lua/vim/markdown/query/...); other
-- filetypes fall back to regex syntax. No nvim-treesitter, so no extra parsers.
vim.api.nvim_create_autocmd("FileType", {
  callback = function()
    if vim.treesitter.get_parser(nil, nil, { error = false }) then
      vim.treesitter.start()
      vim.wo.foldmethod = "expr"
      vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
      vim.wo.foldlevel = 99
    end
  end,
})

-- trailing-whitespace highlight. matchadd is window-local, and fzf reuses the
-- window for its terminal, so always clear first (else the padded fzf header
-- stays highlighted red) and re-add only for normal file buffers.
local function ws_match()
  vim.fn.clearmatches()
  if vim.bo.buftype == "" then
    vim.fn.matchadd("ErrorMsg", [[\s\+$]])
  end
end
vim.api.nvim_create_autocmd({ "BufWinEnter", "TermOpen" }, { callback = ws_match })

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    local function hl(group, opts)
      vim.api.nvim_set_hl(0, group, opts)
    end

    vim.cmd("highlight Normal guibg=NONE")
    vim.cmd("highlight SignColumn guibg=NONE")

    hl("Added", { fg = "#00cd00" })
    hl("Changed", { fg = "#00cdcd" })
    hl("Removed", { fg = "#cd0000" })

    local keep = {
      ["Pmenu"] = "Normal",
      ["NormalFloat"] = "Normal",
      ["WinSeparator"] = "Normal",
      ["@function"] = "Function",
      ["@function.call"] = "Function",
      ["@function.method.call"] = "Function",
      ["@function.builtin"] = "Normal",
      ["@method"] = "Function",
      ["@method.call"] = "Normal",
      ["@comment"] = "Comment",
      ["@string"] = "String",
      ["@keyword"] = "Keyword",
      ["@type"] = "Type",
      ["@type.builtin"] = "Type",
      ["@property.yaml"] = "Type",
      ["@markup.heading"] = "Keyword",
      ["@markup.raw"] = "String",
      ["@markup.link"] = "Type",
      ["@punctuation.special.markdown"] = "Type",
    }

    local function target_for(g)
      if keep[g] then
        return keep[g]
      end
      for k, target in pairs(keep) do
        if g:find("^" .. k:gsub("%.", "%%.") .. "%.") then
          return target
        end
      end
      return "Normal"
    end

    for _, g in ipairs(vim.fn.getcompletion("@", "highlight")) do
      hl(g, { link = target_for(g) })
    end
    for g, target in pairs(keep) do
      hl(g, { link = target })
    end
  end,
})

vim.cmd.colorscheme("torte")
