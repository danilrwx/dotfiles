local picker = require("picker")
local search = require("picker.search")

vim.diagnostic.config({ virtual_text = { prefix = "🐗" }, signs = false })

-- Diagnostics = whole-project error search. Neovim's own LSP only reports open
-- buffers, so run the project linter (golangci-lint, else `go vet`) and show its
-- hits in the picker (fuzzy + preview), like fzf-lua's workspace diagnostics but
-- project-wide. Async — the linter takes a moment, then the picker opens.
picker.launchers.diagnostics = function()
  local cmd = vim.fn.executable("golangci-lint") == 1 and { "golangci-lint", "run", "./..." }
    or vim.fn.executable("go") == 1 and { "go", "vet", "./..." }
    or nil
  if not cmd then
    vim.notify("no golangci-lint / go", vim.log.levels.WARN)
    return
  end
  vim.notify("running " .. table.concat(cmd, " ") .. " …")
  vim.system(cmd, { text = true }, function(res)
    local items = {}
    for _, line in ipairs(vim.split((res.stdout or "") .. "\n" .. (res.stderr or ""), "\n")) do
      local it = search.grep_parse(line)
      if it.file and it.lnum then -- keep only file:line[:col]: rows, drop headers
        items[#items + 1] = line
      end
    end
    vim.schedule(function()
      if #items == 0 then
        vim.notify("diagnostics: no issues")
        return
      end
      picker.open(items, {
        name = "diagnostics",
        prompt = "Diagnostics",
        parse = search.grep_parse,
        path_hl = function(line)
          local c = line:find(":")
          return 0, c and c - 1 or #line
        end,
        on_pick = picker.open_hit,
      })
    end)
  end)
end

-- reachable as `:Picker diagnostics`; <leader>D is the fzf-lua-style shortcut
vim.keymap.set("n", "<leader>D", picker.launchers.diagnostics, { silent = true })
