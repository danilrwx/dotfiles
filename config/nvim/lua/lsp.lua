vim.api.nvim_create_autocmd({ "LspAttach" }, {
  desc = "LSP actions",
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
      vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" },
        { callback = function() vim.lsp.codelens.refresh() end })
      vim.keymap.set("n", "grc", "<cmd>lua vim.lsp.codelens.run()<cr>", opts)
    end

    if client:supports_method("textDocument/formatting") then
      vim.keymap.set({ "n", "x" }, "grf", "<cmd>lua vim.lsp.buf.format({async = true})<cr>", opts)
    end
  end,
})

vim.o.completeopt = "menuone,noselect,noinsert,fuzzy,popup"

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

-- vim.lsp.config("*", {
--   -- capabilities = {},
--   root_markers = { ".git" },
-- })
--
-- vim.lsp.enable("gopls")
-- vim.lsp.enable("lua_ls")
