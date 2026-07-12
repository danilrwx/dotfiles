-- PICKERS: the concrete sources (Files/GFiles/Buffers/LiveGrep), their shell
-- helpers, and how a chosen item is opened. Registers launchers on the engine.
local picker = require("picker")
local search = require("picker.search")
local session = require("session")

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
  if vim.fn.executable("fd") == 1 then
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
  -- ugrep, else plain grep (bare machines). rg is skipped on purpose: its Rust
  -- regex differs from POSIX, and A-r toggles -E (ERE) / -F (fixed), which both
  -- ugrep and grep accept — so the regex syntax stays uniform. Both emit
  -- file:line[:col]:text, which grep_parse handles.
  local tool = vim.fn.executable("ugrep") == 1
      and { "ugrep", "-RInk", "--ignore-files", "--color=never" }
    or { "grep", "-RInH", "--exclude-dir=.git" }
  -- Two persistent queries applied together: the grep pattern (drives the search tool)
  -- and the file filter (fuzzy on path). A-g only switches which one the prompt
  -- edits, so you can narrow files then refine the grep, or vice versa. `cache`
  -- holds the last grep hits so editing the file filter doesn't re-grep.
  local mode, gq, fq, cache = "grep", "", "", {}
  local fixed = false -- pattern is ERE by default (-E); A-r → fixed string (-F)
  local job -- running search handle, killed when the pattern changes
  local MAX = 10000 -- cap hits fed to the picker; the tool can flood on short patterns
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
    hint_extra = "   A-g grep/file   A-r regex/fixed",
    -- highlight both queries at once, in distinct colours: the grep pattern in
    -- the hit text (blue, literal) and the file filter fuzzily in the path
    -- (orange). The path is the line prefix, so its columns need no offset.
    line_positions = function(line)
      local out = {}
      -- colour the row structure grep-style: path magenta, line:col green
      -- (low priority so the match/file-filter highlights below overlay them).
      local c1 = line:find(":")
      local c2 = c1 and line:find(":", c1 + 1)
      if c1 then
        out[#out + 1] = { col = 0, end_col = c1 - 1, hl = "PickerGrepFile", priority = 100 }
      end
      if c1 and c2 then
        out[#out + 1] = { col = c1, end_col = c2 - 1, hl = "PickerGrepLnum", priority = 100 }
      end
      for _, c in ipairs(search.find_all(line, gq)) do
        out[#out + 1] = { col = c, hl = "PickerMatch", priority = 200 }
      end
      local it = search.grep_parse(line)
      for _, c in ipairs((it.file and search.subseq_pos(it.file, fq)) or {}) do
        out[#out + 1] = { col = c, hl = "PickerMatchFile", priority = 200 }
      end
      return out
    end,
    -- grep runs async: kill any in-flight search, launch the new one, and show
    -- the current cache now; feed() delivers the fresh hits when it returns.
    -- File-filter mode never re-greps — it just narrows the cache in-process.
    live = function(q, feed)
      if mode == "file" then
        fq = q
        return recompute()
      end
      if q == gq then
        return recompute()
      end
      gq = q
      if job then
        pcall(function()
          job:kill(9)
        end)
        job = nil
      end
      if q == "" then
        cache = {}
        return {}
      end
      local cmd = vim.deepcopy(tool)
      table.insert(cmd, fixed and "-F" or "-E") -- ERE regex, or fixed-string
      vim.list_extend(cmd, { "--", q })
      job = vim.system(cmd, { text = true }, function(res)
        local lines = vim.split(res.stdout or "", "\n", { trimempty = true })
        if #lines > MAX then
          lines = vim.list_slice(lines, 1, MAX)
        end
        cache = lines
        vim.schedule(function()
          feed(recompute())
        end)
      end)
      return recompute() -- keep showing the previous hits until the new ones land
    end,
    actions = {
      ["<A-g>"] = function(ctx)
        mode = mode == "grep" and "file" or "grep"
        ctx.set_query(mode == "grep" and gq or fq)
        ctx.set_title(mode == "file" and "Filter file" or "LiveGrep")
        ctx.refilter()
      end,
      ["<A-r>"] = function(ctx)
        fixed = not fixed
        gq = "\1" -- invalidate cache so the next grep re-runs in the new mode
        ctx.set_title(fixed and "LiveGrep [fixed]" or "LiveGrep [regex]")
        ctx.refilter()
      end,
    },
    on_pick = function(line, cmd)
      edit_at(search.grep_parse(line), cmd)
    end,
  })
end

-- Sessions: pick a saved per-cwd session to restore; C-d deletes one.
picker.launchers.sessions = function(o)
  picker.open(session.list(), {
    name = "sessions",
    prompt = "Sessions",
    resuming = o and o.resuming,
    hint_extra = "   ^d del",
    on_pick = function(cwd)
      session.restore(cwd)
    end,
    actions = {
      ["<C-d>"] = function(ctx)
        if ctx.sel then
          session.delete(ctx.sel)
        end
        ctx.close()
        vim.schedule(function()
          picker.launchers.sessions({ resuming = true })
        end)
      end,
    },
  })
end

-- Hunks: every changed hunk in the repo (git diff vs HEAD) as a grep-shaped
-- file:line row, so you can fuzzy-search and jump to a change. Text is the @@
-- context (enclosing function git prints), which fuzzy-matches nicely.
picker.launchers.git_hunks = function(o)
  local dir = vim.fn.expand("%:p:h")
  if dir == "" then
    dir = vim.fn.getcwd()
  end
  local root = vim.trim((vim.system({ "git", "-C", dir, "rev-parse", "--show-toplevel" }, { text = true }):wait().stdout or ""))
  if root == "" then
    vim.notify("not a git repo")
    return
  end
  local items, file = {}, nil
  for _, l in ipairs(lines_of({ "git", "-C", root, "diff", "--no-color", "-U0", "HEAD" })) do
    local f = l:match("^%+%+%+ b/(.+)")
    if f then
      file = f
    elseif file then
      local ln, tail = l:match("^@@ %-%S+ %+(%d+),?%d* @@ ?(.*)")
      if ln then
        items[#items + 1] = string.format("%s/%s:%s:1: %s", root, file, ln, tail)
      end
    end
  end
  if #items == 0 then
    vim.notify("git: no hunks")
    return
  end
  local dcache = {} -- file -> its `git diff -U3` lines, for the preview pane
  picker.open(items, {
    name = "git_hunks",
    prompt = "Hunks",
    parse = search.grep_parse,
    resuming = o and o.resuming,
    preview = function(v, line)
      local it = search.grep_parse(line or "")
      if not it.file then
        v:show_text({}, "", "")
        return
      end
      if dcache[it.file] then
        v:show_text(dcache[it.file], "diff", vim.fn.fnamemodify(it.file, ":t"))
        return
      end
      vim.system({ "git", "-C", root, "diff", "--no-color", "-U3", "HEAD", "--", it.file },
        { text = true }, function(r)
          local dl = vim.split(r.stdout or "", "\n")
          dcache[it.file] = dl
          vim.schedule(function()
            pcall(function()
              v:show_text(dl, "diff", vim.fn.fnamemodify(it.file, ":t"))
            end)
          end)
        end)
    end,
    on_pick = function(line, cmd)
      edit_at(search.grep_parse(line), cmd)
    end,
  })
end

local BOAR = "🐗 " -- diagnostics line prefix; stripped before parsing the path

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
    items[#items + 1] = string.format("%s%s:%d:%d: [%s] %s",
      BOAR, file, d.lnum + 1, d.col + 1, sev[d.severity] or "?", msg)
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
      edit_at(search.grep_parse((line:gsub("^" .. BOAR, ""))), cmd)
    end,
  })
end

return picker.launchers
