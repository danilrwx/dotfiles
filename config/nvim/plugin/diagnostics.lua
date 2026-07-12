local picker = require("picker")
local search = require("picker.search")

vim.diagnostic.config({ virtual_text = { prefix = "🐗" }, signs = false })

local BOAR = "🐗 " -- diagnostics line prefix; stripped before parsing the path

-- Workspace diagnostics picker (fzf-lua's diagnostics_workspace): one grep-shaped
-- row per diagnostic across all buffers, severity-sorted, fuzzy-filtered and
-- jumped to. `:Picker! diagnostics` / o.buf scopes it to the current buffer.
picker.launchers.diagnostics = function(o)
  local sev = { "E", "W", "I", "H" }
  local ds = vim.diagnostic.get(o and o.buf and 0 or nil)
  table.sort(ds, function(a, b)
    return a.severity < b.severity
  end)

  local items = {}
  for _, d in ipairs(ds) do
    local file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(d.bufnr), ":~:.")
    local msg = (d.message or ""):gsub("%s*\n%s*", " ")
    items[#items + 1] = string.format("%s%s:%d:%d: [%s] %s",
      BOAR, file, d.lnum + 1, d.col + 1, sev[d.severity] or "?", msg)
  end

  local sev_hl = { E = "DiagnosticError", W = "DiagnosticWarn", I = "DiagnosticInfo", H = "DiagnosticHint" }
  picker.open(items, {
    name = "diagnostics",
    prompt = "Diagnostics",
    parse = search.grep_parse,
    path_hl = function(line)
      local c = line:find(":", #BOAR + 1)
      return #BOAR, c and c - 1
    end,
    resuming = o and o.resuming,
    -- colour the [SEV] marker by severity (builtin Diagnostic* groups)
    line_positions = function(line)
      local s = line:find("%[%u%]")
      local hl = s and sev_hl[line:sub(s + 1, s + 1)]
      if not hl then
        return {}
      end
      local out = {}
      for c = s - 1, s + 1 do
        out[#out + 1] = { col = c, hl = hl }
      end
      return out
    end,
    on_pick = function(line, cmd)
      picker.open_hit((line:gsub("^" .. BOAR, "")), cmd)
    end,
  })
end

vim.keymap.set("n", "<leader>D", picker.launchers.diagnostics, { silent = true })

-- Whole-project lint into the quickfix: the LSP only reports open buffers, so run
-- the project linter (golangci-lint, else `go vet`) async and parse its output.
-- Kept as a command, separate from the diagnostics picker.
local function lint_project()
  local cmd = vim.fn.executable("golangci-lint") == 1 and { "golangci-lint", "run", "./..." }
    or vim.fn.executable("go") == 1 and { "go", "vet", "./..." }
    or nil
  if not cmd then
    vim.notify("no golangci-lint / go", vim.log.levels.WARN)
    return
  end

  vim.notify("running " .. table.concat(cmd, " ") .. " …")
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
        vim.notify("lint: no issues")
        return
      end

      vim.cmd("copen")
      vim.cmd("cfirst")
    end)
  end)
end

vim.api.nvim_create_user_command("Lint", lint_project, {})
