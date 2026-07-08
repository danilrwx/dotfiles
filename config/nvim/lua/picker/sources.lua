-- PICKERS: the concrete sources (Files/GFiles/Buffers/LiveGrep), their shell
-- helpers, and how a chosen item is opened. Registers launchers on the engine.
local picker = require("picker")
local search = require("picker.search")

local OPEN = { edit = "edit", split = "split", vsplit = "vsplit", tab = "tabedit" }
local GIT_LS = { "git", "ls-files", "--cached", "--others", "--exclude-standard" }

local function lines_of(cmd)
  local ok, r = pcall(function()
    return vim.system(cmd, { text = true }):wait()
  end)
  if not ok or not r then
    return {}
  end
  return vim.split(r.stdout or "", "\n", { trimempty = true })
end

local function edit_file(f, cmd)
  local verb = OPEN[cmd] or "edit"
  if verb == "edit" and vim.bo.modified then
    verb = "hide edit" -- current buffer has unsaved changes; keep it (no E37)
  end
  vim.cmd(verb .. " " .. vim.fn.fnameescape(f))
end

-- open a parsed {file,lnum,col} hit and jump to the position
local function edit_at(it, cmd)
  if not it.file then
    return
  end
  edit_file(it.file, cmd)
  if it.lnum then
    pcall(vim.fn.cursor, it.lnum, it.col or 1)
  end
end

local function files_source()
  if vim.fn.executable("rg") == 1 then
    return { "rg", "--files" }
  elseif vim.fn.executable("fd") == 1 then
    return { "fd", "--type", "f" }
  end
  return GIT_LS
end

picker.launchers.files = function(o)
  picker.open(lines_of(files_source()),
    { name = "files", prompt = "Files", on_pick = edit_file, resuming = o and o.resuming })
end

picker.launchers.gfiles = function(o)
  picker.open(lines_of(GIT_LS),
    { name = "gfiles", prompt = "GFiles", on_pick = edit_file, resuming = o and o.resuming })
end

picker.launchers.buffers = function(o)
  local names = {}
  for _, b in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    if b.name ~= "" then
      names[#names + 1] = vim.fn.fnamemodify(b.name, ":~:.")
    end
  end
  picker.open(names, {
    name = "buffers",
    prompt = "Buffers",
    on_pick = edit_file,
    resuming = o and o.resuming,
    hint_extra = "   ^d del",
    actions = {
      ["<C-d>"] = function(ctx)
        if ctx.sel then
          pcall(vim.cmd, "bdelete " .. vim.fn.fnameescape(ctx.sel))
        end
        ctx.close()
        vim.schedule(function()
          picker.launchers.buffers({ resuming = true })
        end)
      end,
    },
  })
end

picker.launchers.livegrep = function(o)
  local tool = vim.fn.executable("ugrep") == 1
      and { "ugrep", "-RInk", "--ignore-files", "--color=never" }
    or { "rg", "--column", "--line-number", "--no-heading", "--color=never" }
  -- Two persistent queries applied together: the grep pattern (drives ripgrep)
  -- and the file filter (fuzzy on path). A-g only switches which one the prompt
  -- edits, so you can narrow files then refine the grep, or vice versa. `cache`
  -- holds the last grep hits so editing the file filter doesn't re-grep.
  local mode, gq, fq, cache = "grep", "", "", {}
  local function recompute()
    if fq == "" then
      return cache
    end
    return vim.tbl_filter(function(line)
      local it = search.grep_parse(line)
      return it.file ~= nil and search.subseq(it.file, fq)
    end, cache)
  end
  picker.open({}, {
    name = "livegrep",
    prompt = "LiveGrep",
    query = o and o.query,
    parse = search.grep_parse,
    resuming = o and o.resuming,
    hint_extra = "   A-g grep/file",
    -- highlight both queries at once, in distinct colours: the grep pattern in
    -- the hit text (blue, literal) and the file filter fuzzily in the path
    -- (orange). The path is the line prefix, so its columns need no offset.
    line_positions = function(line)
      local out = {}
      for _, c in ipairs(search.find_all(line, gq)) do
        out[#out + 1] = { col = c, hl = "PickerMatch" }
      end
      local it = search.grep_parse(line)
      for _, c in ipairs((it.file and search.subseq_pos(it.file, fq)) or {}) do
        out[#out + 1] = { col = c, hl = "PickerMatchFile" }
      end
      return out
    end,
    live = function(q)
      if mode == "grep" then
        if q ~= gq then
          gq = q
          cache = q ~= "" and lines_of(vim.list_extend(vim.deepcopy(tool), { "--", q })) or {}
        end
      else
        fq = q
      end
      return recompute()
    end,
    actions = {
      ["<A-g>"] = function(ctx)
        mode = mode == "grep" and "file" or "grep"
        ctx.set_query(mode == "grep" and gq or fq)
        ctx.set_title(mode == "file" and "Filter file" or "LiveGrep")
        ctx.refilter()
      end,
    },
    on_pick = function(line, cmd)
      edit_at(search.grep_parse(line), cmd)
    end,
  })
end

-- Diagnostics: one grep-shaped line per diagnostic (file:line:col: [SEV] msg),
-- sorted most-severe first, jumped to via the same parser. Static source, so
-- the query fuzzy-filters it. o.buf = current buffer only.
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
    items[#items + 1] = string.format("%s:%d:%d: [%s] %s",
      file, d.lnum + 1, d.col + 1, sev[d.severity] or "?", msg)
  end
  local sev_hl = { E = "DiagnosticError", W = "DiagnosticWarn", I = "DiagnosticInfo", H = "DiagnosticHint" }
  picker.open(items, {
    name = "diagnostics",
    prompt = "Diagnostics",
    parse = search.grep_parse,
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
      edit_at(search.grep_parse(line), cmd)
    end,
  })
end

return picker.launchers
