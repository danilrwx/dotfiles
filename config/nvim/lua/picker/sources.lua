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
  -- A-g toggles the prompt between grep mode (query drives ripgrep) and file
  -- mode (query fuzzily filters the last grep hits by path). `last` caches the
  -- hits so file mode filters without re-grepping.
  local mode, last = "grep", {}
  picker.open({}, {
    name = "livegrep",
    prompt = "LiveGrep",
    query = o and o.query,
    parse = search.grep_parse,
    resuming = o and o.resuming,
    hint_extra = "   A-g grep/file",
    live = function(q)
      if mode == "file" then
        if q == "" then
          return last
        end
        return vim.tbl_filter(function(line)
          local it = search.grep_parse(line)
          return it.file ~= nil and search.subseq(it.file, q)
        end, last)
      end
      if q == "" then
        last = {}
        return last
      end
      last = lines_of(vim.list_extend(vim.deepcopy(tool), { "--", q }))
      return last
    end,
    actions = {
      ["<A-g>"] = function(ctx)
        mode = mode == "grep" and "file" or "grep"
        ctx.set_query("")
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
