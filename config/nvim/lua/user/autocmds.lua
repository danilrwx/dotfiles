local M = {}

M.setup = function()
  local group = vim.api.nvim_create_augroup("user_autocmds", { clear = true })

  vim.api.nvim_create_autocmd("TextYankPost", {
    group = group,
    callback = function()
      vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
    end,
  })

  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function()
      require('symbol-usage').setup({
        kinds = {
          vim.lsp.protocol.SymbolKind.Function,
          vim.lsp.protocol.SymbolKind.Method,
          vim.lsp.protocol.SymbolKind.Interface,
          vim.lsp.protocol.SymbolKind.Constant,
        },
        definition = { enabled = true },
        implementation = { enabled = true },
        references = { enabled = true, include_declaration = false },
        vt_position = "end_of_line",
      })
    end,
  })

  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function(event)
      local opts = { buffer = event.buf }
      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if client == nil then return end

      if client.server_capabilities.codeLensProvider then
        vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold" }, {
          group = group,
          callback = function() vim.lsp.codelens.refresh() end,
        })
        vim.keymap.set("n", "grc", "<cmd>lua vim.lsp.codelens.run()<cr>", opts)
      end

      if client:supports_method("textDocument/formatting") then
        vim.keymap.set({ "n", "x" }, "grf", "<cmd>lua vim.lsp.buf.format({async = true})<cr>", opts)
      end
    end,
  })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    callback = function(details)
      if vim.treesitter.get_parser(nil, nil, { error = false }) then
        vim.treesitter.start()
      end

      local bufnr = details.buf
      vim.bo[bufnr].syntax = "on"
      vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

      vim.wo.foldlevel = 99
      vim.wo.foldmethod = "expr"
      vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    end,
  })

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function()
      local link = vim.api.nvim_set_hl
      local function hl(group, opts) link(0, group, opts) end

      hl("Normal", { bg = nil })
      hl("SignColumn", { bg = nil })

      hl("Added", { fg = "#00cd00" })
      hl("Changed", { fg = "#00cdcd" })
      hl("Removed", { fg = "#cd0000" })

      local highlight_keep = {
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
        if highlight_keep[g] then
          return highlight_keep[g]
        end
        for keep, target in pairs(highlight_keep) do
          if g:find("^" .. keep:gsub("%.", "%%.") .. "%.") then
            return target
          end
        end
        return "Normal"
      end

      for _, g in ipairs(vim.fn.getcompletion("@", "highlight")) do
        hl(g, { link = target_for(g) })
      end

      for g, target in pairs(highlight_keep) do
        hl(g, { link = target })
      end
    end,
  })
end

return M
