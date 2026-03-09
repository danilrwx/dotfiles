return {
  {
    'neovim/nvim-lspconfig',
    cmd = { "LspInfo", "LspInstall", "LspStart" },
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      servers = {
        lua_ls = {
          on_init = function(client)
            if client.workspace_folders then
              local path = client.workspace_folders[1].name
              if
                  path ~= vim.fn.stdpath("config")
                  and (vim.loop.fs_stat(path .. "/.luarc.json") or vim.loop.fs_stat(path .. "/.luarc.jsonc"))
              then
                return
              end
            end

            client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
              runtime = { version = "LuaJIT" },
              workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } },
            })
          end,
          settings = { Lua = {} },
        },
        gopls = {},
      }
    },
    config = function(_, opts)
      local lspconfig = require('lspconfig')
      for server, config in pairs(opts.servers) do
        lspconfig[server].setup(config)
      end
    end
  },
  {
    "nvimtools/none-ls.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local nls = require("null-ls")
      nls.setup({
        debug = true,
        sources = {
          nls.builtins.diagnostics.golangci_lint,
          nls.builtins.code_actions.gomodifytags,
          nls.builtins.code_actions.impl,
          nls.builtins.formatting.gofumpt,
          nls.builtins.formatting.goimports,
          nls.builtins.code_actions.refactoring
        },
      })
    end,
  },

  {
    "Wansmer/symbol-usage.nvim",
    event = "LspAttach",
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
    },
  },
}
