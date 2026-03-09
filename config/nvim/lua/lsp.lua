vim.api.nvim_create_autocmd({ "LspAttach" }, {
  desc = "LSP actions",
  callback = function(event)
    local opts = { buffer = event.buf }
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client == nil then return end

    -- if client:supports_method('textDocument/completion') then
    --   local chars = {}; for i = 32, 126 do table.insert(chars, string.char(i)) end
    --   client.server_capabilities.completionProvider.triggerCharacters = chars
    --   vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = true })
    -- end

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

    -- local _, cancel_prev = nil, function() end
    -- vim.api.nvim_create_autocmd('CompleteChanged', {
    --   buffer = event.buf,
    --   callback = function()
    --     cancel_prev()
    --     local info = vim.fn.complete_info({ 'selected' })
    --     local completionItem = vim.tbl_get(vim.v.completed_item, 'user_data', 'nvim', 'lsp', 'completion_item')
    --     if nil == completionItem then
    --       return
    --     end
    --     _, cancel_prev = vim.lsp.buf_request(event.buf,
    --       vim.lsp.protocol.Methods.completionItem_resolve,
    --       completionItem,
    --       function(err, item, ctx)
    --         if not item then
    --           return
    --         end
    --         local docs = (item.documentation or {}).value
    --         local win = vim.api.nvim__complete_set(info['selected'], { info = docs })
    --         if win.winid and vim.api.nvim_win_is_valid(win.winid) then
    --           vim.treesitter.start(win.bufnr, 'markdown')
    --           vim.wo[win.winid].conceallevel = 3
    --         end
    --       end)
    --   end
    -- })

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

-- vim.o.completeopt = "menuone,noselect,noinsert,fuzzy,popup"

vim.diagnostic.config({
  virtual_text = {
    prefix = "🐗",
  },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "🔥",
      [vim.diagnostic.severity.WARN] = "💫",
      [vim.diagnostic.severity.INFO] = "🔩",
      [vim.diagnostic.severity.HINT] = "📎",
    },
  }
})

-- vim.lsp.config("*", {
--   capabilities = {
--     textDocument = {
--       semanticTokens = {
--         multilineTokenSupport = true,
--       }
--     },
--     completionItem = {
--       snippetSupport = true,
--       resolve = true,
--       resolveSupport = {
--         properties = {
--           "documentation",
--           "detail",
--           "additionalTextEdits",
--         },
--       },
--     }
--   },
--   root_markers = { ".git" },
-- })
--
-- vim.lsp.enable("gopls")
-- vim.lsp.enable("lua_ls")
