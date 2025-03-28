vim.api.nvim_create_autocmd({ "TextYankPost" }, {
  group = vim.api.nvim_create_augroup("highlight_yank", {}),
  desc = "Hightlight selection on yank",
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  pattern = { "*" },
  callback = function()
    local save_cursor = vim.fn.getpos(".")
    pcall(function()
      vim.cmd([[%s/\s\+$//e]])
    end)
    vim.fn.setpos(".", save_cursor)
  end,
})

vim.api.nvim_create_autocmd({ "LspAttach" }, {
  desc = "LSP actions",
  callback = function(event)
    local opts = { buffer = event.buf }

    vim.keymap.set("n", "K", "<cmd>lua vim.lsp.buf.hover()<cr>", opts)
    vim.keymap.set("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<cr>", opts)
    vim.keymap.set("n", "gd", "<cmd>lua require('fzf-lua').lsp_definitions({ jump_to_single_result = true })<cr>", opts)
    vim.keymap.set("n", "gi", "<cmd>lua require('fzf-lua').lsp_implementation({ jump_to_single_result = true })<cr>", opts)
    vim.keymap.set("n", "gr", "<cmd>lua require('fzf-lua').lsp_references()<cr>", opts)


    local client = vim.lsp.get_client_by_id(event.data.client_id)

    if client == nil then
      return
    end

    if client.server_capabilities.renameProvider then
      vim.keymap.set("n", "<leader>cr", "<cmd>lua vim.lsp.buf.rename()<cr>", opts)
    end

    if client.server_capabilities.documentSymbolProvider then
      vim.keymap.set("n", "<leader>ss", "<cmd>lua require('fzf-lua').lsp_document_symbols()<cr>", opts)
    end

    if client.server_capabilities.workspaceSymbolProvider then
      vim.keymap.set("n", "<leader>sS", "<cmd>lua require('fzf-lua').lsp_workspace_symbols()<cr>", opts)
    end

    if client.server_capabilities.codeLensProvider then
      vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" },
        { callback = function() vim.lsp.codelens.refresh() end })

      vim.keymap.set("n", "<leader>ca", "<cmd>lua require('fzf-lua').lsp_code_actions()<cr>", opts)
    end

    if client.supports_method("textDocument/formatting") then
      vim.keymap.set({ "n", "x" }, "<leader>cf", "<cmd>lua vim.lsp.buf.format({async = true})<cr>", opts)
    end
  end,
})
