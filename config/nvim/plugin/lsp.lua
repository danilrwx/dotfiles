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

    -- code lenses (gopls shows a "run go generate" lens above //go:generate
    -- directives): enable() renders them and owns its own debounced refresh on
    -- view/edit; grc runs the one under the cursor.
    if client:supports_method("textDocument/codeLens") then
      vim.lsp.codelens.enable(true, { bufnr = ev.buf })
      vim.keymap.set("n", "grc", vim.lsp.codelens.run, { buffer = ev.buf })
    end

    if not client:supports_method("textDocument/formatting") then
      return
    end
    vim.keymap.set({ "n", "x" }, "grf", function()
      vim.lsp.buf.format({ async = true })
    end, { buffer = ev.buf })
    if vim.bo[ev.buf].filetype == "go" then
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
