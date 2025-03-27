return {
  {
    "neovim/nvim-lspconfig",
    cmd = { "LspInfo", "LspInstall", "LspStart" },
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("lspconfig").gopls.setup({
        root_dir = function(fname)
          local util = require("lspconfig.util")
          local async = require("lspconfig.async")
          local mod_cache = nil

          -- see: https://github.com/neovim/nvim-lspconfig/issues/804
          if not mod_cache then
            local result = async.run_command({ "go", "env", "GOMODCACHE" })
            if result and result[1] then
              mod_cache = vim.trim(result[1])
            else
              mod_cache = vim.fn.system("go env GOMODCACHE")
            end
          end
          if mod_cache and fname:sub(1, #mod_cache) == mod_cache then
            local clients = util.get_lsp_clients({ name = "gopls" })
            if #clients > 0 then
              return clients[#clients].config.root_dir
            end
          end
          return util.root_pattern("go.work", ".git", "go.mod")(fname)
        end,
      })

      require("lspconfig").golangci_lint_ls.setup({
        filetypes = { "go", "gomod" },
        init_options = { command = { "golangci-lint", "run", "--out-format", "json", "--issues-exit-code=1" } },
      })

      require("lspconfig").lua_ls.setup({
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
      })
    end,
  },

  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        -- go = { "golangci", "gofmt" },
        go = { "goimports", "gofumpt" },
        ["*"] = { "codespell" },
        ["_"] = { "trim_whitespace" },
      },
      format_on_save = { lsp_format = "fallback", timeout_ms = 500 },
      formatters = {
        golangci = {
          command = "golangci-lint",
          args = { "run", "--out-format", "json", "--fix", "$FILENAME" },
          -- cwd = require("conform.util").root_file({ ".golangci.yaml" }),
        },
      },
    },
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
