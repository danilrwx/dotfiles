vim.diagnostic.config({ virtual_text = { prefix = "🐗" }, signs = false })

-- whole-workspace diagnostics: LSP drops unopened files, so run the project
-- checker (golangci-lint, else `go vet`) async and parse into quickfix.
local function diag_ws()
  local cmd = vim.fn.executable("golangci-lint") == 1 and { "golangci-lint", "run", "./..." }
    or vim.fn.executable("go") == 1 and { "go", "vet", "./..." }
    or nil
  if not cmd then
    vim.notify("no golangci-lint / go")
    return
  end
  vim.notify("running " .. table.concat(cmd, " ") .. " ...")
  vim.system(cmd, { text = true }, function(res)
    local lines = vim.split((res.stdout or "") .. (res.stderr or ""), "\n")
    vim.schedule(function()
      vim.fn.setqflist({}, " ", {
        title = table.concat(cmd, " "),
        lines = lines,
        efm = [[%-G#%.%#,%f:%l:%c: %m,%f:%l: %m]],
      })
      local valid = vim.tbl_filter(function(i)
        return i.valid == 1
      end, vim.fn.getqflist())
      if #valid == 0 then
        vim.notify("workspace: no diagnostics")
        return
      end
      vim.cmd("copen")
      vim.cmd("cfirst")
    end)
  end)
end
vim.api.nvim_create_user_command("LspDiagWs", diag_ws, {})
vim.keymap.set("n", "<leader>D", diag_ws, { silent = true })
