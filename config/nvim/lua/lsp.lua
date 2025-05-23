vim.api.nvim_create_autocmd({ "LspAttach" }, {
  desc = "LSP actions",
  callback = function(event)
    local opts = { buffer = event.buf }
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client == nil then return end

    if not client.supports_method('textDocument/willSaveWaitUntil')
        and client.supports_method('textDocument/formatting') then
      vim.api.nvim_create_autocmd('BufWritePre', {
        group = vim.api.nvim_create_augroup('my.lsp', { clear = false }),
        buffer = event.buf,
        callback = function()
          vim.lsp.buf.format({ bufnr = event.buf, id = client.id, timeout_ms = 1000 })
        end,
      })
    end

    if client.server_capabilities.codeLensProvider then
      vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" },
        { callback = function() vim.lsp.codelens.refresh() end })
      vim.keymap.set("n", "grc", "<cmd>lua vim.lsp.codelens.run()<cr>", opts)
    end

    if client.server_capabilities.codeActionProvider then
      vim.keymap.set("n", "gra", "<cmd>lua vim.lsp.buf.code_action()<cr>", opts)
    end

    if client.server_capabilities.renameProvider then
      vim.keymap.set("n", "grn", "<cmd>lua vim.lsp.buf.rename()<cr>", opts)
    end

    if client.server_capabilities.documentFormattingProvider then
      vim.keymap.set("n", "grf", "<cmd>lua vim.lsp.buf.format()<cr>", opts)
    end

    if client.server_capabilities.implementationProvider then
      vim.keymap.set("n", "gri", "<cmd>lua require('fzf-lua').lsp_implementations()<cr>", opts)
    end

    if client.server_capabilities.referencesProvider then
      vim.keymap.set("n", "grr", "<cmd>lua require('fzf-lua').lsp_references()<cr>", opts)
    end

    if client.server_capabilities.workspaceSymbolProvider then
      vim.keymap.set("n", "<leader>S", "<cmd>lua require('fzf-lua').lsp_live_workspace_symbols()<cr>", opts)
    end

    if client.server_capabilities.documentSymbolProvider then
      vim.keymap.set("n", "<leader>s", "<cmd>lua require('fzf-lua').lsp_document_symbols()<cr>", opts)
    end
  end,
})

DIAGNOSTIC_ICONS = {
  [vim.diagnostic.severity.ERROR] = "🔥",
  [vim.diagnostic.severity.WARN] = "💫",
  [vim.diagnostic.severity.INFO] = "🔩",
  [vim.diagnostic.severity.HINT] = "📎",
}

vim.diagnostic.config({
  virtual_text = {
    prefix = "🐗",
  },
  signs = false,
  -- signs = {
  --   text = DIAGNOSTIC_ICONS,
  -- }
})

