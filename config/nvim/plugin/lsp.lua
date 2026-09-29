-- native LSP, no plugin. Skip servers whose binary is absent (mirrors the vim
-- config's ignoreMissingServer) so opening a file never spams start errors.
for _, name in ipairs({
  "gopls",
  "golangci_lint_ls",
  "helm_ls",
  "clangd",
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
    -- colours come from treesitter: LSP semantic tokens (clangd sends them,
    -- gopls does not) would paint over it with the @lsp.* groups, which
    -- colors.lua links to Normal. Dropping the capability here, before nvim
    -- starts the token requests, keeps the highlighting treesitter-only.
    client.server_capabilities.semanticTokensProvider = nil
    vim.lsp.completion.enable(true, ev.data.client_id, ev.buf, { autotrigger = true })

    -- code lenses (gopls shows a "run go generate" lens above //go:generate
    -- directives): enable() renders them and owns its own debounced refresh on
    -- view/edit; grc runs the one under the cursor. enable() is 0.12+, on 0.11
    -- (Ubuntu) refresh by hand on the same per-buffer augroup as the formatter.
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
