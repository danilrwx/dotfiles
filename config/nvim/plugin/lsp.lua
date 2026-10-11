-- native LSP, no plugin. Skip servers whose binary is absent (mirrors the vim
-- config's ignoreMissingServer) so opening a file never spams start errors.
for _, name in ipairs({
  "gopls",
  "golangci_lint_ls",
  "helm_ls",
  "clangd",
  "zls",
}) do
  local cfg = vim.lsp.config[name]
  local exe = cfg and cfg.cmd and cfg.cmd[1]
  if not exe or vim.fn.executable(exe) == 1 then
    vim.lsp.enable(name)
  end
end

-- completion menu dressed the way mini.completion does it (glyph + coloured
-- kind, short detail, bordered markdown docs), on the native engine. No nerd
-- font (alacritty runs plain Iosevka), so the glyphs are plain Unicode.
local KIND = {
  Text = { "≡", "Comment" },
  Method = { "ƒ", "Function" },
  Function = { "ƒ", "Function" },
  Constructor = { "ƒ", "Function" },
  Field = { "◇", "Type" },
  Variable = { "◦", "Identifier" },
  Class = { "◈", "Type" },
  Interface = { "◇", "Type" },
  Module = { "▣", "Keyword" },
  Property = { "◇", "Type" },
  Unit = { "#", "Constant" },
  Value = { "#", "Constant" },
  Enum = { "∈", "Type" },
  Keyword = { "λ", "Keyword" },
  Snippet = { "»", "String" },
  Color = { "●", "String" },
  File = { "▤", "Comment" },
  Reference = { "→", "Comment" },
  Folder = { "▸", "Comment" },
  EnumMember = { "∈", "Constant" },
  Constant = { "π", "Constant" },
  Struct = { "▦", "Type" },
  Event = { "↯", "Keyword" },
  Operator = { "±", "Keyword" },
  TypeParameter = { "τ", "Type" },
}

local function convert(item)
  local name = vim.lsp.protocol.CompletionItemKind[item.kind] or "Text"
  local k = KIND[name] or KIND.Text
  local detail = (item.detail or ""):gsub("%s+", " ")
  if vim.fn.strchars(detail) > 40 then
    detail = vim.fn.strcharpart(detail, 0, 39) .. "…"
  end
  return { kind = k[1] .. " " .. name, kind_hlgroup = k[2], menu = detail }
end

vim.o.pumheight = 12
-- the info popup nvim opens beside the menu (completeopt=popup): give it the
-- border every other float has and render its markdown.
vim.api.nvim_create_autocmd("CompleteChanged", {
  group = vim.api.nvim_create_augroup("compl_info", { clear = true }),
  callback = function()
    vim.schedule(function()
      local info = vim.fn.complete_info({ "preview_winid", "preview_bufnr" })
      local win = info.preview_winid
      if not win or not vim.api.nvim_win_is_valid(win) then
        return
      end
      vim.api.nvim_win_set_config(win, { border = "rounded" })
      vim.wo[win].conceallevel = 2
      if vim.bo[info.preview_bufnr].filetype ~= "markdown" then
        vim.bo[info.preview_bufnr].filetype = "markdown"
      end
    end)
  end,
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("lsp_attach", { clear = true }),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client then
      return
    end
    -- colours come from treesitter: LSP semantic tokens (clangd sends them,
    -- gopls does not) would paint over it with the @lsp.* groups, which
    -- colors.lua links to Normal. Dropping the capability here, before nvim
    -- starts the token requests, keeps the highlighting treesitter-only.
    client.server_capabilities.semanticTokensProvider = nil
    vim.lsp.completion.enable(true, ev.data.client_id, ev.buf, { autotrigger = true, convert = convert })
    -- autotrigger fires on the server's trigger characters alone ("." "->"),
    -- so the menu also opens on any word character typed while it is closed;
    -- once open, nvim narrows it itself. One per-buffer augroup, as below.
    if client:supports_method("textDocument/completion") then
      vim.api.nvim_create_autocmd("InsertCharPre", {
        group = vim.api.nvim_create_augroup("lsp_compl_" .. ev.buf, { clear = true }),
        buffer = ev.buf,
        callback = function()
          if vim.fn.pumvisible() == 0 and vim.v.char:match("[%w_]") then
            vim.schedule(vim.lsp.completion.get)
          end
        end,
      })
    end

    -- code lenses (gopls shows a "run go generate" lens above //go:generate
    -- directives): enable() renders them and owns its own debounced refresh on
    -- view/edit; grc runs the one under the cursor. enable() is 0.12+, on 0.11
    -- (Ubuntu) refresh by hand on a per-buffer augroup of its own.
    if client:supports_method("textDocument/codeLens") then
      if vim.lsp.codelens.enable then
        vim.lsp.codelens.enable(true, { bufnr = ev.buf })
      else
        local grp = vim.api.nvim_create_augroup("lsp_codelens_" .. ev.buf, { clear = true })
        vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave", "BufWritePost" }, {
          group = grp,
          buffer = ev.buf,
          callback = function()
            vim.lsp.codelens.refresh({ bufnr = ev.buf })
          end,
        })
        vim.lsp.codelens.refresh({ bufnr = ev.buf })
      end
      vim.keymap.set("n", "grc", vim.lsp.codelens.run, { buffer = ev.buf })
    end

    if not client:supports_method("textDocument/formatting") then
      return
    end
    vim.keymap.set({ "n", "x" }, "grf", function()
      vim.lsp.buf.format({ async = true })
    end, { buffer = ev.buf })
    if vim.bo[ev.buf].filetype == "go" or vim.bo[ev.buf].filetype == "zig" then
      -- one per-buffer augroup (clear=true) so re-attach (:LspRestart, a second
      -- client) doesn't stack duplicate autocmds that format N times per save.
      local grp = vim.api.nvim_create_augroup("lsp_format_" .. ev.buf, { clear = true })
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = grp,
        buffer = ev.buf,
        callback = function()
          vim.lsp.buf.format({ id = client.id })
        end,
      })
    end
  end,
})
