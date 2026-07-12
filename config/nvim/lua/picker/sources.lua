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
-- expose the open-a-grep-hit helper so other launchers (e.g. lint) reuse it
picker.open_hit = function(line, cmd)
  edit_at(search.grep_parse(line), cmd)
end

-- path_hl helpers: byte span of the file path in a row (coloured PickerGrepFile).
local function whole_path(line)
  return 0, #line
end
-- path up to the first ":" after offset (0 for grep rows, #prefix for prefixed ones)
local function grep_path(line, offset)
  offset = offset or 0
  local c = line:find(":", offset + 1)
  return offset, c and c - 1 or #line
end

-- unload a buffer, first moving any window that shows it to another listed
-- buffer: :bdelete/nvim_buf_delete silently leave a *displayed* buffer loaded,
-- which is why the currently-viewed (first) entry wouldn't delete. No force, so
-- a modified buffer is kept (the pcall swallows E37/E89).
local function close_buffer(nr)
  if not nr or not vim.api.nvim_buf_is_valid(nr) then
    return
  end

  local others = vim.tbl_filter(function(b)
    return b ~= nr and vim.fn.buflisted(b) == 1
  end, vim.api.nvim_list_bufs())

  for _, w in ipairs(vim.fn.win_findbuf(nr)) do
    vim.api.nvim_win_call(w, function()
      vim.cmd(#others > 0 and ("buffer " .. others[1]) or "enew")
    end)
  end

  pcall(vim.api.nvim_buf_delete, nr, {})
end

-- an action that deletes the selected row then reopens the picker with the same
-- query so the list refreshes in place (used by the ^d delete bindings).
local function delete_and_relaunch(launcher, del)
  return function(ctx)
    if ctx.sel then
      del(ctx.sel)
    end
    ctx.close()
    vim.schedule(function()
      launcher({ query = ctx.query })
    end)
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
    { name = "files", prompt = "Files", on_pick = edit_file, path_hl = whole_path, resuming = o and o.resuming })
end

picker.launchers.gfiles = function(o)
  picker.open(lines_of(GIT_LS),
    { name = "gfiles", prompt = "GFiles", on_pick = edit_file, path_hl = whole_path, resuming = o and o.resuming })
end

picker.launchers.buffers = function(o)
  local names, bufof = {}, {} -- display name -> bufnr, so ^d deletes by number
  for _, b in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    if b.name ~= "" then
      local nm = vim.fn.fnamemodify(b.name, ":~:.")
      names[#names + 1] = nm
      bufof[nm] = b.bufnr
    end
  end

  picker.open(names, {
    name = "buffers",
    prompt = "Buffers",
    on_pick = edit_file,
    path_hl = whole_path,
    resuming = o and o.resuming,
    query = o and o.query,
    hint_extra = "   ^d del",
    actions = {
      ["<C-d>"] = delete_and_relaunch(picker.launchers.buffers, function(sel)
        close_buffer(bufof[sel])
      end),
    },
  })
end

local function lg_title(lg)
  if lg.mode == "file" then
    return "Filter file"
  end
  return lg.fixed and "LiveGrep [fixed]" or "LiveGrep"
end

picker.launchers.livegrep = function(o)
  -- ugrep, else plain grep (bare machines). rg is skipped on purpose: its Rust
  -- regex differs from POSIX, and A-r toggles -E (ERE) / -F (fixed), which both
  -- ugrep and grep accept — so the regex syntax stays uniform. Both emit
  -- file:line[:col]:text, which grep_parse handles.
  local tool = vim.fn.executable("ugrep") == 1
      and { "ugrep", "-RInk", "--ignore-files", "--color=never" }
    or { "grep", "-RInH", "--exclude-dir=.git" }
  -- per-history-entry state, so each resumed LiveGrep keeps its own grep pattern
  -- (gq), file filter (fq), prompt mode, regex/fixed flag and last hits (cache,
  -- reused so a resume renders without re-grepping). Restored from o.state on a
  -- resume, fresh otherwise, and handed back via get_state.
  -- ponytail: cache (grep hits) is kept in the persisted state so a resume
  -- renders instantly and file-filter mode still has rows to narrow. Ceiling is
  -- MAX hits × HISTORY_MAX entries; if that memory ever bites, drop cache here
  -- and re-grep on resume instead.
  local lg = (o and o.state) or { mode = "grep", gq = "", fq = "", fixed = false, cache = {} }
  local job -- running search handle, killed when the pattern changes or on close
  local MAX = 10000 -- cap hits fed to the picker; the tool can flood on short patterns
  local function recompute()
    if lg.fq == "" then
      return lg.cache
    end
    return vim.tbl_filter(function(line)
      local it = search.grep_parse(line)
      return it.file ~= nil and search.subseq(it.file, lg.fq)
    end, lg.cache)
  end
  picker.open({}, {
    name = "livegrep",
    prompt = lg_title(lg),
    query = o and o.query,
    parse = search.grep_parse,
    resuming = o and o.resuming,
    get_state = function()
      return lg
    end,
    on_close = function()
      if job then
        pcall(function()
          job:kill(9)
        end)
      end
    end,
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
      for _, c in ipairs(search.find_all(line, lg.gq)) do
        out[#out + 1] = { col = c, hl = "PickerMatch", priority = 200 }
      end
      local it = search.grep_parse(line)
      for _, c in ipairs((it.file and search.subseq_pos(it.file, lg.fq)) or {}) do
        out[#out + 1] = { col = c, hl = "PickerMatchFile", priority = 200 }
      end
      return out
    end,
    -- grep runs async: kill any in-flight search, launch the new one, and show
    -- the current cache now; feed() delivers the fresh hits when it returns.
    -- File-filter mode never re-greps — it just narrows the cache in-process.
    live = function(q, feed)
      if lg.mode == "file" then
        lg.fq = q
        return recompute()
      end
      if q == lg.gq then
        return recompute()
      end
      lg.gq = q
      if job then
        pcall(function()
          job:kill(9)
        end)
        job = nil
      end
      if q == "" then
        lg.cache = {}
        return {}
      end

      local cmd = vim.deepcopy(tool)
      table.insert(cmd, lg.fixed and "-F" or "-E") -- ERE regex, or fixed-string
      vim.list_extend(cmd, { "--", q })
      job = vim.system(cmd, { text = true }, function(res)
        local lines = vim.split(res.stdout or "", "\n", { trimempty = true })
        if #lines > MAX then
          lines = vim.list_slice(lines, 1, MAX)
        end
        lg.cache = lines
        vim.schedule(function()
          feed(recompute())
        end)
      end)
      return recompute() -- keep showing the previous hits until the new ones land
    end,
    actions = {
      ["<A-g>"] = function(ctx)
        lg.mode = lg.mode == "grep" and "file" or "grep"
        ctx.set_query(lg.mode == "grep" and lg.gq or lg.fq)
        ctx.set_title(lg_title(lg))
        ctx.keep_pos() -- switching mode keeps the same hits; don't jump to the top
        ctx.refilter()
      end,
      ["<A-r>"] = function(ctx)
        lg.fixed = not lg.fixed
        lg.gq = "\1" -- invalidate cache so the next grep re-runs in the new mode
        ctx.set_title(lg_title(lg))
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
    path_hl = whole_path,
    resuming = o and o.resuming,
    query = o and o.query,
    hint_extra = "   ^d del",
    on_pick = function(cwd)
      session.restore(cwd)
    end,
    actions = {
      ["<C-d>"] = delete_and_relaunch(picker.launchers.sessions, session.delete),
    },
  })
end

-- Hunks: every changed hunk in the repo (git diff vs HEAD) as a grep-shaped
-- file:line row, so you can fuzzy-search and jump to a change. Text is the @@
-- context (enclosing function git prints), which fuzzy-matches nicely.
picker.launchers.git_hunks = function(o)
  local root = require("git").root()
  if not root then
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
        -- pure deletions report +0; clamp so the row points at a real line
        items[#items + 1] = string.format("%s/%s:%d:1: %s", root, file, math.max(1, tonumber(ln)), tail)
      end
    end
  end
  if #items == 0 then
    vim.notify("git: no hunks")
    return
  end

  picker.open(items, {
    name = "git_hunks",
    prompt = "Hunks",
    parse = search.grep_parse,
    path_hl = grep_path,
    resuming = o and o.resuming,
    preview = require("git").cached_preview(
      function(line) return search.grep_parse(line or "").file end,
      function(f) return { "git", "-C", root, "diff", "--no-color", "-U3", "HEAD", "--", f } end,
      "diff",
      function(f) return vim.fn.fnamemodify(f, ":t") end),
    on_pick = function(line, cmd)
      edit_at(search.grep_parse(line), cmd)
    end,
  })
end

return picker.launchers
