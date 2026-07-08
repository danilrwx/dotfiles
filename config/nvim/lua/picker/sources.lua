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
    -- highlight the query you're editing: grep pattern in the hit text (literal),
    -- or the file filter fuzzily in the path.
    line_positions = function(line)
      if mode == "grep" then
        return search.find_all(line, gq)
      end
      local it = search.grep_parse(line)
      return (it.file and search.subseq_pos(it.file, fq)) or {}
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
      local it = search.grep_parse(line)
      if it.file then
        edit_file(it.file, cmd)
        if it.lnum then
          pcall(vim.fn.cursor, it.lnum, 1)
        end
      end
    end,
  })
end

return picker.launchers
